# AGENTS.md — ZeroClaw Deploy Directory

Scope: `deploy/` directory only.

## Purpose

This directory contains a Dokploy-ready (or any Docker Compose platform) deployment setup for ZeroClaw. The entrypoint script generates `config.toml` from environment variables at container startup, so operators only need to set env vars in their hosting panel.

## File Inventory

| File | Role |
|---|---|
| `entrypoint.sh` | Generates `/zeroclaw-data/.zeroclaw/config.toml` from env vars, then execs `zeroclaw daemon` |
| `Dockerfile` | Pulls official ZeroClaw image, layers entrypoint on a shell-capable Debian base |
| `docker-compose.yml` | Compose file with all env vars declared and documented |

## Architecture Decisions

1. **Why a custom entrypoint instead of native env overrides?**
   ZeroClaw's `apply_env_overrides()` covers core settings (API key, provider, model, gateway) but does not cover channel config (`channels_config.telegram`, etc.). The entrypoint bridges this gap by templating the full TOML from env vars.

2. **Why Debian instead of distroless?**
   The entrypoint uses `sh`, `cat`, `grep`, `sed` for config templating. Distroless has no shell. The tradeoff is a larger image (~80MB vs ~30MB) for full env-driven configurability.

3. **Why `daemon` as default CMD?**
   `daemon` runs both the gateway API and all configured channels. The upstream default is `gateway` (API only, no channels). For a Telegram bot deployment, `daemon` is the correct mode.

4. **Why conditional channel blocks?**
   Channels are only written to config when their token env var is set. This avoids ZeroClaw attempting to start unconfigured channels and logging errors.

## Environment Variables

### Required

- `API_KEY` — LLM provider API key

### Channel Activation

Channels are enabled by setting their token:

- `TELEGRAM_BOT_TOKEN` — enables Telegram channel
- `DISCORD_BOT_TOKEN` — enables Discord channel

If neither is set, ZeroClaw runs in gateway-only mode (API at port 42617).

### Escape Hatch

- `ZEROCLAW_EXTRA_CONFIG` — raw TOML appended to the end of config. Use for any setting not covered by the templated env vars (e.g., Slack, Matrix, Signal, memory backends, security policy).

## Editing Rules

- Keep `entrypoint.sh` POSIX sh compatible (no bashisms). The Debian base uses `/bin/sh`.
- When adding a new channel, follow the existing pattern: check for token env var, conditionally append TOML block, ensure `[channels_config]` header exists.
- Do not hardcode secrets in any file. All sensitive values must come from env vars.
- Test locally with `docker compose --env-file .env up --build` before committing.
- The `ZEROCLAW_EXTRA_CONFIG` escape hatch exists so operators don't need code changes for uncommon settings. Prefer it over adding env vars for rarely-used options.

## Validation

```bash
# Build and run locally
cd deploy/
echo "API_KEY=test" > .env
echo "TELEGRAM_BOT_TOKEN=123:test" >> .env
docker compose up --build -d

# Verify generated config
docker compose exec zeroclaw cat /zeroclaw-data/.zeroclaw/config.toml

# Check health
curl http://localhost:42617/health

# Cleanup
docker compose down -v
```
