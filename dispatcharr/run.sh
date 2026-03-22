#!/bin/bash

echo "Starting Dispatcharr Add-on Wrapper..."

# 1. Create host-accessible folders inside Home Assistant's 'share' directory
mkdir -p /share/dispatcharr/plugins
mkdir -p /share/dispatcharr/export

# 2. Ensure the standard /data directory exists (from the 'data' mapping)
mkdir -p /data

# 3. Symlink the internal Dispatcharr plugins folder
if [ ! -L "/data/plugins" ]; then
    echo "Linking /share/dispatcharr/plugins to /data/plugins..."
    rm -rf /data/plugins
    ln -s /share/dispatcharr/plugins /data/plugins
fi

# 4. Symlink the internal Dispatcharr export folder
if [ ! -L "/data/export" ]; then
    echo "Linking /share/dispatcharr/export to /data/export..."
    rm -rf /data/export
    ln -s /share/dispatcharr/export /data/export
fi

# 5. Execute the original Dispatcharr container entrypoint/CMD
exec /entrypoint.sh "$@"
