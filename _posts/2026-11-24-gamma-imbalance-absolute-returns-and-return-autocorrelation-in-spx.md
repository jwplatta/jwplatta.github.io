---
layout: post
title: Gamma Imbalance, Absolute Returns, and Return Autocorrelation in SPX
date: 2026-11-24 20:19 -0600
math: true
categories: [quantitative-finance]
tags: [gamma, market-microstructure]
img_path: /assets/img/posts/
toc:
published: true
---
Barbon and Buraschi (2021) explore the relationship of aggregate dealers' gamma imbalance with next day returns. Their experiments consider both next day's absolute returns and the tendency of intraday returns to continue or reverse. The authors propose that this relationship results from the delta hedging behavior of dealers. As the underlying price moves, dealers regularly adjust their hedges by selling/buying shares of the underlying asset in order to remain delta neutral. In particular, when dealers are long gamma, they'll tend to trade against intraday moves, and when they are short gamma, they'll tend to reinforce the market move. This practice can lead to intraday momentum or reversal. The data used for the experiments spans observations on four different indexes (S&P 500, Dow Jones Industrial Average, Nasdaq-100, and Russell 2000) and a broad sample of 2,700 individual stocks.

The authors investigate the relationship from multiple vantages. The two that I'm most interested in are:
1. Does prior session's gamma imbalance explain the next session's absolute returns?
2. And does the prior session's gamma imbalance explain whether the following session's intraday returns tend to continue or reverse?

Specifically, I'm interested in the extent to which these effects show up for SPX options.

The authors define gamma imbalance $\Gamma^{IB}$ as the volume-normalized aggregate dollar amount of outstanding gamma dealers have with takers. Here's an expanded representation of their formula:

$$
\Gamma^{IB}(t)= \frac{100 S_t[\sum_{i \in calls} \gamma_{i,t} OI_{i,t} - \sum_{i \in puts} \gamma_{i,t} OI_{i,t}]}{ADV(t)}
$$

Each term is an option contract's gamma multiplied by its open interest. These exposures are summed across calls with the corresponding puts total subtracted. The $100$ is the contract multiplier, $S_t$ is the spot price at date $t$, and $ADV(t)$ is the average daily trading volume. The authors don't specify the volume series used for index underlyings. For index options, a key assumption of $\Gamma^{IB}$ is that dealers are short puts and long calls. This simplification is a common assumption used to make a naive gamma imbalance calculation.

The authors regress absolute returns $\vert R \vert$ on day $t$ for asset $j$ on the previous day's gamma imbalance $\Gamma_{j,t-1}^{IB}$ while controlling for prior day implied volatility $IV_{j,t-1}$ and baseline differences between assets $\alpha_j$ and months $m_{month(t)}$:

$$
\vert R_{j,t} \vert = \alpha + \beta_0 \Gamma^{IB}_{j,t-1} + \beta_1 IV_{j,t-1} + \alpha_j + m_{month(t)} + \epsilon_{j,t}
$$

The authors also regress autocorrelation $\rho_{j,t}$ of intraday $h$-minute returns on the previous days gamma imbalance again controlling for implied volatility, baseline difference in assets and months, and asset $j$'s dollar trading volume $V$ during day $t$:

$$
\rho_{j,t}^h = \alpha^h + \beta_0^h \Gamma_{j,t-1}^{IB} + \beta_1^hIV_{j, t-1} + \beta_2^hV_{j,t} + a_j + m_t + \epsilon_{j,t}
$$

The following table summarizes selected results of Barbon and Buraschi. The gamma-imbalance coefficient is negative and statistically significant in all three specifications. The first rows highlight the absolute returns regression for index options with and without baseline effects. In both cases, the gamma-imbalance coefficient is negative indicating that higher gamma imbalance is associated with lower absolute returns. The last line shows the results of the 5-min autocorrelation regression for single name stocks. The gamma-imbalance coefficient is again negative indicating that higher gamma imbalance is associated with lower autocorrelation, i.e. more reversal or less continuation.

| Selected Results                                                                                                     | Finding                                                    | $\gamma$-imbalance coef. (pp) | t-stat | Model $R^2$ | Observations |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ----------------------------- | ------ | ----------- | ------------ |
| Absolute daily returns: pooled regression<br>across 4 equity indices, controlling<br>for prior IV with no baseline effects | Higher gamma associated with<br>smaller absolute returns      | −0.1479                       | −4.42  | 25.2%       | 21,434       |
| Absolute daily returns: pooled regression<br>across 4 equity indices with asset and month effects                       | Negative association remains                               | −0.0549                       | −3.33  | 35.8%       | 21,434       |
| 5-minute autocorrelation: individual-stocks<br>with IV, volume, asset and month controls                                | Higher gamma associated with<br>more reversal / less momentum | −1.814                        | −4.830 | 0.3%        | 1,541,400    |

