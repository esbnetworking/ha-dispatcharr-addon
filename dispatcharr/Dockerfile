
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

# CLEAR Home Assistant environment variables and force PyPI
RUN export UV_EXTRA_INDEX_URL="" && \
    export PIP_EXTRA_INDEX_URL="" && \
    export UV_INDEX_URL="https://pypi.org/simple" && \
    uv venv /app/env --python 3.13 --clear && \
    mkdir -p /tmp/dummy_torch/torch && \
    echo 'version = "2.11.0+cpu"' > /tmp/dummy_torch/setup.py && \
    echo 'from setuptools import setup; setup(name="torch", version="2.11.0+cpu", packages=["torch"])' > /tmp/dummy_torch/setup.py && \
    touch /tmp/dummy_torch/torch/__init__.py && \
    /app/env/bin/pip install /tmp/dummy_torch && \
    uv export --no-dev --no-hashes --format requirements-txt > /tmp/reqs.txt && \
    sed -i '/torch/d' /tmp/reqs.txt && \
    uv pip install --python /app/env --no-cache -r /tmp/reqs.txt && \
    /app/env/bin/pip install --no-cache-dir . gunicorn

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
