FROM ubuntu:22.04

# Install system dependencies for building CuraEngine and Python app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git build-essential cmake unzip curl python3 python3-pip python3-dev libprotobuf-dev protobuf-compiler libboost-all-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone and build CuraEngine
RUN git clone --depth 1 https://github.com/Ultimaker/CuraEngine.git /curaengine && \
    mkdir /curaengine/build && cd /curaengine/build && \
    cmake .. && \
    make && \
    cp CuraEngine /usr/local/bin/ && \
    chmod +x /usr/local/bin/CuraEngine


# Set working directory for your app
WORKDIR /app

# Copy your Python app files into the container
COPY app.py requirements.txt default_config.json ./

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 10000

# Command to run your app with Gunicorn
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
