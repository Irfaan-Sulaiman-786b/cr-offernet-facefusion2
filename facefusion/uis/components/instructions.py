import gradio as gr

def render():
    instructions_text = """
<div style="border: 2px solid steelblue; background-color: #e0f2f7; padding: 15px; border-radius: 5px;">
    <p style="font-weight: bold; font-size: 1.2em; margin-top: 0; text-decoration: underline;">INSTRUCTIONS:</p>
    <p style="font-weight: bold;">Option 1: Using Uploaded Source Image</p>
    <ul style="list-style-type: disc; margin-left: 20px;">
        <li>Upload a Target Image.</li>
        <li>Upload a Source Image.</li>
        <li>Click the <strong>START</strong> button.</li>
    </ul>
    <p style="font-weight: bold;">Option 2: Using Webcam Source</p>
    <ul style="list-style-type: disc; margin-left: 20px;">
        <li>Upload a Target Image.</li>
        <li>Click the "Click to Access Webcam" button.</li>
        <li>Click the Camera Icon.</li>
        <li>Click the <strong>START</strong> button.</li>
    </ul>
</div>
    """
    gr.HTML(instructions_text)