ARG BUILD_FROM=ghcr.io/dispatcharr/dispatcharr:dev
FROM $BUILD_FROM

LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# Install bashio dependencies (Debian/Ubuntu base)
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install bashio
RUN curl -J -L -o /tmp/bashio.tar.gz https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/*

# Copy your script into the official S6-overlay init folder
# This ensures it runs BEFORE the app services start
COPY 00-dispatcharr-init.sh /etc/cont-init.d/00-dispatcharr-init.sh
RUN chmod +x /etc/cont-init.d/00-dispatcharr-init.sh
