ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
FROM $BUILD_FROM

LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"

# 1. System Dependencies
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

# 2. Critical Runtime Directories
# We create /run/postgresql here AND ensure it's writable
RUN mkdir -p /run/postgresql /data/db && \
    chown -R postgres:postgres /run/postgresql /data/db && \
    chmod 777 /run/postgresql /data/db

WORKDIR /app

# 3. Clone Dispatcharr
RUN git clone -b main https://github.com/Dispatcharr/Dispatcharr.git .

# 4. Environment Tuning
# We add /app to PYTHONPATH so 'import apps.api' works correctly
ENV PATH="/app/env/bin:$PATH" \
    PYTHONPATH="/app" \
    UV_PROJECT_ENVIRONMENT="/app/env" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 5. Build Python 3.13 Environment
RUN export UV_INDEX_URL="https://pypi.org/simple" && \
    uv venv /app/env --python 3.13 --clear && \
    # Add the index strategy to allow uv to look beyond the HA wheels index
    uv pip install --python /app/env --no-cache --index-strategy unsafe-best-match gunicorn && \
    # Extract requirements
    grep -oE '[a-zA-Z0-9_-]+[>=<]+[0-9.]+' pyproject.toml | grep -v "torch" > /tmp/requirements.txt && \
    # Apply the same index strategy here to find rapidfuzz 3.14.3 on PyPI
    uv pip install --python /app/env --no-cache --index-strategy unsafe-best-match -r /tmp/requirements.txt && \
    # Install the app in editable mode
    uv pip install --python /app/env --no-cache --no-deps -e .

# 6. Build Frontend
WORKDIR /app/frontend
RUN npm install --legacy-peer-deps && npm run build

# 7. Finalize Structure
WORKDIR /app
COPY rootfs /

RUN chmod +x /etc/cont-init.d/*.sh && \
    chmod +x /etc/services.d/*/run
