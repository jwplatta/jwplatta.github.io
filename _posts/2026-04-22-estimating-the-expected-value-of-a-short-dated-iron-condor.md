---
layout: post
title: Estimating the Expected Value of a Short-Dated Iron Condor
date: 2026-04-22 14:43 -0500
tags:
  - spx
categories:
  - writing-to-learn
  - options-trading
toc: true
img_path: /assets/img/posts/
math: true
---
One of the challenges trading short-dated iron condors is that their high probability of profit is often disconnected from their actual profitability. Most of the time they expire worthless and you keep the credit. But that high win rate doesn't imply positive expected value. The important question is whether repeating the trade over time leads to a net gain or loss. In other words, the focus should be on expected value (EV) rather than probability of profit. Determining EV in this context is non-trivial. It depends not only on the payoff structure, but also on trade management and evolving market conditions. To make this concrete, I consider three increasingly realistic approaches to estimate the EV of a single 7DTE SPX iron condor.

The simplest approach is to estimate EV using the initial credit and option deltas as proxies for probabilities even though they don't actually measure the probability of the market hitting that level and assume that losses occur at maximum loss. This leads to the following expression for EV:

$$
E(x) = (1 - \delta_{\text{long put}} - \delta_{\text{long call}}) \cdot \text{credit} + (\delta_{\text{long put}} + \delta_{\text{long call}}) \cdot \text{max loss}
$$

As an example, consider an iron condor constructed from the SPX option chain with expiration April 6th, 2026 sampled at March 31st at 2:08pm:

| type | strike | qty | mark | delta  |
| ---- | ------ | --- | ---- | ------ |
| PUT  | 5850   | +1  | 6.00 | -0.048 |
| PUT  | 5875   | -1  | 6.65 | -0.053 |
| CALL | 6630   | -1  | 4.45 | 0.056  |
| CALL | 6655   | +1  | 3.03 | 0.041  |

With spot at 6318, the initial credit is 2.07. Given 25 point spreads, the maximum loss is 25. Plugging these values into the expression above gives the EV for the trade:
$$
(1 - 0.048 - 0.041) \cdot 2.07 - (0.048 + 0.041) \cdot 25 \approx -0.34
$$

The resulting EV is negative, but the calculation relies on some strong assumptions. In particular, it assumes the position is held to maximum loss and ignores trade management entirely. In practice, positions are rarely held to expiration, especially under adverse conditions. Rather, exits are typically determined by stop-loss rules. These rules make the path dependence of the trade an important aspect of the payoff.

A more realistic estimation of EV incorporates a stop-loss threshold. The EV can then be written as: 
$$
E(x) = (1 - \delta_{\text{put stop}} - \delta_{\text{call stop}}) \cdot \text{credit} + (\delta_{\text{put stop}} + \delta_{\text{call stop}}) \cdot L
$$
where $p_{\text{put stop}}$ and $p_{\text{call stop}}$ are the probabilities of hitting the stop on each side, and $L$ represents the realized loss at exit. These probabilities are not directly observable at trade entry and must be estimated. A crude approximation is to shift the iron condor along the observed option chain to simulate moves in spot and identify the configurations where the stop-loss would be triggered. Then use the deltas of the short legs as proxies for the corresponding probabilities.

|      | Move down IC | exit price=5.55 | Move up IC | exit price=5.4 |
| ---- | ------------ | --------------- | ---------- | -------------- |
| type | strike       | delta           | strike     | delta          |
| PUT  | 6150         | -0.229          | 5725       | -0.03          |
| PUT  | 6175         | -0.261          | 5750       | -0.032         |
| CALL | 6925         | 0.002           | 6505       | 0.193          |
| CALL | 6950         | 0.002           | 6530       | 0.158          |

Using this approach and assuming a stop-loss of x2.5 credit received, 5.175, results in exit prices of approximately 5.55 on a downward move and 5.40 on an upward move. Using the associated deltas as shown in the above table, the updated EV calculations is:
$$
(1 - 0.261 - 0.193) \cdot 2.07 - 0.261 \cdot 5.55 - 0.193 \cdot 5.4 \approx -1.36
$$

