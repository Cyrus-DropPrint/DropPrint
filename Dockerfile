# FINAL DIAGNOSTIC: Search the entire filesystem for the executable

# --- Stage 1: The Builder ---
FROM linuxserver/cura:5.7.1 as builder

# --- THIS IS THE DIAGNOSTIC STEP ---
# This command will search the entire image for the correct file
RUN echo "########### SEARCHING FOR THE ENGINE FILE ###########" && \
    find / -type f -iname "*cura*engine*" && \
    echo "########### SEARCH COMPLETE ###########"
