# FINAL BUILD: Extracting the AppImage and setting the library path

FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip libfuse2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download the official Cura AppImage, extract it, and move the contents
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract > /dev/null && \
    # Move the entire extracted directory to a permanent location
    mv /tmp/squashfs-root /opt/cura && \
    # Clean up the downloaded AppImage
    rm /tmp/Cura.AppImage

# --- THIS IS THE CRITICAL STEP ---
# Add the bundled library paths to the environment
ENV LD_LIBRARY_PATH="/opt/cura/lib:/opt/cura/usr/lib:${LD_LIBRARY_PATH}"

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 10000

# Run the application with a robust Gunicorn configuration
CMD ["gunicorn", "--worker-class", "gevent", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
