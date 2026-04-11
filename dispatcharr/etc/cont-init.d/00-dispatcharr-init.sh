#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr AIO for Home Assistant..."

# --- Configuration & Paths ---
APP_DIR="/app"
DATA_DIR="/data"
USER_DIR="/share/dispatcharr"
WEB_PORT=$(bashio::config 'web_port')
LOG_LEVEL=$(bashio::config 'log_level')

# --------------------------------------------------
# 1. Create Persistent Structural Folders
# --------------------------------------------------
# These live in the Add-on's internal persistent storage
mkdir -p "$DATA_DIR/db" "$DATA_DIR/logos" "$DATA_DIR/media" \
         "$DATA_DIR/recordings" "$DATA_DIR/logs" \
         "$DATA_DIR/runtime" "$DATA_DIR/exports"

# --------------------------------------------------
# 2. Create User-Facing Share Folders
# --------------------------------------------------
# These live in /share/dispatcharr so you can see them via Samba/File Editor
if [ ! -d "$USER_DIR" ]; then
    bashio::log.info "Creating user share directory at $USER_DIR"
    mkdir -p "$USER_DIR/m3us" "$USER_DIR/epgs" "$USER_DIR/plugins" \
             "$USER_DIR/backups" "$USER_DIR/scripts"
fi
chmod -R 775 "$USER_DIR"

# --------------------------------------------------
# 3. Critical Remapping (The "Invisible" Bridge)
# --------------------------------------------------
# Official image looks at /app/data; we force it to look at HA's /data
if [ ! -L "$APP_DIR/data" ]; then
    bashio::log.info "Linking /app/data to persistent /data"
    rm -rf "$APP_DIR/data"
    ln -sf "$DATA_DIR" "$APP_DIR/data"
fi

# Link the user folders into the data directory for the app to use
ln -sf "$USER_DIR/m3us" "$DATA_DIR/m3us"
ln -sf "$USER_DIR/epgs" "$DATA_DIR/epgs"
ln -sf "$USER_DIR/plugins" "$DATA_DIR/plugins"
ln -sf "$USER_DIR/backups" "$DATA_DIR/backups"

# --------------------------------------------------
# 4. Persistence & Environment Variables
# --------------------------------------------------
# Handle the Secret Key so sessions don't break on restart
if [ ! -f "$DATA_DIR/jwt" ]; then
    bashio::log.info "Generating persistent Secret Key..."
    echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)" > "$DATA_DIR/jwt"
fi

# Export variables the official image's entrypoint script expects
export DJANGO_SECRET_KEY=$(cat "$DATA_DIR/jwt")
export DISPATCHARR_SECRET_KEY=$(cat "$DATA_DIR/jwt")
export DISPATCHARR_LOG_LEVEL=$LOG_LEVEL
export NGINX_PORT=$WEB_PORT
export PORT=$WEB_PORT

# --------------------------------------------------
# 5. Final Permission Fixes
# --------------------------------------------------
# PostgreSQL is picky about the database directory permissions
chown -R root:root "$DATA_DIR"
chmod 700 "$DATA_DIR/db"

bashio::log.info "Initialization complete. Passing control to Official Entrypoint."
