# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Install build tools and dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git build-essential cmake python3 python3-pip python3-dev \
      libprotobuf-dev protobuf-compiler libboost-all-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone and build CuraEngine v5.0.0
RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. && make && \
    cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

# Set working directory
WORKDIR /app

# Copy app files
COPY app.py default_config.json requirements.txt ./

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose port 10000
EXPOSE 10000

# Start Flask app with Gunicorn
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
