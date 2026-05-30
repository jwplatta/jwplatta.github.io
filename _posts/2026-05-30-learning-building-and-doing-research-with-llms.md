---
layout: post
title: Learning, Building, and Doing Research with LLMs
date: 2026-05-30 13:59 -0500
tags:
  - quant-finance
  - llms
categories:
toc:
img_path: /assets/img/posts/
math:
---
Lots of discussion around LLMs focuses on prompting techniques, context management, agent workflows, MCP servers, and other methods for extracting more capability from the model. The implicit assumption is that you already know what you want the model to do. The challenge is getting the model to do it correctly. In my experience, this is not the primary bottleneck. The most important factor in my ability to use these models effectively isn't better prompting, context engineering or larger context windows, or workflow tooling. It has been developing a deeper understanding of the domain where I am trying to do work. The more I understand a domain, the easier it becomes to direct the model, evaluate its output, and build tools and workflows around it.

I find myself repeating a process of learning, building, and doing real work. At the start of a project, most of my effort goes into understanding the problem or domain. I read books and papers, work through examples manually, write code, inspect outputs, and ask a lot of questions. The goal isn't to complete tasks quickly, but to develop a clear understanding of the domain, workflow, and constraints. As my understanding grows, I begin to recognize patterns like repeated code, repeated steps, shared data, etc. Those patterns make it possible to design shared interfaces and build tools and worfklows. Then I can ask the LLM to work inside an environment I’ve designed that reflects my best understanding of the domain. Still, I need to read the code, understand what it's doing, and check whether the results make sense. But the model can now do a large part of the implementation work while I focus my attention on formulating hypotheses, interpreting results, and deciding what to do next.

Of course, none of this process is really new. Before LLMs, I still had to learn a domain, identify recurring patterns, and build tools around them. The difference is that implementation is much cheaper now. Once I understand what I want to build, the model can produce a decent chunk of the surrounding code and infrastructure. This significantly compresses the cycle between learning, building, and doing the work.

One recent example for me has been learning quantaitive finance and experimenting with statistical arbitrage approaches to portfolio construction. At the beginning, I wasn’t trying to build a library. I was trying to understand the research process. I spent most of my time in Jupyter notebooks writing messy pandas code, reading papers and books, testing ideas, and asking questions. I wanted to understand how statistical arbitrage and cross sectional equity research actually worked.

That process involved a large amount of repetitive work. I would load security prices, construct returns, sometimes residualize them against factors, construct a signal, apply filters or scalers, build the positions, apply transaction costs and rebalance. Finally I'd evaluate the performance of the portfolio. Most experiments differed only in a few steps and the alpha hypothesis is often a relatively small part of the total implementation.

A typical experiment looked something like this:

```python

import statsmodels.api as sm

# residualize returns against factor ETFs
common_index = returns.index.intersection(factors.index)
r = returns.loc[common_index]
f = sm.add_constant(factors.loc[common_index])

residuals = pd.DataFrame(index=common_index, columns=r.columns)

for ticker in r.columns:
	y = r[ticker].dropna()
	residuals.loc[y.index, ticker] = sm.OLS(y, f.loc[y.index]).fit().resid

# residual mean reversion signal
signal = -residuals.rolling(5).mean()
signal = signal.sub(signal.mean(axis=1), axis=0)

# low volatility filter
vol = residuals.rolling(5).std()
threshold = vol.quantile(0.6, axis=1)
signal = signal.where(vol.lt(threshold, axis=0))

# build long/short portfolio
ranks = signal.rank(axis=1, ascending=False, na_option="bottom")
n = signal.count(axis=1)

longs = ranks <= 3
shorts = ranks.ge((n - 2).values[:, None]) & signal.notna()
positions = longs.astype(float) - shorts.astype(float)
positions = positions.div(positions.abs().sum(axis=1), axis=0)

portfolio_returns = (positions.shift(1) * returns).sum(axis=1)
```

As I became comfortable with the workflow, I began to understand what each step actually did and why it was there. I saw which parts are essential, which parts are interchangeable, and which parts are simply implementation details.

In general, I could describe almost every experiment as a sequence of transformations applied to a return stream. I was repeatedly converting returns into signals, signals into positions, and positions into portfolio returns. So I built a small research library called qstudy, viz. "quant study", that encoded this transformation pipeline into a simple common interface. Instead of repeatedly writing the plumbing around a strategy, I could concisely express the strategy:

```python

study = (
	Study(universe=universe, factors=factors)
	.residualize_returns()
	.base_signal(lambda **cache: -cache["residual_returns"].rolling(5).mean())
	.demean_signal()
	.add_vol_filter(vol_window=5, quantile=0.6)
	.build_long_short(n_long=3, n_short=3)
	.run()
)
```

As my understanding of the research process improved, I started wrapping recurring patterns into a small library called `qstudy`. The motivation was practical. I wanted a concise way to express research ideas without repeatedly writing the same code around data preparation, signal construction, filtering, portfolio weighting, rebalancing, and performance evaluation. With `qstudy` adding a new signal family often became a matter of implementing a single function rather than rewriting an entire backtest. Because the LLM and I now shared the same tooling and vocabulary, it became much easier to hand implementation tasks to the model. That made it possible to evaluate far more ideas than I could reasonably test by hand. Moreover, it shifted my attention to research questions like which hypotheses are worth testing, how to interpret the results, and what experiments to run next.

Importantly, this didn’t eliminate the need for my understanding. I was constantly moving back and forth between learning, building, and doing the work. Sometimes I discovered things I didn’t understand. For example, one bug effectively turned a supposedly market-neutral portfolio into a long-only strategy. The issue was easy to fix, but the danger was recognizing that the output didn’t make sense. In my experience, LLMs excel at writing running code, but not necessarily writing correct code. Because I understood the research process, I had a clear expectation for how the strategy should behave. That expectation made it obvious when the implementation and the results diverged.

This process reminds me a lot of Peter Naur's essay "Programming as Theory Building". Naur argues that programming is not primarily the production of code. Programming is the construction of a coherent understanding of a problem domain. The source code is merely one artifact produced by that understanding.

Naur's claim still seems true to me even with these new powerful models. The useful abstractions in `qstudy` didn't come from the model writing code for me. They emerged from learning the research workflow. Once I understood the process, it was straightforward to build something that encapsulated that understanding and that an LLM could use to help me do my work. The model helped implement the abstraction, but the abstraction itself came from understanding the domain.

This distinction matters because many discussions about LLMs implicitly treat software development as a code generation problem. But code was never the scarce resource; understanding is. The ability to generate code cheaply doesn't remove the need to have a working understanding of a domain. If anything, they increase the value of having one.

I increasingly think of LLMs as tools that accelerate movement rather than tools that replace judgment and understanding. They can generate code, documentation, experiments, tests, and analyses at a speed that would have been impractical a few years ago. But deciding what belongs, what doesn't, which abstractions matter, which results are meaningful, and which directions are worth pursuing still depends on human understanding.