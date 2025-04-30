# Stage 1: Model download (cached layer)
FROM python:3.11-slim as model-downloader
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p .assets/models && \
    cd .assets/models && \
    curl -fL -o yoloface_8n.onnx https://github.com/facefusion/models/releases/download/v1.0/yoloface_8n.onnx && \
    curl -fL -o arcface_w600k_r50.onnx https://github.com/facefusion/models/releases/download/v1.0/arcface_w600k_r50.onnx && \
    curl -fL -o inswapper_128_fp16.onnx https://github.com/facefusion/models/releases/download/v1.0/inswapper_128_fp16.onnx && \
    sha256sum *.onnx > checksums.txt

# Stage 2: Runtime image
FROM python:3.11-slim

#–– Environment
ENV PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    GRADIO_SERVER_PORT=8080 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    PORT=8080 \
    ASSETS_IN_TMP=/tmp/.assets

WORKDIR /app

#–– System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 ffmpeg \
    libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 \
    libxtst6 libxss1 libasound2 libatk-bridge2.0-0 libgbm1 \
  && rm -rf /var/lib/apt/lists/*

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

#–– Copy application code
COPY . .

#–– Copy models from downloader stage
COPY --from=model-downloader /app/.assets /app/.assets

#–– Model handling with verification
RUN echo "Verifying models..." && \
    mkdir -p ${ASSETS_IN_TMP}/models && \
    if [ -f /app/.assets/models/checksums.txt ]; then \
        cd /app/.assets/models && sha256sum -c checksums.txt; \
    else \
        echo "⚠️ Missing checksums - cannot verify models"; exit 1; \
    fi && \
    mv /app/.assets/models/* ${ASSETS_IN_TMP}/models/ && \
    rm -rf /app/.assets && \
    ln -s ${ASSETS_IN_TMP} /app/.assets && \
    chmod -R a+r ${ASSETS_IN_TMP}

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Production hardening
RUN useradd -m -u 1000 facefusion && \
    chown -R facefusion:facefusion /app

USER facefusion
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:8080 || exit 1

CMD ["python", "facefusion.py", "run"]