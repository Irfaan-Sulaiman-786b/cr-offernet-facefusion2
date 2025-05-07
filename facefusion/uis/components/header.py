import gradio as gr
from google.cloud import storage
from google.oauth2 import service_account
import os
import json
import base64

# Load the service account key contents from the environment variable
GOOGLE_SERVICE_ACCOUNT_KEY = os.getenv("GOOGLE_SERVICE_ACCOUNT_KEY")

# Function to retrieve and base64-encode the logo image from GCS
def get_logo_base64():
    if not GOOGLE_SERVICE_ACCOUNT_KEY:
        print("No service account key content found in environment variable.")
        return None

    try:
        # Parse the service account key from JSON string
        key_info = json.loads(GOOGLE_SERVICE_ACCOUNT_KEY)
        credentials = service_account.Credentials.from_service_account_info(key_info)
        client = storage.Client(credentials=credentials, project=credentials.project_id)

        # Get logo image from GCS
        bucket = client.bucket("gcs-offernet-facefusion-live")
        blob = bucket.blob("logo.jpg")
        logo_bytes = blob.download_as_bytes()

        # Encode image as base64 string
        return base64.b64encode(logo_bytes).decode("utf-8")

    except Exception as e:
        print(f"Error retrieving logo: {e}")
        return None

# Gradio render function
def render() -> gr.Blocks:
    print("******* render.render")

    logo_base64 = get_logo_base64()
    logo_html = ""

    if logo_base64:
        print("******* logo_base64")
        logo_html = f"""
            <img src="data:image/jpeg;base64,{logo_base64}" style="max-height: 125px; margin-right: 25px;">
        """

    header_html = f"""
        <div style="display: flex; align-items: center; justify-content: center; padding: 10px; margin-bottom: 0;">
            {logo_html}
            <h1 style="font-family: Arial, sans-serif; font-size: 28px; font-weight: bold; color: #4A90E2; margin: 0;">
                RavenWatch with FaceFusion Integration
            </h1>
        </div>
        <hr style="border: 2px solid #4A90E2; width: 100%; margin-top: 0;">
    """

    with gr.Blocks() as app:
        gr.HTML(header_html)

    return app
