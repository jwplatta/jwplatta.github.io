---
layout: post
title: Gamma Imbalance, Absolute Returns, and Return Autocorrelation in SPX
date: 2026-11-24 20:19 -0600
math: true
categories:
img_path: /assets/img/posts/
toc:
published: false
---
Barbon and Buraschi (2021) explore the relationship of aggregate dealers' gamma imbalance with next day returns. Their experiments consider both next day's absolute returns and the tendency of intraday returns to continue or reverse. The authors propose that this relationship results from the delta hedging behavior of dealers. As the underlying price moves, dealers regularly adjust their hedges by selling/buying shares of the underlying asset in order to remain delta neutral. In particular, when dealers are long gamma, they will tend to trade against intraday moves, and when they are short gamma, they will tend to reinforce the market move. This practice can lead to intraday momentum or reversal. The data used for the experiments spans observations on four different indexes (S&P 500, Dow Jones Industrial Average, Nasdaq-100, and Russell 2000) and a broad sample of 2,700 individual stocks.

The authors investigate the relationship from multiple vantages. The two that I'm most interested in are:
1. Does prior session's gamma imbalance explain the next session's absolute returns?
2. And does the prior session's gamma imbalance explain whether the following session's intraday returns tend to continue or reverse?

Specifically, I'm interested in the extent to which these effects show up for SPX options.

The authors define gamma imbalance $\Gamma^{IB}$ as the volume-normalized aggregate dollar amount of outstanding gamma dealers have with takers. Here's an expanded representation of their formula:

$$
\Gamma^{IB}(t)= \frac{100 S_t[\sum_{i \in calls} \gamma_{i,t} OI_{i,t} - \sum_{i \in puts} \gamma_{i,t} OI_{i,t}]}{ADV(t)}
$$

Each term is an option contract's gamma multiplied by its open interest. These exposures are summed across calls with the corresponding puts total subtracted. The $100$ is the contract multiplier, $S_t$ is the spot price at date $t$, and $ADV(t)$ is the average daily trading volume. The authors do not specify the volume series used for index underlyings. For index options, a key assumption of $\Gamma^{IB}$ is that dealers are short puts and long calls. This is common simplifying assumption used to make a naive gamma imbalance calculation.

The authors regress absolute returns $\vert R \vert$ on day $t$ for asset $j$ on the previous day's gamma imbalance $\Gamma_{j,t-1}^{IB}$ while controlling for prior day implied volatility $IV_{j,t-1}$ and baseline differences between assets $\alpha_j$ and months $m_{month(t)}$:

$$
\vert R_{j,t} \vert = \alpha + \beta_0 \Gamma^{IB}_{j,t-1} + \beta_1 IV_{j,t-1} + \alpha_j + m_{month(t)} + \epsilon_{j,t}
$$

The authors also regress autocorrelation $\rho_{j,t}$ of intraday $h$-minute returns on the previous days gamma imbalance again controlling for implied volatility, baseline difference in assets and months, as well as asset $j$'s dollar trading volume $V$ during day $t$:

$$
\rho_{j,t}^h = \alpha^h + \beta_0^h \Gamma_{j,t-1}^{IB} + \beta_1^hIV_{j, t-1} + \beta_2^hV_{j,t} + a_j + m_t + \epsilon_{j,t}
$$

The following table summarizes selected results of Barbon and Buraschi. The gamma-imbalance coefficient is negative and statistically significant in all three specifications. The first rows highlight the absolute returns regression for index options with and without baseline effects. In both cases, the gamma-imbalance coefficient is negative indicating that higher gamma imbalance is associated with lower absolute returns. The last line shows the results of the 5-min autocorrelation regression for single name stocks. The gamma-imbalance coefficient is again negative indicating that higher gamma imbalance is associated with lower autocorrelation, i.e. more reversal or less continuation.

| Selected Results                                                                                                     | Finding                                                    | $\gamma$-IB coef. (pp) | t-stat | Model $R^2$ | Observations |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ----------------------------- | ------ | ----------- | ------------ |
| Absolute daily returns:<br>pooled regression across 4 equity indices,<br>controlling for prior IV<br>with no baseline effects | Higher gamma associated with<br>smaller absolute returns      | −0.1479                       | −4.42  | 25.2%       | 21,434       |
| Absolute daily returns: pooled regression across<br>4 equity indices with asset and month effects                       | Negative association remains                               | −0.0549                       | −3.33  | 35.8%       | 21,434       |
| 5-minute autocorrelation: individual-stocks with IV,<br>volume, asset and month controls                                | Higher gamma associated with more<br>reversal / less momentum | −1.814                        | −4.830 | 0.3%        | 1,541,400    |

## Works Cited
- Barbon, A., & Buraschi, A. (2021). Gamma fragility [Working paper](https://doi.org/10.2139/ssrn.3725454).