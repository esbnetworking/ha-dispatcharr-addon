#!/usr/bin/with-contenv bash

echo "Fixing permissions on /data..."

chown -R 1000:1000 /data || true

echo "Starting Dispatcharr..."
exec /init
