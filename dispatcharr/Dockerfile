FROM ghcr.io/dispatcharr/dispatcharr:0.27.1
LABEL io.hass.version="latest" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# Inject Hardware Acceleration Environment Variables for RPI and Nvidia
ENV UDEV=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
    LIBVA_DRIVER_NAME=render

# Install V4L2 drivers
RUN apt-get update && apt-get install -y --no-install-recommends \
    v4l-utils \
    && rm -rf /var/lib/apt/lists/*
    
# Fix permissions at runtime
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT [ "/run.sh" ]
