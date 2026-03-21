#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting Dispatcharr..."

# Ensure persistent folder exists
mkdir -p /data

# 🔥 CRITICAL: Force app to use HA storage
export DISPATCHARR_DATA=/data

# 🔥 OPTIONAL: if app uses /app/data internally
if [ -d /app/data ]; then
    rm -rf /app/data
    ln -s /data /app/data
fi

# Start ORIGINAL container entrypoint
exec /init
