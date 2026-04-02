
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
    su-exec

WORKDIR /app

# Clone Dispatcharr
RUN git clone -b main https://github.com/Dispatcharr/Dispatcharr.git .

# Setup Python environment
RUN python3 -m venv /app/env
ENV PATH="/app/env/bin:$PATH"
ENV UV_PROJECT_ENVIRONMENT="/app/env"

# CLEAR Home Assistant environment variables and force PyPI
RUN pip install --no-cache-dir uv gunicorn && \
    export UV_EXTRA_INDEX_URL="" && \
    export PIP_EXTRA_INDEX_URL="" && \
    export UV_INDEX_URL="https://pypi.org/simple" && \
    uv sync --no-dev \
    --index-strategy first-index \
    --no-locked

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
