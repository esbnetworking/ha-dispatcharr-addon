#!/bin/bash

echo "Starting Dispatcharr Add-on Wrapper..."

# 1. Create host-accessible folders
mkdir -p /share/dispatcharr/plugins
mkdir -p /share/dispatcharr/export

# 2. FIX: Grant the container full read/write access to the host folders
chmod -R 777 /share/dispatcharr/plugins
chmod -R 777 /share/dispatcharr/export

# 3. Ensure /data exists
mkdir -p /data

# 4. Safely Symlink Plugins
if [ ! -L "/data/plugins" ]; then
    echo "Linking /share/dispatcharr/plugins to /data/plugins..."
    if [ -d "/data/plugins" ]; then
        cp -rn /data/plugins/* /share/dispatcharr/plugins/ 2>/dev/null || true
    fi
    rm -rf /data/plugins
    ln -s /share/dispatcharr/plugins /data/plugins
fi

# 5. Safely Symlink Exports
if [ ! -L "/data/export" ]; then
    echo "Linking /share/dispatcharr/export to /data/export..."
    if [ -d "/data/export" ]; then
        cp -rn /data/export/* /share/dispatcharr/export/ 2>/dev/null || true
    fi
    rm -rf /data/export
    ln -s /share/dispatcharr/export /data/export
fi

exec /init
