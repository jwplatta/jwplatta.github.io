# AGENTS.md

Instructions for AI agents working on this Jekyll blog.

## Overview

This is a personal research blog at [jwplatta.github.io](https://jwplatta.github.io/). It publishes research notes on quantitative finance, machine learning, NLP, and software engineering. Built with a custom minimal theme, deployed to GitHub Pages via GitHub Actions.

## Git Conventions

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, etc.
- **No attributions** in commit messages (no Co-Authored-By lines).
- Commit directly to `main`. No pull requests for routine changes.
- `Gemfile.lock` is committed for reproducible CI builds.

## Project Structure

```
_layouts/           # Page templates
  default.html      # Base HTML shell (head, nav, main, footer)
  home.html         # Paginated post list (index page)
  post.html         # Single post with TOC, meta, prev/next nav
  page.html         # Generic page (used by tabs)
  archives.html     # Timeline view grouped by year
  categories.html   # All categories with post lists
  tags.html         # Tag cloud
  category.html     # Single category page (jekyll-archives)
  tag.html          # Single tag page (jekyll-archives)

_includes/          # Reusable partials
  head.html         # <head> tag: meta, SEO, stylesheets, favicons, feed
  nav.html          # Top navigation bar
  footer.html       # Social links (inline SVG), copyright
  katex.html        # MathJax 3 CDN scripts (loaded when page.math: true)
  mermaid.html      # Mermaid.js CDN (loaded when page.mermaid: true)
  toc.html          # JS-generated table of contents

_sass/              # SCSS partials (imported via assets/css/main.scss)
  _variables.scss   # Design tokens: colors, fonts, spacing, breakpoints
  _base.scss        # Reset, body defaults, base element styles
  _typography.scss  # Headings, paragraphs, blockquotes in post content
  _code.scss        # Code blocks, Rouge syntax theme, line numbers
  _math.scss        # MathJax display overrides
  _tables.scss      # Academic-style tables with horizontal scroll
  _post.scss        # TOC styling
  _pages.scss       # Archive, category, tag page styles
  _layout.scss      # Page structure: nav, main, footer, post list, responsive

_tabs/              # Navigation pages (collected as site.tabs, sorted by order)
  about.md          # order: 0
  categories.md     # order: 1
  tags.md           # order: 2
  archives.md       # order: 4

_plugins/
  posts-lastmod-hook.rb  # Sets last_modified_at from git history
  img-path-hook.rb       # Prepends img_path frontmatter to relative image srcs

_data/              # Data files
  (contact.yml was removed -- footer is hardcoded with inline SVGs)

assets/
  css/main.scss     # SCSS entry point
  img/              # Avatar, favicons, post images
    posts/          # Post-specific images (charts, diagrams)
    favicons/       # Favicon files

.github/workflows/pages-deploy.yml  # GitHub Actions: build + deploy
```

## Design

- **Aesthetic:** Minimal, academic, Tufte-inspired. Light only, no dark mode.
- **Colors:** `#111` text, `#fff` background, `#666` secondary, `#ddd` borders, `#2563eb` accent (links).
- **Typography:** Georgia/serif for body, system sans-serif for nav/headings, monospace for code.
- **Layout:** 900px max content column, centered. Single column, no sidebar.
- **Nav:** Horizontal top bar with site title left, page links right. Hamburger on mobile (<768px).
- **No external dependencies** except MathJax and Mermaid CDNs (loaded conditionally).

## Post Frontmatter

```yaml
---
layout: post
title: "Post Title"
date: YYYY-MM-DD HH:MM -0500
categories: [single-category]
tags: [tag1, tag2, tag3]
math: true          # loads MathJax
toc: true           # shows table of contents
img_path: /assets/img/posts/  # prepended to relative image srcs
mermaid: true       # loads Mermaid.js
published: false    # for drafts
---
```

### Rules

- **One category per post.**
- **Max 3 tags per post.**
- Tags and categories should be specific, professional, and credible. Avoid generic terms (e.g., "machine-learning" as a tag) or jargon that only insiders would know (e.g., "1dte-trade").
- Kramdown converts `$$...$$` to `\[...\]` and `$...$` to `\(...\)` -- MathJax handles both.
- Images: use `img_path` in frontmatter and reference images by filename in markdown. The `img-path-hook.rb` plugin handles the path prepending.

### Current Categories

- `quantitative-finance`
- `natural-language-processing`
- `machine-learning`
- `software`

### Current Tags

authentication, aws-amplify, backtesting, derivatives, expected-value, factor-models, gamma, iron-condor, k-means, knn, large-language-models, logic-programming, market-microstructure, nextjs, options, random-forest, regime-detection, regression, reinforcement-learning, research-tools, return-autocorrelation, risk-metrics, ruby, semantic-search, stat-arb, text-embeddings, textual-entailment, transformers, volatility

## Development

```bash
bundle install
bundle exec jekyll serve --port 4000
```

The site builds at http://localhost:4000. Auto-regeneration is enabled but frontmatter changes may require a restart.

## Deployment

Push to `main` triggers GitHub Actions (`.github/workflows/pages-deploy.yml`). The workflow:
1. Checks out with full git history (needed for `posts-lastmod-hook.rb`)
2. Sets up Ruby 3.2 with bundler cache
3. Builds with `JEKYLL_ENV=production`
4. Deploys to GitHub Pages

## Key Plugins (Gemfile)

- `jekyll-archives` -- generates `/categories/:name/` and `/tags/:name/` pages
- `jekyll-paginate` -- homepage pagination (10 posts per page)
- `jekyll-seo-tag` -- SEO meta tags
- `jekyll-sitemap` -- sitemap.xml
- `jekyll-feed` -- Atom feed at /feed.xml
- `rouge` -- syntax highlighting
