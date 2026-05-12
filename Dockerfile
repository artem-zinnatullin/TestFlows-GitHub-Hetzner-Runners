FROM python:3.12-slim

# === Build argument for the exact testflows package version ===
# Must be overridden at build time, otherwise the build fails with a clear error.
ARG TESTFLOWS_VERSION="PROVIDE_VERSION_VIA_DOCKER_BUILD_ARG"

# Fail fast and loudly if the version was not overridden
RUN if [ "$TESTFLOWS_VERSION" = "PROVIDE_VERSION_VIA_DOCKER_BUILD_ARG" ] || [ -z "$TESTFLOWS_VERSION" ]; then \
        echo "ERROR: TESTFLOWS_VERSION build argument must be provided!"; \
        echo "   Example:"; \
        echo "     docker build --build-arg TESTFLOWS_VERSION=1.10.260403.1003327 ..."; \
        exit 2; \
    fi

LABEL org.opencontainers.image.title="TestFlows GitHub Hetzner Runners"
LABEL org.opencontainers.image.description="Autoscaling GitHub Actions self-hosted runners on Hetzner Cloud"
LABEL org.opencontainers.image.source="https://github.com/testflows/TestFlows-GitHub-Hetzner-Runners"
LABEL org.opencontainers.image.version="1.10.260403.1003327-fixed"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.authors="TestFlows community"

ENV PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONIOENCODING=utf-8

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Install system dependencies:
#   - ca-certificates (required for HTTPS)
#   - openssh-client (ssh, ssh-keygen, ssh-agent — required by testflows for runner management)
#   - curl, git, procps (common tools needed by testflows runners manager and debugging)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-client \
    curl \
    git \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install the exact pinned version + the critical compatibility fix \
# requests-cache==1.2.1 + requests==2.34+ causes pickle NameError for RequestsCookieJar, remove once fixed in upstream
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir testflows.github.hetzner.runners==${TESTFLOWS_VERSION} && \
    pip install --no-cache-dir --force-reinstall --no-deps "requests==2.32.3"

# Create non-root user (security best practice)
RUN useradd -m -u 1000 runner && \
    chown -R runner:runner /app

USER runner

# Dashboard (Streamlit)
EXPOSE 8090

# Prometheus metrics
EXPOSE 9090

ENTRYPOINT ["/app/entrypoint.sh"]

