# Stage 1: Get the binary from Dispatcharr
FROM ghcr.io/dispatcharr/dispatcharr:latest AS dispatcharr-source

# Stage 2: Build the Home Assistant Add-on environment
FROM ghcr.io/home-assistant/amd64-base:3.18 
# ^ Note: Use 'aarch64-base' for Raspberry Pi or 'base' for multi-arch

# Install any dependencies your app needs (e.g., libc, openssl)
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

# Copy the application from the first stage
COPY --from=dispatcharr-source /app /app
# Ensure the binary is in the path
RUN ln -s /app/dispatcharr /usr/bin/dispatcharr

LABEL io.hass.version="latest" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

WORKDIR /app

# Create the defaults directory
RUN mkdir -p /defaults

# Copy your local config/templates into the image for the first-run sync
COPY dispatcher.conf /defaults/dispatcher.conf
# Ensure the templates folder exists locally before building
COPY templates/ /defaults/templates/ 

# Copy and set permissions for the startup script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
