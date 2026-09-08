# Santiment GraphQL Query Patterns

Eight examples demonstrating distinct API capabilities. Each uses a different sub-field or parameter pattern. All curl commands use GraphQL variables with a heredoc to avoid quote-escaping issues.

Several examples end their time window at `utc_now-31d` rather than `utc_now`. That is deliberate — many metrics carry a realtime lag on most plans. See `references/rate-limits.md`.

## 1. Timeseries — Daily Bitcoin Price

Uses `timeseriesDataJson` with relative time expressions to fetch a daily price series. No field selection — the API returns a JSON list of maps.

```graphql
{
  getMetric(metric: "price_usd") {
    timeseriesDataJson(
      slug: "bitcoin"
      from: "utc_now-7d"
      to: "utc_now"
      interval: "1d"
    )
  }
}
```

**curl:**

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

## 2. Multi-Asset Comparison — Exchange Inflows

Uses `timeseriesDataPerSlugJson` with a `slugs` selector to fetch one metric for several assets in a single API call.

Note the time window: `exchange_inflow` is commonly lagged ~30 days on paid plans, so this example ends at `utc_now-31d` rather than `utc_now`. Ending at `utc_now` returns a restriction error on such plans. See `references/rate-limits.md`.

```graphql
{
  getMetric(metric: "exchange_inflow") {
    timeseriesDataPerSlugJson(
      selector: { slugs: ["bitcoin", "ethereum", "ripple"] }
      from: "utc_now-61d"
      to: "utc_now-31d"
      interval: "1d"
    )
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "query($metric: String!, $selector: MetricTargetSelectorInputObject, $from: DateTime!, $to: DateTime!, $interval: interval) { getMetric(metric: $metric) { timeseriesDataPerSlugJson(selector: $selector, from: $from, to: $to, interval: $interval) } }",
  "variables": {
    "metric": "exchange_inflow",
    "selector": { "slugs": ["bitcoin", "ethereum", "ripple"] },
    "from": "utc_now-61d",
    "to": "utc_now-31d",
    "interval": "1d"
  }
}
QUERY
```

## 3. Transform — Ethereum MVRV with 7-Day Moving Average

Uses the `transform` parameter to smooth noisy data with a moving average.

Two things to note in the time window. `mvrv_usd` is another commonly lagged metric, so it ends at `utc_now-31d`. And the ~6-month span is written `utc_now-26w`, not `utc_now-6m` — `m` means **minutes** in this API, and there is no month unit.

```graphql
{
  getMetric(metric: "mvrv_usd") {
    timeseriesDataJson(
      slug: "ethereum"
      from: "utc_now-30w"
      to: "utc_now-31d"
      interval: "1d"
      transform: { type: "moving_average", movingAverageBase: 7 }
    )
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "query($metric: String!, $slug: String, $from: DateTime!, $to: DateTime!, $interval: interval, $transform: TimeseriesMetricTransformInputObject) { getMetric(metric: $metric) { timeseriesDataJson(slug: $slug, from: $from, to: $to, interval: $interval, transform: $transform) } }",
  "variables": {
    "metric": "mvrv_usd",
    "slug": "ethereum",
    "from": "utc_now-30w",
    "to": "utc_now-31d",
    "interval": "1d",
    "transform": { "type": "moving_average", "movingAverageBase": 7 }
  }
}
QUERY
```

## 4. Aggregated Value — Average Daily Active Addresses

Uses `aggregatedTimeseriesData` to return a single summary number instead of a time series.

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    aggregatedTimeseriesData(
      slug: "cardano"
      from: "utc_now-30d"
      to: "utc_now"
      aggregation: AVG
    )
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "query($metric: String!, $slug: String, $from: DateTime!, $to: DateTime!, $aggregation: Aggregation) { getMetric(metric: $metric) { aggregatedTimeseriesData(slug: $slug, from: $from, to: $to, aggregation: $aggregation) } }",
  "variables": {
    "metric": "daily_active_addresses",
    "slug": "cardano",
    "from": "utc_now-30d",
    "to": "utc_now",
    "aggregation": "AVG"
  }
}
QUERY
```

## 5. Discovery Workflow — Finding and Querying an Unknown Metric

Demonstrates the full discovery flow when the user asks for data and you don't know the exact metric name. Scenario: "How much ETH do the top 100 holders own?"

**Step 1 — Fetch all metrics and search by keyword.**

The response is large (1,100+ metrics), so save it to a file with `-o` and read it directly (e.g., `open()` in Python). Do not pipe the contents through stdin at any stage — neither from curl nor when processing the file afterward:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d '{"query": "{ getAvailableMetrics }"}' \
  -o /tmp/santiment-metrics.json
```

