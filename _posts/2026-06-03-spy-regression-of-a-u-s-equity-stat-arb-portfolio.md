---
layout: post
title: SPY Regression of a U.S. Equity Stat-Arb Portfolio
date: 2026-06-03 12:43 -0500
tags:
  - quant-finance
  - stat-arb
math: true
categories:
img_path: /assets/img/posts/
toc:
---
I recently designed and implemented a multi-sleeve statistical arbitrage portfolio for large-cap U.S. equities. The portfolio combines mean reversion, momentum, distance-relative pairs, and event-driven signals into a dollar-neutral long-short framework. The final portfolio consists of eight sleeves with relatively low correlations and achieves an in-sample net Sharpe ratio above 2.0 after transaction costs during the 2015-2023 development period. Although performance weakens during the 2024-2026 evaluation period, the portfolio remains profitable and preserves much of its diversification structure.

One question my original analysis did not answer is whether the portfolio returns are actually alpha or a form of disguised market exposure. To investigate this, I regressed the daily portfolio returns against SPY using a simple OLS model,

$$
R_{port} = \alpha + \beta R_{SPY} + \epsilon
$$

Given the portfolio’s construction, I would expect low market exposure and a low R^2. A statistical arbitrage portfolio that derives its returns from security selection should exhibit a small beta, little explanatory power from the benchmark, and positive alpha. Conversely, if the portfolio’s returns are largely driven by market direction, beta and R^2 should be substantially higher.

The below table shows the regression results for each calendar year and the aggregate in-sample (2015-2023), out-of-sample (2024-2026), and full-period results.

| Period    | Label | Ann Ret | Ann Vol | Sharpe | SPY Ret | Alpha (ann) |  CI lo | CI hi | t(alpha) | p(alpha) |   Beta | t(beta) | p(beta) |     R2 |  Skew | Kurt |    N |
| --------- | ----- | ------: | ------: | -----: | ------: | ----------: | -----: | ----: | -------: | -------: | -----: | ------: | ------: | -----: | ----: | ---: | ---: |
| 2015–2023 | IS    |   19.2% |    8.4% |   2.29 |   11.8% |       17.5% |  11.2% | 23.9% |     5.42 |      0.0 | 0.0334 |    0.86 |   0.391 | 0.0052 |  1.41 | 11.0 | 2264 |
| 2024–2026 | OOS   |    5.8% |   12.3% |  0.472 |   20.5% |       -2.3% | -13.1% |  8.4% |    -0.42 |   0.6725 | 0.4377 |    3.35 |  0.0008 | 0.3252 |   5.0 | 86.1 |  583 |
| 2015–2026 | ALL   |   15.4% |    9.3% |  1.665 |   13.5% |       13.2% |   7.5% | 18.9% |     4.54 |      0.0 | 0.1093 |    2.01 |   0.044 | 0.0434 |  3.16 | 59.8 | 2847 |

The in-sample results are positive. During the 2015-2023 period, the portfolio generated approximately 17.5% annualized alpha with a t-statistic of 5.42 and a p-value effectively equal to zero. At the same time, beta was only 0.0334 and indistinguishable from zero while SPY explained less than 1% of the variation in portfolio returns ($R^2 = 0.52\%$). These results are consistent with the portfolio’s performance during this period was driven primarily by security selection and portfolio construction rather than systematic market risk. Beta remained close to zero throughout most of the period and the strongest contributions came from 2016, 2020, and 2022.

On the other hand, the out-of-sample results aren't as positive. Annualized alpha falls to roughly -2.3% and loses statistical significance. Beta rises to 0.4377 and $R^2$ increases to 32.52%. A much larger fraction of portfolio returns are explainable by movements of the benchmark. The year 2024 was particularly challenging with a negative alpha despite relatively modest market exposure. Although performance improves in 2025 and 2026, the recovery also shows substantially higher beta. These results suggest that the portfolio's behavior changed during the out-of-sample period. During 2015-2023 the portfolio behaved like a fairly pure statistical arbitrage strategy, but during 2024-2026 its returns became increasingly associated with movements in the benchmark.

One possible explanation is that the out-of-sample period represents a different market regime. The benchmark during these years was dominated by the unusually persistent momentum of a small number of large-cap stocks. This environment would've been difficult for the portfolio’s mean-reversion sleeves which is consistent with the conclusions in my initial portfolio analysis. It's also supported by the increased beta and higher benchmark influence in the regression results.

In sum, during the in-sample period the portfolio exhibited near-zero market exposure and generated statistically significant alpha. During the out-of-sample period, however, alpha disappeared while beta increased substantially. The most important question raised by these results is why the portfolio behavior appeared market-neutral in-sample, but developed meaningful market exposure out-of-sample. I think the next step is to identify the source of that exposure. One possibility is that certain sleeves became dominant during the 2024–2026 period and altered the aggregate behavior of the portfolio. One way to investigate this question is to decompose performance at the sleeve level and examine how each sleeve contributes to alpha, beta, and overall risk across different market environments. It would also be useful to run a broader factor analysis to determine whether the observed beta is truly market exposure or whether it reflects exposure to other risk factors such as momentum, size, value, or low-volatility effects.

Notebook with regression results [here](https://github.com/jwplatta/portfolio-research/blob/main/notebooks/shared/us-equities-start-arb-alpha-regression-annual.ipynb).