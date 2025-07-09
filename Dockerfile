FROM ubuntu:22.04
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential git curl libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev \
    pybind11-dev python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install CMake 3.27.9 manually
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /usr/local

# Clone standard-project-settings required by libArcus
RUN git clone --depth 1 https://github.com/Ultimaker/standard-project-settings.git /opt/standard-project-settings

# Build and install libArcus (safe version)
RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/libArcus.git /tmp/Arcus && \
    mkdir /tmp/Arcus/build && cd /tmp/Arcus/build && \
    cmake .. && make && make install && \
    rm -rf /tmp/Arcus
    
# Build CuraEngine (v5.0.0) with Arcus support
RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. -DArcus_DIR=/usr/local/lib/cmake/Arcus && \
    make && cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

# Set up Flask app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
