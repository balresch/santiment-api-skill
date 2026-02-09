# Santiment API Skill

Teach your AI agent to query the Santiment GraphQL API — hundreds of crypto metrics across 2,000+ assets.

## What This Does

This skill gives AI agents (Claude Code, OpenClaw, and others) the ability to fetch on-chain, financial, social, and development data from [Santiment's GraphQL API](https://api.santiment.net/graphiql). The agent learns how to construct queries, handle errors, manage rate limits, and discover metrics dynamically.

## Install

### OpenClaw

```bash
git clone https://github.com/balresch/santiment-api-skill.git
openclaw plugins install ./santiment-api-skill
```

Restart the Gateway after installing. The plugin's `configSchema` will prompt for your API key in the Control UI. Once configured, your agent automatically gains access to the Santiment skill.

### Claude Code

```bash
# Add this repo as a plugin marketplace
/plugin marketplace add balresch/santiment-api-skill

# Install the plugin
/plugin install santiment-api@balresch-santiment-api-skill
```

Then run the setup command to configure your API key:

```
/santiment-api:setup
```

### Updating

To get the latest version, update the marketplace first, then the plugin:

```bash
/plugin marketplace update santiment-api
/plugin update santiment-api@santiment-api
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
| `skills/santiment-graphql/references/metrics-catalog.md` | Keyword-to-metric discovery map + 20 curated quick-reference metrics |
| `skills/santiment-graphql/references/rate-limits.md` | Tier limits, complexity scoring, optimization tips |
| `skills/santiment-graphql/examples/query-patterns.md` | 5 worked GraphQL examples with curl commands |

## Links

- [Santiment API Docs](https://academy.santiment.net/sanapi/)
- [GraphQL Explorer](https://api.santiment.net/graphiql)
- [Santiment API Source (sanbase2)](https://github.com/santiment/sanbase2)
