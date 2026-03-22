#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Dispatcharr Add-on..."

# --- 1. Map Home Assistant Options to Environment Variables ---
export DISPATCHARR_DATA=$(bashio::config 'DISPATCHARR_DATA')
export DISPATCHARR_ENV=$(bashio::config 'DISPATCHARR_ENV')
export REDIS_HOST=$(bashio::config 'REDIS_HOST')
export CELERY_BROKER_URL=$(bashio::config 'CELERY_BROKER_URL')
export DISPATCHARR_LOG_LEVEL=$(bashio::config 'DISPATCHARR_LOG_LEVEL')
export UWSGI_NICE_LEVEL=$(bashio::config 'UWSGI_NICE_LEVEL')
export CELERY_NICE_LEVEL=$(bashio::config 'CELERY_NICE_LEVEL')

# --- 2. Ensure the Data Directory Exists ---
if [ ! -d "$DISPATCHARR_DATA" ]; then
    bashio::log.info "Creating data directory at $DISPATCHARR_DATA"
    mkdir -p "$DISPATCHARR_DATA"
fi

# --- 3. Create a Visible Shortcut (Symlink) ---
# This makes the "hidden" /data folder visible in your HA /config folder
# so you can see your EPG and DB files in the File Editor.
if [ ! -e "/config/dispatcharr" ]; then
    bashio::log.info "Creating symlink to /config/dispatcharr for easy access"
    ln -s "$DISPATCHARR_DATA" /config/dispatcharr
fi

# --- 4. Start Services ---
# If your image requires Redis to run internally, start it here:
if [ "$REDIS_HOST" == "localhost" ]; then
    bashio::log.info "Starting local Redis instance..."
    redis-server --daemonize yes
fi

bashio::log.info "Launching Dispatcharr (Mode: $DISPATCHARR_ENV)..."

# --- 5. Execute the App ---
# We use 'exec' so the app receives the shutdown signals from HA correctly
exec /app/dispatcharr
