FROM python:3.11-slim

#–– Environment
ENV PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    GRADIO_SERVER_PORT=8080 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    PORT=8080 \
    ASSETS_IN_IMAGE=/app/.assets/models \
    ASSETS_IN_TMP=/tmp/.assets/models

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

#–– Copy code & (optional) baked assets
# Ensure .assets/models contains yoloface_8n.onnx in your repo
COPY . .

#–– Move any baked-in models into /tmp and symlink back
RUN mkdir -p ${ASSETS_IN_TMP} \
 && if [ -d "${ASSETS_IN_IMAGE}" ]; then \
      cp -R ${ASSETS_IN_IMAGE}/* ${ASSETS_IN_TMP}/; \
    else \
      echo "⚠️  Warning: no ${ASSETS_IN_IMAGE} to copy"; \
    fi \
 && rm -rf /app/.assets \
 && ln -s /tmp/.assets /app/.assets

#–– FaceFusion install (if present)
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & launch
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]
