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
    # 1. Consolidated Core Stack (Web, API, Streaming, Utilities)
    uv pip install --python /app/env --no-cache --index-strategy unsafe-best-match \
        gunicorn \
        daphne \
        django-cors-headers \
        django-filter \
        djangorestframework \
        djangorestframework-simplejwt \
        django-extensions \
        psycopg2-binary \
        redis \
        regex \
        pytz \
        python-dotenv \
        drf-spectacular \
        m3u8 \
        requests \
        aiohttp \
        whitenoise \
        tzdata \
        celery && \
    # 2. Extract remaining requirements (minus ML/Torch)
    grep -oE '[a-zA-Z0-9_-]+[>=<]+[0-9.]+' pyproject.toml | \
    grep -vE "torch|sentence-transformers|transformers" > /tmp/requirements.txt && \
    # 3. Install remaining dependencies from filtered list
    uv pip install --python /app/env --no-cache --index-strategy unsafe-best-match -r /tmp/requirements.txt && \
    # 4. Final App Install
    uv pip install --python /app/env --no-cache --no-deps -e .

# 6. Build Frontend
WORKDIR /app/frontend
RUN npm install --legacy-peer-deps && npm run build

# 7. Finalize Structure
WORKDIR /app
COPY rootfs /

# 1. Strip any hidden Windows characters just in case
RUN find /etc/services.d -type f -name "run" -exec sed -i 's/\r$//' {} + && \
    find /etc/cont-init.d -type f -name "*.sh" -exec sed -i 's/\r$//' {} +

# 2. FORCE executable permissions on all service scripts and init scripts
RUN chmod -R 755 /etc/services.d && \
    chmod -R 755 /etc/cont-init.d && \
    chmod +x /etc/services.d/*/run /etc/cont-init.d/*.sh

# 3. Ensure the postgres socket directory is owned by the database user
RUN mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql
