# Santiment API Skill

Teach your AI agent to query the Santiment GraphQL API — 750+ crypto metrics across 2,000+ assets.

## What This Does

This skill gives AI agents (Claude Code, OpenClaw, and others) the ability to fetch on-chain, financial, social, and development data from [Santiment's GraphQL API](https://api.santiment.net/graphiql). The agent learns how to construct queries, handle errors, manage rate limits, and discover metrics dynamically.

## Install

### OpenClaw

Paste this repo URL in any OpenClaw chat. The bot handles installation and API key setup.

### Claude Code

```bash
claude plugin add https://github.com/balresch/santiment-api-skill
```

Then run the setup command to configure your API key:

```
/santiment-api:setup
```

## Get an API Key

1. Sign up or log in at [app.santiment.net](https://app.santiment.net)
2. Go to **Account Settings > API Keys**: https://app.santiment.net/account#api-keys
3. Generate a new key

A free tier is available with limited rate limits and historical data access.

## What's Included

| File | Description |
|---|---|
| `skills/santiment-graphql/SKILL.md` | Core skill — endpoint, auth, `getMetric` query pattern, dynamic discovery, error handling |
| `skills/santiment-graphql/references/metrics-catalog.md` | Curated ~20 metrics across 7 categories |
| `skills/santiment-graphql/references/rate-limits.md` | Tier limits, complexity scoring, optimization tips |
| `skills/santiment-graphql/examples/query-patterns.md` | 4 worked GraphQL examples with curl commands |

## Links

- [Santiment API Docs](https://academy.santiment.net/sanapi/)
- [GraphQL Explorer](https://api.santiment.net/graphiql)
- [Santiment API Source (sanbase2)](https://github.com/santiment/sanbase2)
