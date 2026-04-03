#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr environment..."

APP_DIR="/app"
DATA_DIR="/data"
USER_DIR="/config"
PYTHON_BIN="/app/env/bin/python3"

# --------------------------------------------------
# 1. Create persistent directories
# --------------------------------------------------
mkdir -p "$DATA_DIR/db" "$DATA_DIR/logos" "$DATA_DIR/media" "$DATA_DIR/recordings" \
         "$DATA_DIR/uploads/m3us" "$DATA_DIR/uploads/epgs" \
         "$DATA_DIR/logs" "$DATA_DIR/runtime"

mkdir -p "$USER_DIR/m3us" "$USER_DIR/epgs" "$USER_DIR/plugins" \
         "$USER_DIR/backups" "$USER_DIR/scripts" "$USER_DIR/uploads"

# --------------------------------------------------
# 2. FORCE ALL APP DATA INTO /data (CRITICAL FIX)
# --------------------------------------------------

# Main app data (THIS IS THE BIG ONE)
rm -rf "$APP_DIR/data"
ln -s "$DATA_DIR" "$APP_DIR/data"

# Logs
rm -rf "$APP_DIR/logs"
ln -s "$DATA_DIR/logs" "$APP_DIR/logs"

# Runtime (optional but good practice)
ln -sf "$DATA_DIR/runtime" "$APP_DIR/runtime"

# Existing mappings (keep these)
ln -sf "$USER_DIR/m3us" "$DATA_DIR/uploads/m3us"
ln -sf "$USER_DIR/epgs" "$DATA_DIR/uploads/epgs"
ln -sf "$USER_DIR/plugins" "$DATA_DIR/plugins"
ln -sf "$USER_DIR/backups" "$DATA_DIR/backups"
ln -sf "$USER_DIR/scripts" "$DATA_DIR/scripts"
ln -sf "$USER_DIR/uploads" "$DATA_DIR/uploads"

ln -sf "$DATA_DIR/media" "$APP_DIR/media"
ln -sf "$DATA_DIR/logos" "$APP_DIR/logo_cache"

# --------------------------------------------------
# 3. PostgreSQL setup
# --------------------------------------------------
mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql
chmod 775 /run/postgresql

chown -R postgres:postgres "$DATA_DIR/db"
chmod 700 "$DATA_DIR/db"

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
# 4. Generate SECRET + NGINX config
# --------------------------------------------------
SECRET=$($PYTHON_BIN -c "import secrets; print(secrets.token_urlsafe(64))")

WEB_PORT=$(bashio::config 'web_port')
LOG_LEVEL=$(bashio::config 'log_level')

sed "s/{{WEB_PORT}}/${WEB_PORT}/g" \
    /etc/nginx/http.d/dispatcharr.conf.template \
    > /etc/nginx/http.d/dispatcharr.conf

# --------------------------------------------------
# 5. Generate .env
# --------------------------------------------------
cat <<EOF > "$APP_DIR/.env"
SECRET_KEY=$SECRET
DISPATCHARR_SECRET_KEY=$SECRET
DJANGO_SECRET_KEY=$SECRET
DISPATCHARR_LOG_LEVEL=$LOG_LEVEL

POSTGRES_DB=dispatcharr
POSTGRES_USER=dispatch
POSTGRES_PASSWORD=secret
POSTGRES_HOST=/run/postgresql

REDIS_HOST=localhost
CELERY_BROKER_URL=redis://localhost:6379/0

DISPATCHARR_ENV=aio
DISPATCHARR_DATA_DIR=/data
EOF

chmod 644 "$APP_DIR/.env"

# --------------------------------------------------
# 6. Load env
# --------------------------------------------------
set -a
. "$APP_DIR/.env"
set +a

# --------------------------------------------------
# 7. Django setup
# --------------------------------------------------
bashio::log.info "Running Django migrations..."

cd "$APP_DIR" || exit 1

su-exec postgres pg_ctl -D "$DATA_DIR/db" \
    -o "-c unix_socket_directories='/run/postgresql'" \
    -w start

$PYTHON_BIN manage.py migrate --noinput --run-syncdb
$PYTHON_BIN manage.py collectstatic --noinput

su-exec postgres pg_ctl -D "$DATA_DIR/db" -m fast -w stop

bashio::log.info "Dispatcharr initialization complete."
