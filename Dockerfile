FROM python:3.11-slim

#–– Environment
ENV PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    GRADIO_SERVER_PORT=8080 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    PORT=8080 \
    ASSETS_IN_IMAGE=/app/.assets/models \
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

#–– Debug: Show directory structure before copy
RUN mkdir -p /app/.assets/models && ls -la /app || echo "No /app directory"

#–– Copy code & assets
COPY . .

#–– Debug: Show what was copied
RUN ls -la /app/.assets/models || echo "No models directory"

#–– Ensure models directory exists and has content
RUN mkdir -p ${ASSETS_IN_TMP}/models \
 && if [ -d "${ASSETS_IN_IMAGE}" ] && [ "$(ls -A ${ASSETS_IN_IMAGE})" ]; then \
      echo "Copying models from image to tmp..." && \
      cp -R ${ASSETS_IN_IMAGE}/* ${ASSETS_IN_TMP}/models/ && \
      ls -la ${ASSETS_IN_TMP}/models; \
    else \
      echo "⚠️  Warning: No models found in ${ASSETS_IN_IMAGE}, you'll need to download them at runtime"; \
      mkdir -p ${ASSETS_IN_TMP}/models; \
    fi \
 && rm -rf /app/.assets \
 && ln -s ${ASSETS_IN_TMP} /app/.assets \
 && ls -la /app/.assets/models || echo "No models in symlinked location"

#–– FaceFusion install (if present)
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & launch
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]