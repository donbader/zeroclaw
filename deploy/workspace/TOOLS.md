# TOOLS.md — Local Notes

Skills define HOW tools work. This file is for YOUR specifics —
the stuff that's unique to your setup.

## Environment

- **Runtime:** ZeroClaw daemon inside Docker (Debian-based container)
- **OS:** Debian (not Alpine, not distroless — you have a full shell and `apt-get`)
- **Workspace:** `/zeroclaw-data/workspace/`
- **Config:** `/zeroclaw-data/.zeroclaw/config.toml` (generated at boot — don't edit directly, edit `config.template.toml` instead)
- **Workspace subdirs:** `sessions/`, `memory/`, `state/`, `cron/`, `skills/`
- **Docker host access:** use `host.docker.internal` to reach services on the host
- **Health check:** `zeroclaw status`

For models, providers, channels, delegate agents, MCP servers, autonomy settings — read your config file. It's the single source of truth.

## Git & GitHub

Pre-installed and pre-configured at boot (if `GITHUB_TOKEN` is set in `.env`):

- **git** — clone, branch, commit, push. Credentials are auto-configured via token.
- **gh** — GitHub CLI. Create PRs, manage issues, review code. Already authenticated.
- **Git identity:** defaults to `Dorey <doreyortea@gmail.com>` (override via `GIT_USER_NAME` / `GIT_USER_EMAIL` in `.env`)

Typical workflow for contributing back to your own source:

```
cd /zeroclaw-data
git clone https://github.com/donbader/zeroclaw.git
cd zeroclaw
git checkout -b fix/something
# make changes
git add -A && git commit -m "fix: something"
git push -u origin fix/something
gh pr create --title "fix: something" --body "description"
```

## Built-in Tools

- **shell** — Execute terminal commands
    - Use when: running local checks, build/test commands, or diagnostics.
    - Don't use when: a safer dedicated tool exists, or command is destructive without approval.
    - **Installing packages:** You have passwordless sudo. Use `sudo apt-get update && sudo apt-get install -y <package>` to install anything you need at runtime (e.g. `gh`, `git`, `ripgrep`, `python3`).
- **file_read** — Read file contents
    - Use when: inspecting project files, configs, or logs.
    - Don't use when: you only need a quick string search (prefer targeted search first).
- **file_write** — Write file contents
    - Use when: applying focused edits, scaffolding files, or updating docs/code.
    - Don't use when: unsure about side effects or when the file should remain user-owned.
- **memory_store** — Save to memory
    - Use when: preserving durable preferences, decisions, or key context.
    - Don't use when: info is transient, noisy, or sensitive without explicit need.
- **memory_recall** — Search memory
    - Use when: you need prior decisions, user preferences, or historical context.
    - Don't use when: the answer is already in current files/conversation.
- **memory_forget** — Delete a memory entry
    - Use when: memory is incorrect, stale, or explicitly requested to be removed.
    - Don't use when: uncertain about impact; verify before deleting.

---

_Add whatever helps you do your job. This is your cheat sheet._
