from typing import List, Optional, Tuple
import gradio as gr
from facefusion import state_manager, wording
from facefusion.common_helper import get_first
from facefusion.filesystem import filter_audio_paths, filter_image_paths, has_audio, has_image
from facefusion.uis.core import register_ui_component
from facefusion.uis.typing import File

# Global placeholders
SOURCE_FILE: Optional[gr.File] = None
SOURCE_WEBCAM: Optional[gr.Image] = None
SOURCE_AUDIO: Optional[gr.Audio] = None
SOURCE_IMAGE: Optional[gr.Image] = None

def render() -> None:
    global SOURCE_FILE, SOURCE_WEBCAM, SOURCE_AUDIO, SOURCE_IMAGE

    stored = state_manager.get_item('source_paths') or []
    has_src_audio = has_audio(stored)
    has_src_image = has_image(stored)

    SOURCE_FILE = gr.File(
        label=wording.get('uis.source_file_label') or "Upload Source Image(s)/Audio",
        file_count="multiple",
        file_types=["image", "audio"],
        value=stored if stored else None
    )

    SOURCE_AUDIO = gr.Audio(
        value=get_first(filter_audio_paths(stored)) if has_src_audio else None,
        visible=has_src_audio,
        show_label=False
    )

    SOURCE_IMAGE = gr.Image(
        value=get_first(filter_image_paths(stored)) if has_src_image else None,
        visible=has_src_image,
        show_label=False
    )

    SOURCE_WEBCAM = gr.Image(
        sources=["webcam"],   # Use browser webcam
        type="filepath",      # Save as temporary file
        interactive=True,
        label=wording.get('uis.webcam_preview_label') or "Webcam Capture"
    )

    for name, component in [
        ("source_file", SOURCE_FILE),
        ("source_webcam", SOURCE_WEBCAM),
        ("source_audio", SOURCE_AUDIO),
        ("source_image", SOURCE_IMAGE)
    ]:
        register_ui_component(name, component)

def listen() -> None:
    SOURCE_FILE.change(
        fn=update,
        inputs=SOURCE_FILE,
        outputs=[SOURCE_AUDIO, SOURCE_IMAGE]
    )

    SOURCE_WEBCAM.change(
        fn=on_capture,
        inputs=SOURCE_WEBCAM,
        outputs=SOURCE_IMAGE
    )

def update(files: Optional[List[File]]) -> Tuple[gr.Audio, gr.Image]:
    if files:
        names = [f.name for f in files if hasattr(f, "name") and f.name]
        if names:
            state_manager.set_item("source_paths", names)
            return (
                gr.update(value=get_first(filter_audio_paths(names)), visible=has_audio(names)),
                gr.update(value=get_first(filter_image_paths(names)), visible=has_image(names))
            )

    state_manager.clear_item("source_paths")
    return (
        gr.update(value=None, visible=False),
        gr.update(value=None, visible=False)
    )

def on_capture(image_path: str) -> gr.Image:
    """
    Called when user captures a webcam snapshot.
    We get the temp file path and save it.
    """
    state_manager.set_item("source_paths", [image_path])
    return gr.update(value=image_path, visible=True)
