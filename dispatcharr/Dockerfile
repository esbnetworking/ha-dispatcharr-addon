FROM ghcr.io/dispatcharr/dispatcharr:latest
LABEL io.hass.version="latest" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"
      
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