This approach still results in negative EV, but it likely understates risk because it assumes the volatility surface remains static as spot moves and time passes. This assumption is inconsistent with how markets actually behave. Changes in the spot price alter moneyness, implied volatility shifts across strikes, and the shape of the skew changes. Option repricing is therefore inherently dynamic.

A more realistic EV calculation uses an implied volatility surface as a function of moneyness and time to expiration. Using approximately 9,800 sampled SPX option chains, I fit a simple parametric model using linear regression with features capturing log-moneyness, curvature, time to expiration, and their interactions. This results in a quadratic model for implied volatility as a function of these variables.

 >**Feature Set**
>- $x$ = log(K / S) → moneyness
>- $x^2$ to account for the curvature or smile
>- $t$ account for the term structure
>- $xt$ skew evolution over time
>- $x^2·t$ wing steepness over time

And the quadratic function is
$$
IV ≈ a + bx + cx^2 + dt + e(xt) + f(x^2t)
$$

Using this model, option prices can be recomputed using Black–Scholes as spot moves. For each simulated move, spot is incremented, and implied volatility for each leg is updated using the modeled surface, and the options repriced. The leg values are then summed to obtain the new iron condor price and the stop-loss condition is evaluated on this dynamically repriced position.

> 1. Increment spot price up or down
> 2. Recompute implied volatility for each leg using the modeled IV surface
> 3. Reprice each option leg with the new spot price, volatility, and time remaining with Black-Scholes
> 4. Sum the four leg values to get the new iron condor price
> 5. Check if the price triggers the stop-loss threshold
  
When compared against a later sample of the same option chain, the model overstates individual leg prices but produces a reasonably accurate estimate of the total condor value. 

|        |        |     | Sample 1 | (spot=6318) |        | Sample 2 | (spot=6505) |        | Calculated  | (spot=6518) |
| ------ | ------ | --- | -------- | ----------- | ------ | -------- | ----------- | ------ | ----------- | ----------- |
| type   | strike | qty | mark     | delta       | vol    | mark     | delta       | vol    | mark        | delta       |
| PUT    | 5850   | +1  | 6.00     | -0.048      | 33.857 | 1.38     | -0.013      | 36.329 | 18.37407718 |             |
| PUT    | 5875   | -1  | 6.65     | -0.053      | 32.994 | 1.5      | -0.014      | 37.195 | 18.79896286 | -0.081      |
| CALL   | 6630   | -1  | 4.45     | 0.056       | 21.609 | 17.35    | 0.208       | 17.983 | 37.47777457 | 0.298       |
| CALL   | 6655   | +1  | 3.03     | 0.041       | 21.219 | 11.75    | 0.157       | 17.422 | 32.25982281 |             |
| TOTALS |        |     | 2.07     |             |        | 5.72     |             |        | 5.64        |             |

This level of accuracy is enough for a rough EV estimation. Recomputing the EV with stop loss using the deltas and price generated by the IV model we find:

$$
(1 - 0.298 - 0.399) \cdot 2.07 - 0.298 \cdot 5.64 - 0.399 \cdot 5.69 \approx -3.32
$$

Using the IV model to update prices as spot moves, the EV of the trade becomes negative again.

None of these EV calculations are perfect. They demonstrate that EV estimates for short-dated options are highly sensitive to modeling assumptions. Under simplistic assumptions the trade can appear more attractive. As the assumptions become increasingly realistic, the estimated EV deteriorates. The implication is that the payoff structure of the iron condor itself doesn't generate positive EV. Any persistent profitability is more likely to arise from factors such as regime selection, timing, execution, and the identification of mispriced volatility, rather than from the structure of the trade in isolation.

Full notebook with code for EV calculations and to build the IV surface model along with the sampled options data can be found [here](https://github.com/jwplatta/trade_lab/blob/main/notebooks/IronCondor%20EV%20Calculations.ipynb).