FROM ghcr.io/dispatcharr/dispatcharr:latest

# Switch to apt-get because this is a Debian-based image
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install bashio (Required for your run.sh to work)
RUN curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio.tar.gz /tmp/bashio

COPY run.sh /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
