# AGENTS.md — ZeroClaw Corey Directory

Scope: `corey/` directory only.

## Purpose

Dokploy-ready (or any Docker Compose platform) deployment for ZeroClaw. Config lives in a TOML template; secrets are injected from `.env` via `envsubst` at container startup.

## Reference Configuration

The canonical deployment settings (config template, compose file, env example, workspace files) live in the [`corey/` folder on the `corey-setup` branch of `github.com/donbader/zeroclaw`](https://github.com/donbader/zeroclaw/tree/corey-setup/corey). Use that as the source of truth when bootstrapping or updating this deployment.

## File Inventory

| File | Role |
|---|---|
| `config.template.toml` | Full ZeroClaw config with `${VAR}` placeholders for secrets |
| `entrypoint.sh` | Runs `envsubst` on the template, copies workspace files, then execs `zeroclaw daemon` |
| `Dockerfile` | Registry-based deploy image; pulls pre-built binary from `ghcr.io` and layers deploy tools |
| `.env.example` | Example secrets file (copy to `.env`) |
| `workspace/` | Identity/personality markdown files injected into the system prompt |

## Workspace Identity Files

These files define the agent's personality, tone, and behavior. They are copied into `/zeroclaw-data/workspace/` on first boot (existing files on the volume are not overwritten).

| File | Purpose |
|---|---|
| `IDENTITY.md` | Name, creature type, vibe, emoji |
| `SOUL.md` | Personality, communication style, boundaries |
| `USER.md` | Info about the operator (name, timezone, preferences) |
| `BOOTSTRAP.md` | First-run greeting (agent deletes this after getting to know you) |
| `AGENTS.md` | Session startup checklist, safety rules, memory system |
| `TOOLS.md` | Built-in tool reference and local environment notes |
| `HEARTBEAT.md` | Periodic tasks (empty by default) |
| `MEMORY.md` | Long-term curated memory (auto-injected into system prompt) |

To customize personality: edit the files in `corey/workspace/` and rebuild. Or edit them live on the Docker volume — the entrypoint won't overwrite existing files.

## How It Works

The `docker-compose.yml` builds from `corey/Dockerfile`, which pulls the pre-built ZeroClaw binary from `ghcr.io/zeroclaw-labs/zeroclaw` and layers deploy tools on top (envsubst, git, gh, nodejs/npm, uv). No Rust compilation required — builds take ~30s instead of ~10min.

Pin a specific version via `ZEROCLAW_VERSION` in `.env` (default: `latest`).

The deploy layer adds `envsubst`, the config template, workspace files, and the entrypoint.

At container startup, `entrypoint.sh`:
   - Copies workspace identity files to the volume (skip if already present)
   - Runs `envsubst` to produce the final `config.toml` with real values from `.env`
   - Execs `zeroclaw daemon`

## Editing Rules

- Edit `config.template.toml` directly for any non-secret config change (provider, model, channel settings, allowed users, etc.).
- Only use `${VAR}` placeholders for actual secrets (API keys, tokens). Don't over-parameterize.
- Edit `workspace/*.md` for personality/tone changes. These are templates from the official onboarding wizard.
- Keep `entrypoint.sh` minimal — it's `envsubst` + file copy + `exec`. No conditional logic needed.
- Never commit `.env`. Only `.env.example` is tracked.
- Keep `entrypoint.sh` POSIX sh compatible.

## Known Gotchas

1. **Custom provider format**: ZeroClaw does NOT resolve `[model_providers.<name>]` profiles as provider IDs. Use `custom:<url>` directly as `default_provider` for OpenAI-compatible endpoints (e.g., `custom:http://host.docker.internal:8765/v1`). Use `anthropic-custom:<url>` for Anthropic-compatible endpoints. Note: `anthropic-custom:` URLs must NOT include `/v1` — the provider appends `/v1/messages` automatically (e.g., `anthropic-custom:http://host.docker.internal:8765`).

2. **`[memory]` requires `auto_save`**: When specifying `[memory]` in config, `auto_save` is a required field (no serde default). Always include `auto_save = true`.

3. **Docker host access**: To reach services on the Docker host (or other containers exposing ports to the host), use `host.docker.internal`. The compose file includes `extra_hosts: host.docker.internal:host-gateway` to ensure this resolves on Linux.

4. **Debian base (not distroless)**: The Dockerfile uses Debian instead of the upstream distroless image because `envsubst` (from `gettext-base`) requires a shell. Tradeoff is ~50MB larger image.

5. **Default CMD is `daemon`**: This runs gateway + all configured channels. The upstream default is `gateway` (API only). For Telegram bot deployments, `daemon` is correct.

6. **Workspace files are copy-on-first-boot**: The entrypoint only copies workspace `.md` files if they don't already exist on the volume. To force-reset all identity files from the image, set `RESET_WORKSPACE=true` in `.env` and restart. Remove it after reset to preserve runtime edits.

## Validation

```bash
cd corey/
cp .env.example .env
# Edit .env with real values
docker compose up --build -d

# Verify generated config
docker compose exec zeroclaw cat /zeroclaw-data/.zeroclaw/config.toml

# Verify workspace files
docker compose exec zeroclaw ls /zeroclaw-data/workspace/

# Check health
curl http://localhost:42617/health

# Tail logs
docker compose logs -f

# Cleanup
docker compose down -v
```
