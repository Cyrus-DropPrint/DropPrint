# Base image
FROM ubuntu:22.04

# Install build tools and Python
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git build-essential cmake unzip curl python3 python3-pip python3-dev libprotobuf-dev protobuf-compiler libboost-all-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone and build CuraEngine legacy-compatible source
tmpdir=$(mktemp -d) && \
RUN git clone --depth 1 --branch 4.x $\
    https://github.com/Ultimaker/CuraEngine.git $tmpdir && \
    mkdir $tmpdir/build && cd $tmpdir/build && \
    cmake .. && make && cp CuraEngine /usr/local/bin/ && chmod +x /usr/local/bin/CuraEngine && \
    rm -rf $tmpdir

# App setup
WORKDIR /app
COPY app.py default_config.json requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose & run\ nEXPOSE 10000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000"]
