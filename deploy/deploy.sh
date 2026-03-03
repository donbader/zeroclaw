#!/bin/sh
# ZeroClaw deploy helper — builds base image + runs docker compose.
#
# Usage:
#   ./deploy.sh          # build + start
#   ./deploy.sh down     # stop
#   ./deploy.sh logs     # tail logs
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case "${1:-up}" in
  down)
    exec docker compose -f "$SCRIPT_DIR/docker-compose.yml" down "${@:2}"
    ;;
  logs)
    exec docker compose -f "$SCRIPT_DIR/docker-compose.yml" logs "${@:2}"
    ;;
  *)
    echo "==> Building base image (zeroclaw:dev) from source..."
    docker build -t zeroclaw:dev --target dev -f "$REPO_ROOT/Dockerfile" "$REPO_ROOT"

    echo "==> Building deploy layer + starting..."
    exec docker compose -f "$SCRIPT_DIR/docker-compose.yml" up --build -d "$@"
    ;;
esac
