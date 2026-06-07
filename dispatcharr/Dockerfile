FROM ghcr.io/dispatcharr/dispatcharr:0.26.0
LABEL io.hass.version="latest" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# Inject Hardware Acceleration Environment Variables for RPI and Nvidia
ENV UDEV=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
    LIBVA_DRIVER_NAME=render

# Install V4L2 and Mesa drivers
RUN apt-get update && apt-get install -y --no-install-recommends \
    v4l-utils \
    va-driver-all \
    mesa-va-drivers \
    libgles2 \
    libgles2-dev \
    libgl1-mesa-dri \
    && rm -rf /var/lib/apt/lists/*

# Fix permissions at runtime
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT [ "/run.sh" ]
