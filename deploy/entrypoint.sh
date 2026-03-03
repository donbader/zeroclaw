#!/bin/sh
set -e

CONFIG_DIR="/zeroclaw-data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
TEMPLATE="/etc/zeroclaw/config.template.toml"

mkdir -p "${CONFIG_DIR}" /zeroclaw-data/workspace

# Create workspace subdirectories (matches onboard wizard)
for dir in sessions memory state cron skills; do
  mkdir -p "/zeroclaw-data/workspace/${dir}"
done

# Copy workspace identity files
# RESET_WORKSPACE=true → overwrite all; otherwise skip existing files
for f in /etc/zeroclaw/workspace/*.md; do
  name=$(basename "$f")
  if [ "${RESET_WORKSPACE}" = "true" ] || [ ! -f "/zeroclaw-data/workspace/${name}" ]; then
    cp "$f" "/zeroclaw-data/workspace/${name}"
  fi
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
