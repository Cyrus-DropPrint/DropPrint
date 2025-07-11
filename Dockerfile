# FINAL BUILD: Using the AppImage directly as the executable

FROM ubuntu:22.04

# Install only the absolute minimum dependencies needed
RUN apt-get update && apt-get install -y \
    wget python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory for all subsequent commands
WORKDIR /app

# Download the official Cura 5.10.1 AppImage into the /app directory
RUN wget https://github.com/Ultimaker/Cura/releases/download/5.10.1/UltiMaker-Cura-5.10.1-linux-x64.AppImage -O Cura.AppImage && \
    chmod +x Cura.AppImage

# Copy the rest of the application files into the working directory
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
