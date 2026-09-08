---
name: santiment-graphql
description: >
  Queries the Santiment GraphQL API for crypto market data (on-chain, financial, social,
  development) across 2,000+ assets. Use when the user asks to query Santiment, fetch
  crypto metrics, get on-chain data, check exchange flows, look up MVRV, get social
  volume, fetch price of Bitcoin, or access cryptocurrency market data via the API.
version: 1.1.7
metadata:
  {
    "openclaw":
      {
        "emoji": "📊",
        "requires": { "env": ["SANTIMENT_API_KEY"] },
        "primaryEnv": "SANTIMENT_API_KEY",
      },
  }
---

# Santiment GraphQL API

Query the Santiment API — a GraphQL platform providing 1,100+ metrics for 2,000+ crypto assets across 12 blockchains. Fetch on-chain, financial, social, and development data for the cryptocurrency market.

## Endpoint and Authentication

- **GraphQL endpoint:** `https://api.santiment.net/graphql`
- **Interactive explorer:** `https://api.santiment.net/graphiql`

Every request requires an API key in the `Authorization` header (`Authorization: Apikey <KEY>`). The user must provide their own key — never hardcode or assume one. If `$SANTIMENT_API_KEY` is set in the environment, use it directly. Otherwise, ask the user for their key (free tier available at https://app.santiment.net/account#api-keys).

All requests are HTTP `POST` with `Content-Type: application/json`. **Use GraphQL variables** to separate the query template from runtime values — this avoids quote-escaping errors. In curl, use a heredoc with a quoted delimiter (`<< 'QUERY'`) so the shell doesn't interpret `$variable` as environment variables.

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "query($metric: String!, $slug: String, $from: DateTime!, $to: DateTime!, $interval: interval) { getMetric(metric: $metric) { timeseriesDataJson(slug: $slug, from: $from, to: $to, interval: $interval) } }",
  "variables": {
    "metric": "price_usd",
    "slug": "bitcoin",
    "from": "utc_now-7d",
    "to": "utc_now",
    "interval": "1d"
  }
}
QUERY
```

### Variable Types

GraphQL types for `query(...)` variable declarations:

| Parameter     | Type                                   |
| ------------- | -------------------------------------- |
| `metric`      | `String!`                              |
| `slug`        | `String`                               |
| `selector`    | `MetricTargetSelectorInputObject`      |
| `from` / `to` | `DateTime!`                            |
| `interval`    | `interval`                             |
| `aggregation` | `Aggregation`                          |
| `transform`   | `TimeseriesMetricTransformInputObject` |

## Core Query: `getMetric`

Nearly all data flows through `getMetric`. Pass a metric name, then select one sub-field that determines the response shape.

### Sub-fields

Choose exactly one per `getMetric` call:

| Sub-field                   | Returns                | When to use                                                                                                                                                                                                      |
| --------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `timeseriesDataJson`        | JSON list of maps      | Time series over `from`–`to`, with points spaced `interval` apart.                                                                                                                                               |
| `timeseriesDataPerSlugJson` | JSON list of maps      | Fetch the same metric for multiple assets in one API call. Pass `selector: { slugs: ["bitcoin", "ethereum"] }` — far cheaper than one query per asset.                                                            |
| `aggregatedTimeseriesData`  | Single numeric value   | Need one summary number (average, sum, last value) over a time range.                                                                                                                                            |
| `metadata`                  | Metric metadata object | Available slugs, aggregations, selectors, intervals, and data type. Call before querying an unfamiliar metric.                                                                                                   |
| `availableSince`            | ISO 8601 date string   | How far back data exists for a metric + slug. `1970-01-01T00:00:00Z` means the metric was **never computed** for this slug.                                                                                      |

### Parameters

Passed to the sub-fields, not to `getMetric` itself. `aggregatedTimeseriesData` takes neither `interval` nor `transform`:

| Parameter     | Type   | Description                                                                                                                                 | Example                                        |
| ------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `slug`        | String | Asset identifier. Use for single-asset queries.                                                                                             | `"bitcoin"`, `"ethereum"`                      |
| `selector`    | Object | Use instead of `slug` for multi-asset queries or filtering by `owner`, `label`, `holdersCount`, `source`.                                   | `{ slug: "bitcoin", source: "cryptocompare" }` |
| `from`        | String | Start of time range. Accepts ISO 8601 timestamps or relative expressions.                                                                   | `"2024-01-01T00:00:00Z"`, `"utc_now-30d"`      |
| `to`          | String | End of time range. Same format as `from`.                                                                                                   | `"utc_now"`                                    |
| `interval`    | String | Time granularity between data points.                                                                                                       | `"5m"`, `"1h"`, `"1d"`, `"7d"`                 |
| `aggregation` | Enum   | Override the default aggregation method. Options: `AVG`, `SUM`, `LAST`, `FIRST`, `MEDIAN`, `MAX`, `MIN`, `ANY`.                             | `AVG`                                          |
| `transform`   | Object | Post-processing transform applied to the result.                                                                                            | See Transforms section.                        |

**Important:** `slug` and `selector` are mutually exclusive. Use `selector` for multi-slug queries (`{ slugs: [...] }`) or when a metric requires extra selector fields like `holdersCount` or `owner`.

### Relative Time Expressions

The `from` and `to` fields accept ISO8601 strings (`2025-01-01T12:30:00Z`) or relative expressions: `"utc_now"` for the current time, or `utc_now-<N><unit>`.

Units: `s` seconds, `m` **minutes**, `h` hours, `d` days, `w` weeks, `y` years.

**There is no month unit.** `m` is minutes — `"utc_now-6m"` is six *minutes* ago, not six months, and silently returns almost no data instead of erroring. Express months in weeks or days: 6 months → `"utc_now-26w"` or `"utc_now-180d"`. `M` and `mo` are rejected outright.

### Transforms

Post-process server-side by passing `transform` to `timeseriesDataJson`:

| Transform                                        | Effect                                                          |
| ------------------------------------------------ | --------------------------------------------------------------- |
| `{type: "moving_average", movingAverageBase: N}` | Replace each value with the average of the preceding N values   |
| `{type: "consecutive_differences"}`              | Replace each value with the difference from the prior value     |
| `{type: "percent_change"}`                       | Replace each value with the percent change from the prior value |

Moving averages reduce returned points by N-1; request a slightly wider range to compensate.

## Dynamic Discovery

When the metric name is unknown, use this 3-step workflow.

### Step 1 — Fetch the metric list

```graphql
{ getAvailableMetrics }
```

Returns 1,100+ `snake_case` strings. Save to a file with `-o` and read directly; do not pipe through stdin:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getAvailableMetrics }"}' \
  -o /tmp/santiment-metrics.json
```

