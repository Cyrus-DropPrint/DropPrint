# FINAL DIAGNOSTIC: List all files to find the correct engine name in this image

# --- Stage 1: The Builder ---
# This stage's only job is to download the image so we can inspect it
FROM linuxserver/cura:5.7.1 as builder

# --- Stage 2: The Inspector ---
# This stage just lists the files from the builder
FROM ubuntu:22.04

# This is the debugging command to list all files from the builder stage
RUN echo "########### START OF FILE LIST ###########" && \
    ls -R / --from=builder && \
    echo "########### END OF FILE LIST ###########"

# The Dockerfile will stop here after listing the files.
