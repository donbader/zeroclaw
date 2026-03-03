# syntax=docker/dockerfile:1.7
# Thin deploy layer on top of the locally-built ZeroClaw dev image.
#
# Requires the base image to be built first:
#   docker build -t zeroclaw:dev --target dev -f Dockerfile .
#
# Then:
#   cd deploy && docker compose up --build -d

ARG BASE_IMAGE=zeroclaw:dev
FROM ${BASE_IMAGE}

USER root

# envsubst for config template secret injection
RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY deploy/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY deploy/config.template.toml /etc/zeroclaw/config.template.toml
COPY deploy/workspace/ /etc/zeroclaw/workspace/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Reset runtime dirs (base image may have stale defaults)
RUN rm -f /zeroclaw-data/.zeroclaw/config.toml \
    && chown -R 65534:65534 /zeroclaw-data

USER 65534:65534
ENTRYPOINT ["entrypoint.sh"]
CMD ["daemon"]
