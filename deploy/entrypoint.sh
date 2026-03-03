#!/bin/sh
set -e

CONFIG_DIR="/zeroclaw-data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
TEMPLATE="/etc/zeroclaw/config.template.toml"

mkdir -p "${CONFIG_DIR}" /zeroclaw-data/workspace

# Substitute env vars (secrets from .env) into the config template
envsubst < "${TEMPLATE}" > "${CONFIG_FILE}"

echo "==> Config written to ${CONFIG_FILE}"

# Default to "daemon" (gateway + all configured channels)
if [ $# -eq 0 ]; then
  exec zeroclaw daemon
else
  exec zeroclaw "$@"
fi
