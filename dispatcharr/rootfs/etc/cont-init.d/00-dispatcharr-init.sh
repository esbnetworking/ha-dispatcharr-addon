#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr environment..."

APP_DIR="/app"
DATA_DIR="/data"
PYTHON_BIN="/app/env/bin/python3"

# --------------------------------------------------
# 1. Create persistent directories
# --------------------------------------------------
mkdir -p "$DATA_DIR/db" "$DATA_DIR/logos" "$DATA_DIR/media" "$DATA_DIR/recordings" \
         "$DATA_DIR/uploads/m3us" "$DATA_DIR/uploads/epgs" "$DATA_DIR/m3us" \
         "$DATA_DIR/epgs" "$DATA_DIR/plugins"

# Postgres runtime dirs
mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql
chmod 775 /run/postgresql

# DB permissions
chown -R postgres:postgres /data/db
chmod 700 /data/db

# --------------------------------------------------
# 2. Bridge mapping
# --------------------------------------------------
ln -sf "$DATA_DIR/media" "$APP_DIR/media"
ln -sf "$DATA_DIR/logos" "$APP_DIR/logo_cache"

# --------------------------------------------------
# 3. Setup PostgreSQL (first run only)
# --------------------------------------------------
if [ -z "$(ls -A "$DATA_DIR/db")" ]; then
    bashio::log.info "Creating PostgreSQL database..."

    su-exec postgres initdb -D "$DATA_DIR/db" -E UTF8

    su-exec postgres pg_ctl -D "$DATA_DIR/db" \
        -o "-c unix_socket_directories='/run/postgresql'" \
        -w start

    su-exec postgres psql -c "CREATE USER dispatch WITH PASSWORD 'secret';"
    su-exec postgres psql -c "CREATE DATABASE dispatcharr OWNER dispatch;"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dispatcharr TO dispatch;"

    su-exec postgres pg_ctl -D "$DATA_DIR/db" -m fast -w stop
fi

# --------------------------------------------------
# 4. Generate SECRET KEY and NGINX Config
# --------------------------------------------------
bashio::log.info "Generating random SECRET_KEY"
WEB_PORT=$(bashio::config 'web_port')
SECRET=$($PYTHON_BIN -c "import secrets; print(secrets.token_urlsafe(64))")

# 1. Path definitions
NGINX_CONF="/etc/nginx/http.d/dispatcharr.conf"
NGINX_TEMPLATE="/etc/nginx/http.d/dispatcharr.conf.template"

# 2. Cleanup old configs to prevent port conflicts
rm -f "$NGINX_CONF"

if [ -f "$NGINX_TEMPLATE" ]; then
    bashio::log.info "Applying WEB_PORT ${WEB_PORT} to Nginx template..."
    
    # Perform the replacement
    sed "s/%%WEB_PORT%%/${WEB_PORT}/g" "$NGINX_TEMPLATE" > "$NGINX_CONF"
    
    # 3. Double check the result
    if grep -q "listen ${WEB_PORT}" "$NGINX_CONF"; then
        bashio::log.info "Nginx configuration generated successfully."
    else
        bashio::log.error "Failed to inject port into Nginx config!"
    fi
else
    bashio::log.error "Nginx template not found at $NGINX_TEMPLATE"
    # Fallback: create a basic one so Nginx doesn't crash the whole add-on
    echo "server { listen ${WEB_PORT}; location / { return 500 'Template Missing'; } }" > "$NGINX_CONF"
fi
# --------------------------------------------------
# 5. Generate .env file
# --------------------------------------------------
bashio::log.info "Generating .env file..."

LOG_LEVEL=$(bashio::config 'log_level')

cat <<EOF > "$APP_DIR/.env"
SECRET_KEY=$SECRET
DISPATCHARR_SECRET_KEY=$SECRET
DISPATCHARR_LOG_LEVEL=$LOG_LEVEL
DJANGO_SECRET_KEY=$SECRET
POSTGRES_DB=dispatcharr
POSTGRES_USER=dispatch
POSTGRES_PASSWORD=secret
POSTGRES_HOST=localhost
REDIS_HOST=localhost
CELERY_BROKER_URL=redis://localhost:6379/0
DISPATCHARR_ENV=aio
EOF

chmod 644 "$APP_DIR/.env"

# --------------------------------------------------
# 6. Load environment globally
# --------------------------------------------------
set -a
. "$APP_DIR/.env"
set +a

# --------------------------------------------------
# 7. Run migrations
# --------------------------------------------------
bashio::log.info "Running Django migrations..."

cd "$APP_DIR" || exit 1

# Start postgres temporarily
su-exec postgres pg_ctl -D "$DATA_DIR/db" \
    -o "-c unix_socket_directories='/run/postgresql'" \
    -w start

# Run Django setup
/app/env/bin/python3 manage.py migrate --noinput
/app/env/bin/python3 manage.py collectstatic --noinput

# Stop postgres (s6 will restart it properly)
su-exec postgres pg_ctl -D "$DATA_DIR/db" -m fast -w stop

bashio::log.info "Dispatcharr initialization complete."
