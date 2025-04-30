FROM python:3.11-slim

#–– Environment
env PYTHONUNBUFFERED=1 \
    PORT=8080 \
    ASSETS_IN_IMAGE=/app/.assets/models \
    ASSETS_IN_TMP=/tmp/.assets

WORKDIR /app

#–– System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 ffmpeg libsm6 libxext6 libxrender-dev \
  && rm -rf /var/lib/apt/lists/*

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

#–– Copy application code AND baked-in assets
#    Ensure .dockerignore does NOT exclude .assets/
COPY . .

#–– Move baked assets into /tmp and symlink
RUN mkdir -p ${ASSETS_IN_TMP} \
 && mv ${ASSETS_IN_IMAGE} ${ASSETS_IN_TMP}/models \
 && ln -s ${ASSETS_IN_TMP} /app/.assets

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Expose & run
EXPOSE 8080

CMD ["python", "facefusion.py", "run"]
