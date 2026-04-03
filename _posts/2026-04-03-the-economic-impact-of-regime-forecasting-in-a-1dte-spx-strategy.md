---
layout: post
title: The Economic Impact of Regime Forecasting in a 1DTE SPX Strategy
date: 2026-04-03 16:05 -0500
tags:
  - spx
  - 1dte-trade
categories:
  - writing-to-learn
  - options-trading
img_path: /assets/img/posts/
toc: true
---
## Motivation

In this post, I evaluate the economic impact of a regime forecasting model on a 1DTE SPX iron condor strategy.

As a brief recap, I’ve been working toward automating a short volatility carry strategy that I have traded manually for over a year. The initial step was to construct a simple baseline backtest for a 1DTE iron condor. That baseline performed poorly, but it revealed a clear pattern: losses are concentrated on days where the intraday range expands beyond a certain threshold.

In the previous post, I showed that these high-range regimes are at least partially predictable using simple features such as recent realized volatility and term structure signals from VIX and VIX9D. The natural next question is whether those forecasts have any economic value. Specifically, can we improve the performance of the strategy by avoiding trades on days that are predicted to be high range?

## Experimental Setup

Rather than running a new backtest, I apply the regime model as a filter on the existing set of trades. The goal is to isolate the incremental value of the forecast without introducing additional complexity.

The model is a logistic regression classifier trained to predict whether the next trading day’s SPX range exceeds a fixed threshold (51.698). The feature set includes:
- Prior day VIX–VIX9D slope
- 5-day average SPX range
- Prior day absolute return
- Overnight gap magnitude

Days predicted to be in a high-range regime are excluded from the trade set. Performance is then recomputed on the remaining trades.

To reduce lookahead bias, the model is trained on data from April 2022 through December 2023 and evaluated on trades from January 2024 through December 2025. The range threshold itself is determined from the full sample, which introduces some residual bias, but the primary results are out-of-sample with respect to the model.
## Results

Filtering trades using the regime model improves performance across all metrics.

The equity curve becomes noticeably more stable, and the filtered strategy avoids the largest drawdown observed in the baseline, particularly during the sharp volatility expansion in April 2025. Drawdowns are both shallower and shorter in duration. The Sharpe ratio also improves materially even though it remains negative.

![Equity and Drawdown SPX Regime Filter](equity_drawdown_spx_regime_filter.png)

From a classification standpoint, the regime model exhibits meaningful predictive power. Accuracy is approximately 71%, with balanced performance across low and high-range regimes. So the model clearly captures non-random structure in the data even if it's imperfect.

|            | Precision | Recall | F1-Scores |
| ---------- | --------- | ------ | --------- |
| low range  | 0.74      | 0.72   | 0.73      |
| high range | 0.66      | 0.69   | 0.68      |
| accuracy   |           |        | 0.71      |

![SPX Regime Confusion Matrix](spx_regime_cm.png)

However, the most important insight comes from examining performance conditional on predicted probability.

The model successfully identifies clearly adverse regimes (high-probability buckets), which are removed by the filter. However, losses remain in the lowest probability bucket, which is supposed to represent the safest trades. As a result, the strategy remains unprofitable despite the improvement in aggregate metrics.

| Probability Bucket | Trade Count | Expectancy |
| ------------------ | ----------- | ---------- |
| 0.0-0.2            | 100         | -14.35     |
| 0.2-0.4            | 125         | 1.32       |
| 0.4-0.6            | 59          | -41.73     |
| 0.6-0.8            | 52          | -40.79     |
| 0.8-1.0            | 52          | 138.67     |

## Analysis

The results are mixed but informative. 

On one hand, the range regime model is directionally useful. It reduces exposure to high range days and improves the overall distribution of returns. This result is consistent with the earlier finding that high range regimes drive a disproportionate amount of the strategy's risk. On the other hand, the model fails to address the most important component of the problem: tail risk.

The probability bucket analysis makes this clear. While the model removes many trades in obviously hostile regimes (probability buckets 0.4 to 1.0), it still allows a subset of damaging trades to pass through, viz. those in the lowest probability bucket (0.0 to 0.2). These trades dominate the left tail of the PnL distribution and ultimately determine the strategy’s performance.

There are two structural reasons for this.

First, the dataset is relatively small. With only a few hundred observations, the model is unlikely to learn the full range of conditions that lead to extreme outcomes. In effect, the model has limited ability to estimate the behavior of rare events that cause high range days which are precisely the events that matter most for this strategy.

Second, and perhaps more important, the strategy itself is highly path dependent. A 1DTE iron condor is effectively short convexity (or short gamma). So its losses are driven not just by the magnitude of the move, but by the intraday price path of the underlying SPX. Two days with similar ranges can produce very different outcomes depending on how price evolves throughout the day. So, the failure of the strategy is driven by a small number of tail events that aren't captured by the regime level features.

This path dependence makes tail events inherently difficult to anticipate and manage using a simple regime model. The model successfully captures broad volatility conditions, but it doesn't capture the specific sequences of price movements that trigger large losses. In practice, many of these events are driven by shocks or regime transitions that aren't well represented in the feature set for the model.

In short, the model improves exposure to regimes, but it's too coarse to reliably eliminate the tail events that dominate the strategy’s risk and would make the strategy profitable. 
## Conclusion

The high range regime forecast model has clear economic value. Conditioning trades on predicted range reduces drawdowns and improves overall performance. Yet it's insufficient to make a 1DTE short volatility strategy viable on its own.

The core issue is structural. The convexity and path dependence of 1DTE options make the strategy highly sensitive to intraday dynamics and tail events which are difficult to model and anticipate with limited data. In effect, even a reasonably accurate model can't totally eliminate the trades that ultimately drive negative expectancy of the strategy as its currently defined.

These result have led me to consider an alternative approach. Rather than continuing to refine a predictive model, I'll focus more on trade structures that are more controllable. For example, longer dated options, such as 7DTE trades, have lower convexity and are less sensitive to intraday path. Their outcomes depend on multi-day dynamics and should be easier to reason about and manage systematically.

The next step is to decompose the mechanics of the 7DTE trade that have worked for me and evaluate simple, rule-based adjustments. For example, rules such as recentering the position when a delta threshold is breached can be tested directly to determine whether they improve, degrade, or have no effect on outcomes. Ultimately, a longer term goal might be to build a framework that combines these mechanics with simple regime filters and eventually a higher level strategy manager that determines when to deploy different structures and rules.