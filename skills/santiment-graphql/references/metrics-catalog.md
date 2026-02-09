# Santiment Metrics Catalog

For the full list of 750+ metrics, query `getAvailableMetrics`. Use this reference to translate user intent into search keywords, then scan the API's metric list for matches.

## Keyword Map for Metric Discovery

When the user describes data they want, map their intent to search keywords that appear in Santiment metric names. Search the `getAvailableMetrics` result for these keywords to find candidate metrics.

| User Intent | Search Keywords | Example Matches |
|---|---|---|
| Price, valuation | `price`, `marketcap`, `volume` | `price_usd`, `marketcap_usd`, `volume_usd` |
| On-chain activity | `active_addresses`, `transaction`, `network_growth` | `daily_active_addresses`, `transaction_volume` |
| Exchange flows | `exchange`, `inflow`, `outflow`, `balance` | `exchange_inflow`, `exchange_outflow`, `exchange_balance` |
| Holder / whale behavior | `holder`, `top`, `amount_in`, `supply`, `whale` | `amount_in_top_holders`, `holders_distribution_*` |
| MVRV / NVT / ratios | `mvrv`, `nvt`, `realized`, `ratio` | `mvrv_usd`, `mvrv_usd_intraday`, `nvt` |
| Social sentiment | `social`, `sentiment`, `dominance` | `social_volume_total`, `social_dominance_total` |
| Development | `dev_activity`, `contributors`, `github` | `dev_activity`, `dev_activity_contributors_count` |
| Supply distribution | `supply`, `percent`, `circulation`, `dormant` | `percent_of_total_supply_on_exchanges`, `circulation_*` |
| Token age / movement | `age`, `consumed`, `dormant`, `velocity` | `token_age_consumed`, `dormant_circulation_*`, `velocity` |
| Derivatives / funding | `funding`, `open_interest`, `liquidation` | `funding_rate`, `open_interest`, `total_liquidations_*` |
| NFT | `nft` | `nft_*` |
| Labeled flows | `labeled`, `label`, `dex`, `defi`, `cex` | `labeled_exchange_*`, `defi_*` |

## Curated Quick-Reference

Twenty commonly used metrics for the most frequent query types. Use these directly when they match the user's request — no discovery needed.

| Category | Metric | Description |
|---|---|---|
| Financial | `price_usd` | Price in USD |
| Financial | `price_btc` | Price in BTC |
| Financial | `volume_usd` | Trading volume in USD |
| Financial | `marketcap_usd` | Market capitalization in USD |
| On-Chain | `daily_active_addresses` | Unique addresses active per day |
| On-Chain | `transaction_volume` | Total value transferred on-chain |
| On-Chain | `network_growth` | New addresses created per day |
| On-Chain | `velocity` | Transaction volume / token supply |
| On-Chain | `token_circulation` | Tokens that changed addresses |
| On-Chain | `token_age_consumed` | Destruction of token-days (signals long-held coins moving) |
| Exchange | `exchange_balance` | Total token balance held on known exchanges |
| Exchange | `exchange_inflow` | Tokens deposited to exchanges |
| Exchange | `exchange_outflow` | Tokens withdrawn from exchanges |
| Valuation | `mvrv_usd` | Market Value to Realized Value — signals over/undervaluation |
| Valuation | `nvt` | Network Value to Transactions ratio |
| Social | `social_volume_total` | Total mentions across social channels |
| Social | `social_dominance_total` | Relative share of social mentions vs all assets |
| Development | `dev_activity` | Development activity (filtered GitHub events) |
| Development | `dev_activity_contributors_count` | Number of active contributors |
| Supply | `amount_in_top_holders` | Amount held by top N holders (use `holdersCount` in selector) |
| Supply | `percent_of_total_supply_on_exchanges` | Share of supply sitting on exchanges |

## Naming Conventions

Metric names use `snake_case`. Prefixes indicate category (`exchange_`, `social_`, `dev_`, `holders_`). Suffixes indicate denomination or scope (`_usd`, `_btc`, `_total`). The `_intraday` suffix marks higher-frequency variants of daily metrics (e.g., `mvrv_usd_intraday`). Wildcard patterns like `holders_distribution_*` cover families of related sub-metrics with different selector parameters.
