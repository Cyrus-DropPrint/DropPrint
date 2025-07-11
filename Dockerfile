# FINAL DIAGNOSTIC V2: List contents of the builder stage directly

# --- Stage 1: The Builder ---
# This stage's only job is to download the image and list its contents
FROM linuxserver/cura:5.7.1 as builder

# --- THIS IS THE CORRECTED DIAGNOSTIC STEP ---
# This command will list all files inside the /usr/bin directory of the image
RUN echo "########### LISTING /usr/bin IN BUILDER ###########" && \
    ls -l /usr/bin && \
    echo "########### END OF FILE LIST ###########"
