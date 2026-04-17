FROM ghcr.io/dispatcharr/dispatcharr:0.23.0-20260417003113
LABEL io.hass.version="latest" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# Fix permissions at runtime
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT [ "/run.sh" ]
