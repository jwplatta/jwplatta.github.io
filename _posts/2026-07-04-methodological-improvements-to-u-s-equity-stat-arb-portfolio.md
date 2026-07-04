---
layout: post
title: Methodological Improvements to U.S. Equity Stat-Arb Portfolio
date: 2026-07-04 14:00 -0500
tags:
  - quant-finance
  - stat-arb
math: true
categories:
img_path: /assets/img/posts/
toc:
---
## Motivation

The first version of the stat-arb portfolio I'm developing had a couple of significant methodological weaknesses that I wanted to address. First, the historical price data came entirely from `yfinance` and only has today's S&P 500 constituents. So any company that was removed from the index was simply invisible to the backtest. This is a problem for a long-short strategy because the shorts are populated with recent underperformers and those underperformers often include companies that were eventually removed from the index. A backtest that can't see those removals is effectively pretending those shorts kept trading indefinitely at prices that never existed which makes the shorts look better than they really were. Second, the portfolio validation framework relied on in-sample optimization. I was fitting the portfolio to the in-sample same data and then evaluating against that same data. That kind of in-sample validation does little to test whether the portfolio generalizes prior to evaluating it against the out-of-sample dataset. I noted both limitations in the first report, but I've since come back and addressed them directly.

## Methodology Enhancements

### Addressing Survivorship Bias

