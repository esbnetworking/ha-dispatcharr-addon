#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr environment..."

APP_DIR="/app"
DATA_DIR="/data"
PYTHON_BIN="/app/env/bin/python3"

# 1. Create ALL persistent directories
mkdir -p "$DATA_DIR/db" "$DATA_DIR/logos" "$DATA_DIR/media" "$DATA_DIR/recordings" \
         "$DATA_DIR/uploads/m3us" "$DATA_DIR/uploads/epgs" "$DATA_DIR/m3us" \
         "$DATA_DIR/epgs" "$DATA_DIR/plugins"

# Ensure postgres run directory exists for the lock file
mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql
chmod 775 /run/postgresql

# Ensure the DB directory has correct permissions
mkdir -p /data/db
chown -R postgres:postgres /data/db
chmod 700 /data/db

# 2. Bridge mapping
ln -sf "$DATA_DIR/media" "$APP_DIR/media"
ln -sf "$DATA_DIR/logos" "$APP_DIR/logo_cache"

# 3. Setup PostgreSQL Database (First boot only)
if [ -z "$(ls -A "$DATA_DIR/db")" ]; then
    bashio::log.info "Creating new PostgreSQL database in /data/db..."
    su-exec postgres initdb -D "$DATA_DIR/db" -E UTF8
    
    # Start temporary postgres to setup DB
    su-exec postgres pg_ctl -D "$DATA_DIR/db" -o "-c unix_socket_directories='/run/postgresql'" -w start
    su-exec postgres psql -c "CREATE USER dispatch WITH PASSWORD 'secret';"
    su-exec postgres psql -c "CREATE DATABASE dispatcharr OWNER dispatch;"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dispatcharr TO dispatch;"
    su-exec postgres pg_ctl -D "$DATA_DIR/db" -m fast -w stop
fi

# 4. Generate .env file
# Remove the old one during testing to ensure your new SECRET_KEY format is applied
rm -f "$APP_DIR/.env" 

bashio::log.info "Generating .env file..."

# 1. Try to get the key from Home Assistant Options
if bashio::config.has_value 'django_secret_key'; then
    SECRET=$(bashio::config 'django_secret_key')
else
    # 2. Fallback to generating a random one
    SECRET=$($PYTHON_BIN -c "import secrets; print(secrets.token_urlsafe(64))")
fi

# Ensure the secret is not empty before writing
if [ -z "$SECRET" ] || [ "$SECRET" = "null" ]; then
    SECRET="fallback-secret-at-least-fifty-characters-long-for-django-safety"
fi

cat <<EOF > "$APP_DIR/.env"
SECRET_KEY=$SECRET
DISPATCHARR_SECRET_KEY=$SECRET
POSTGRES_DB=dispatcharr
POSTGRES_USER=dispatch
POSTGRES_PASSWORD=secret
POSTGRES_HOST=localhost
REDIS_HOST=localhost
CELERY_BROKER_URL=redis://localhost:6379/0
DISPATCHARR_ENV=aio
EOF

# Crucial: Set permissions so the app can definitely read it
chmod 644 "$APP_DIR/.env"

# 5. Run Migrations & Collectstatic
bashio::log.info "Running Django migrations..."

cd "/app" || exit 1

# Start Postgres temporarily
su-exec postgres pg_ctl -D "/data/db" -o "-c unix_socket_directories='/run/postgresql'" -w start

# Get the key directly from bashio
USER_SECRET=$(bashio::config 'django_secret_key')

# Run migrations with an inline prefix
SECRET_KEY="$USER_SECRET" DISPATCHARR_SECRET_KEY="$USER_SECRET" \
/app/env/bin/python3 manage.py migrate --noinput

# Run collectstatic with an inline prefix
SECRET_KEY="$USER_SECRET" DISPATCHARR_SECRET_KEY="$USER_SECRET" \
/app/env/bin/python3 manage.py collectstatic --noinput

# Stop Postgres
su-exec postgres pg_ctl -D "/data/db" -m fast -w stop

bashio::log.info "Dispatcharr initialization complete."
