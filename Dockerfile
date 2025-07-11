# Diagnostic Build: Inspecting CuraEngine build output (using git clone for libArcus - no specific branch)

FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev \
    python3 python3-pip curl wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install a recent version of CMake
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.tar.gz \
    | tar --strip-components=1 -xz -C /usr/local

# Part 1: Build libArcus by cloning the default branch (most reliable)
RUN git clone https://github.com/Ultimaker/libArcus.git /tmp/libArcus && \
    cd /tmp/libArcus && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON=OFF && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/libArcus

# Part 2: Build the Clipper2 library from source
RUN git clone https://github.com/AngusJohnson/Clipper2.git /tmp/Clipper2 && \
    cd /tmp/Clipper2 && git checkout v1.3.0 && \
    mkdir build && cd build && \
    cmake ../C++ -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/Clipper2

# Part 3: Build the libnest2d library
RUN git clone https://github.com/tamasmeszaros/libnest2d.git /tmp/libnest2d && \
    cd /tmp/libnest2d && git checkout 1.3.0-cura && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/libnest2d

# Part 4: Build the modern CuraEngine and list its build directory contents
RUN git clone --depth 1 --branch 5.7.2 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    # !!! DIAGNOSTIC STEP: List contents of the build directory !!!
    ls -l . && \
    # This copy command might still fail if the name is wrong, but we'll have the 'ls -l' output
    cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

# Setup your Flask/Gunicorn app
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
