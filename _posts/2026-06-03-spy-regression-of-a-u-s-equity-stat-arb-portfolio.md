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

Given the portfolio’s construction, I would expect low market exposure and a low $R^2$. A statistical arbitrage portfolio that derives its returns from security selection should exhibit a small beta, little explanatory power from the benchmark, and positive alpha. Conversely, if the portfolio’s returns are largely driven by market direction, beta and $R^2$ should be substantially higher.

The below table shows the regression results for each calendar year and the aggregate in-sample (2015-2023), out-of-sample (2024-2026), and full-period results.

| Period    | Label | Ann Ret | Ann Vol | Sharpe | SPY Ret | Alpha (ann) |  CI lo | CI hi | t(alpha) | p(alpha) |    Beta | t(beta) | p(beta) |     R2 |  Skew | Kurt |    N |
| --------- | ----- | ------: | ------: | -----: | ------: | ----------: | -----: | ----: | -------: | -------: | ------: | ------: | ------: | -----: | ----: | ---: | ---: |
| 2015      | IS    |    5.5% |    5.3% |  1.049 |    1.3% |        5.5% |  -4.3% | 15.3% |      1.1 |    0.271 |  0.0102 |     0.4 |  0.6908 | 0.0009 |  0.59 |  4.5 |  252 |
| 2016      | IS    |   20.6% |    6.4% |  3.223 |   12.0% |       17.0% |   7.3% | 26.7% |     3.44 |   0.0006 |  0.1613 |    4.05 |  0.0001 | 0.1084 | -0.19 |  0.8 |  252 |
| 2017      | IS    |    2.7% |    5.9% |   0.46 |   21.8% |        2.2% |  -8.2% | 12.6% |     0.42 |   0.6773 |  0.0326 |    0.33 |  0.7389 | 0.0014 | -0.31 |  3.5 |  251 |
| 2018      | IS    |   18.1% |    7.6% |   2.37 |   -4.6% |       17.2% |   3.1% | 31.3% |     2.39 |   0.0167 |  0.0869 |    1.48 |  0.1377 | 0.0376 |  0.48 |  3.6 |  251 |
| 2019      | IS    |   20.2% |    7.9% |  2.542 |   31.2% |       16.6% |   1.1% | 32.2% |      2.1 |   0.0359 |  0.0745 |    1.63 |  0.1025 | 0.0138 |  0.62 |  1.5 |  252 |
| 2020      | IS    |   50.5% |   13.0% |  3.901 |   18.3% |       42.7% |   9.0% | 76.4% |     2.49 |   0.0129 | -0.0427 |   -0.62 |  0.5378 | 0.0121 |  2.37 | 12.7 |  253 |
| 2021      | IS    |    3.6% |    8.5% |  0.429 |   28.7% |        2.6% | -11.8% | 17.0% |     0.35 |   0.7239 |  0.0513 |    0.57 |   0.567 | 0.0062 |   0.1 |  0.4 |  252 |
| 2022      | IS    |   45.8% |   10.2% |  4.498 |  -18.2% |       39.6% |  25.6% | 53.6% |     5.55 |      0.0 |  0.0771 |    1.96 |  0.0503 | 0.0337 |  0.87 |  3.5 |  251 |
| 2023      | IS    |   15.3% |    7.9% |  1.937 |   26.4% |       10.7% |  -3.1% | 24.5% |     1.52 |    0.128 |  0.1563 |    3.97 |  0.0001 | 0.0673 |  0.34 |  0.1 |  250 |
| 2024      | OOS   |   -9.1% |    7.0% | -1.311 |   24.9% |       -9.7% | -22.6% |  3.2% |    -1.48 |   0.1394 |   0.017 |    0.46 |  0.6422 | 0.0009 |  -0.3 |  1.0 |  252 |
| 2025      | OOS   |   14.4% |   15.8% |  0.909 |   17.9% |        3.7% | -15.0% | 22.4% |     0.39 |   0.6982 |  0.5957 |    4.48 |     0.0 | 0.5405 |  5.56 | 74.0 |  250 |
| 2026      | OOS   |   33.7% |   13.1% |  2.567 |   15.1% |       21.5% |  -2.9% | 45.9% |     1.73 |   0.0835 |  0.5533 |    7.43 |     0.0 | 0.3557 | -0.39 |  0.6 |   81 |
| 2015–2023 | IS    |   19.2% |    8.4% |   2.29 |   11.8% |       17.5% |  11.2% | 23.9% |     5.42 |      0.0 |  0.0334 |    0.86 |   0.391 | 0.0052 |  1.41 | 11.0 | 2264 |
| 2024–2026 | OOS   |    5.8% |   12.3% |  0.472 |   20.5% |       -2.3% | -13.1% |  8.4% |    -0.42 |   0.6725 |  0.4377 |    3.35 |  0.0008 | 0.3252 |   5.0 | 86.1 |  583 |
| 2015–2026 | ALL   |   15.4% |    9.3% |  1.665 |   13.5% |       13.2% |   7.5% | 18.9% |     4.54 |      0.0 |  0.1093 |    2.01 |   0.044 | 0.0434 |  3.16 | 59.8 | 2847 |

The in-sample results are positive. During the 2015-2023 period, the portfolio generated approximately 17.5% annualized alpha with a t-statistic of 5.42 and a p-value effectively equal to zero. At the same time, beta was only 0.0334 and indistinguishable from zero while SPY explained less than 1% of the variation in portfolio returns ($R^2 = 0.52\%$). These results are consistent with the portfolio’s performance during this period was driven primarily by security selection and portfolio construction rather than systematic market risk. Beta remained close to zero throughout most of the period and the strongest contributions came from 2016, 2020, and 2022.

On the other hand, the out-of-sample results aren't as positive. Annualized alpha falls to roughly -2.3% and loses statistical significance. Beta goes up to 0.4377 and $R^2$ increases to 32.52%. A much larger fraction of portfolio returns are explainable by movements of the benchmark. The year 2024 was particularly challenging with a negative alpha despite relatively modest market exposure. Although performance improves in 2025 and 2026, the recovery also shows substantially higher beta. These results suggest that the portfolio's behavior changed during the out-of-sample period. During 2015-2023 the portfolio behaved like a fairly pure statistical arbitrage strategy, but during 2024-2026 its returns became increasingly associated with movements in the benchmark.

One possible explanation is that the out-of-sample period represents a different market regime. The benchmark during these years was dominated by the unusually persistent momentum of a small number of large-cap stocks. This environment would've been difficult for the portfolio’s mean-reversion sleeves which is consistent with the conclusions in my initial portfolio analysis. It's also supported by the increased beta and higher benchmark influence in the regression results.

In sum, during the in-sample period the portfolio exhibited near-zero market exposure and generated statistically significant alpha. During the out-of-sample period, however, alpha disappeared while beta increased substantially. The most important question raised by these results is why the portfolio behavior appeared market-neutral in-sample, but developed meaningful market exposure out-of-sample. I think the next step is to identify the source of that exposure. One possibility is that certain sleeves became dominant during the 2024–2026 period and altered the aggregate behavior of the portfolio. One way to investigate this question is to decompose performance at the sleeve level and examine how each sleeve contributes to alpha, beta, and overall risk across different market environments. It would also be useful to run a broader factor analysis to determine whether the observed beta is truly market exposure or whether it reflects exposure to other risk factors such as momentum, size, value, or low-volatility effects.

Notebook with regression results [here](https://github.com/jwplatta/portfolio-research/blob/main/notebooks/shared/us-equities-start-arb-alpha-regression-annual.ipynb).