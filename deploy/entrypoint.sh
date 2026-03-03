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

# Copy bundled skills (each skill is a directory under skills/)
if [ -d /etc/zeroclaw/workspace/skills ]; then
  for skill_dir in /etc/zeroclaw/workspace/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="/zeroclaw-data/workspace/skills/${skill_name}"
    if [ "${RESET_WORKSPACE}" = "true" ] || [ ! -d "${target}" ]; then
      rm -rf "${target}"
      cp -r "$skill_dir" "${target}"
    fi
  done
fi

# Configure git + GitHub CLI if token is available
if [ -n "${GITHUB_TOKEN}" ]; then
  git config --global credential.helper 'store'
  git config --global user.name "${GIT_USER_NAME:-Dorey}"
  git config --global user.email "${GIT_USER_EMAIL:-doreyortea@gmail.com}"
  printf 'https://x-access-token:%s@github.com\n' "${GITHUB_TOKEN}" > "${HOME}/.git-credentials"
  echo "${GITHUB_TOKEN}" | gh auth login --with-token 2>/dev/null || true
  echo "==> Git + GitHub CLI configured"
fi

# Substitute env vars (secrets from .env) into the config template
envsubst < "${TEMPLATE}" > "${CONFIG_FILE}"

echo "==> Config written to ${CONFIG_FILE}"

# Default to "daemon" (gateway + all configured channels)
if [ $# -eq 0 ]; then
  exec zeroclaw daemon
else
  exec zeroclaw "$@"
fi
