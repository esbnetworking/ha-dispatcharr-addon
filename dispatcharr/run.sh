#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Dispatcharr Add-on..."

# 1. Get the data path from HA options (should be /config/dispatcharr)
DATA_PATH=$(bashio::config 'DISPATCHARR_DATA')

# 2. Create the directory if it doesn't exist
if [ ! -d "$DATA_PATH" ]; then
    mkdir -p "$DATA_PATH"
fi

# 3. THE MAGIC LINK: 
# The app is hard-coded to use /data. We link /data to your visible folder.
if [ ! -L /data ]; then
    # Move any existing internal data to the visible folder first
    cp -rp /data/* "$DATA_PATH/" 2>/dev/null || true
    rm -rf /data
    ln -s "$DATA_PATH" /data
    bashio::log.info "Linked /data to $DATA_PATH"
fi

# 4. Export the standard variables
export DISPATCHARR_DATA="/data"
export DISPATCHARR_ENV=$(bashio::config 'DISPATCHARR_ENV')
export REDIS_HOST=$(bashio::config 'REDIS_HOST')

# 5. Launch the app's internal entrypoint
# Note: Since the base image has a complex startup (Postgres/Nginx), 
# we call the original entrypoint instead of just the binary.
exec /entrypoint.sh
