# FINAL BUILD: Adding FUSE and OpenGL libraries for AppImage support

FROM ubuntu:22.04

# Install all necessary dependencies, including libfuse2 and libgl1-mesa-glx
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip libfuse2 libgl1-mesa-glx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Download the official Cura AppImage and make it executable
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O Cura.AppImage && \
    chmod +x Cura.AppImage

# Copy your application files
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 10000

# Run the application with a robust Gunicorn configuration
CMD ["gunicorn", "--worker-class", "gevent", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
