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

ENV DISPATCHARR_VERSION="0.22.1"

WORKDIR /app

# 3. Clone Dispatcharr
RUN git clone --depth 1 --branch v${DISPATCHARR_VERSION} https://github.com/Dispatcharr/Dispatcharr.git .

# 4. Environment Tuning
# We add /app to PYTHONPATH so 'import apps.api' works correctly
ENV PATH="/app/env/bin:$PATH" \
    PYTHONPATH="/app" \
    UV_PROJECT_ENVIRONMENT="/app/env" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DISPATCHARR_DATA_DIR=/data

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

# 7. Finalize Structure & Force Clean Scripts
WORKDIR /app
COPY rootfs /

# 1. Strip Windows line endings from EVERYTHING first
RUN find /etc/services.d -type f -exec sed -i 's/\r$//' {} + && \
    find /etc/cont-init.d -type f -exec sed -i 's/\r$//' {} +

# 2. RE-WRITE Postgres & Redis run scripts to be 100% sure they are clean
# We use printf here because it is more reliable than echo for shebangs
RUN printf "#!/usr/bin/with-contenv bashio\nexec su-exec postgres postgres -D /data/db -c unix_socket_directories='/run/postgresql'\n" > /etc/services.d/postgres/run && \
    printf "#!/usr/bin/with-contenv bashio\nexec redis-server /etc/redis.conf\n" > /etc/services.d/redis/run

# 3. Fix permissions for the whole tree
RUN chmod -R 755 /etc/services.d && \
    chmod -R 755 /etc/cont-init.d && \
    chmod +x /etc/services.d/*/run /etc/cont-init.d/*.sh

# 4. Final fix for the Postgres socket directory
RUN mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql
