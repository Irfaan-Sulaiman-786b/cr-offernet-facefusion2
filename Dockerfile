FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    GRADIO_SERVER_PORT=8080 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    PORT=8080

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
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
    libxrandr2 \
    x11-utils \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Optional facefusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

# Expose port for Gradio
EXPOSE 8080

# Run app
CMD ["python", "facefusion.py", "run"]
