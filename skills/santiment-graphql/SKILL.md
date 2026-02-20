---
name: santiment-graphql
description: >
  Queries the Santiment GraphQL API for crypto market data (on-chain, financial, social,
  development) across 2,000+ assets. Use when the user asks to query Santiment, fetch
  crypto metrics, get on-chain data, check exchange flows, look up MVRV, get social
  volume, fetch price of Bitcoin, or access cryptocurrency market data via the API.
version: 1.1.5
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

Query the Santiment API — a GraphQL platform providing 750+ metrics for 2,000+ crypto assets across 12 blockchains. Fetch on-chain, financial, social, and development data for the cryptocurrency market.

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

Use these GraphQL types in `query(...)` variable declarations:

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

Nearly all data flows through `getMetric`. Pass a metric name string and then select one sub-field that determines the shape of the response data.

### Sub-fields

Choose exactly one sub-field per `getMetric` call:

| Sub-field                   | Returns                | When to use                                                                                                                                                                                                      |
| --------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `timeseriesDataJson`        | JSON list of maps      | Returns a time series spanning the `from`-`to` time range where values are equally spaced `interval` time apart                                                                                                  |
| `timeseriesDataPerSlugJson` | JSON list of maps      | Fetch the same metric for multiple assets in a single API call. Pass `selector: { slugs: ["bitcoin", "ethereum"] }`. This counts as one API call, making it much more efficient than separate queries per asset. |
| `aggregatedTimeseriesData`  | Single numeric value   | Need one summary number (average, sum, last value) over a time range.                                                                                                                                            |
| `metadata`                  | Metric metadata object | Discover available slugs, aggregations, selectors, intervals, and data type for a metric. Call this before querying an unfamiliar metric.                                                                        |
| `availableSince`            | ISO 8601 date string   | Check how far back data exists for a given metric and slug. Prevents wasted calls on empty time ranges. A return value of `1970-01-01T00:00:00Z` means the metric has **never been computed** for this slug.     |

### Parameters

These parameters are passed to the sub-fields (timeseriesDataJson, timeseriesDataPerSlugJson and aggregatedTimeseriesData), not to `getMetric` itself. aggregatedTimeseriesData does not take `interval` and `transform`:

| Parameter     | Type   | Description                                                                                                                                 | Example                                        |
| ------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `slug`        | String | Asset identifier. Use for single-asset queries.                                                                                             | `"bitcoin"`, `"ethereum"`                      |
| `selector`    | Object | Advanced selection. Use instead of `slug` when you need multi-asset queries, or filtering by `owner`, `label`, `holdersCount`, or `source`. | `{ slug: "bitcoin", source: "cryptocompare" }` |
| `from`        | String | Start of time range. Accepts ISO 8601 timestamps or relative expressions.                                                                   | `"2024-01-01T00:00:00Z"`, `"utc_now-30d"`      |
| `to`          | String | End of time range. Same format as `from`.                                                                                                   | `"utc_now"`                                    |
| `interval`    | String | Time granularity between data points.                                                                                                       | `"5m"`, `"1h"`, `"1d"`, `"7d"`                 |
| `aggregation` | Enum   | Override the default aggregation method. Options: `AVG`, `SUM`, `LAST`, `FIRST`, `MEDIAN`, `MAX`, `MIN`, `ANY`.                             | `AVG`                                          |
| `transform`   | Object | Post-processing transform applied to the result.                                                                                            | See Transforms section.                        |

**Important:** `slug` and `selector` are mutually exclusive. Use `slug` for simple single-asset queries. Use `selector` when querying multiple slugs at once (`selector: { slugs: [...] }`) or when a metric requires additional selector fields like `holdersCount` or `owner`.

### Relative Time Expressions

The `from` and `to` fields accept ISO8601 strings (`2025-01-01T12:30:00Z`) or relative expressions: `utc_now-<N><unit>` where unit is `d` (day), `w` (week), `m` (month), or `y` (year).

- `"utc_now"` — current time
- `"utc_now-7d"` — 7 days ago
- `"utc_now-1m"` — 1 month ago
- `"utc_now-1y"` — 1 year ago

