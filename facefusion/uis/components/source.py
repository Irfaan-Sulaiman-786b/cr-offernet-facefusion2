from typing import List, Optional, Tuple
import gradio as gr
import cv2
import tempfile
from facefusion import state_manager, wording
from facefusion.common_helper import get_first
from facefusion.filesystem import filter_audio_paths, filter_image_paths, has_audio, has_image
from facefusion.uis.core import register_ui_component
from facefusion.uis.typing import File

SOURCE_FILE: Optional[gr.File] = None
SOURCE_CAMERA_BUTTON: Optional[gr.Button] = None
SOURCE_WEBCAM: Optional[gr.HTML] = None
SOURCE_AUDIO: Optional[gr.Audio] = None
SOURCE_IMAGE: Optional[gr.Image] = None
webcam_active = False
cap = None

def render() -> None:
    global SOURCE_FILE, SOURCE_CAMERA_BUTTON, SOURCE_WEBCAM, SOURCE_AUDIO, SOURCE_IMAGE

    stored_source_paths = state_manager.get_item('source_paths')
    has_source_audio = has_audio(stored_source_paths)
    has_source_image = has_image(stored_source_paths)

    SOURCE_FILE = gr.File(
        label=wording.get('uis.source_file_label') or "Upload Source Image(s)/Audio",
        file_count='multiple',
        file_types=['audio', 'image'],
        value=stored_source_paths if stored_source_paths else None
    )

    with gr.Row():
        SOURCE_CAMERA_BUTTON = gr.Button(
            value=wording.get('uis.take_picture_button') or "TAKE PICTURE",
            variant='primary',
            size='sm'
        )

        SOURCE_WEBCAM = gr.HTML(
            value="""
            <div>
                <video id="webcam" width="100%" height="auto" autoplay></video>
                <button id="capture" style="margin-top: 10px;">Capture</button>
                <canvas id="canvas" style="display: none;"></canvas>
            </div>
            <script>
                const video = document.getElementById('webcam');
                const captureButton = document.getElementById('capture');
                const canvas = document.getElementById('canvas');
                const context = canvas.getContext('2d');

                async function startWebcam() {
                    const stream = await navigator.mediaDevices.getUserMedia({ video: true });
                    video.srcObject = stream;
                }

                captureButton.addEventListener('click', () => {
                    context.drawImage(video, 0, 0, canvas.width, canvas.height);
                    const imageDataUrl = canvas.toDataURL('image/jpeg');
                    const event = new CustomEvent("webcam-image-captured", { detail: imageDataUrl });
                    window.dispatchEvent(event);
                });

                video.onloadedmetadata = () => {
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                };

                startWebcam();
            </script>
            """,
            visible=True
        )

    source_audio_path = get_first(filter_audio_paths(stored_source_paths))
    source_image_path = get_first(filter_image_paths(stored_source_paths))

    SOURCE_AUDIO = gr.Audio(
        label=wording.get('uis.source_audio_preview_label') or "Source Audio Preview",
        value=source_audio_path if has_source_audio else None,
        visible=has_source_audio,
        show_label=False
    )

    SOURCE_IMAGE = gr.Image(
        label=wording.get('uis.source_image_preview_label') or "Source Image Preview",
        value=source_image_path if has_source_image else None,
        visible=has_source_image,
        show_label=False
    )

    register_ui_component('source_audio', SOURCE_AUDIO)
    register_ui_component('source_image', SOURCE_IMAGE)
    register_ui_component('source_camera_button', SOURCE_CAMERA_BUTTON)
    register_ui_component('source_webcam', SOURCE_WEBCAM)
    register_ui_component('source_file', SOURCE_FILE)

def listen() -> None:
    if SOURCE_FILE and SOURCE_CAMERA_BUTTON and SOURCE_WEBCAM and SOURCE_AUDIO and SOURCE_IMAGE:
        SOURCE_FILE.change(update, inputs=SOURCE_FILE, outputs=[SOURCE_AUDIO, SOURCE_IMAGE])
        SOURCE_CAMERA_BUTTON.click(
            toggle_webcam,
            outputs=[SOURCE_WEBCAM, SOURCE_CAMERA_BUTTON]
        ).then(
            capture_image,
            outputs=[SOURCE_IMAGE, SOURCE_WEBCAM, SOURCE_CAMERA_BUTTON]
        )
    else:
        print("Warning: Source components not fully initialized before listen() call.")

def toggle_webcam() -> Tuple[gr.HTML, gr.Button]:
    global webcam_active, cap

    if not webcam_active:
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            return gr.HTML(visible=False), gr.Button(value="Webcam Error")

        webcam_active = True
        return gr.HTML(visible=True), gr.Button(value="Take Picture Now")
    else:
        if cap is not None:
            cap.release()
        webcam_active = False
        return gr.HTML(visible=False), gr.Button(value="Take Picture")

def capture_image() -> Tuple[gr.Image, gr.HTML, gr.Button]:
    global webcam_active, cap

    if not webcam_active or cap is None or not cap.isOpened():
        return gr.Image(visible=False), gr.HTML(visible=False), gr.Button(value="Take Picture")

    ret, frame = cap.read()
    if not ret:
        return gr.Image(visible=False), gr.HTML(visible=False), gr.Button(value="Capture Failed")

    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
        temp_path = temp_file.name
        cv2.imwrite(temp_path, frame)

    state_manager.set_item('source_paths', [temp_path])
    cap.release()
    webcam_active = False

    return (
        gr.Image(value=temp_path, visible=True),
        gr.HTML(visible=False),
        gr.Button(value="Take Picture")
    )

def update(files: Optional[List[File]]) -> Tuple[gr.Audio, gr.Image]:
    if files:
        file_names = [file.name for file in files if hasattr(file, 'name') and file.name]
        if not file_names:
            state_manager.clear_item('source_paths')
            return gr.Audio(value=None, visible=False), gr.Image(value=None, visible=False)

        has_current_audio = has_audio(file_names)
        has_current_image = has_image(file_names)

        if has_current_audio or has_current_image:
            source_audio_path = get_first(filter_audio_paths(file_names))
            source_image_path = get_first(filter_image_paths(file_names))
            state_manager.set_item('source_paths', file_names)
            return gr.Audio(value=source_audio_path, visible=has_current_audio), gr.Image(value=source_image_path, visible=has_current_image)

    state_manager.clear_item('source_paths')
    return gr.Audio(value=None, visible=False), gr.Image(value=None, visible=False)
