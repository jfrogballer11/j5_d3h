# Kalshi 15m Confluence (TradingView indicator)

A single indicator that runs all of the checks together on a **1-minute** BTC/ETH chart
and gives one answer for the current 15-minute Kalshi contract.

| # | Check | Based on | Default |
|---|-------|----------|---------|
| 1 | 15m trend (last closed 15m bar vs McGinley channel) | SSL Hybrid baseline | McGinley 50, channel 0.2 |
| 2 | 1m SSL direction agrees with the trend | SSL Hybrid | HMA 30 |
| 3 | Pattern forecast to expiry: % of best historical matches ending above the strike | Next Pivot idea | Pearson, % change, length 30, 2000 bars, top 15 |
| 4 | Volume rising (PVO > 0 and above its signal) | PVO | 6 / 13 / 5 |
| 5 | Still early in the contract | - | first 8 minutes |

The forecast length is set automatically to the **bars left until the contract expires**.

## Checklist table (top right)
- **Time left / Strike**: strike defaults to the price at the start of the 15-minute window.
  Type Kalshi's strike into the settings if your contract uses a different one.
- **VERDICT**: `BUY YES / ABOVE`, `BUY NO / BELOW` or `NO TRADE`. All five checks must agree.
- **Kalshi price**: the most you should pay. This is the share of matches that agree, minus a safety margin.
  It's a rough estimate, not a real probability.

On the chart:
- Blue/red step line + grey band = 15m baseline and chop zone
- Thin line = 1m SSL
- Yellow = strike
- Dashed line = projected path to expiry
- Small triangles = past setups (checks 1, 2, 4, 5 only; the forecast is computed on the live bar)

## Install
The TradingView phone app can't edit Pine scripts, so do this once in a browser at tradingview.com:
1. Open a chart, then open **Pine Editor** at the bottom.
2. Delete what's there, then paste in the contents of `kalshi_15m_confluence.pine`.
3. Click **Save**, then **Add to chart**.
4. In the phone app: **Indicators → Personal / My scripts → Kalshi 15m Confluence**.

Use it on **COINBASE:BTCUSD** (or ETHUSD) on the **1-minute** chart.

Alerts: **Create alert → Condition: Kalshi 15m Confluence → "Any alert() function call"**.

## Honest caveats
- Short-term crypto direction is close to random. Paper trade at least 50 contracts first.
- The forecast is a pattern match, not a prediction.
