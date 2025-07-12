# FINAL BUILD: Using the user-verified PrusaSlicer AppImage URL

FROM ubuntu:22.04

# Install dependencies needed for AppImage and Python
RUN apt-get update && apt-get install -y \
    wget \
    libfuse2 \
    python3 \
    python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# --- THIS IS THE CORRECTED LINE USING YOUR LINK ---
# Download the official PrusaSlicer AppImage
RUN wget "https://github.com/prusa3d/PrusaSlicer/releases/download/version_2.8.1/PrusaSlicer-2.8.1+linux-x64-older-distros-GTK3-202409181354.AppImage" -O PrusaSlicer.AppImage && \
    chmod +x PrusaSlicer.AppImage

# Copy your application files
COPY app.py prusa_config.ini requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port and set a long timeout for Gunicorn
EXPOSE 10000
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
