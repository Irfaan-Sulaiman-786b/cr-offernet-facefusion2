FROM python:3.11-slim

#–– Environment
ENV PYTHONUNBUFFERED=1 \
    PORT=8080 \
    # where facefusion expects its assets
    ASSETS_IN_IMAGE=/app/.assets/models \
    # where we’ll expose them at runtime
    ASSETS_IN_TMP=/tmp/.assets/models

WORKDIR /app

#–– System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 ffmpeg libsm6 libxext6 libxrender-dev \
  && rm -rf /var/lib/apt/lists/*

#–– Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

#–– Copy code + baked-in ONNX model
#    (make sure your .dockerignore does NOT exclude .assets/)
COPY . .

#–– FaceFusion install
RUN if [ -f install.py ]; then python install.py --skip-conda --onnxruntime default; fi

#–– Symlink baked assets into /tmp at build time
#    (so that at runtime /tmp/.assets/models contains your onnx)
RUN mkdir -p ${ASSETS_IN_TMP} \
 && cp -R ${ASSETS_IN_IMAGE}/* ${ASSETS_IN_TMP}/ \
 && rm -rf /app/.assets \
 && ln -s /tmp/.assets /app/.assets

#–– Expose & run
EXPOSE 8080
CMD ["python", "facefusion.py", "run"]
