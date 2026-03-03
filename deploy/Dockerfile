# syntax=docker/dockerfile:1.7
# Dokploy-ready Dockerfile for ZeroClaw.
# Uses a config template + envsubst to inject secrets at startup.

FROM ghcr.io/zeroclaw-labs/zeroclaw:latest AS upstream

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY --from=upstream /usr/local/bin/zeroclaw /usr/local/bin/zeroclaw
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config.template.toml /etc/zeroclaw/config.template.toml
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
