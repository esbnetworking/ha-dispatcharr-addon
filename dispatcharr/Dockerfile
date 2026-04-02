
ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
FROM $BUILD_FROM
LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"
# 1. ADDED: libxml2-dev and libxslt-dev (required for lxml compilation)
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

WORKDIR /app

# Clone Dispatcharr
RUN git clone -b main https://github.com/Dispatcharr/Dispatcharr.git .

# Setup Python environment
ENV PATH="/app/env/bin:$PATH"
ENV UV_PROJECT_ENVIRONMENT="/app/env"

# 1. Setup the 3.13 venv using uv (fastest way to get 3.13)
# 2. Use standard pip to install EVERYTHING except torch
# 3. Use --no-deps to force the final install
RUN export UV_INDEX_URL="https://pypi.org/simple" && \
    uv venv /app/env --python 3.13 --clear && \
    export PATH="/app/env/bin:$PATH" && \
    pip install --no-cache-dir gunicorn && \
    pip install --no-cache-dir . --no-deps && \
    pip install --no-cache-dir $(grep -v "torch" pyproject.toml | grep -oE '[a-zA-Z0-9_-]+>=[0-9.]+|[a-zA-Z0-9_-]+==[0-9.]+') || true && \
    /app/env/bin/pip install --no-cache-dir . --no-deps

# Build Frontend
WORKDIR /app/frontend
RUN npm install --legacy-peer-deps && npm run build

# Return to root app dir
WORKDIR /app

# Copy the S6 rootfs directory into the container
COPY rootfs /

# Ensure scripts are executable
RUN chmod +x /etc/cont-init.d/*.sh && \
    chmod +x /etc/services.d/*/run
