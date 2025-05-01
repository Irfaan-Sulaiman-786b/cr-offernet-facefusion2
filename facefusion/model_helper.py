import os
import sys
from functools import lru_cache
from typing import Any, Union, Optional
import hashlib

import onnx
import onnxruntime as ort
import numpy as np
from google.cloud import storage
from google.auth.exceptions import DefaultCredentialsError
from facefusion.typing import ModelInitializer

# Configuration
BUCKET_NAME = "gcs-offernet-facefusion-live"
GCS_MODELS_DIR = ".assets/models"  # Corrected path within the GCS bucket
MODELS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.assets', 'models'))
os.makedirs(MODELS_DIR, exist_ok=True)

class GCSModelManager:
    _instance = None
    _client = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._initialize_client()
        return cls._instance

    @classmethod
    def _initialize_client(cls):
        try:
            if "GOOGLE_APPLICATION_CREDENTIALS" in os.environ:
                cls._client = storage.Client.from_service_account_json(
                    os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
                )
            else:
                cls._client = storage.Client()
        except DefaultCredentialsError:
            print("GCS credentials not found, falling back to local models only")
            cls._client = None
        except Exception as e:
            print(f"GCS initialization error: {e}")
            cls._client = None

    def download_model(self, model_name: str) -> str:
        """Download model from GCS (/.assets/models) if not exists locally"""
        local_path = os.path.join(MODELS_DIR, model_name)

        # Check if already exists locally
        if os.path.exists(local_path):
            return local_path

        if self._client is None:
            raise RuntimeError("GCS client not available - cannot download models")

        try:
            blob = self._client.bucket(BUCKET_NAME).blob(f"{GCS_MODELS_DIR}/{model_name}")
            if not blob.exists():
                raise FileNotFoundError(f"Model {model_name} not found in GCS bucket at {GCS_MODELS_DIR}/{model_name}")

            print(f"Downloading {model_name} from GCS...")
            blob.download_to_filename(local_path)

            # Verify download
            if not os.path.exists(local_path):
                raise RuntimeError(f"Download failed for {model_name}")

            return local_path
        except Exception as e:
            # Clean up if download failed
            if os.path.exists(local_path):
                os.remove(local_path)
            raise RuntimeError(f"Failed to download {model_name}: {e}")

    @staticmethod
    def verify_model_integrity(model_path: str) -> bool:
        """Basic verification that file is a valid ONNX model"""
        try:
            onnx.load(model_path)
            return True
        except Exception:
            return False

# Initialize singleton manager
gcs_manager = GCSModelManager()

@lru_cache(maxsize=32)
def get_static_model_initializer(model_path: str) -> np.ndarray:
    """
    FaceFusion-compatible static model initializer
    Args:
        model_path: Original model path from FaceFusion (e.g., '../.assets/models/yoloface_8n.onnx')
    Returns:
        numpy.ndarray: Model initializer weights
    """
    model_name = os.path.basename(model_path)
    try:
        local_path = gcs_manager.download_model(model_name)

        if not gcs_manager.verify_model_integrity(local_path):
            raise RuntimeError(f"Invalid ONNX model: {model_name}")

        model = onnx.load(local_path)
        if not model.graph.initializer:
            raise ValueError(f"No initializers found in {model_name}")

        return np.array(onnx.numpy_helper.to_array(model.graph.initializer[-1]))
    except Exception as e:
        raise RuntimeError(f"Failed to get static initializer for {model_name}: {e}")

@lru_cache(maxsize=32)
def load_model(model_path: str) -> Union[ort.InferenceSession, np.ndarray]:
    """
    Dual-purpose model loader that matches FaceFusion's expectations
    Args:
        model_path: Original model path from FaceFusion
    Returns:
        Either InferenceSession or numpy array depending on model type
    """
    model_name = os.path.basename(model_path)
    try:
        local_path = gcs_manager.download_model(model_name)

        if not gcs_manager.verify_model_integrity(local_path):
            raise RuntimeError(f"Invalid ONNX model: {model_name}")

        model = onnx.load(local_path)

        # Return static initializer if available
        if model.graph.initializer:
            return np.array(onnx.numpy_helper.to_array(model.graph.initializer[-1]))

        # Fall back to inference session
        return create_inference_session(local_path)
    except Exception as e:
        raise RuntimeError(f"Failed to load model {model_name}: {e}")

def create_inference_session(model_path: str) -> ort.InferenceSession:
    """Create properly configured ONNX Runtime inference session"""
    session_options = ort.SessionOptions()

    # Configure session options
    session_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    session_options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
    session_options.inter_op_num_threads = 1
    session_options.intra_op_num_threads = 4

    # Get available providers and prioritize CUDA if available
    providers = ort.get_available_providers()
    preferred_order = ['CUDAExecutionProvider', 'CPUExecutionProvider']
    providers = sorted(providers, key=lambda x: preferred_order.index(x) if x in preferred_order else len(preferred_order))

    try:
        return ort.InferenceSession(
            model_path,
            sess_options=session_options,
            providers=providers
        )
    except Exception as e:
        raise RuntimeError(f"Failed to create inference session: {e}")

def preload_essential_models():
    """Pre-download models that are required early in the pipeline"""
    essential_models = [
        'yoloface_8n.onnx',     # Face detection
        'arcface_w600k_r50.onnx', # Face recognition
        'fan_68_5.onnx',
        '2dfan4.onnx',
        'fairface.onnx',
        'inswapper_128_fp16.onnx',
        'open_nsfw.onnx'
    ]

    for model in essential_models:
        try:
            print(f"Preloading {model}...")
            gcs_manager.download_model(model)
        except Exception as e:
            print(f"Warning: Could not preload {model}: {e}")

# Preload essential models on import
if not os.getenv("SKIP_MODEL_PRELOAD"):
    preload_essential_models()

# Clean up function for cached sessions
def clear_model_cache():
    get_static_model_initializer.cache_clear()
    load_model.cache_clear()