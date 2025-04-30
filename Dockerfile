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

#–– Verify .assets exists in build context
RUN echo "Build context contents:" && ls -la /app

#–– Copy everything including .assets
COPY . .

#–– Verify copied files
RUN echo "Copied files:" && \
    ls -la /app && \
    ls -la /app/.assets && \
    ls -la /app/.assets/models || echo "Models not found"

#–– Handle models with proper path management
RUN mkdir -p ${ASSETS_IN_TMP}/models && \
    if [ -d "${ASSETS_IN_IMAGE}" ] && [ -n "$(ls -A ${ASSETS_IN_IMAGE} 2>/dev/null)" ]; then \
        echo "Moving models to tmp..." && \
        mv ${ASSETS_IN_IMAGE}/* ${ASSETS_IN_TMP}/models/ && \
        echo "Moved models:" && ls -la ${ASSETS_IN_TMP}/models; \
    else \
        echo "⚠️  Error: Models not found in ${ASSETS_IN_IMAGE}"; \
        exit 1; \
    fi && \
    rm -rf /app/.assets && \
    ln -s ${ASSETS_IN_TMP} /app/.assets && \
    echo "Final symlink check:" && \
    ls -la /app/.assets/models

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & launch
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]