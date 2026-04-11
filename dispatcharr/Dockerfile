ARG BUILD_FROM=ghcr.io/dispatcharr/dispatcharr:latest
FROM $BUILD_FROM

LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# Install bashio dependencies (Alpine base)
RUN apk add --no-cache \
    jq \
    curl \
    bash

# Install bashio
RUN curl -J -L -o /tmp/bashio.tar.gz https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -sf /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/*
    

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
