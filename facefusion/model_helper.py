import os
from functools import lru_cache

import onnx
from google.cloud import storage
from facefusion.typing import ModelInitializer

# Cloud Storage settings
BUCKET_NAME = "gcs-offernet-facefusion-live"
SERVICE_ACCOUNT_KEY = os.getenv("GOOGLE_SERVICE_ACCOUNT_KEY")  # Optional (may be None)

def create_storage_client() -> storage.Client:
    """Create a GCS storage client, using service account key if provided."""
    if SERVICE_ACCOUNT_KEY and os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"Using service account key: {SERVICE_ACCOUNT_KEY}")
        return storage.Client.from_service_account_json(SERVICE_ACCOUNT_KEY)
    else:
        print("Using default application credentials (no explicit key).")
        return storage.Client()

def download_model_from_gcs(bucket_name: str, cloud_model_path: str, local_model_path: str) -> None:
    """Download the model from GCS to a local path."""
    storage_client = create_storage_client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(cloud_model_path)

    # Ensure the local directories exist
    os.makedirs(os.path.dirname(local_model_path), exist_ok=True)

    # Download the model to /tmp (temporary directory in Cloud Run)
    if os.path.exists("/tmp"):
        local_model_path = os.path.join("/tmp", os.path.basename(local_model_path))

    blob.download_to_filename(local_model_path)
    print(f"✅ Model downloaded from GCS: {cloud_model_path} -> {local_model_path}")

@lru_cache(maxsize=None)
def get_static_model_initializer(model_path: str) -> ModelInitializer:
    """Get model initializer, downloading it from GCS if missing."""
    # If the model isn't found locally, download it from GCS
    if not os.path.exists(model_path):
        filename = os.path.basename(model_path)  # e.g., "yoloface_8n.onnx"
        cloud_model_path = f"models/{filename}"  # Model is under the 'models/' folder in GCS
        print(f"⚠️ Model {model_path} not found locally. Downloading from GCS...")
        
        # Ensure the model gets downloaded to /tmp on Cloud Run
        download_model_from_gcs(BUCKET_NAME, cloud_model_path, f"/tmp/{filename}")
        
        model_path = f"/tmp/{filename}"  # Set the model path to /tmp for Cloud Run

    print(f"📦 Loading ONNX model: {model_path}")
    model = onnx.load(model_path)
    return onnx.numpy_helper.to_array(model.graph.initializer[-1])
