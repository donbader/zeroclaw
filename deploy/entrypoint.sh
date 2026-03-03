#!/bin/sh
set -e

CONFIG_DIR="/zeroclaw-data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
TEMPLATE="/etc/zeroclaw/config.template.toml"

mkdir -p "${CONFIG_DIR}" /zeroclaw-data/workspace

# Copy workspace identity files (skip if already present from volume)
for f in /etc/zeroclaw/workspace/*.md; do
  name=$(basename "$f")
  [ ! -f "/zeroclaw-data/workspace/${name}" ] && cp "$f" "/zeroclaw-data/workspace/${name}"
done

# Substitute env vars (secrets from .env) into the config template
envsubst < "${TEMPLATE}" > "${CONFIG_FILE}"

echo "==> Config written to ${CONFIG_FILE}"

# Default to "daemon" (gateway + all configured channels)
if [ $# -eq 0 ]; then
  exec zeroclaw daemon
else
  exec zeroclaw "$@"
fi