### Transforms

Apply transforms directly in the query to post-process data server-side. Pass the `transform` parameter to `timeseriesDataJson`:

| Transform                                        | Effect                                                          | Use case                                               |
| ------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------ |
| `{type: "moving_average", movingAverageBase: N}` | Replace each value with the average of the preceding N values   | Smooth noisy metrics like MVRV, social volume          |
| `{type: "consecutive_differences"}`              | Replace each value with the difference from the prior value     | Compute daily change from a cumulative metric          |
| `{type: "percent_change"}`                       | Replace each value with the percent change from the prior value | Normalize changes across metrics with different scales |

Transforms reduce the number of returned data points by N-1 for moving averages. Request a slightly wider time range to compensate.

## Dynamic Discovery

When you don't know the exact metric name for a user's request, follow this 3-step workflow. Always prefer dynamic discovery over hardcoded values.

### Step 1 — Fetch the metric list

```graphql
{
  getAvailableMetrics
}
```

Returns 1,000+ `snake_case` strings. **The response is large** — save to a file with `-o` and read it directly (e.g., `open()` in Python). Do not pipe the contents through stdin at any stage — neither from curl nor when processing the file afterward:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getAvailableMetrics }"}' \
  -o /tmp/santiment-metrics.json
```

Filter by plan with `getAvailableMetrics(product: SANAPI, plan: BUSINESS_PRO)`.

### Step 2 — Search by keywords

Search the saved file for keywords matching user intent. Example: whale activity → search for `holder`, `top`, `whale`, `supply`, `amount_in`. See `references/metrics-catalog.md` for intent-to-keyword mappings.

### Step 3 — Inspect metadata before querying

Once you have candidate metrics, fetch metadata to confirm compatibility:

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

This reveals required selectors (e.g., `holdersCount`, `owner`, `labelFqn`, etc.), supported slugs, and minimum interval. See `examples/query-patterns.md`.

### Find a project's slug

Look up a specific project by slug to verify it exists and see its details:

```graphql
{
  projectBySlug(slug: "bitcoin") {
    slug
    name
    ticker
    infrastructure
  }
}
```

Browse all projects paginated (useful when the user provides a token name or ticker instead of a slug):

```graphql
{
  allProjects {
    slug
    name
    ticker
  }
}
```

### Fast pattern: aggregated metrics for many assets via `allProjects`

When the user asks for **many assets** and **many summary metrics** at once, use `allProjects` with `aggregatedTimeseriesData` fields on each project. This is often faster and cheaper than doing `getMetric` calls asset-by-asset because one query can return a full matrix (projects x metrics) of already-aggregated values.

Use this pattern when:

- You need snapshot-like values (for example 30-day average, 7-day sum, latest value)
- You do not need full timeseries points for each asset
- You want to rank or compare many assets by multiple metrics in one response

**Important:** paginate `allProjects` for large universes, and keep metric count reasonable to avoid complexity spikes.

Example 1 — one aggregated metric across many assets:

```graphql
{
  allProjects(page: 1, pageSize: 100) {
    slug
    name
    avg_daa_30d: aggregatedTimeseriesData(
      metric: "daily_active_addresses"
      from: "utc_now-30d"
      to: "utc_now"
      aggregation: AVG
    )
  }
}
```

Example 2 — multiple aggregated metrics across many assets in one query:

```graphql
{
  allProjects(page: 1, pageSize: 100) {
    slug
    name
    ticker
    last_price_usd: aggregatedTimeseriesData(
      metric: "price_usd"
      from: "utc_now-1d"
      to: "utc_now"
      aggregation: LAST
    )
    avg_daa_30d: aggregatedTimeseriesData(
      metric: "daily_active_addresses"
      from: "utc_now-30d"
      to: "utc_now"
      aggregation: AVG
    )
    sum_exchange_inflow_7d: aggregatedTimeseriesData(
      metric: "exchange_inflow"
      from: "utc_now-7d"
      to: "utc_now"
      aggregation: SUM
    )
  }
}
```

Practical guidance:

- Use aliases (`last_price_usd`, `avg_daa_30d`, etc.) so each metric column is explicit.
- Start with small pages (`pageSize: 50` or `100`), then paginate.
- If complexity errors appear, reduce `pageSize`, narrow time windows, or request fewer metrics per query.
- Prefer this pattern for screening/ranking; switch to `getMetric(...){ timeseriesDataJson(...) }` only for drill-down charts.

### Check data availability for a metric and slug

Before making a large timeseries query, verify that data exists for the desired metric-slug.

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    availableSince(slug: "ethereum")
  }
}
```

