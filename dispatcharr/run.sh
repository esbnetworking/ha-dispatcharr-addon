#!/bin/bash

echo "Initializing Dispatcharr AIO for Home Assistant..."

# --------------------------------------------------
# 0. Hardware Acceleration Permission Fixes
# --------------------------------------------------
echo "Aligning container hardware permissions with Home Assistant host..."

# Align the 'render' group (Standard AMD/Intel GPUs)
if [ -e /dev/dri/renderD128 ]; then
    HOST_RENDER_GID=$(stat -c '%g' /dev/dri/renderD128)
    echo "Detected host Render GID: ${HOST_RENDER_GID}"
    groupmod -g "${HOST_RENDER_GID}" render 2>/dev/null || true
fi

# Align the 'video' group (Raspberry Pi V4L2 and Standard GPUs)
if [ -e /dev/dri/card0 ]; then
    HOST_VIDEO_GID=$(stat -c '%g' /dev/dri/card0)
    echo "Detected host Video GID (DRI): ${HOST_VIDEO_GID}"
    groupmod -g "${HOST_VIDEO_GID}" video 2>/dev/null || true
elif [ -e /dev/video11 ]; then
    # Fallback for Raspberry Pi V4L2 nodes if DRI card0 is missing
    HOST_VIDEO_GID=$(stat -c '%g' /dev/video11)
    echo "Detected host Video GID (V4L2): ${HOST_VIDEO_GID}"
    groupmod -g "${HOST_VIDEO_GID}" video 2>/dev/null || true
fi

# Ensure the 'dispatch' user is explicitly added to these groups
if id "dispatch" &>/dev/null; then
    usermod -aG video,render dispatch 2>/dev/null || true
    echo "Added 'dispatch' user to hardware groups."
fi

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
