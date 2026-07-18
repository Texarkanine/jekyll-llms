# Project Brief

## User Story

As a Jekyll site operator, I want optional per-category and per-collection `llms.txt` / `llms-full.txt` indexes (plus a root `llms-full.txt`) so that LLM consumers can fetch scoped corpora beside the human HTML indexes I already publish.

## Use-Case(s)

### Root full corpus

With `llms.llms_full: true`, the build emits `/llms-full.txt` concatenating Markdown bodies for root-included entries.

### Category scopes

With `llms.categories: true`, each key in `site.categories` gets `llms.txt` and (when `llms_full`) `llms-full.txt` under the category archive path, listing only entries that are both in that category and in the root `EntrySet`.

### Collection scopes

With `llms.collection_indexes: true`, each included writeable collection (not `pages`/`posts`) gets the same pair of files under `/{label}/`.

## Requirements

1. Add boolean config flags: `llms_full`, `categories`, `collection_indexes` (all default `false`).
2. Category path: use `jekyll-archives.permalinks.category` when present; otherwise default to `/category/:name/` (jekyll-archives stock default). No gem-owned `category_permalink` config.
3. Collection path: `/{label}/` for included writeable collections.
4. Reuse the existing `EntrySet` filter; scoped indexes never publish entries the root index would refuse.
5. Reuse / lightly generalize `Index` for scoped titles/descriptions; add a `FullIndex` (or equivalent) for concatenation.
6. Keep the PR tight: no author/tag indexes, no HTML alternate links on archive pages, no root-index links to scopes.

## Constraints

1. KISS / DRY / YAGNI — no duplicate path config; soft-read archives only.
2. No hard dependency on `jekyll-archives`.
3. Root `llms.txt` / Markdown sidecar / HTML linker behavior unchanged when new flags are false.
4. 100% line coverage and 100% mutation coverage (`AGENTS.md`).
5. Prior creative doc is guidance only; plan reflects the superseding design decisions from intent clarification.

## Acceptance Criteria

1. Flags default false; existing tests and root behavior stay green without new config.
2. Enabling `categories` writes `/category/{name}/llms.txt` (or archives-configured path) with only that category’s included entries.
3. Enabling `collection_indexes` writes `/{label}/llms.txt` for included writeable collections.
4. Enabling `llms_full` writes `llms-full.txt` at root and at each enabled scope.
5. When `jekyll-archives.permalinks.category` is set, category artifacts use that template.
6. `bundle exec rake test` and `bundle exec mutant run` both pass.
