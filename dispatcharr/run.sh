#!/usr/bin/with-contenv bash
set -e

echo "Setting up Dispatcharr storage..."

# Ensure directories exist
mkdir -p /config/exports
mkdir -p /data

# Replace exports folder with symlink
rm -rf /data/exports
ln -s /config/exports /data/exports

echo "Starting Dispatcharr..."

exec /init
