ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
FROM $BUILD_FROM

LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# 1. System Dependencies (Added sed and uv for the build logic)
RUN apk add --no-cache \
    python3 py3-pip python3-dev \
    nodejs npm git curl wget \
    postgresql postgresql-dev postgresql-contrib \
    redis ffmpeg nginx streamlink \
    gcc musl-dev linux-headers build-base \
    libxml2-dev libxslt-dev \
    su-exec \
    ca-certificates \
    sed \
    uv

# 2. PostgreSQL Directory Setup
# This prevents the "could not create lock file" error at runtime
RUN mkdir -p /run/postgresql /data/db && \
    chown -R postgres:postgres /run/postgresql /data/db && \
    chmod 775 /run/postgresql /data/db

WORKDIR /app

# 3. Clone Dispatcharr
RUN git clone -b main https://github.com/Dispatcharr/Dispatcharr.git .

# 4. Python Environment Configuration
# PYTHONPATH="/app" ensures Django can find the 'apps.api' module
ENV PATH="/app/env/bin:$PATH" \
    PYTHONPATH="/app" \
    UV_PROJECT_ENVIRONMENT="/app/env" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 5. Build Python 3.13 Environment & Strip Torch
# We use uv to grab 3.13 and bypass the broken torch requirement
RUN export UV_INDEX_URL="https://pypi.org/simple" && \
    uv venv /app/env --python 3.13 --clear && \
    uv pip install --python /app/env --no-cache gunicorn && \
    grep -oE '[a-zA-Z0-9_-]+[>=<]+[0-9.]+' pyproject.toml | grep -v "torch" > /tmp/requirements.txt && \
    uv pip install --python /app/env --no-cache -r /tmp/requirements.txt && \
    uv pip install --python /app/env --no-cache --no-deps . && \
    /app/env/bin/python3 -m pip install --no-cache-dir . --no-deps --break-system-packages || true

# 6. Build Frontend
WORKDIR /app/frontend
RUN npm install --legacy-peer-deps && npm run build

# 7. Finalize Add-on Structure
WORKDIR /app
COPY rootfs /

# Ensure scripts are executable
RUN chmod +x /etc/cont-init.d/*.sh && \
    chmod +x /etc/services.d/*/run

# The container will use your S6 overlay to start Postgres, Redis, and Gunicorn
