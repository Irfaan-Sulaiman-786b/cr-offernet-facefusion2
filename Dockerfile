FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=1
ENV GRADIO_SERVER_PORT=8080
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV PORT=8080
ENV ASSETS_IN_IMAGE=/app/.assets/models
ENV ASSETS_IN_TMP=/tmp/.assets

WORKDIR /app

#–– System deps
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

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

#–– Copy application code (including assets if they exist)
COPY . .

#–– Create assets directory structure (handles case where assets don't exist)
RUN mkdir -p ${ASSETS_IN_TMP}/models \
 && if [ -d "${ASSETS_IN_IMAGE}" ]; then \
      mv ${ASSETS_IN_IMAGE}/* ${ASSETS_IN_TMP}/models/ && \
      rm -rf ${ASSETS_IN_IMAGE}; \
    fi \
 && ln -sf ${ASSETS_IN_TMP} /app/.assets

#–– FaceFusion install (if install.py exists)
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & run
EXPOSE 8080

CMD ["python", "facefusion.py", "run"]