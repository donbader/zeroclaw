# syntax=docker/dockerfile:1.7
# Dokploy-ready Dockerfile for ZeroClaw.
# Builds from local source so the binary always matches the codebase.
# Uses a config template + envsubst to inject secrets at startup.

FROM rust:1.87-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Cargo.toml Cargo.lock build.rs ./
COPY src/ src/
COPY crates/ crates/

RUN cargo build --release --locked --bin zeroclaw \
    && strip target/release/zeroclaw

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/zeroclaw /usr/local/bin/zeroclaw
COPY deploy/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY deploy/config.template.toml /etc/zeroclaw/config.template.toml
COPY deploy/workspace/ /etc/zeroclaw/workspace/
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace \
    && chown -R 65534:65534 /zeroclaw-data

ENV HOME=/zeroclaw-data
ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace

WORKDIR /zeroclaw-data
USER 65534:65534
EXPOSE 42617

ENTRYPOINT ["entrypoint.sh"]
CMD ["daemon"]
