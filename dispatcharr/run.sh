#!/usr/bin/env bash

echo "Starting Dispatcharr..."

# Start original container entrypoint in background
/app/docker/entrypoint.sh &

# Wait for app to initialize
sleep 15

echo "Mirroring /data to /config for visibility..."

mkdir -p /config/data
rsync -a --delete /data/ /config/data/ 2>/dev/null || true

echo "Dispatcharr started"
