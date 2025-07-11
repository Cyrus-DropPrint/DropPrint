# FINAL BUILD: Extracting CuraEngine from AppImage for direct execution

FROM ubuntu:22.04

# Install necessary dependencies for AppImage extraction and headless Qt operation
# libfuse2 is needed for AppImage extraction
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

# Set the QT_QPA_PLATFORM environment variable for headless operation
# This is crucial to prevent the "could not connect to display" error
ENV QT_QPA_PLATFORM=offscreen

# Set the working directory
WORKDIR /app

# Download the official Cura AppImage, make it executable, and EXTRACT CuraEngine
# The --appimage-extract command extracts the contents to squashfs-root/
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O /tmp/Cura.AppImage && \
    chmod +x /tmp/Cura.AppImage && \
    cd /tmp && ./Cura.AppImage --appimage-extract >/dev/null && \
    # Copy the extracted CuraEngine binary to a standard PATH location
    cp /tmp/squashfs-root/CuraEngine /usr/local/bin/CuraEngine && \
    chmod +x /usr/local/bin/CuraEngine && \
    # Clean up the temporary AppImage and extracted directory
    rm -rf /tmp/Cura.AppImage /tmp/squashfs-root

# Copy your application files
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 10000

# Run the application with a robust Gunicorn configuration
CMD ["gunicorn", "--worker-class", "gevent", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