### Step 2 — Search by keywords

Search the file for keywords matching user intent (e.g. whale → `holder`, `top`, `amount_in`). See `references/metrics-catalog.md` for mappings.

### Step 3 — Inspect metadata

For candidate metrics, fetch metadata to confirm compatibility:

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    metadata {
      availableSlugs
      availableAggregations
      availableSelectors
      dataType
      defaultAggregation
      minInterval
    }
  }
}
```

Metadata reveals required selectors (`holdersCount`, `owner`, `labelFqn`), supported slugs, and min interval.

### Find a project's slug

```graphql
{ projectBySlug(slug: "bitcoin") { slug name ticker infrastructure } }
```

For ticker → slug, use `allProjects { slug name ticker }` (paginated).

### Fast pattern: aggregated metrics for many assets via `allProjects`

For **many assets × many summary metrics** at once, use `allProjects` with aliased `aggregatedTimeseriesData` fields — one query returns a projects×metrics matrix, faster than asset-by-asset `getMetric`. Best for ranking and screening. A `null` column is **not** "no data": it usually means the metric is restricted on your plan (see Plan Restrictions). Full example in `examples/query-patterns.md`.

### Check data availability

Verify data exists for a metric+slug before large timeseries queries:

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    availableSince(slug: "ethereum")
  }
}
```

### Plan Restrictions and Data Freshness

Most plans apply a realtime lag to many metrics — commonly ~30 days on `mvrv_usd`, `exchange_*`, `social_*`, `network_growth`, and holder metrics. The data exists upstream; your plan just cannot read it. **This usually does not surface as an error** — the API errors only when the *entire* window is outside your allowance; a window that merely overlaps the boundary is silently clipped:

