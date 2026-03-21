#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting Dispatcharr..."

export DISPATCHARR_DATA=/config

if [ -d /app/data ]; then
    rm -rf /app/data
    ln -s /config /app/data
fi

# Start ORIGINAL container entrypoint
exec /init
