#!/bin/bash

echo "Starting Dispatcharr Add-on Wrapper..."

# 1. Create a host-accessible folder inside Home Assistant's 'share' directory
mkdir -p /share/dispatcharr/plugins

# 2. Ensure the standard /data directory exists (from the 'data' mapping)
mkdir -p /data

# 3. Symlink the internal Dispatcharr plugins folder to the host-accessible share folder
if [ ! -L "/data/plugins" ]; then
    echo "Linking /share/dispatcharr/plugins to /data/plugins..."
    # Remove the internal directory if it exists as a standard folder
    rm -rf /data/plugins
    ln -s /share/dispatcharr/plugins /data/plugins
fi

# 4. Execute the original Dispatcharr container entrypoint/CMD
# The ghcr.io/dispatcharr/dispatcharr base image handles the rest.
exec /entrypoint.sh "$@"
