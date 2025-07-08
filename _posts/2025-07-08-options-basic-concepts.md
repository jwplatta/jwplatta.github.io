---
layout: post
title:  "Basic Concepts of Options"
date:   2025-07-08 10:00:00 -0500
categories: [investing, writing-to-learn]
tags: [investing, writing-to-learn]
math: true
toc: true
img_path: /assets/img/posts/
---
The last year and a half I've been learning how to trade options. It took me some time to get comfortable thinking in terms of options and I've enjoyed teaching others the basic concepts. I strongly believe that once a person takes the time to sit down and think carefully about the fundamental concepts and some basic examples, it's easy. So, although there are plenty of summaries on the web and, of course, any of the LLM powered chat tools can crank out an excellent tutorial on options trading, I'm writing my own summary to check my own understanding and to also have something to share with others.

## What is an option?

An **option** is contract to buy or sell an underlying asset at a specified price and before a given date. This date is called the **expiration date** and it defines the lifespan of the option. The price at which the underlying asset will be bought or sold at when the option is exercised is the **strike price**. The amount paid to own the contract is the called the **premium**.

Options on an underlying asset are bought and sold in batches. For options on stocks, one contract represents 100 shares of that underlying stock. So if the price per contract is 0.5, then the premium per a share is 0.5 and the total premium for the contract is $\\$500$. However, options on futures and indexes can have different price structures. For example, options on the E-mini S&P500 futures have a multiplier of 50 rather than 100. So if one contract on the **/ES** is priced at 0.5, then the total premium for the contract is $\\$25$.

There are two types of option contracts: **calls** and **puts**. Each type of contract gives the buyer and seller different powers and constraints. The *buyer of a call option* has the *right to buy* the underlying security at the strike price before the expiration date. On the other hand, the *seller of a call option* has the *obligation to sell* the underlying stock at the strike price if the buyer exercises the contract. The *buyer of a put option* has the *right to sell* the underlying security at the strike price before the expiration date. On the other hand, the *seller of a put option* has the *obligation to buy* the underlying stock at the strike price if the buyer exercises the contract.

|      | buyer         | seller             |
| ---- | ------------- | ------------------ |
| call | right to buy  | obligation to sell |
| put  | right to sell | obligation to buy  |

## Who are the bears and bulls?

An investor indicates a different orientation towards the market based on whether she is the buyer or seller of a put or call. The sellers of puts and buyers of calls have a bullish orientation while the buyers of puts and sellers of calls have a bearish orientation.

|      | buyer   | seller  |
| ---- | ------- | ------- |
| call | bullish | bearish |
| put  | bearish | bullish |

Consider that the *buyer of a call option* indicates a bullish position on the underlying stock. Acquiring the right to buy a stock at a given strike price at a later date signals the buyer's wish to profit from the stock's increase. The buyer of the call option can profit either by purchasing the stock at a discount or by selling the option at a higher premium as the underlying price moves close to or passes the strike price on the contract.

Take Marvel Technology Inc (MRVL) for example. Suppose that in September you purchase the option to call away 100 shares of MRVL at the current strike price around 71.00 before the end of the November. Let's say the contract costs 4.00 per a share and has an expiration date of `11-22-2024` which was the last Friday the market was open in November. On `11-22-2024` the MRVL stock price had increased to 92.51. If the holder of the contract exercises the contract, she purchases the shares at the 71.00 strike price and can sell them at the current market price of 92.51. This would net the option buyer a profit of $$(92.51 - 71.0 - 4.0) \times 100 = \$1751$$.

![MRVL](MRVL_2024-2025.png){: w="1000" }

On the other hand, the *seller of the call option* signals her expectation that the share price of MRVL will go down. If the share price is at or below the strike the price of the so that the option expires without being exercised and she can pocket the premium and not have to sell the stock at a discount.

The *buyer of a put option* takes a bearish position on the underlying stock. By buying the option to sell the stock at the strike price at a later date, the buyer indicates her wish that the price of the stock decrease so that she can sell the stock above the market rate or sell the option at a higher premium. On the other hand, the seller of the put option wishes the price of the stock to go up so that the option expires without being exercised. If the option expires with the market price above the strike price on the contract, then the contract expires worthless and the seller can pocket the premium and avoids buying the stock at an above market rate.

Consider MRVL again. I bought 100 shares of MRVL back in the summer of 2024 at 71.00. Suppose at the beginning of 2025 I do a bunch of market research and talk to lots of folks and start to think there is some risk that the MRVL share price will fall during the beginning of the year. In order to protect my position and gains, I buy a put contract at the 100 strike price with an expiration of `2-28-2025` at 3.00 per share. When the share price does fall and reach 91.82 on February 28th, I'm able to exit my position at the 100 strike price for a net profit of $$(100 - 71) \times 100 - 400 = \$2500$$ instead of $$(91.82 - 71) \times 100 = \$2082$$.

However, the seller of the a put contract takes a bullish position. Suppose the person who sold me the put contract at the 100 strike price believed that the MRVL share price would continue to do well in the beginning of 2025. For this investor, the ideal scenario is for the share price of MRVL to remain above the $100 price through the end of February. If the MRVL did remain above 100, then the put contract would expire worthless and the seller of the contract walks away with the premium.

---

Those few concepts makeup the basics of options. The next topic a novice option trader needs to master is how to read the option chain.