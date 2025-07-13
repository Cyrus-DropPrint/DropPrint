# Start with a standard Ubuntu image, as it's great for handling the required libraries.
FROM ubuntu:22.04

# Install system-level dependencies for Python and PrusaSlicer AppImage
# This includes Python itself and all the graphics/UI libraries PrusaSlicer needs to run.
RUN apt-get update && apt-get install -y \
    wget \
    libfuse2 \
    libgl1-mesa-glx \
    libglu1-mesa \
    libgtk-3-0 \
    libegl1-mesa \
    libwebkit2gtk-4.0-37 \
    python3 \
    python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy just the requirements file first to leverage Docker's layer caching
COPY requirements.txt .

# Install the Python packages specified in your requirements file
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of your application files into the container
# This includes app.py, prusa_config.ini, etc.
COPY . .

# Download the specific PrusaSlicer AppImage you were using and make it executable
# This ensures the correct version is always available for your app.
RUN wget "https://github.com/prusa3d/PrusaSlicer/releases/download/version_2.8.1/PrusaSlicer-2.8.1+linux-x64-older-distros-GTK3-202409181354.AppImage" -O PrusaSlicer.AppImage && \
    chmod +x PrusaSlicer.AppImage

# Expose the port the app will run on. This is a good practice for documentation.
EXPOSE 8080

# Set the command to run your Flask application using the Gunicorn production server.
# This is the corrected, production-ready startup command.
CMD ["gunicorn", "--workers", "1", "--threads", "8", "--timeout", "300", "--bind", "0.0.0.0:8080", "app:app"]
