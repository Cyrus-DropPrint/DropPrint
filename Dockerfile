# Strategy 2: Build a modern, stable version of CuraEngine from source

FROM ubuntu:22.04

# Install system dependencies, including the new ones required by modern CuraEngine
RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev \
    python3 python3-pip \
    # Add new dependencies for CuraEngine 5.7.2+
    libclipper2-dev librange-v3-dev libspdlog-dev rapidjson-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install a recent version of CMake (still good practice)
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.tar.gz \
    | tar --strip-components=1 -xz -C /usr/local

# Part 1: Build the modern libArcus (v6.1.1) that CuraEngine 5.7.2 needs
RUN git clone https://github.com/Ultimaker/libArcus.git /tmp/libArcus && \
    cd /tmp/libArcus && git checkout 6.1.1 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON=OFF && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/libArcus

# Part 2: Build the modern CuraEngine (v5.7.2)
RUN git clone --depth 1 --branch 5.7.2 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
