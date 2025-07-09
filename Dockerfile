# Dockerfile to build CuraEngine + libArcus (no SIP bindings)
FROM ubuntu:22.04

# Install system dependencies and Python pip
RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev \
    python3 python3-dev python3-pip curl wget unzip \
    python3.10-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install latest CMake (needed version 3.23+)
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.tar.gz \
    | tar --strip-components=1 -xz -C /usr/local

# Install Conan (C++ package manager)
RUN pip3 install --no-cache-dir conan

# Setup Conan profile (Conan 2.x compatible)
RUN conan profile detect --force && \
    sed -i 's|compiler\.libcxx=.*|compiler.libcxx=libstdc++11|' /root/.conan2/profiles/default

# Install protobuf 3.21.2 (to satisfy minimum protobuf >= 3.17.1)
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v21.2/protobuf-cpp-3.21.2.tar.gz && \
    tar --no-same-owner -xzf protobuf-cpp-3.21.2.tar.gz && \
    cd protobuf-3.21.2 && \
    ./configure && make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf protobuf-3.21.2 protobuf-cpp-3.21.2.tar.gz

# Clone and build libArcus (without Python SIP bindings)
RUN git clone https://github.com/Ultimaker/libArcus.git /tmp/libArcus && \
    cd /tmp/libArcus && git checkout 5193de3403e5fac887fd18a945ba43ce4e103f90 && \
    # Comment out the SIP module installation
    sed -i '/install_sip_module/ s/^/#/' CMakeLists.txt && \
    mkdir build && cd build && \
    # Point CMake to the correct Python libraries AND set the build type
    cmake .. -DCMAKE_BUILD_TYPE=Release -DPYTHON_INCLUDE_DIR=/usr/include/python3.10 -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.10.so && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/libArcus

# Clone and build CuraEngine v5.0.0
RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    conan install .. --build=missing && \
    cmake .. && make -j$(nproc) && \
    cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
