#!/bin/bash

echo "Starting Dispatcharr Add-on Wrapper..."

# 1. Create host-accessible folders
mkdir -p /share/dispatcharr/plugins
mkdir -p /share/dispatcharr/export

# 2. Ensure /data exists
mkdir -p /data

# 3. Symlink Plugins
if [ ! -L "/data/plugins" ]; then
    echo "Linking /share/dispatcharr/plugins to /data/plugins..."
    rm -rf /data/plugins
    ln -s /share/dispatcharr/plugins /data/plugins
fi

# 4. Symlink Exports
if [ ! -L "/data/export" ]; then
    echo "Linking /share/dispatcharr/export to /data/export..."
    rm -rf /data/export
    ln -s /share/dispatcharr/export /data/export
fi

exec /init
