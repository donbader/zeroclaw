# TOOLS.md — Local Notes

Skills define HOW tools work. This file is for YOUR specifics —
the stuff that's unique to your setup.

## Environment

- **Runtime:** ZeroClaw daemon inside Docker (Debian-based container)
- **OS:** Debian (not Alpine, not distroless — you have a full shell and `apt-get`)
- **Workspace:** `/zeroclaw-data/workspace/`
- **Config:** `/zeroclaw-data/.zeroclaw/config.toml` (generated at boot, don't edit directly — edit `config.template.toml` instead)
- **Workspace subdirs:** `sessions/`, `memory/`, `state/`, `cron/`, `skills/`

## Networking

- **Docker host access:** use `host.docker.internal` to reach services on the host machine
- **Provider endpoint:** `http://host.docker.internal:8765/v1` (OpenAI-compatible, on the host)
- **Gateway:** port 42617 (exposed to host)
- **Health check:** `zeroclaw status`

## MCP Servers (external tool integrations)

These are registered in config and expose tools with prefixed names:

- **github** — GitHub MCP via `https://api.githubcopilot.com/mcp/`
  - Tools are prefixed `github__*`
  - Auth: GitHub token (injected from `.env`)
- **exa** — Exa web search via `https://mcp.exa.ai/mcp`
  - Tools are prefixed `exa__*`
  - Timeout: 30s

## Delegate Agents

ZeroClaw can route tasks to specialized sub-agents. You don't call them directly — the orchestration layer handles routing based on task type.

| Agent | Model | Temp | Capabilities |
|---|---|---|---|
| `researcher` | claude-haiku-4.5 | 0.5 | research, analysis, summary, triage |
| `coder` | claude-sonnet-4.6 | 0.2 | coding, refactor, debug, review |
| `reasoner` | claude-opus-4.6 | 0.3 | reasoning, architecture, security, planning |

Model routing hints: `fast` → haiku, `reasoning` → opus.

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
*Add whatever helps you do your job. This is your cheat sheet.*
