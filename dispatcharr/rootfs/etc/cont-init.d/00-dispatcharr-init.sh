#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing Dispatcharr environment..."

APP_DIR="/app"
DATA_DIR="/data"

# 1. Create ALL persistent directories
mkdir -p "$DATA_DIR/db" 
mkdir -p "$DATA_DIR/logos" 
mkdir -p "$DATA_DIR/media"
mkdir -p "$DATA_DIR/recordings" 
mkdir -p "$DATA_DIR/uploads/m3us" 
mkdir -p "$DATA_DIR/uploads/epgs" 
mkdir -p "$DATA_DIR/m3us" 
mkdir -p "$DATA_DIR/epgs" 
mkdir -p "$DATA_DIR/plugins"

# Ensure postgres run directory exists
mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql
chmod 775 /run/postgresql

# Ensure the DB directory has correct permissions
mkdir -p /data/db
chown -R postgres:postgres /data/d

# 2. Bridge mapping (Link HA's /data to the app's expected internal paths)
ln -sf "$DATA_DIR/media" "$APP_DIR/media"
ln -sf "$DATA_DIR/logos" "$APP_DIR/logo_cache"

# Ensure database permissions
chown -R postgres:postgres "$DATA_DIR/db"
chmod 0700 "$DATA_DIR/db"

# 3. Setup PostgreSQL Database (First boot only)
if [ -z "$(ls -A "$DATA_DIR/db")" ]; then
    bashio::log.info "Creating new PostgreSQL database in /data/db..."
    su-exec postgres initdb -D "$DATA_DIR/db" -E UTF8
    
    su-exec postgres pg_ctl -D "$DATA_DIR/db" -w start
    su-exec postgres psql -c "CREATE USER dispatch WITH PASSWORD 'secret';"
    su-exec postgres psql -c "CREATE DATABASE dispatcharr OWNER dispatch;"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dispatcharr TO dispatch;"
    su-exec postgres pg_ctl -D "$DATA_DIR/db" -w stop
fi

# 4. Generate .env file
if [ ! -f "$APP_DIR/.env" ]; then
    bashio::log.info "Generating .env file..."
    SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(64))")
    cat <<EOF > "$APP_DIR/.env"
DJANGO_SECRET_KEY=$SECRET
POSTGRES_DB=dispatcharr
POSTGRES_USER=dispatch
POSTGRES_PASSWORD=secret
POSTGRES_HOST=localhost
REDIS_HOST=localhost
CELERY_BROKER_URL=redis://localhost:6379/0
DISPATCHARR_ENV=aio
EOF
fi

# 5. Run Migrations & Collectstatic
bashio::log.info "Running Django migrations..."
export $(grep -v '^#' "$APP_DIR/.env" | xargs)
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
