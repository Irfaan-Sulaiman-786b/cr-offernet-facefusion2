import gradio as gr

def render() -> gr.Blocks:
	with gr.Blocks():
		gr.HTML("""
			<h1 style="font-family: Arial, sans-serif; font-size: 28px; font-weight: bold; color: #4A90E2; text-align: center; padding: 20px;">
				RavenWatch with FaceFusion Integration
			</h1>
			<hr style="border: 2px solid #4A90E2; width: 80%; margin: auto;">
		""")
