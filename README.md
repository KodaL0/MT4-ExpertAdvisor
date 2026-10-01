# XAU Pro EA for MetaTrader 4

A configurable MetaTrader 4 Expert Advisor for XAUUSD, with trend and sniper entry modes, ATR-based risk controls, session filters, and trade-management rules.

## What it does

- Supports Trend Pro and Sniper trading modes.
- Uses configurable EMA, ATR, higher-timeframe bias, spread, session, volatility, and regime filters.
- Provides risk-percent or fixed-lot sizing, position limits, daily trade/loss guards, and cooldowns.
- Includes break-even, partial-close, and ATR trailing-management options.
- Displays an on-chart status panel and writes CSV trade-journal data.

## Project layout

- `Experts/XAU_Pro_EA.mq4`: primary Expert Advisor.
- `Include/XAUPro/`: modular configuration, signal, risk, execution, daily-guard, and journal components.
- `Presets/`: Trend and Sniper `.set` profiles.

## Installation

1. Open the MetaTrader 4 data folder.
2. Copy the primary EA and the `Include/XAUPro` dependency tree into the matching MT4 folders.
3. Compile `Experts/XAU_Pro_EA.mq4` in MetaEditor.
4. Attach the EA to the intended XAUUSD chart and timeframe.
5. Load a preset if desired, then review all broker-specific settings before use.

## Configuration and testing

Broker symbol naming, server time, point values, spreads, and contract specifications vary. Review every input for the connected broker.

No automated test suite, CI workflow, or documented backtest results are included. Validate the EA in MetaTrader Strategy Tester and on a demo environment before considering any live use.

## Risk disclaimer

This repository contains software, not investment advice. Trading can result in substantial losses. No strategy, backtest, or configuration guarantees performance.
