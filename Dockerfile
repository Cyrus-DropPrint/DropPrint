# FINAL BUILD: Using PrusaSlicer AppImage

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

# Download the official PrusaSlicer AppImage and make it executable
RUN wget https://github.com/prusa3d/PrusaSlicer/releases/download/version_2.7.4/PrusaSlicer-2.7.4+linux-x64-GTK3-202404051613.AppImage -O PrusaSlicer.AppImage && \
    chmod +x PrusaSlicer.AppImage

# Copy your application files
COPY app.py prusa_config.ini requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port and set a long timeout for Gunicorn
EXPOSE 10000
CMD ["gunicorn", "--timeout", "300", "--bind", "0.0.0.0:10000", "app:app"]
