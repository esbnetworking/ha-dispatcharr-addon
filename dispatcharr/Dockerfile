
ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
FROM $BUILD_FROM
LABEL io.hass.version="1.0.0" \
      io.hass.type="addon" \
      io.hass.arch="aarch64|amd64"
# Install Alpine dependencies (including streamlink)
RUN apk add --no-cache \
    python3 py3-pip python3-dev \
    nodejs npm git curl wget \
    postgresql postgresql-dev postgresql-contrib \
    redis ffmpeg nginx streamlink \
    gcc musl-dev linux-headers build-base \
    su-exec

WORKDIR /app

# Clone Dispatcharr (Main branch)
RUN git clone -b main https://github.com/Dispatcharr/Dispatcharr.git .

# Setup Python environment using uv
RUN python3 -m venv /app/env
ENV PATH="/app/env/bin:$PATH"
ENV UV_PROJECT_ENVIRONMENT="/app/env"

# Install uv and sync modern pyproject.toml dependencies
RUN pip install --no-cache-dir uv gunicorn && \
    uv sync --no-dev

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
