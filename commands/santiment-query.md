---
description: Build and execute a Santiment API query
allowed-tools: Read, Bash(curl:*)
---

Walk the user through building and executing a Santiment GraphQL API query step by step.

Load the skill reference: @${CLAUDE_PLUGIN_ROOT}/skills/santiment-graphql/SKILL.md

## Step 1: Choose a Metric

Ask the user which metric they want to query. If they're unsure, offer common options:
- `price_usd` — asset price
- `daily_active_addresses` — on-chain activity
- `exchange_inflow` / `exchange_outflow` — exchange flows
- `mvrv_usd` — valuation ratio
- `social_volume_total` — social mentions
- `dev_activity` — development activity

For the full catalog, read: @${CLAUDE_PLUGIN_ROOT}/skills/santiment-graphql/references/metrics-catalog.md

If the user describes data they want but doesn't know the metric name, suggest the best match from the catalog.

## Step 2: Choose an Asset (Slug)

Ask the user which cryptocurrency they want data for. Common slugs: `bitcoin`, `ethereum`, `cardano`, `ripple`, `solana`.

If the user gives a ticker or full name instead of a slug, map it (e.g., "BTC" → `bitcoin`, "ETH" → `ethereum`). For uncommon assets, query `allProjects` to find the correct slug.

## Step 3: Choose a Time Range

Ask the user what time period they need. Suggest relative expressions:
- Last 7 days: `from: "utc_now-7d"`, `to: "utc_now"`
- Last 30 days: `from: "utc_now-30d"`, `to: "utc_now"`
- Last 6 months: `from: "utc_now-6m"`, `to: "utc_now"`
- Last year: `from: "utc_now-1y"`, `to: "utc_now"`

Also accept specific ISO 8601 dates if the user provides them.

## Step 4: Choose a Sub-field and Interval

Based on the user's needs, recommend the appropriate sub-field:
- **Time series** → `timeseriesData` with an interval (`"1d"` for daily, `"1h"` for hourly)
- **Single summary value** → `aggregatedTimeseriesData` with an aggregation (`AVG`, `SUM`, `LAST`)
- **Multiple assets at once** → `timeseriesDataPerSlugJson`

Ask if they want any transform (moving average, percent change) applied.

Review rate limit considerations: @${CLAUDE_PLUGIN_ROOT}/skills/santiment-graphql/references/rate-limits.md

## Step 5: Build and Execute

Construct the GraphQL query from the user's choices. Before executing, show the query to the user for confirmation.

The user MUST provide their API key. Do not use any hardcoded key. If the user hasn't provided one, ask:

> I need your Santiment API key to execute this query. You can find it at https://app.santiment.net/account#api-keys. What is your API key?

Execute the query using curl:

```
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <USER_API_KEY>" \
  -d '{"query": "<CONSTRUCTED_QUERY>"}'
```

## Step 6: Present Results

Parse the JSON response and present the data clearly:
- For time series: show a summary (first few and last few data points, min, max, average)
- For aggregated data: show the single value with context
- For multi-asset data: compare values across slugs

If the response contains an `errors` array, explain the error and suggest a fix based on the error handling guidance in the skill reference.
