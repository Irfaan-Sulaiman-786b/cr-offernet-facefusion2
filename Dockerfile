# Use official Python image as the base
FROM python:3.11-slim

# Set environment variables to optimize Python performance and compatibility
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=1

# Install system dependencies necessary for facefusion and gradio
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Set working directory in the container
WORKDIR /app

# Copy the project files into the container
COPY . /app/

# Install project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8080, which is required for Cloud Run
EXPOSE 8080

# Run the facefusion script (instantly start the gradio UI and bind to port)
CMD ["python", "instant_runner.py"]
