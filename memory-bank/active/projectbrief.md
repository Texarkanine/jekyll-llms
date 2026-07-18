# Project Brief

## User Story

As a Jekyll site operator using jekyll-archives with a custom `slug_mode`, I want built-in category scoped `llms.txt` paths to use that same slug mode so LLM indexes land beside the human category archive URLs.

## Use-Case(s)

### Custom slug_mode with categories enabled

Operator sets `llms.categories: true` and `jekyll-archives.slug_mode` (e.g. `ascii`, `latin`, `raw`). Category-scoped LLM indexes must use the same slug for `:name` as jekyll-archives does for HTML archives.

### Default / unset slug_mode

When archives is absent or `slug_mode` is unset / default, category path slugification matches today's behavior.

## Requirements

1. Soft-read `jekyll-archives.slug_mode` when present and pass it to `Jekyll::Utils.slugify` for built-in category `:name` substitution.
2. Preserve current behavior when `slug_mode` is absent or default.
3. Update README Category Paths so it no longer claims custom `slug_mode` is out of scope for v1.
4. Cover with tests; keep 100% line and mutation coverage.

## Constraints

1. Built-in category paths only — no consumer scope-builder helpers, no tag/author builders in the gem.
2. No hard dependency on jekyll-archives; soft-read only.
3. No gem-owned slug_mode config knob.

## Acceptance Criteria

1. With `categories` enabled and archives `slug_mode` set to a non-default mode, a category whose slug differs under that mode writes under the archives-matching path.
2. Without archives / without `slug_mode`, existing category path tests and behavior stay green.
3. README documents that `slug_mode` is honored when present.
4. `bundle exec rake test` and `bundle exec mutant run` both pass.
