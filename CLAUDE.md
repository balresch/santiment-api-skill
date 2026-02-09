# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository is a **Claude Code plugin** that teaches AI agents how to use the Santiment GraphQL API — a crypto market data platform with 750+ metrics across 2,000+ assets. The plugin is designed to be consumed by Claude Code, OpenClaw bots, and other AI agents.

## Repository Structure

```
santiment-api-skill/
├── .claude-plugin/
│   └── plugin.json                          # Plugin manifest
├── skills/
│   └── santiment-graphql/
│       ├── SKILL.md                         # Core skill (loaded on trigger)
│       ├── references/
│       │   ├── metrics-catalog.md           # Curated ~20 metrics by category
│       │   └── rate-limits.md               # Tiers, complexity, optimization tips
│       └── examples/
│           └── query-patterns.md            # 4 varied GraphQL examples
├── commands/
│   └── santiment-query.md                   # Guided query-building slash command
├── CLAUDE.md                                # This file
└── .claude/
    └── settings.local.json                  # Local settings
```

- **SKILL.md** — Core skill file loaded when the skill triggers. Contains endpoint/auth, `getMetric` query pattern, dynamic discovery, error handling, and a query-building checklist.
- **references/** — Loaded on demand. Detailed metrics catalog and rate limit documentation.
- **examples/** — Loaded on demand. Four worked GraphQL examples with curl commands.
- **commands/santiment-query.md** — Slash command (`/santiment-api:santiment-query`) that walks through query construction step by step.

## Working on the Plugin

The plugin is purely documentation (Markdown + JSON manifest). There is no build system, tests, or dependencies.

When editing skill or reference files:
- The audience is an AI agent, not a human developer. Write instructions the way you'd want to receive them.
- Keep the focus on **GraphQL only** — no Python SDK, no Sansheets, no R wrappers.
- The core metrics table is a curated subset. The full list (750+) is discoverable via `getAvailableMetrics`. Don't try to enumerate all metrics.
- Every example should demonstrate a distinct API capability (different sub-field, parameter, or pattern). Avoid redundant examples.
- Rate limit and complexity information is critical — agents burn through quotas fast without it.
- SKILL.md should stay in the 1,500–1,800 word range. Move detailed content to `references/`.

## Key Santiment API Details (for context)

- **Endpoint:** `https://api.santiment.net/graphql`
- **Auth:** `Authorization: Apikey <key>` header
- **Primary query:** `getMetric(metric: "...")` with sub-fields like `timeseriesData`, `aggregatedTimeseriesData`, `histogramData`
- **Source docs:** https://academy.santiment.net/sanapi/
- **GraphQL explorer:** https://api.santiment.net/graphiql
- **Open source server:** https://github.com/santiment/sanbase2

## Internal Testing

API key for testing queries during development (do NOT include in the published skill file):

```
cabnxr3o66cyiygr_biyz63i3zuipf4sj
```

Test with:
```bash
curl -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey cabnxr3o66cyiygr_biyz63i3zuipf4sj" \
  -d '{"query": "{ currentUser { id } }"}'
```
