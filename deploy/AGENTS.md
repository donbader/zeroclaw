# AGENTS.md — ZeroClaw Deploy Directory

Scope: `deploy/` directory only.

## Purpose

Dokploy-ready (or any Docker Compose platform) deployment for ZeroClaw. Config lives in a TOML template; secrets are injected from `.env` via `envsubst` at container startup.

## File Inventory

| File | Role |
|---|---|
| `config.template.toml` | Full ZeroClaw config with `${VAR}` placeholders for secrets |
| `entrypoint.sh` | Runs `envsubst` on the template, then execs `zeroclaw daemon` |
| `Dockerfile` | Pulls official ZeroClaw image, layers entrypoint + template on Debian base |
| `docker-compose.yml` | Compose file, reads `.env` for secrets |
| `.env.example` | Example secrets file (copy to `.env`) |

## How It Works

1. Non-secret config (provider, model, channels, allowed users, etc.) is edited directly in `config.template.toml`.
2. Secrets (`API_KEY`, `TELEGRAM_BOT_TOKEN`, etc.) use `${VAR}` placeholders in the template.
3. At container startup, `entrypoint.sh` runs `envsubst` to produce the final `config.toml` with real values from `.env`.

## Editing Rules

- Edit `config.template.toml` directly for any non-secret config change (provider, model, channel settings, allowed users, etc.).
- Only use `${VAR}` placeholders for actual secrets (API keys, tokens). Don't over-parameterize.
- Keep `entrypoint.sh` minimal — it's just `envsubst` + `exec`. No conditional logic needed.
- Never commit `.env`. Only `.env.example` is tracked.
- Keep `entrypoint.sh` POSIX sh compatible.

## Known Gotchas

1. **Custom provider format**: ZeroClaw does NOT resolve `[model_providers.<name>]` profiles as provider IDs. Use `custom:<url>` directly as `default_provider` for OpenAI-compatible endpoints (e.g., `custom:http://host.docker.internal:8765/v1`). Use `anthropic-custom:<url>` for Anthropic-compatible endpoints.

2. **`[memory]` requires `auto_save`**: When specifying `[memory]` in config, `auto_save` is a required field (no serde default). Always include `auto_save = true`.

3. **Docker host access**: To reach services on the Docker host (or other containers exposing ports to the host), use `host.docker.internal`. The compose file includes `extra_hosts: host.docker.internal:host-gateway` to ensure this resolves on Linux.

4. **Debian base (not distroless)**: The Dockerfile uses Debian instead of the upstream distroless image because `envsubst` (from `gettext-base`) requires a shell. Tradeoff is ~50MB larger image.

5. **Default CMD is `daemon`**: This runs gateway + all configured channels. The upstream default is `gateway` (API only). For Telegram bot deployments, `daemon` is correct.

## Validation

```bash
cd deploy/
cp .env.example .env
# Edit .env with real values
docker compose up --build -d

# Verify generated config
docker compose exec zeroclaw cat /zeroclaw-data/.zeroclaw/config.toml

# Check health
curl http://localhost:42617/health

# Cleanup
docker compose down -v
```
