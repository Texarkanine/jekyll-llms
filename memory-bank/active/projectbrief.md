# Project Brief

## User Story

As a Jekyll site operator (e.g. of `../devblog`), I want to register additional scoped LLM indexes for aggregations the gem does not know about (tags, authors, custom archives) so that those archive URLs get `llms.txt` / optional `llms-full.txt` beside the human indexes, without forking the gem or duplicating its write path.

## Use-Case(s)

### Consumer-contributed scopes

A site `_plugin` registers a scope builder that returns `Scope` objects (path prefix + entry subset). On `post_write`, the gem writes scoped indexes for those scopes using the same Index / FullIndex path as built-in category/collection scopes.

### Tag / author indexes (consumer-side)

`../devblog` (or any site) registers builders that subset the root `EntrySet` by `site.tags` / author membership and emit artifacts under tag/author archive path prefixes. The gem itself does not ship built-in tag or author indexes.

## Requirements

1. Implement Option B from `memory-bank/active/creative/creative-scope-builder-extension.md`: `Jekyll::Llms.register_scope_builder` / `scope_builders` / `reset_scope_builders!`.
2. `SiteWriter#write_scopes` concatenates built-in `ScopeEnumerator` scopes with builder results and writes with the existing index/full path.
3. Builders always run (not gated on `categories?` / `collection_indexes?`); those flags remain enumerator-only.
4. Prefer gem-side skip of empty contributed scopes (match built-in enumerator).
5. Document the extension point for consumers (README / API sketch as in the creative).
6. Keep membership “filter once”: builders receive and should subset the root `entries` list.

## Constraints

1. Design is already decided in the creative (Option B); do not reopen A/C/D unless blocked.
2. No built-in tag/author indexes, no entry-source registry, no fat write-context callback.
3. Unused registry is a no-op; existing sites unchanged.
4. 100% line coverage and 100% mutation coverage (`AGENTS.md`).
5. KISS / YAGNI — minimal additive surface on the current category/collection write path.

## Acceptance Criteria

1. Registering a builder causes scoped `llms.txt` (and `llms-full.txt` when enabled) at the contributed path prefixes for non-empty scopes.
2. With no builders registered, behavior matches current built-in-only scopes.
3. `reset_scope_builders!` clears the registry for tests.
4. README documents how a consumer registers a builder (tag sketch sufficient).
5. `bundle exec rake test` and `bundle exec mutant run` both pass.
