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
    libgl1 libglib2.0-0 curl ffmpeg \
    libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 \
    libxtst6 libxss1 libasound2 libatk-bridge2.0-0 libgbm1 \
  && rm -rf /var/lib/apt/lists/*

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir -r requirements.txt

#–– Download models directly with error handling
RUN mkdir -p /app/.assets/models && \
    cd /app/.assets/models && \
    set -o errexit && \
    curl -fLo yoloface_8n.onnx https://github.com/facefusion/models/releases/download/v1.0/yoloface_8n.onnx || exit 1 && \
    curl -fLo arcface_w600k_r50.onnx https://github.com/facefusion/models/releases/download/v1.0/arcface_w600k_r50.onnx || exit 1 && \
    curl -fLo inswapper_128_fp16.onnx https://github.com/facefusion/models/releases/download/v1.0/inswapper_128_fp16.onnx || exit 1

#–– Copy rest of application
COPY . .

#–– Move models to /tmp and symlink
RUN mkdir -p ${ASSETS_IN_TMP}/models && \
    mv /app/.assets/models/* ${ASSETS_IN_TMP}/models/ && \
    rm -rf /app/.assets && \
    ln -s ${ASSETS_IN_TMP} /app/.assets

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & launch
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]
