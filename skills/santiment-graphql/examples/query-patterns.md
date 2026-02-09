# Santiment GraphQL Query Patterns

Five examples demonstrating distinct API capabilities. Each uses a different sub-field or parameter pattern.

## 1. Timeseries — Daily Bitcoin Price

Uses `timeseriesData` with relative time expressions to fetch a daily price series.

```graphql
{
  getMetric(metric: "price_usd") {
    timeseriesData(
      slug: "bitcoin"
      from: "utc_now-7d"
      to: "utc_now"
      interval: "1d"
    ) {
      datetime
      value
    }
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getMetric(metric: \"price_usd\") { timeseriesData(slug: \"bitcoin\", from: \"utc_now-7d\", to: \"utc_now\", interval: \"1d\") { datetime value } } }"}'
```

## 2. Multi-Asset Comparison — Exchange Inflows

Uses `timeseriesDataPerSlugJson` with a `slugs` selector to fetch one metric for several assets in a single API call.

```graphql
{
  getMetric(metric: "exchange_inflow") {
    timeseriesDataPerSlugJson(
      selector: { slugs: ["bitcoin", "ethereum", "ripple"] }
      from: "utc_now-30d"
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
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getMetric(metric: \"exchange_inflow\") { timeseriesDataPerSlugJson(selector: { slugs: [\"bitcoin\", \"ethereum\", \"ripple\"] }, from: \"utc_now-30d\", to: \"utc_now\", interval: \"1d\") } }"}'
```

## 3. Transform — Ethereum MVRV with 7-Day Moving Average

Uses the `transform` parameter to smooth noisy data with a moving average.

```graphql
{
  getMetric(metric: "mvrv_usd") {
    timeseriesData(
      slug: "ethereum"
      from: "utc_now-6m"
      to: "utc_now"
      interval: "1d"
      transform: { type: "moving_average", movingAverageBase: 7 }
    ) {
      datetime
      value
    }
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getMetric(metric: \"mvrv_usd\") { timeseriesData(slug: \"ethereum\", from: \"utc_now-6m\", to: \"utc_now\", interval: \"1d\", transform: { type: \"moving_average\", movingAverageBase: 7 }) { datetime value } } }"}'
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
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getMetric(metric: \"daily_active_addresses\") { aggregatedTimeseriesData(slug: \"cardano\", from: \"utc_now-30d\", to: \"utc_now\", aggregation: AVG) } }"}'
```

## 5. Discovery Workflow — Finding and Querying an Unknown Metric

Demonstrates the full discovery flow when the user asks for data and you don't know the exact metric name. Scenario: "How much ETH do the top 100 holders own?"

**Step 1 — Fetch all metrics and search by keyword.**

The response is large (1,000+ metrics), so save it to a file:

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
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

```graphql
{
  getMetric(metric: "amount_in_top_holders") {
    timeseriesData(
      selector: { slug: "ethereum", holdersCount: 100 }
      from: "utc_now-30d"
      to: "utc_now"
      interval: "1d"
    ) {
      datetime
      value
    }
  }
}
```

**curl:**

```bash
curl -s -X POST https://api.santiment.net/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey <YOUR_API_KEY>" \
  -d '{"query": "{ getMetric(metric: \"amount_in_top_holders\") { timeseriesData(selector: { slug: \"ethereum\", holdersCount: 100 }, from: \"utc_now-30d\", to: \"utc_now\", interval: \"1d\") { datetime value } } }"}'
```

This example demonstrates the full discovery flow: search the metric list by keywords, inspect metadata to learn required selectors, then construct the query with the correct parameters. The `holdersCount` selector would not have been obvious without the metadata step.