Then search the file for keywords matching the user's intent: `holder`, `top`, `amount`. Matches include `amount_in_top_holders`, `holders_distribution_combined_balance`, and others.

**Step 2 — Inspect metadata for the best candidate.**

```graphql
{
  getMetric(metric: "amount_in_top_holders") {
    metadata {
      availableSlugs
      availableSelectors
      defaultAggregation
      minInterval
      dataType
    }
  }
}
```

The metadata reveals this metric supports `slug: "ethereum"` and requires a `holdersCount` field in the selector. The minimum interval is `1d`.

**Step 3 — Query with the correct parameters.**

`amount_in_top_holders` is also lagged on most plans, so the window ends at `utc_now-31d`. Ending at `utc_now` here does **not** error — it straddles the boundary and silently returns an empty list, which is easy to misread as ghost data. See `references/rate-limits.md`.

```graphql
{
  getMetric(metric: "amount_in_top_holders") {
    timeseriesDataJson(
      selector: { slug: "ethereum", holdersCount: 100 }
      from: "utc_now-61d"
      to: "utc_now-31d"
      interval: "1d"
    )
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "query($metric: String!, $selector: MetricTargetSelectorInputObject, $from: DateTime!, $to: DateTime!, $interval: interval) { getMetric(metric: $metric) { timeseriesDataJson(selector: $selector, from: $from, to: $to, interval: $interval) } }",
  "variables": {
    "metric": "amount_in_top_holders",
    "selector": { "slug": "ethereum", "holdersCount": 100 },
    "from": "utc_now-61d",
    "to": "utc_now-31d",
    "interval": "1d"
  }
}
QUERY
```

This example demonstrates the full discovery flow: search the metric list by keywords, inspect metadata to learn required selectors, then construct the query with the correct parameters. The `holdersCount` selector would not have been obvious without the metadata step.

## 6. Ghost Data Detection — Diagnosing Empty On-Chain Results

Demonstrates the reactive diagnostic flow when an on-chain metric returns empty data for a token on a non-indexed chain. Scenario: "Show me daily active addresses for Trust Wallet Token (TWT)."

**Step 1 — Normal query returns empty `[]`.**

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    timeseriesDataJson(
      slug: "trust-wallet-token"
      from: "utc_now-30d"
      to: "utc_now"
      interval: "1d"
    )
  }
}
```

Response: `{ "data": { "getMetric": { "timeseriesDataJson": [] } } }` — no error, just empty data.

**Step 2 — Check `availableSince` and identify the token's chain.**

Combine the diagnostic checks into a single API call:

```graphql
{
  getMetric(metric: "daily_active_addresses") {
    availableSince(slug: "trust-wallet-token")
    lastDatetimeComputedAt(slug: "trust-wallet-token")
  }
  projectBySlug(slug: "trust-wallet-token") {
    name
    ticker
    infrastructure
  }
}
```

Response reveals:
- `availableSince`: `"1970-01-01T00:00:00Z"` — **epoch = never computed**
- `infrastructure`: `"BEP20"` — TWT lives on BNB Chain, not indexed for on-chain metrics

**curl (combined diagnostic):**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "{ getMetric(metric: \"daily_active_addresses\") { availableSince(slug: \"trust-wallet-token\") lastDatetimeComputedAt(slug: \"trust-wallet-token\") } projectBySlug(slug: \"trust-wallet-token\") { name ticker infrastructure } }"
}
QUERY
```

**Step 3 — Pivot to a chain-agnostic metric.**

```graphql
{
  getMetric(metric: "price_usd") {
    availableSince(slug: "trust-wallet-token")
    timeseriesDataJson(
      slug: "trust-wallet-token"
      from: "utc_now-7d"
      to: "utc_now"
      interval: "1d"
    )
  }
}
```

`availableSince` returns a real date (not epoch), and `timeseriesDataJson` returns actual price data — confirming the token has financial data even though on-chain metrics are unavailable.

**Example user-facing response:**

