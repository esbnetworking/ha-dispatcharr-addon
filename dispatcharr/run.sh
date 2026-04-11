#!/usr/bin/env bash

echo "Starting Dispatcharr..."

# Start original container entrypoint in background
/app/docker/entrypoint.sh &
