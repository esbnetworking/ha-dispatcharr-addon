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

# 5. FIND THE ACTUAL BINARY
# This looks specifically for the 'dispatcharr' command inside the app's environment
BINARY_PATH=$(find /dispatcharrpy/bin -name "dispatcharr" -type f)

if [ -z "$BINARY_PATH" ]; then
    echo "ERROR: Could not find the dispatcharr binary in /dispatcharrpy/bin"
    echo "Available files in /dispatcharrpy/bin are:"
    ls /dispatcharrpy/bin
    exit 1
fi

echo "Found binary at: $BINARY_PATH"
echo "Launching Dispatcharr..."

# 5. Launch using the discovered path
exec "$BINARY_PATH"
