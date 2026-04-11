#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr AIO for Home Assistant..."

# --- Configuration & Paths ---
APP_DIR="/app"
DATA_DIR="/data"
USER_DIR="/share/dispatcharr"

LOG_LEVEL=$(bashio::config 'log_level')

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
    bashio::log.info "Creating user share directory at $USER_DIR"
    mkdir -p "$USER_DIR/m3us" "$USER_DIR/epgs" "$USER_DIR/plugins" \
             "$USER_DIR/backups" "$USER_DIR/scripts"
fi
chmod -R 775 "$USER_DIR"

# --------------------------------------------------
# 3. Critical Remapping
# --------------------------------------------------
bashio::log.info "Linking /app/data to persistent /data"
ln -snf "$DATA_DIR" "$APP_DIR/data"

ln -snf "$USER_DIR/m3us" "$DATA_DIR/m3us"
ln -snf "$USER_DIR/epgs" "$DATA_DIR/epgs"
ln -snf "$USER_DIR/plugins" "$DATA_DIR/plugins"
ln -snf "$USER_DIR/backups" "$DATA_DIR/backups"

# --------------------------------------------------
# 4. Persistence & Environment Variables (The Fix)
# --------------------------------------------------
if [ ! -f "$DATA_DIR/jwt" ]; then
    bashio::log.info "Generating persistent Secret Key..."
    echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)" > "$DATA_DIR/jwt"
fi

# In s6-overlay, you MUST write env vars to /var/run/s6/container_environment/ 
# otherwise the main services started later will not see them.
echo "$(cat "$DATA_DIR/jwt")" > /var/run/s6/container_environment/DJANGO_SECRET_KEY
echo "$(cat "$DATA_DIR/jwt")" > /var/run/s6/container_environment/DISPATCHARR_SECRET_KEY
echo "$LOG_LEVEL" > /var/run/s6/container_environment/DISPATCHARR_LOG_LEVEL

# --------------------------------------------------
# 5. Final Permission Fixes
# --------------------------------------------------
chown -R root:root "$DATA_DIR"
chmod 700 "$DATA_DIR/db"


exec /init
