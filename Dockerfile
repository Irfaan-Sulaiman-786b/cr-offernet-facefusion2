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
    # Webcam dependencies
    libnss3 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libxss1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libgbm1 \
    && rm -rf /var/lib/apt/lists/*

# Set up application
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Run installation if needed
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

# Run application
CMD ["python", "facefusion.py"]