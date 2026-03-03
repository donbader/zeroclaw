# syntax=docker/dockerfile:1.7

# ── Stage 1: Build ────────────────────────────────────────────
FROM rust:1.93-slim@sha256:7e6fa79cf81be23fd45d857f75f583d80cfdbb11c91fa06180fd747fda37a61d AS builder

WORKDIR /app
ARG ZEROCLAW_CARGO_FEATURES=""

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 1. Copy manifests to cache dependencies
COPY Cargo.toml Cargo.lock ./
COPY build.rs build.rs
COPY crates/robot-kit/Cargo.toml crates/robot-kit/Cargo.toml
COPY crates/zeroclaw-types/Cargo.toml crates/zeroclaw-types/Cargo.toml
COPY crates/zeroclaw-core/Cargo.toml crates/zeroclaw-core/Cargo.toml
# Create dummy targets declared in Cargo.toml so manifest parsing succeeds.
RUN mkdir -p src benches crates/robot-kit/src crates/zeroclaw-types/src crates/zeroclaw-core/src \
    && echo "fn main() {}" > src/main.rs \
    && echo "fn main() {}" > benches/agent_benchmarks.rs \
    && echo "pub fn placeholder() {}" > crates/robot-kit/src/lib.rs \
    && echo "pub fn placeholder() {}" > crates/zeroclaw-types/src/lib.rs \
    && echo "pub fn placeholder() {}" > crates/zeroclaw-core/src/lib.rs
RUN --mount=type=cache,id=zeroclaw-cargo-registry,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,id=zeroclaw-cargo-git,target=/usr/local/cargo/git,sharing=locked \
    --mount=type=cache,id=zeroclaw-target,target=/app/target,sharing=locked \
    if [ -n "$ZEROCLAW_CARGO_FEATURES" ]; then \
      cargo build --profile corey --features "$ZEROCLAW_CARGO_FEATURES"; \
    else \
      cargo build --profile corey --locked; \
    fi
RUN rm -rf src benches crates/robot-kit/src crates/zeroclaw-types/src crates/zeroclaw-core/src

# 2. Copy only build-relevant source paths (avoid cache-busting on docs/tests/scripts)
COPY src/ src/
COPY benches/ benches/
COPY crates/ crates/
COPY firmware/ firmware/
COPY templates/ templates/
COPY web/ web/
# Keep release builds resilient when frontend dist assets are not prebuilt in Git.
RUN mkdir -p web/dist && \
    if [ ! -f web/dist/index.html ]; then \
      printf '%s\n' \
        '<!doctype html>' \
        '<html lang="en">' \
        '  <head>' \
        '    <meta charset="utf-8" />' \
        '    <meta name="viewport" content="width=device-width,initial-scale=1" />' \
        '    <title>ZeroClaw Dashboard</title>' \
        '  </head>' \
        '  <body>' \
        '    <h1>ZeroClaw Dashboard Unavailable</h1>' \
        '    <p>Frontend assets are not bundled in this build. Build the web UI to populate <code>web/dist</code>.</p>' \
        '  </body>' \
        '</html>' > web/dist/index.html; \
    fi
RUN --mount=type=cache,id=zeroclaw-cargo-registry,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,id=zeroclaw-cargo-git,target=/usr/local/cargo/git,sharing=locked \
    --mount=type=cache,id=zeroclaw-target,target=/app/target,sharing=locked \
    if [ -n "$ZEROCLAW_CARGO_FEATURES" ]; then \
      cargo build --profile corey --features "$ZEROCLAW_CARGO_FEATURES"; \
    else \
      cargo build --profile corey --locked; \
    fi && \
    cp target/corey/zeroclaw /app/zeroclaw && \
    strip /app/zeroclaw

# Prepare runtime directory structure and default config inline (no extra stage)
RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace && \
    cat > /zeroclaw-data/.zeroclaw/config.toml <<EOF && \
    chown -R 65534:65534 /zeroclaw-data
workspace_dir = "/zeroclaw-data/workspace"
config_path = "/zeroclaw-data/.zeroclaw/config.toml"
api_key = ""
default_provider = "openrouter"
default_model = "anthropic/claude-sonnet-4-20250514"
default_temperature = 0.7

[gateway]
port = 42617
host = "127.0.0.1"
allow_public_bind = false
EOF

# ── Stage 2: Development Runtime (Debian) ────────────────────
FROM debian:trixie-slim@sha256:1d3c811171a08a5adaa4a163fbafd96b61b87aa871bbc7aa15431ac275d3d430 AS dev

# Install essential runtime dependencies only (use docker-compose.override.yml for dev tools)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /zeroclaw-data /zeroclaw-data
COPY --from=builder /app/zeroclaw /usr/local/bin/zeroclaw

# Overwrite minimal config with DEV template (Ollama defaults)
COPY dev/config.template.toml /zeroclaw-data/.zeroclaw/config.toml
RUN chown 65534:65534 /zeroclaw-data/.zeroclaw/config.toml

# Environment setup
# Use consistent workspace path
ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV HOME=/zeroclaw-data
# Defaults for local dev (Ollama) - matches config.template.toml
ENV PROVIDER="ollama"
ENV ZEROCLAW_MODEL="llama3.2"
ENV ZEROCLAW_GATEWAY_PORT=42617

# Note: API_KEY is intentionally NOT set here to avoid confusion.
# It is set in config.toml as the Ollama URL.

WORKDIR /zeroclaw-data
USER 65534:65534
EXPOSE 42617
ENTRYPOINT ["zeroclaw"]
CMD ["gateway"]

# ── Stage 3: Production Runtime (Distroless) ─────────────────
FROM gcr.io/distroless/cc-debian13:nonroot@sha256:84fcd3c223b144b0cb6edc5ecc75641819842a9679a3a58fd6294bec47532bf7 AS release

COPY --from=builder /app/zeroclaw /usr/local/bin/zeroclaw
COPY --from=builder /zeroclaw-data /zeroclaw-data

# Environment setup
ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV HOME=/zeroclaw-data
# Default provider and model are set in config.toml, not here,
# so config file edits are not silently overridden
#ENV PROVIDER=
ENV ZEROCLAW_GATEWAY_PORT=42617

# API_KEY must be provided at runtime!

WORKDIR /zeroclaw-data
USER 65534:65534
EXPOSE 42617
ENTRYPOINT ["zeroclaw"]
CMD ["gateway"]

# ── Stage 4: Deploy (Dokploy / Docker Compose) ───────────────
# Usage: docker compose up --build (from corey/)
FROM dev AS deploy

USER root

# Clear dev-stage env defaults that would override config template values
ENV PROVIDER=""
ENV ZEROCLAW_MODEL=""

# envsubst for config template secret injection; git/gh for repo operations; nodejs/npm for stdio MCP servers
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    git \
    gh \
    nodejs npm \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'ALL ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/zeroclaw

COPY corey/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY corey/config.template.toml /etc/zeroclaw/config.template.toml
COPY corey/workspace/ /etc/zeroclaw/workspace/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Clear stale dev config so entrypoint generates from template
RUN rm -f /zeroclaw-data/.zeroclaw/config.toml \
    && chown -R 65534:65534 /zeroclaw-data

USER 65534:65534
ENTRYPOINT ["entrypoint.sh"]
CMD ["daemon"]
