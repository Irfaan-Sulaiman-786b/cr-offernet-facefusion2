# instant_runner.py
import os
from time import sleep
from typing import Optional, Tuple
import gradio
from facefusion import process_manager, state_manager, wording
from facefusion.args import collect_step_args
from facefusion.core import process_step
from facefusion.filesystem import is_directory, is_image, is_video
from facefusion.jobs import job_helper, job_manager, job_runner, job_store
from facefusion.temp_helper import clear_temp_directory
from facefusion.typing import Args, UiWorkflow
from facefusion.uis.core import get_ui_component
from facefusion.uis.ui_helper import suggest_output_path

INSTANT_RUNNER_WRAPPER: Optional[gradio.Row] = None
INSTANT_RUNNER_START_BUTTON: Optional[gradio.Button] = None
INSTANT_RUNNER_STOP_BUTTON: Optional[gradio.Button] = None
INSTANT_RUNNER_CLEAR_BUTTON: Optional[gradio.Button] = None

g_client = None

def render() -> None:
    global INSTANT_RUNNER_WRAPPER, INSTANT_RUNNER_START_BUTTON, INSTANT_RUNNER_STOP_BUTTON, INSTANT_RUNNER_CLEAR_BUTTON
    print("# instant_runner.py; instant_runner.py:render")

    if job_manager.init_jobs(state_manager.get_item('jobs_path')):
        is_instant_runner = state_manager.get_item('ui_workflow') == 'instant_runner'

        with gradio.Row(visible=is_instant_runner) as INSTANT_RUNNER_WRAPPER:
            INSTANT_RUNNER_START_BUTTON = gradio.Button(
                value=wording.get('uis.start_button'),
                variant='primary',
                size='sm'
            )
            INSTANT_RUNNER_STOP_BUTTON = gradio.Button(
                value=wording.get('uis.stop_button'),
                variant='primary',
                size='sm',
                visible=False
            )
            INSTANT_RUNNER_CLEAR_BUTTON = gradio.Button(
                value=wording.get('uis.clear_button'),
                size='sm'
            )

def listen() -> None:
    output_image = get_ui_component('output_image')
    output_video = get_ui_component('output_video')
    ui_workflow_dropdown = get_ui_component('ui_workflow_dropdown')
    target_file = get_ui_component('target_file')
    target_image = get_ui_component('target_image')
    target_video = get_ui_component('target_video')
    source_file = get_ui_component('source_file')
    source_audio = get_ui_component('source_audio')
    source_image = get_ui_component('source_image')
    source_webcam = get_ui_component('source_webcam')  # Added

    print("# instant_runner.py; instant_runner.py:listen")

    if output_image and output_video and target_file and target_image and target_video and source_file and source_audio and source_image and source_webcam:
        INSTANT_RUNNER_START_BUTTON.click(start, outputs=[INSTANT_RUNNER_START_BUTTON, INSTANT_RUNNER_STOP_BUTTON])
        INSTANT_RUNNER_START_BUTTON.click(run, outputs=[INSTANT_RUNNER_START_BUTTON, INSTANT_RUNNER_STOP_BUTTON, output_image, output_video])
        INSTANT_RUNNER_STOP_BUTTON.click(stop, outputs=[INSTANT_RUNNER_START_BUTTON, INSTANT_RUNNER_STOP_BUTTON])
        INSTANT_RUNNER_CLEAR_BUTTON.click(clear, outputs=[
            output_image, output_video,
            target_file, target_image, target_video,
            source_file, source_audio, source_image,
            source_webcam  # Added
        ])
    if ui_workflow_dropdown:
        ui_workflow_dropdown.change(remote_update, inputs=ui_workflow_dropdown, outputs=INSTANT_RUNNER_WRAPPER)

def remote_update(ui_workflow: UiWorkflow) -> gradio.Row:
    print("# instant_runner.py; instant_runner.py:remote_update")
    is_instant_runner = ui_workflow == 'instant_runner'
    return gradio.Row(visible=is_instant_runner)

def start() -> Tuple[gradio.Button, gradio.Button]:
    print("# instant_runner.py; instant_runner.py:start")
    while not process_manager.is_processing():
        sleep(0.5)
    return gradio.Button(visible=False), gradio.Button(visible=True)

def run() -> Tuple[gradio.Button, gradio.Button, gradio.Image, gradio.Video]:
    print("# instant_runner.py; instant_runner.py:run")
    step_args = collect_step_args()
    output_path = step_args.get('output_path')

    if is_directory(output_path):
        step_args['output_path'] = suggest_output_path(output_path, state_manager.get_item('target_path'))

    if job_manager.init_jobs(state_manager.get_item('jobs_path')):
        print("# instant_runner.py; instant_runner.py:run: init_jobs")
        create_and_run_job(step_args)
        state_manager.set_item('output_path', output_path)

     # ✅ Upload to GCS here
    _upload_output_to_gcs(step_args['output_path'], "gcs-offernet-facefusion-output-live")

    if is_image(step_args['output_path']):
        print("# instant_runner.py; instant_runner.py:run: is_image")
        return gradio.Button(visible=True), gradio.Button(visible=False), gradio.Image(value=step_args['output_path'], visible=True), gradio.Video(value=None, visible=False)
    if is_video(step_args['output_path']):
        return gradio.Button(visible=True), gradio.Button(visible=False), gradio.Image(value=None, visible=False), gradio.Video(value=step_args['output_path'], visible=True)

    return gradio.Button(visible=True), gradio.Button(visible=False), gradio.Image(value=None), gradio.Video(value=None)

def create_and_run_job(step_args: Args) -> bool:
    print("# instant_runner.py; instant_runner.py:create_and_run_job")
    job_id = job_helper.suggest_job_id('ui')

    for key in job_store.get_job_keys():
        state_manager.sync_item(key)  # type: ignore

    return job_manager.create_job(job_id) and job_manager.add_step(job_id, step_args) and job_manager.submit_job(job_id) and job_runner.run_job(job_id, process_step)

def stop() -> Tuple[gradio.Button, gradio.Button]:
    print("# instant_runner.py; instant_runner.py:stop")
    process_manager.stop()
    return gradio.Button(visible=True), gradio.Button(visible=False)

def clear() -> Tuple[gradio.Image, gradio.Video, gradio.File, gradio.Image, gradio.Video, gradio.File, gradio.Audio, gradio.Image, gradio.Image]:
    print("# instant_runner.py; instant_runner.py:clear")
    while process_manager.is_processing():
        sleep(0.5)
    return (
        gradio.Image(value=None),
        gradio.Video(value=None),
        gradio.File(value=None),
        gradio.Image(visible=False),
        gradio.Video(visible=False),
        gradio.File(value=None),
        gradio.Audio(value=None, visible=False),
        gradio.Image(value=None, visible=False),
        gradio.Image(value=None, visible=True)  # <-- Reset webcam
    )

def set_storage_client(client):
    global g_client

    g_client = client

def _upload_output_to_gcs(output_path: str, bucket_name: str):
    global g_client

    bucket = g_client.bucket(bucket_name)

    blob = bucket.blob(os.path.basename(output_path))
    blob.upload_from_filename(output_path)
    print(f"Uploaded {output_path} to {bucket_name}/{blob.name}")