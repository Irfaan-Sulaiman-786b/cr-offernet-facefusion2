FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    GRADIO_SERVER_PORT=8080 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    PORT=8080 \
    # directories for assets
    ASSETS_IN_IMAGE=/app/.assets/models \
    ASSETS_IN_TMP=/tmp/.assets/models

WORKDIR /app

#–– System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    ffmpeg \
    libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libxss1 libasound2 libatk-bridge2.0-0 libgbm1 \
  && rm -rf /var/lib/apt/lists/*

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

#–– Copy application code and baked-in assets
# Ensure .assets folder (with models) is included in build context and not in .dockerignore
COPY . .

#–– Verify assets are present (debug)
RUN ls -R /app/.assets/models || (echo "/app/.assets/models missing" && false)

#–– Move baked assets into tmp and symlink back
RUN mkdir -p ${ASSETS_IN_TMP} \
 && cp -R /app/.assets/models/* ${ASSETS_IN_TMP}/ \
 && rm -rf /app/.assets/models \
 && mkdir -p /app/.assets \
 && ln -s ${ASSETS_IN_TMP%/*} /app/.assets

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & run
EXPOSE 8080
CMD ["python", "facefusion.py", "run", "--server_name=0.0.0.0", "--server_port=8080"]
