# Use official Python image
FROM python:3.11-slim

# Install system libraries needed for OpenCV and others
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the project files into the container
COPY . .

# Optional: Set Pythonpath to /app to fix imports
ENV PYTHONPATH=/app

# Install required ONNX and other dependencies through install.py
RUN python install.py --skip-conda --onnxruntime default

# Install additional project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the expected Cloud Run port
EXPOSE 8080

# Run FaceFusion using Cloud Run’s PORT environment variable
CMD ["python", "facefusion.py"]