### Check access restrictions for your plan

Understand what historical range your API key can access for each metric. Call this to avoid wasted queries that would return restriction errors:

```graphql
{
  getAccessRestrictions(product: SANAPI, plan: BUSINESS_PRO, filter: METRIC) {
    name
    isDeprecated
    # Check if the metric is available at all for your plan
    isAccessible
    # Check if the metric has realtime/historical access restricted
    isRestricted
    # If access is restricted, check what is the first and last datetimes
    # you can access. If null, then no restriction is applied
    restrictedFrom
    restrictedTo
    # The lowest resolution for which the metric has data. Usually it's 5 minutes (5m) or 1 day (1d)
    minInterval
    # Find and read the documentation of the metric
    docs
  }
}
```

## Error Handling

The API returns HTTP **4xx** and **5xx** when experiencing client or network issues.
HTTP Code **429** is reserved for rate-limits. If rate limits are exceeded, the error message and the HTTP response headers will include information about the rate limits.

Otherwise the API always returns HTTP **200**, even for errors. Always parse the JSON and check for the `errors` array.

A typical error response:

```json
{
  "data": { "getMetric": null },
  "errors": [
    {
      "message": "The metric 'nonexistent_metric' is not a valid metric.",
      "locations": [{ "line": 2, "column": 3 }]
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
| Time range restricted       | Historical range exceeds plan allowance                             | Check `getAccessRestrictions`                                                                                                                                                                       |
| Complexity too high         | Query requests too many data points                                 | Reduce time range, increase interval, or fetch fewer fields                                                                                                                                         |
| HTTP 429                    | Rate limit exceeded                                                 | Back off exponentially and retry after a delay                                                                                                                                                      |
| Empty timeseries (no error) | On-chain metric not computed at all or not computed for this period | Check `availableSince` to see if the metric/slug combo is computed, or check if the metric is in the list `projectBySlug(slug: "<slug>") { availableMetrics }`. See `references/metrics-catalog.md` |

## Quick Reference: Building a Query

Follow these steps to construct any Santiment API query:

1. **Pick a metric** — use directly if known, otherwise follow Discovery Workflow.
2. **Pick a slug** — resolve names/tickers via `projectBySlug` or `allProjects`.
3. **Pick a time range** — relative expressions preferred. Check `availableSince` first.
4. **Pick an interval** — `"1d"`, `"1h"`, `"7d"`. Larger intervals reduce complexity.
5. **Pick a sub-field** — `timeseriesDataJson` for series, `aggregatedTimeseriesData` for single value, `timeseriesDataPerSlugJson` for multi-asset.
6. **Optionally add** — `transform`, `selector` (instead of `slug`), or `aggregation` override.
7. **If data is empty** — check `availableSince` for epoch. If epoch, the metric isn't computed for this slug's chain. Report unavailability and suggest alternative metrics.

Execute via curl with the user's API key and parse the JSON response. Always check for the `errors` array before processing `data`.

## Additional Resources

Consult these reference files for detailed information:

- **Metrics catalog** — `references/metrics-catalog.md` — keyword-to-metric mapping for translating user intent into search terms, plus 20 curated quick-reference metrics and naming conventions
- **Rate limits** — `references/rate-limits.md` — tier limits, complexity scoring, and optimization strategies to avoid quota exhaustion
- **Query patterns** — `examples/query-patterns.md` — 6 worked examples with both GraphQL and curl, including discovery workflow and ghost data diagnostics

Official docs: [Getting started for developers](https://academy.santiment.net/for-developers).
