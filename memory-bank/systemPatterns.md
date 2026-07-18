# System Patterns

## How This System Works

`jekyll-llms` is a thin post-build writer. On `:site, :post_write`, `Jekyll::Llms.write` builds a filtered list of `Entry` objects from the live `site`, then writes artifacts into `site.dest`. Membership (what counts as an LLM-visible document) is decided once in `EntrySet` via `include` / `exclude` / per-item `llms: false`. Renderers (`Index`, Markdown sidecars, HTML linker) consume that list; they should not invent a second include/exclude story.

The load-bearing assumption: **filter once, write many**. New output formats should reuse the same `Entry` list (or a subset of it), not re-walk `site.pages` / collections with their own rules. Violating that duplicates edge cases and drifts from root `llms.txt` behavior.

## Post-write dest writer

Artifacts are written after Jekyll has already rendered the site. Paths are relative to `site.dest`. The gem does not register generators that invent new Jekyll pages for indexes; it writes files beside whatever HTML already exists (or would exist).

Evidence: `lib/jekyll/llms.rb` hook, `SiteWriter`, `FileWriter`.

## Config as merged defaults bag

`Config.from_site` merges operator `llms:` over a frozen `DEFAULTS` hash and exposes typed predicates/readers. New knobs should stay boolean-or-list shaped and default to preserving today's root behavior when unset/false.
