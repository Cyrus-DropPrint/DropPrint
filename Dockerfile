FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libeigen3-dev \
    libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libtbb-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Build Arcus first
RUN git clone --depth 1 https://github.com/Ultimaker/Arcus.git /tmp/Arcus && \
    mkdir /tmp/Arcus/build && cd /tmp/Arcus/build && \
    cmake .. && make && make install && \
    rm -rf /tmp/Arcus

# Build CuraEngine with Arcus installed
RUN git clone --depth 1 --branch 5.0.0 https://github.com/Ultimaker/CuraEngine.git /tmp/CuraEngine && \
    mkdir /tmp/CuraEngine/build && cd /tmp/CuraEngine/build && \
    cmake .. -DArcus_DIR=/usr/local/lib/cmake/Arcus && \
    make && \
    cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf /tmp/CuraEngine

WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
