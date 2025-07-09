FROM ubuntu:22.04

# Install system dependencies and Python pip
RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev \
    python3 python3-dev python3-pip curl wget unzip && \
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

# Clone and build libArcus with patched CMakeLists.txt and fake cpython module
RUN git clone https://github.com/Ultimaker/libArcus.git /tmp/libArcus && \
    cd /tmp/libArcus && git checkout 5193de3403e5fac887fd18a945ba43ce4e103f90 && \
    sed -i '41s/.*/if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")/' CMakeLists.txt && \
    # Create fake cpython package to satisfy find_package
    mkdir -p /usr/local/lib/cmake/cpython && \
    echo "add_library(cpython INTERFACE)" > /usr/local/lib/cmake/cpython/cpythonConfig.cmake && \
    echo "set(cpython_FOUND TRUE)" >> /usr/local/lib/cmake/cpython/cpythonConfig.cmake && \
    mkdir build && cd build && \
    cmake .. -Dcpython_DIR=/usr/local/lib/cmake/cpython -DPYTHON_SITE_PACKAGES_DIR=/usr/lib/python3/dist-packages && \
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