> Daily active addresses is not available for Trust Wallet Token (TWT) because Santiment does not index on-chain data for BEP-20 tokens. However, I can provide price, trading volume, social, and development metrics. Here's the TWT price for the last 7 days: [data]

This example demonstrates the ghost data diagnostic flow: detect empty results, confirm via `availableSince` epoch check, identify the chain, and pivot to available metrics. See `references/metrics-catalog.md` Ghost Data section for the full decision tree.

## 7. Projects × Metrics Matrix — Screening Many Assets at Once

Uses `allProjects` with aliased `aggregatedTimeseriesData` fields to return a projects×metrics table in a single query. Much faster than looping `getMetric` per asset when ranking or screening.

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
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d @- << 'QUERY'
{
  "query": "{ allProjects(page: 1, pageSize: 100) { slug name ticker last_price_usd: aggregatedTimeseriesData(metric: \"price_usd\", from: \"utc_now-1d\", to: \"utc_now\", aggregation: LAST) avg_daa_30d: aggregatedTimeseriesData(metric: \"daily_active_addresses\", from: \"utc_now-30d\", to: \"utc_now\", aggregation: AVG) } }"
}
QUERY
```

Notes:

- Use aliases for metric columns; start with a small `pageSize` (50–100) and paginate.
- If complexity errors, reduce `pageSize`, narrow time windows, or request fewer metrics.
- Prefer for screening and ranking; use `getMetric { timeseriesDataJson }` for drill-down charts.
- **A `null` column is not "no data".** Restricted metrics return `null` here with no error at all. Re-query that metric on its own to surface the reason — see example 8.

## 8. Plan Restriction — Diagnosing Silently Stale Aggregates

Demonstrates the failure mode where the API returns a plausible number that is roughly a month out of date, with nothing in the response indicating a problem. Scenario: "What's Bitcoin's current MVRV?"

**Step 1 — The obvious query returns a clean-looking answer.**

```graphql
{
  getMetric(metric: "mvrv_usd") {
    aggregatedTimeseriesData(
      slug: "bitcoin"
      from: "utc_now-30d"
      to: "utc_now"
      aggregation: LAST
    )
  }
}
```

Response: `{ "data": { "getMetric": { "aggregatedTimeseriesData": 1.258348453254 } } }` — no `errors` array, no `null`, no warning.

On a lagged plan this is **not** the latest MVRV. The request was silently clipped to the allowed window, so `LAST` is the value at the restriction boundary, ~30 days ago.

**Step 2 — Check the metric's true freshness.**

```graphql
{
  getMetric(metric: "mvrv_usd") {
    availableSince(slug: "bitcoin")
    lastDatetimeComputedAt(slug: "bitcoin")
  }
}
```

If `lastDatetimeComputedAt` is today but your value came from a 30-day-old window, the data exists and is current — your plan just cannot read the recent part. Note this is the opposite of ghost data, where `availableSince` returns the Unix epoch because the metric was never computed at all.

**Step 3 — Confirm the exact boundary by forcing the error.**

`timeseriesDataJson` fails loudly where the aggregate failed silently, and the error states the real bounds:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SANTIMENT_API_KEY" \
  -d '{"query": "{ getMetric(metric: \"mvrv_usd\") { timeseriesDataJson(slug: \"bitcoin\", from: \"utc_now-2d\", to: \"utc_now\", interval: \"1d\") } }"}'
```

```
Both `from` and `to` parameters are outside the allowed interval you can query
mvrv_usd with your current subscription SANBASE PRO.

Allowed time restrictions:
  - `from` - 2025-09-07 11:59:31.016012Z
  - `to`   - 2026-08-08 11:59:31.016012Z
```

**Step 4 — Re-query inside the allowed window and report honestly.**

```graphql
{
  getMetric(metric: "mvrv_usd") {
    timeseriesDataJson(
      slug: "bitcoin"
      from: "utc_now-35d"
      to: "utc_now-31d"
      interval: "1d"
    )
  }
}
```

**Example user-facing response:**

> Bitcoin's MVRV was 1.26 as of 2026-08-08. That's the most recent value your API plan can access — `mvrv_usd` carries roughly a 30-day realtime lag on this subscription, so I can't give you today's figure. Santiment has computed it (as of today), it's just gated behind a higher tier.

The lesson: on a lagged metric, an aggregate ending at `utc_now` yields a stale number with no error. Verify freshness with `lastDatetimeComputedAt` before describing any value as current.
