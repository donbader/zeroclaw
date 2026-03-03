#!/bin/sh
set -e

CONFIG_DIR="/zeroclaw-data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

mkdir -p "${CONFIG_DIR}" /zeroclaw-data/workspace

# ── Core config ─────────────────────────────────────────────
cat > "${CONFIG_FILE}" <<EOF
workspace_dir = "/zeroclaw-data/workspace"
config_path = "${CONFIG_FILE}"
api_key = "${API_KEY:-}"
default_provider = "${PROVIDER:-openrouter}"
default_model = "${ZEROCLAW_MODEL:-anthropic/claude-sonnet-4-20250514}"
default_temperature = ${ZEROCLAW_TEMPERATURE:-0.7}

[gateway]
port = ${ZEROCLAW_GATEWAY_PORT:-42617}
host = "0.0.0.0"
allow_public_bind = true

[memory]
backend = "${ZEROCLAW_MEMORY_BACKEND:-markdown}"
EOF

# ── Telegram channel (only if token is set) ─────────────────
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  cat >> "${CONFIG_FILE}" <<EOF

[channels_config]
cli = false

[channels_config.telegram]
bot_token = "${TELEGRAM_BOT_TOKEN}"
allowed_users = [$(echo "${TELEGRAM_ALLOWED_USERS:-*}" | sed 's/,/", "/g; s/^/"/; s/$/"/' )]
stream_mode = "${TELEGRAM_STREAM_MODE:-off}"
mention_only = ${TELEGRAM_MENTION_ONLY:-false}
interrupt_on_new_message = ${TELEGRAM_INTERRUPT:-false}
ack_enabled = ${TELEGRAM_ACK_ENABLED:-true}
EOF

  # Group reply config (optional)
  if [ -n "${TELEGRAM_GROUP_REPLY_MODE:-}" ]; then
    cat >> "${CONFIG_FILE}" <<EOF

[channels_config.telegram.group_reply]
mode = "${TELEGRAM_GROUP_REPLY_MODE}"
EOF
  fi
fi

# ── Discord channel (only if token is set) ──────────────────
if [ -n "${DISCORD_BOT_TOKEN:-}" ]; then
  # Ensure channels_config header exists
  grep -q '^\[channels_config\]' "${CONFIG_FILE}" || cat >> "${CONFIG_FILE}" <<EOF

[channels_config]
cli = false
EOF

  cat >> "${CONFIG_FILE}" <<EOF

[channels_config.discord]
bot_token = "${DISCORD_BOT_TOKEN}"
allowed_users = [$(echo "${DISCORD_ALLOWED_USERS:-*}" | sed 's/,/", "/g; s/^/"/; s/$/"/' )]
EOF

  if [ -n "${DISCORD_GUILD_ID:-}" ]; then
    echo "guild_id = \"${DISCORD_GUILD_ID}\"" >> "${CONFIG_FILE}"
  fi
fi

# ── Append raw TOML snippet (escape hatch) ──────────────────
if [ -n "${ZEROCLAW_EXTRA_CONFIG:-}" ]; then
  printf '\n%s\n' "${ZEROCLAW_EXTRA_CONFIG}" >> "${CONFIG_FILE}"
fi

echo "==> Generated config at ${CONFIG_FILE}"

# ── Exec into zeroclaw ──────────────────────────────────────
# Default to "daemon" which runs gateway + all configured channels
if [ $# -eq 0 ]; then
  exec zeroclaw daemon
else
  exec zeroclaw "$@"
fi
