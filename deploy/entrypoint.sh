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

# Copy workspace identity files (skip if already present from volume)
for f in /etc/zeroclaw/workspace/*.md; do
  name=$(basename "$f")
  [ ! -f "/zeroclaw-data/workspace/${name}" ] && cp "$f" "/zeroclaw-data/workspace/${name}"
done

# Substitute env vars (secrets from .env) into the config template
envsubst < "${TEMPLATE}" > "${CONFIG_FILE}"

echo "==> Config written to ${CONFIG_FILE}"

# Register Telegram bot commands if token is set
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  resp=$(curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMyCommands" \
    -H 'Content-Type: application/json' \
    -d '{"commands":[{"command":"new","description":"Start a new conversation"},{"command":"model","description":"Show or switch the current model"},{"command":"models","description":"Show or switch the current provider"}]}' 2>&1) || true
  case "$resp" in
    *'"ok":true'*) echo "==> Telegram bot commands registered" ;;
    *) echo "==> WARN: Telegram setMyCommands failed: ${resp}" ;;
  esac
fi

# Default to "daemon" (gateway + all configured channels)
if [ $# -eq 0 ]; then
  exec zeroclaw daemon
else
  exec zeroclaw "$@"
fi
