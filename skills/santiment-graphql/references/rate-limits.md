# Santiment API Rate Limits

## Tier Limits

| Tier | Monthly calls | Per hour | Per minute |
|---|---|---|---|
| Free | 1,000 | 500 | 100 |
| Sanbase Pro | 5,000 | 1,000 | 100 |
| Sanbase Max | 80,000 | 4,000 | 100 |
| Business Pro/Max | Higher (custom) | Higher | Higher |

## Key Rules

- Rate limits are **per account** — all API keys on one account share limits.
- Each GraphQL **query** inside a request counts as one API call (a single HTTP request can contain multiple queries).
- HTTP **429** = rate limited. Back off and retry.
- **Free tier**: 1 year of historical data, 30-day lag on real-time data.

## Plan Time Restrictions

Separate from call quotas, plans restrict **which time window** you may read per metric. Paid tiers still carry a realtime lag on many metrics — the data is computed upstream, but your plan cannot read the most recent stretch of it.

Observed on a Sanbase PRO account: `mvrv_usd`, `exchange_inflow`, `exchange_balance`, `social_volume_total`, and `network_growth` were all capped ~30 days behind the present, while `price_usd`, `daily_active_addresses`, and `dev_activity` had no lag. The affected set varies by plan and changes over time — determine it empirically, do not memorize this list.

### The restriction is usually silent

The key rule: **the API errors only when the entire requested window falls outside your allowance.** The error text itself says so — "Both `from` and `to` parameters are outside the allowed interval". A window that merely *overlaps* the boundary is silently clipped instead.

| Situation | Behaviour |
|---|---|
| Window entirely outside allowance | Hard error in `errors[]`, naming the exact allowed `from`/`to` |
| Window partly overlapping, `timeseriesDataJson` | **Silently truncated** — a short or empty list, no error |
| Window partly overlapping, `aggregatedTimeseriesData` | **Silently clipped** — returns a stale value, no error |
| `aggregatedTimeseriesData` inside `allProjects` | **Silently returns `null`**, no error |

The silent cases are the dangerous ones, and the most common query shape walks straight into them. On a metric lagged ~30 days, `from: "utc_now-30d", to: "utc_now"` straddles the boundary exactly, so it never errors. Asked for a series you get a nearly empty list that looks like ghost data; asked for an aggregate you get a well-formed number that is roughly a month stale, with nothing in the response to signal it. Reporting that as the current value is a factual error the response gives you no way to notice.

A useful diagnostic trick: if a query returns suspiciously little data, **re-run it against a strictly recent window** (e.g. `from: "utc_now-2d", to: "utc_now"`). That pushes the window entirely outside the allowance and converts the silence into the explicit error, which tells you the real bounds.

### Detecting it

Compare the metric's true freshness against the window your data could have come from:

```graphql
{
  getMetric(metric: "mvrv_usd") {
    lastDatetimeComputedAt(slug: "bitcoin")
  }
}
```

If `lastDatetimeComputedAt` is much newer than the data you received, you were served clipped data. Note the contrast with ghost data: there, `availableSince` returns the Unix epoch because the metric was **never computed**. Here the metric is computed and current — your plan simply cannot read the recent part. The two look nothing alike once you check the timestamps, and the remedies differ.

### `getAccessRestrictions` is not reliable for this

The natural diagnostic does not work. On the PRO account above, `getAccessRestrictions(product: SANBASE, plan: PRO, filter: METRIC)` reported `isRestricted: false` for `exchange_inflow` — a metric the API rejected moments later on time-range grounds. The `product` and `plan` arguments must also match the account's actual subscription (a Sanbase subscription is `product: SANBASE`, not `SANAPI`), and a mismatch silently returns another plan's restrictions rather than an error.

**The restriction error message is authoritative.** It carries the exact bounds:

```
Both `from` and `to` parameters are outside the allowed interval you can query
exchange_inflow with your current subscription SANBASE PRO.

Allowed time restrictions:
  - `from` - 2025-09-07 11:59:31.016012Z
  - `to`   - 2026-08-08 11:59:31.016012Z
```

Parse `from` and `to` out of the message and retry inside them.

### Handling it

1. On a restriction error, read the allowed bounds from the message and retry within them.
2. Tell the user the window was narrowed and why — do not silently return older data as though it were current.
3. Never label an aggregate "current", "today's", or "latest" unless you have confirmed freshness with `lastDatetimeComputedAt`.
4. Treat a `null` column in an `allProjects` matrix as "unknown, probably restricted" — re-query that metric alone to surface the error.

## Complexity Scoring

Every request is scored for complexity (~50,000 max). Complexity grows with the number of data points returned:

- **Wider time range + smaller interval = more data points = higher complexity.**
- If complexity is exceeded, the request is rejected before execution.
- The error message will indicate the complexity limit was exceeded.

## Optimization Strategies

Use these strategies to minimize API calls and stay within limits:

1. **Use `aggregatedTimeseriesData`** when you only need a summary number — returns a single value instead of a full series.
2. **Use `timeseriesDataPerSlugJson`** with `slugs` to batch multiple assets into one call instead of making separate calls per asset.
3. **Prefer larger `interval` values** (e.g., `"1d"` over `"1h"`) when high granularity isn't needed.
4. **Narrow the time range** — only fetch the period you actually need.
5. **Cache responses** — avoid re-fetching data that hasn't changed.
6. **Check `availableSince`** before querying — avoids wasting calls on time ranges with no data.
