import os
from functools import lru_cache

import onnx
from google.cloud import storage
from facefusion.typing import ModelInitializer

# Cloud storage bucket and service account key
BUCKET_NAME = "gcs-offernet-facefusion-live"
GOOGLE_SERVICE_ACCOUNT_KEY = os.getenv("GOOGLE_SERVICE_ACCOUNT_KEY")

def download_model_from_gcs(bucket_name: str, model_file_name: str, local_model_path: str) -> None:
    """Download the model from Google Cloud Storage to a local path."""
    # Create a storage client with explicit credentials
    storage_client = storage.Client.from_service_account_json(GOOGLE_SERVICE_ACCOUNT_KEY)

    # Get the bucket
    bucket = storage_client.bucket(bucket_name)

    # Download the blob
    blob = bucket.blob(model_file_name)
    blob.download_to_filename(local_model_path)

    print(f"Model downloaded from GCS: {model_file_name} -> {local_model_path}")

@lru_cache(maxsize=None)
def get_static_model_initializer(model_path: str) -> ModelInitializer:
    """Get model initializer, downloading from GCS if not present locally."""
    if not os.path.exists(model_path):
        model_file_name = "models/face_swapper.onnx"  # The path inside the bucket
        print(f"Model not found locally. Downloading from GCS: {model_file_name}")
        download_model_from_gcs(BUCKET_NAME, model_file_name, model_path)

    print(f"******* model_helper: get_static_model_initializer: model_path: {model_path}")
    model = onnx.load(model_path)
    return onnx.numpy_helper.to_array(model.graph.initializer[-1])