| Situation                                          | Behaviour                                              |
| -------------------------------------------------- | ------------------------------------------------------ |
| Window entirely outside                            | Error naming the exact allowed `from` / `to`           |
| Window partly overlapping, `timeseriesDataJson`    | **Silently truncated** — short or empty list, no error |
| Window partly overlapping, `aggregatedTimeseriesData` | **Silently clipped** — returns a stale value        |
| `aggregatedTimeseriesData` inside `allProjects`    | **Silently returns `null`**                            |

This is why `from: "utc_now-30d", to: "utc_now"` on a ~30-day-lagged metric is the worst case: it straddles the boundary, so it never errors — it just returns almost nothing, or a month-old number. Never call a value "current", "today's", or "latest" without confirming freshness:

```graphql
{ getMetric(metric: "mvrv_usd") { lastDatetimeComputedAt(slug: "bitcoin") } }
```

If that timestamp is far newer than the window your data came from, you were served clipped data — say so rather than reporting it as current.

Do **not** trust `getAccessRestrictions` here; it reports `isRestricted: false` for metrics the API then rejects. The restriction **error message is authoritative** — it states the allowed `from` and `to`. To force it out of a silent case, re-query a strictly recent window (`utc_now-2d` → `utc_now`), read the bounds, then retry inside them. See `references/rate-limits.md`.

## Error Handling

The API returns HTTP **200** even for errors — always parse the JSON and check the `errors` array. Use 4xx/5xx for client or network issues; **429** means rate limit (see `references/rate-limits.md`).

A typical error response:

```json
{
  "data": { "getMetric": null },
  "errors": [
    {
      "message": "The metric 'nonexistent_metric' is not a valid metric."
    }
  ]
}
```

When `data` contains `null` and `errors` is present, the query failed. Common errors:

| Error                       | Cause                                                               | Fix                                                                                                                                                                                                 |
| --------------------------- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Invalid metric name         | Metric string doesn't exist                                         | Verify with `getAvailableMetrics`                                                                                                                                                                   |
| Invalid slug                | Asset slug not recognized                                           | Verify with `allProjects` or `projectBySlug`                                                                                                                                                        |
| Interval too small          | Requested interval below minimum for this metric or plan            | Check `metadata { minInterval }`                                                                                                                                                                    |
| Time range restricted       | Requested window exceeds your plan's historical or realtime allowance | Read the allowed `from`/`to` from the error message and retry inside them. See Plan Restrictions.                                                                                                    |
| Complexity too high         | Query requests too many data points                                 | Reduce time range, increase interval, or fetch fewer fields                                                                                                                                         |
| HTTP 429                    | Rate limit exceeded                                                 | Back off exponentially and retry after a delay                                                                                                                                                      |
| Empty timeseries (no error) | Ghost data, or a silently clipped plan restriction | Check `availableSince`: epoch = never computed; a real date = restriction or gap. See `references/metrics-catalog.md` |

## Quick Reference: Building a Query

Steps to construct any Santiment API query:

1. **Pick a metric** — use directly if known, otherwise follow Discovery Workflow.
2. **Pick a slug** — resolve names/tickers via `projectBySlug` or `allProjects`.
3. **Pick a time range** — relative expressions preferred. Check `availableSince` first.
4. **Pick an interval** — `"1d"`, `"1h"`, `"7d"`. Larger intervals reduce complexity.
5. **Pick a sub-field** — `timeseriesDataJson` for series, `aggregatedTimeseriesData` for single value, `timeseriesDataPerSlugJson` for multi-asset.
6. **Optionally add** — `transform`, `selector` (instead of `slug`), or `aggregation` override.
7. **If data is empty** — check `availableSince` for epoch. If epoch, the metric isn't computed for this slug's chain. Report unavailability and suggest alternative metrics.
8. **Before calling any value "current"** — if it came from an aggregate on a restricted metric, confirm with `lastDatetimeComputedAt`. A plausible number is not proof of a fresh one.

## Additional Resources

- **Metrics catalog** — `references/metrics-catalog.md` — keyword-to-metric mapping and ~20 quick-reference metrics
- **Rate limits** — `references/rate-limits.md` — tier limits, complexity scoring, optimization
- **Query patterns** — `examples/query-patterns.md` — 8 worked GraphQL+curl examples (discovery, ghost data, plan restrictions)
