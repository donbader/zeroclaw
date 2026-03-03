# syntax=docker/dockerfile:1.7
# Dokploy-ready Dockerfile for ZeroClaw with env-driven config generation.
#
# Uses the main Dockerfile's builder stage, then adds a shell-capable
# runtime so entrypoint.sh can template config.toml from env vars.

FROM ghcr.io/zeroclaw-labs/zeroclaw:latest AS upstream

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=upstream /usr/local/bin/zeroclaw /usr/local/bin/zeroclaw
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
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
