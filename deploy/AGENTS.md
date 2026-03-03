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
