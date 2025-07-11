# FINAL BUILD v3 - Corrected for Direct AppImage Execution

FROM ubuntu:22.04

# Install all necessary dependencies for a headless Qt/GUI application
# libfuse2 is needed for AppImage execution
# python3 and python3-pip for your application
RUN apt-get update && apt-get install -y \
    wget \
    python3 \
    python3-pip \
    libfuse2 \
    libgl1-mesa-glx \
    libegl1-mesa \
    libfontconfig1 \
    libglib2.0-0 \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libdbus-1-3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Download the official Cura AppImage and make it executable
# It will be located at /app/Cura.AppImage as per your app.py
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O Cura.AppImage && \
    chmod +x Cura.AppImage

# *** ADD THIS LINE: Set the QT_QPA_PLATFORM environment variable for headless operation ***
# This is crucial to prevent the "could not connect to display" error when the AppImage runs
ENV QT_QPA_PLATFORM=offscreen

# Copy your application files
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 10000

# Run the application with a robust Gunicorn configuration
CMD ["gunicorn", "--worker-class", "gevent", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
