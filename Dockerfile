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

#–– Copy application (excluding .gitignore)
COPY . .

#–– Create the target directory
RUN mkdir -p ${ASSETS_IN_TMP}/models

#–– Copy the models explicitly, bypassing .gitignore
COPY .assets/models/yoloface_8n.onnx ${ASSETS_IN_TMP}/models/
COPY .assets/models/arcface_w600k_r50.onnx ${ASSETS_IN_TMP}/models/
COPY .assets/models/inswapper_128_fp16.onnx ${ASSETS_IN_TMP}/models/

#–– Remove the now-empty /app/.assets directory
RUN rm -rf /app/.assets

#–– Create the symlink
RUN ln -s ${ASSETS_IN_TMP} /app/.assets

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & launch
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]
