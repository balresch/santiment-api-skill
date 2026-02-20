# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository is a **Claude Code plugin** that teaches AI agents how to use the Santiment GraphQL API — a crypto market data platform with 750+ metrics across 2,000+ assets. The plugin is designed to be consumed by Claude Code, OpenClaw bots, and other AI agents.

## Key Components

- **SKILL.md** — Core skill file loaded when the skill triggers. Contains endpoint/auth, `getMetric` query pattern, dynamic discovery, error handling, and a query-building checklist.
- **references/** — Loaded on demand. Detailed metrics catalog and rate limit documentation.
- **examples/** — Loaded on demand. Six worked GraphQL examples with curl commands.
- **commands/santiment-query.md** — Slash command (`/santiment-api:santiment-query`) that walks through query construction step by step.
- **commands/setup.md** — Slash command (`/santiment-api:setup`) that configures the user's API key for persistent use.
- **hooks/** — SessionStart hook that auto-loads the API key from `~/.claude/santiment-api.local.md` into `$SANTIMENT_API_KEY`.

## Working on the Plugin

The plugin is purely documentation (Markdown + JSON manifest). There is no build system, tests, or dependencies.

When editing skill or reference files:
- The audience is an AI agent, not a human developer. Write instructions the way you'd want to receive them.
- Keep the focus on **GraphQL only** — no Python SDK, no Sansheets, no R wrappers.
- `metrics-catalog.md` contains a keyword-concept mapping table (for translating user intent into metric name search terms) and a curated quick-reference of ~20 common metrics. The full list (750+) is discoverable via `getAvailableMetrics`. Don't try to enumerate all metrics; instead, maintain the keyword map to cover new concept clusters.
- Every example should demonstrate a distinct API capability (different sub-field, parameter, or pattern). Avoid redundant examples.
- Rate limit and complexity information is critical — agents burn through quotas fast without it.
- SKILL.md should stay in the 1,500–1,800 word range. Move detailed content to `references/`.

## Platform Compatibility

This plugin supports both **Claude Code** and **OpenClaw** via dual manifests on `main`. The two manifests don't collide — Claude Code reads `.claude-plugin/plugin.json`, OpenClaw reads `openclaw.plugin.json`. Shared content (SKILL.md, references, examples) is used by both platforms without duplication.

**API key configuration by platform:**

| Platform | How `$SANTIMENT_API_KEY` gets set |
|---|---|
| Claude Code | SessionStart hook loads from `~/.claude/santiment-api.local.md`, or user runs `/santiment-api:setup` |
| OpenClaw | Plugin `configSchema.apiKey` + `primaryEnv` mapping sets the env var automatically |
| Other agents | Agent asks the user for the key at runtime |

SKILL.md uses platform-neutral wording (`If $SANTIMENT_API_KEY is set...`) so it works everywhere.

**Platform-specific components:**
- `commands/` — Claude Code only (slash commands). OpenClaw ignores these.
- `hooks/` — Claude Code only (SessionStart hook). OpenClaw ignores these.
- `openclaw.plugin.json` — OpenClaw only. Claude Code ignores this file.
- `skills/`, `references/`, `examples/` — Shared across all platforms.

## Internal Testing

The dev API key is stored in `.env` (gitignored, never committed). Export it before running test commands.

Test with:
```bash
export $(grep -v '^#' .env | xargs)
curl -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d '{"query": "{ currentUser { id } }"}'
```
