# Use official Python image
FROM python:3.11-slim

# Install system libraries needed for FaceFusion and OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    ffmpeg \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files into the container
COPY . .

# Optional: Set Pythonpath to /app to fix imports
ENV PYTHONPATH=/app

# Install required ONNX and other dependencies through install.py
RUN python install.py --skip-conda --onnxruntime default

# Install additional Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Start FaceFusion and forward Cloud Run's port 8080 to localhost:7860
CMD bash -c "python facefusion.py run & socat TCP-LISTEN:8080,fork TCP:localhost:7860"
