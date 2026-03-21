FROM ghcr.io/dispatcharr/dispatcharr:latest

# Install bashio for HA
RUN apk add --no-cache bash curl

COPY run.sh /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
