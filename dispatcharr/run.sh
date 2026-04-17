#!/bin/bash

echo "Initializing Dispatcharr AIO for Home Assistant..."

# --- Configuration & Paths ---
APP_DIR="/app"
DATA_DIR="/data"
USER_DIR="/share/dispatcharr"

# --------------------------------------------------
# 1. Ensure structural folders exist
# --------------------------------------------------
mkdir -p "$APP_DIR"

mkdir -p "$DATA_DIR/db" "$DATA_DIR/logos" "$DATA_DIR/media" \
         "$DATA_DIR/recordings" "$DATA_DIR/logs" \
         "$DATA_DIR/runtime" "$DATA_DIR/exports"

# --------------------------------------------------
# 2. Create User-Facing Share Folders
# --------------------------------------------------
if [ ! -d "$USER_DIR" ]; then
    echo "Creating user share directory at $USER_DIR"
    mkdir -p "$USER_DIR/m3us" "$USER_DIR/epgs" "$USER_DIR/plugins" \
             "$USER_DIR/backups" "$USER_DIR/scripts"
fi
chmod -R 775 "$USER_DIR"

# --------------------------------------------------
# 3. Critical Remapping
# --------------------------------------------------
echo "Linking /app/data to persistent /data"
ln -snf "$DATA_DIR" "$APP_DIR/data"

ln -snf "$USER_DIR/m3us" "$DATA_DIR/m3us"
ln -snf "$USER_DIR/epgs" "$DATA_DIR/epgs"
ln -snf "$USER_DIR/plugins" "$DATA_DIR/plugins"
ln -snf "$USER_DIR/backups" "$DATA_DIR/backups"

# --------------------------------------------------
# 4. Persistence & Environment Variables
# --------------------------------------------------
if [ ! -f "$DATA_DIR/jwt" ]; then
    echo "Generating persistent Secret Key..."
    date +%s | sha256sum | base64 | head -c 32 > "$DATA_DIR/jwt"
fi

export DJANGO_SECRET_KEY=$(cat "$DATA_DIR/jwt")
export DISPATCHARR_SECRET_KEY=$(cat "$DATA_DIR/jwt")

# --------------------------------------------------
# 5. Final Permission Fixes
# --------------------------------------------------
chown -R root:root "$DATA_DIR"
chmod 700 "$DATA_DIR/db"


echo "Folder mapping complete. Starting Dispatcharr..."

# Hand over the container's main process to the official entrypoint
exec /app/docker/entrypoint.sh
