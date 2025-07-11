# FINAL DIAGNOSTIC: List the contents of the final build stage

# --- Stage 1: The Builder ---
# This stage's only job is to download the image so we can inspect it
FROM linuxserver/cura:5.7.1 as builder

# --- THIS IS THE DIAGNOSTIC STEP ---
# This command will list all files inside the /usr/bin directory of the image
RUN echo "########### LISTING /usr/bin IN BUILDER ###########" && \
    ls -l /usr/bin && \
    echo "########### END OF FILE LIST ###########"