I examine the same two relationships with some modifications. I use a smaller dataset focused only on the SPX. The dataset uses SPX option snapshots from January 2026 to November 2026. It covers 192 trading days when gamma imbalance is determined by the option chain that's one trading session from expiry (1DTE) and 180 trading days when gamma imbalance is determined by all expiries after the snapshot date and strikes (1DTE+). Each option chain snapshot is from the prior session's morning and the IV is the prior session at-the-money IV. I test both whether the prior session's gamma imbalance is associated with absolute returns and 5 minute return autocorrelation.

For the volume normalization of gamma imbalance, I use the previous 21 trading sessions (excluding day $t$) moving average of ES futures traded volume. Also, while I aggregate all strikes and expiries, sample coverage is weaker in earlier months than later months:

$$
\Gamma^{IB}(t) = \frac{100 S_t[\sum_{i \in calls} \gamma_{i,t} OI_{i,t} - \sum_{i \in puts} \gamma_{i,t} OI_{i,t}]}{50 \cdot \bar{V}^{ES}_{21,t-1}}
$$

Where 50 is the contract multiplier for the `ES` futures contracts. The regressions are also modified for simplicity. The absolute return regression doesn't include the month and asset baseline factors:

$$
\vert R_{j,t} \vert = \alpha + \beta_0 \Gamma^{IB}_{j,t-1} + \beta_1 IV_{j,t-1} + \epsilon_{j,t}
$$

And I focus on 5-minute non-overlapping returns for the autocorrelation regression:

$$
\rho^5_{t} = \alpha + \beta_0^5 \Gamma_{t-1} + \beta_1^5 IV_{t-1} + \epsilon_{t}
$$

For all regressions, the predictors are winsorized at the 1st and 99th percentiles and standardized. Inferences use HAC standard errors with five lags. Also, the paper uses percentage points while my results are in the raw decimal-return and autocorrelation units.

The absolute return regression produced mixed and very weak results. Only the 1DTE result shows a very small negative relationship between the gamma imbalance and absolute returns. The magnitude of the 1DTE and 1DTE+'s gamma imbalance coefficients are about even. So these results don't establish a relationship in either direction (p-value of 0.684 and 0.66):

| Expiry set | Observations | $\gamma$-IB coef. | z-stat | p-val | 95% confidence interval | Model $R^2$ | Adjusted $R^2$ |
| ---------- | ------------ | ----------------- | ------ | ----- | ----------------------- | ----------- | -------------- |
| 1DTE       | 192          | −0.0001487        | −0.407 | 0.684 | [−0.0008641, 0.0005667] | 9.1%        | 8.1%           |
| 1DTE+      | 180          | 0.0001862         | 0.44   | 0.66  | [−0.0006440, 0.0010164] | 9.1%        | 8.1%           |

The autocorrelation regression results are more encouraging. Higher gamma imbalance is associated with lower 5-minute autocorrelation of returns. This effect is larger for the 1DTE+ dataset (-0.0421) than 1DTE dataset (-0.0231). The support is strongest for the 1DTE+ (p-value of 0.001) while support for the 1DTE dataset is borderline (p-value 0.047).

| Expiry set | Observations | $\gamma$-IB coef. | z-stat | p-val | 95% confidence interval | Model $R^2$ | Adjusted $R^2$ |
| ---------- | ------------ | ----------------- | ------ | ----- | ----------------------- | ----------- | -------------- |
| 1DTE       | 192          | −0.0231           | −1.984 | 0.047 | [−0.046, −0.000¹]       | 6.3%        | 5.3%           |
| 1DTE+      | 180          | −0.0421           | −3.373 | 0.001 | [−0.067, −0.018]        | 10.2%       | 9.2%           |

As a baseline comparison, I also regressed the autocorrelation of 5-min returns on the prior session morning ATM IV. The prior session ATM IV explains only 4.44% of the variation in daily five-minute return autocorrelation. On the other hand, the implied volatility and gamma imbalance increases the $R^2$ to 10.24%:

| Model                      | Observations | $R^2$                      | Adjusted $R^2$             |
| -------------------------- | ------------ | -------------------------- | -------------------------- |
| Prior IV only              | 180          | 4.44%                      | 3.91%                      |
| Prior IV + gamma imbalance | 180          | 10.24%                     | 9.23%                      |
| **Increase**               | -            | **5.80 percentage points** | **5.32 percentage points** |

In sum, the absolute returns estimates are very small and statistically inconclusive. But I find some evidence that higher prior session gamma imbalance is associated with lower 5-minute SPX return autocorrelation. This effect is stronger for the 1DTE+ dataset. Adding gamma imbalance to the prior session ATM IV for the autocorrelation regression increases the in-sample $R^2$ from 4.44% to 10.24% which is encouraging, but most of the variation in the return autocorrelation remains unexplained. One possibility is that the gamma imbalance signal (from the autocorrelation regression) might be paired with other weak signals to produce a stronger explanation returns.

## Works Cited
- Barbon, A., & Buraschi, A. (2021). Gamma fragility [Working paper](https://doi.org/10.2139/ssrn.3725454).