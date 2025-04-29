FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=1
ENV GRADIO_SERVER_PORT=8080
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV PORT=8080

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Set up application
WORKDIR /app

# Copy only the necessary files for installation first
COPY install.py .
COPY requirements.txt .

# Run requirements
RUN pip install --no-cache-dir -r requirements.txt

# Run installation
RUN python install.py --skip-conda --onnxruntime default

# Copy the rest of the application
COPY . .

# Run application
CMD ["python", "facefusion.py", "run"]