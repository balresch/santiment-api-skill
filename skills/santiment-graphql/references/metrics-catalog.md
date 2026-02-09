# Santiment Metrics Catalog

A curated subset of commonly used metrics organized by category. For the full list of 750+ metrics, query `getAvailableMetrics`.

## Financial / Price

| Metric | Description |
|---|---|
| `price_usd` | Price in USD |
| `price_btc` | Price in BTC |
| `volume_usd` | Trading volume in USD |
| `marketcap_usd` | Market capitalization in USD |

## On-Chain Activity

| Metric | Description |
|---|---|
| `daily_active_addresses` | Unique addresses active per day |
| `transaction_volume` | Total value transferred on-chain |
| `network_growth` | New addresses created per day |
| `velocity` | Transaction volume / token supply |
| `token_circulation` | Tokens that changed addresses |
| `token_age_consumed` | Destruction of token-days (signals long-held coins moving) |

## Exchange Flows

| Metric | Description |
|---|---|
| `exchange_balance` | Total token balance held on known exchanges |
| `exchange_inflow` | Tokens deposited to exchanges |
| `exchange_outflow` | Tokens withdrawn from exchanges |

## Valuation Ratios

| Metric | Description |
|---|---|
| `mvrv_usd` | Market Value to Realized Value — signals over/undervaluation |
| `nvt` | Network Value to Transactions ratio |

## Social

| Metric | Description |
|---|---|
| `social_volume_total` | Total mentions across social channels |
| `social_dominance_total` | Relative share of social mentions vs all assets |

## Development

| Metric | Description |
|---|---|
| `dev_activity` | Development activity (filtered GitHub events) |
| `dev_activity_contributors_count` | Number of active contributors |

## Supply / Holders

| Metric | Description |
|---|---|
| `amount_in_top_holders` | Amount held by top N holders (use `holdersCount` in selector) |
| `percent_of_total_supply_on_exchanges` | Share of supply sitting on exchanges |