To fix the data problem, I needed a record of which companies were actually in the S&P 500 on any given day and not just which ones are there now. I sourced a historical membership index from a [community-maintained repository](https://github.com/fja05680/sp500/tree/master) and then went about collecting the daily price history for each historical constituent back to 2015. Interactive Brokers supplied many of these candles. For companies that are now defunct, I often had to pull historical data from investing.com. The result is a dataset that captures most of the index turnover over the past decade, though there are still some gaps for some delisted names.

The more interesting piece was integrating this into the [qstudy](https://github.com/jwplatta/qstudy) research library. The naive approach of feeding a wider ticker list to the backtest did not actually solve the problem because the pipeline still received prices for periods when a ticker wasn't eligible. So what I needed was a per-day eligibility mask to tell the pipeline that on any given date, only the companies that were actually index members should be visible.

The implementation builds a boolean membership mask as a date-by-ticker DataFrame. For a 2015–2023 window this covers roughly 680 unique tickers (more than the ~500 on any single day) because the index turns over about 20–30 names per year. The mask is applied at data load time by converting OHLCV prices and returns to `NaN` for any ticker-date pair that falls outside that ticker's membership window. It uses `NaN` rather than dropping columns entirely because this keeps all the vectorized operations working correctly and allows the pipeline to propagate the eligibility constraint forward naturally. When a stock isn't a member on a given date, its return is `NaN`. Rolling means propagate that `NaN`. Rank functions treat `NaN` as ineligible. The backtest engine zeroes out `NaN` entries when computing PnL. Also, the residualization is handled when fitting OLS betas for the factor-model residuals because non-member dates are excluded automatically via `dropna()`.

### A Walkforward Validation Framework

The second change was to my validation methodology. The original portfolio was built by running signal sweeps on the full historical in-sample period and then selecting the combination of sleeves that maximized in-sample Sharpe subject to correlation constraints. This process identified strategies that are genuinely good, but it doesn't distinguish them from strategies that happen to fit idiosyncrasies in the 2015–2023 period.

So, the new framework introduces a walkforward validation loop with five expanding training windows:
- 2015–2018 → validate 2019
- 2015–2019 → validate 2020
- 2015–2020 → validate 2021
- 2015–2021 → validate 2022
- 2015–2022 → validate 2023

The aim is to justify each portfolio decision on data the portfolio hasn't already seen. For each fold, the training window grows by one year while the validation year stays fixed at the next calendar year out. This mirrors how a portfolio would actually be managed, i.e. you make decisions based on what you know, then the next year happens.

My research process itself becomes iterative:
1. Run broad signal sweeps to generate a candidate pool
2. Rank candidate sleeves by stability across the IS period
3. Use the top-ranked sleeves as seeds for a greedy selection algorithm that builds portfolios fold-by-fold
4. Evaluate the resulting portfolios, identify weaknesses (which years fail and why)
5. Extend the sleeve pool with economically motivated additions to address those weaknesses
6. Repeat until a stable, well-rounded portfolio emerges

The greedy selection algorithm is straightforward. At each step, it tries adding the remaining candidate sleeves to the current portfolio, tests three weighting schemes (equal weight, equal volatility, and equal Sharpe), and picks whichever combination produces the highest net Sharpe subject to acceptance gates. Those gates require that each addition keeps pairwise correlation low across all sleeve pairs, improves Sharpe, and does not regress max drawdown or daily turnover beyond small tolerances. After the fifth sleeve, each addition must show improvement across Sharpe, drawdown, and turnover. In practice, this is what terminates the process.

Both versions of the portfolio are evaluated against an out-of-sample dataset (2024 to mid 2026), but the new version also regresses its returns against SPY. This is important because it separates two questions. First, is the portfolio losing money? Second, is the portfolio's loss driven by market exposure? A strategy that loses 10% in a year when SPY is up 25%, but near zero beta is a very different from one that loses because it has hidden long exposure to an index that fell. The regression results make this difference detectable.

## Portfolio Evolution

### The Original Portfolio's Concentration Problem

The original portfolio relied heavily on multiple variants of distance-pairs mean reversion (DPMR). In fact, four of the sleeves were variations of the same underlying idea with different parameter settings. The diversification was largely parameter diversity rather than economic diversity. When DPMR works, all four sleeves benefit. When it doesn't, they all struggle together.

### The GREEDY-5 Core

I ran the walkforward greedy process across multiple starting sleeves and fold configurations. It consistently converged on a core set of five sleeves that represent mostly distinct economic mechanisms:
- **Distance-Pairs MR** finds each stock's closest historical price-path neighbor, computes how far the two have diverged, and bets on reversion. The key addition in v2 is a regime gate that turns this sleeve fully off when market breadth is below 50% and SPY is in an uptrend.
- **Bear Reversal** is dormant in normal market conditions and activates only when SPY is in a downtrend and fewer than 40% of stocks are above their 200-day moving averages. In those conditions, it bets on short-term overshoots.
- **Cross-Sectional MR** fades the deviation of each stock's short-term return from its annual baseline. It's always active (no regime gate) and relies instead on a volatility scaler that compresses exposure during high volatility periods.
- **Monotonic Momentum** rewards consistency of direction over a full year. Rather than just measuring total return, it scores stocks by how often their daily returns agreed with the sign of their 252-day mean return scaled by that mean's magnitude. A breadth gate turns it off when the broad market is rallying. This keeps it active in the narrower markets where momentum signals tend to work.
- **Sector ETF Momentum** is the only sleeve in the portfolio that uses cross-asset data rather than individual stock prices. It measures each sector ETF's 20-day return relative to SPY and assigns that signal to every stock in that sector. A dispersion gate keeps it active only when sector returns are meaningfully diverging.

This greedy sleeve selection process improved original in-sample optimization because it forced these sleeves to earn their place in different market environments independently. Each sleeve was selected in 4 of 5 folds across multiple starting seed variants.

### Addressing the 2022 Weakness

The 2022 validation year was a problem for the GREEDY-5 core. The portfolio had a Sharpe of 0.11 in the 2022 fold. This year was characterized by a trending bear market and none of the sleeves handled it well except for the Sector ETF. Mean reversion signals can do little in one-directional markets. The narrow-bull gate on the distance-pairs sleeve doesn't fire in a bear market. Sector ETF momentum helps with a Sharpe of 1.80, but it wasn't enough to carry the portfolio.

So two extensions were added to handle this weakness:
- **Gap Accumulation** earns a Sharpe of 2.88 in the 2022 fold. The signal fades accumulated overnight gaps over 3 days and is turned off in uptrends. So during 2022, it activates and captures the gap-fill reversions that occur intraday even as prices trend lower overall. Adding it to the GREEDY-5 core moves the 2022 fold Sharpe from +0.11 to +1.34 while barely affecting the other folds.
- **Residual Z-Score MR** uses factor-residualized returns (a different data input from any other sleeve), rebalances at a 10-day frequency that fills a gap between the other weekly and monthly sleeves, and achieves the highest efficiency ratio of any sleeve in the portfolio. While it adds modest gains to the GREEDY-5 core it provides value primarily by dropping the portfolio's average max drawdown.

## Updated Findings

The new portfolio has similar in-sample results while giving me much more confidence in how those results were obtained. The final portfolio remains market neutral with a beta of just 0.04 and generates statistically significant alpha relative to SPY. The regression results suggest the returns are primarily driven by cross-sectional stock selection rather than directional market exposure. And the walkforward process produces a portfolio whose construction can be justified repeatedly across multiple training and validation windows rather than by a single optimization over the full in-sample period.

However, the out-of-sample results are still mixed. The portfolio struggles during 2024 and 2025 before partially recovering in 2026, and the regression shows that the in-sample alpha basically disappears while beta remains low. In other words, the portfolio isn’t losing because it has hidden market exposure. It's losing at the signal level. One plausible explanation is that the losing sleeves rely on cross-sectional dispersion through mean reversion or sector rotation, but the 2024-2025 period instead was dominated by persistent, narrow-breadth leadership from a handful of mega-cap technology stocks.

Monotonic Momentum is the one sleeve that does well out-of-sample. Unlike the other sleeves, it profits from persistence rather than betting against it and is explicitly gated to activate in narrow-breadth environments. That result lends some support to the idea that the portfolio is exposing a regime gap rather than simply collapsing out-of-sample. At the same time, some amount of in-sample overfitting is likely present. The walkforward methodology reduces that risk, but it can't eliminate it entirely.

## Conclusion

A good next research question is the regime gap. The portfolio could use a sleeve capable of profiting from concentrated leadership rather than betting against it. Some plausible ideas worth exploring include explicitly targeting the mega-cap leaders, within-sector relative strength conditioned on low breadth, and possibly targeting the persistence of factor returns. There's also smaller incremental improvements worth studying. For example, the narrow-bull gate threshold on the distance-pairs sleeve is 50% breadth. Market breadth averaged 52% in 2024 and so the sleeve keeps running in the regime it was designed to avoid. A slightly higher threshold (55%–60%) might provide better protection without changing the in-sample results. Aside from the portfolio, the backtest framework is still relatively simple. It assumes 10 bps flat transaction costs with no slippage or market impact. A more realistic event-driven backtest would model realistic fills and borrowing costs for short positions.

The full report with detailed tables, charts, and sleeve-level attribution is available [here](https://github.com/jwplatta/portfolio-research/tree/main/us-equity-stat-arb).
