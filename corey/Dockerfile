# ZeroClaw Deploy — Registry-based (no Rust compilation)
#
# Pulls the pre-built binary from ghcr.io and layers deploy tools on top.
# Build time: ~30s (vs ~10min for source compilation).
#
# Usage:
#   cd corey && docker compose up --build -d

ARG ZEROCLAW_VERSION=latest
FROM ghcr.io/zeroclaw-labs/zeroclaw:${ZEROCLAW_VERSION} AS upstream

FROM debian:trixie-slim

# Runtime deps + deploy tools (envsubst, git, gh, nodejs/npm for MCP, uv for Python MCP)
RUN curl() { command curl "$@"; }; \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gettext-base \
    git \
    nodejs npm \
    sudo \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'ALL ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/zeroclaw \
    && curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Copy binary and default data from upstream registry image
COPY --from=upstream /usr/local/bin/zeroclaw /usr/local/bin/zeroclaw
COPY --from=upstream /zeroclaw-data /zeroclaw-data

# Environment
ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV HOME=/zeroclaw-data
ENV ZEROCLAW_GATEWAY_PORT=42617

# Deploy layer: entrypoint, config template, workspace identity files
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config.template.toml /etc/zeroclaw/config.template.toml
COPY workspace/ /etc/zeroclaw/workspace/
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && rm -f /zeroclaw-data/.zeroclaw/config.toml \
    && chown -R 65534:65534 /zeroclaw-data

USER 65534:65534
WORKDIR /zeroclaw-data
EXPOSE 42617
ENTRYPOINT ["entrypoint.sh"]
CMD ["daemon"]
