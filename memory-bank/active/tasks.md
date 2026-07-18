# Task: category-collection-llms-indexes

* Task ID: category-collection-llms-indexes
* Complexity: Level 3
* Type: feature

Optional root `llms-full.txt` plus per-category and per-collection scoped `llms.txt` / `llms-full.txt`, reusing `EntrySet`. Category paths soft-read from jekyll-archives when present, else `/category/:name/`.

## Creative Supersession

`memory-bank/active/creative/creative-category-collection-llms-indexes.md` was **guidance**, not the final contract. Intent clarification superseded these creative details:

| Creative said | Plan / build uses |
|---------------|-------------------|
| `category_permalink` config | **Removed** — YAGNI |
| Default `/categories/:name/` (plural) | **`/category/:name/`** — match jekyll-archives stock default |
| Optional archives read as convenience beside own config | Soft-read **only** source of customization (no gem path knob) |
| Suggested module split | Keep — `Scope`, `ScopeEnumerator`, `FullIndex`, thin `Config`/`SiteWriter`/`Index` |

Architecture Option A (native scopes over `EntrySet`) still stands. Path/config shape does not.

## Pinned Info

### Write pipeline

Shows how scoped writes reuse one filtered entry list.

```mermaid
flowchart TD
  Hook["site post_write"] --> SW[SiteWriter]
  SW --> ES[EntrySet]
  ES --> Entries["filtered Entry list"]
  SW --> MD[Markdown sidecars]
  SW --> RootIdx["root llms.txt"]
  SW --> RootFull["root llms-full.txt"]
  SW --> Scopes[ScopeEnumerator]
  Scopes --> Cat["categories + path template"]
  Scopes --> Col["included collections + /label/"]
  Cat --> ScopedWrite["scoped llms.txt + llms-full.txt"]
  Col --> ScopedWrite
  Entries --> RootIdx
  Entries --> RootFull
  Entries --> ScopedWrite
```

## Component Analysis

### Affected Components

- `Config`: defaults + predicates for markdown/llms_txt/include/exclude → add `llms_full?`, `categories?`, `collection_indexes?`, and `category_permalink_template(site)` (or equivalent reader that digs archives then falls back).
- `Index`: root title/description from site config → accept optional `title:` / `description:` for scopes.
- `FullIndex` (new): render concatenated Markdown corpus for a set of entries.
- `Scope` (new): value object `{ path_prefix, title, description, entries }`.
- `ScopeEnumerator` (new): build category + collection scopes from site + config + root entries.
- `SiteWriter`: orchestrate root index/full + scopes; leave HTML linker on document sidecars only.
- `lib/jekyll/llms.rb`: require new constants.
- `README.md`: document the three new flags and category path behavior.

### Cross-Module Dependencies

- `SiteWriter` → `EntrySet` → entries (unchanged membership).
- `SiteWriter` → `ScopeEnumerator` → scopes (subset of entries + path/title).
- `SiteWriter` → `Index` / `FullIndex` → string content → `FileWriter`.
- `ScopeEnumerator` → `Config` for flags + category path template; → `site.categories` / `site.collections` for membership/labels.
- `FullIndex` → needs Markdown body per entry (reuse `MarkdownSource` or bodies already written — prefer reading via `MarkdownSource` at write time for entries that are markdown sources; omit HTML-only from full).

### Boundary Changes

- Public operator config grows three booleans (`llms_full`, `categories`, `collection_indexes`).
- Soft-read of `site.config["jekyll-archives"]["permalinks"]["category"]` when present (string with `:name`).
- No new gem dependency.

### Invariants & Constraints

- Must preserve root `llms.txt` / sidecar / HTML linker behavior when new flags are false.
- Must filter once via `EntrySet`; scopes only subset that list.
- Must not require jekyll-archives to be installed.
- Must keep 100% line + mutation coverage.
- Must not add `category_permalink` or author/tag/HTML-archive-linker scope.

## Open Questions

- [x] Category path config vs archives → Resolved: no gem path config; soft-read archives permalink; default `/category/:name/` (intent clarification; **supersedes creative**)
- [x] Architecture → Resolved: Option A native scopes (creative; still valid)
- [x] Full corpus format → Resolved: H1 scope title; per markdown entry H2 title + body; omit HTML-only from full; blank line between entries (creative guidance, tightened)
- [x] `:name` slugification → Resolved: `Jekyll::Utils.slugify(category_name)` so paths align with jekyll-archives default slug behavior

None unresolved — no creative phase re-entry required.

## Test Plan (TDD)

### Behaviors to Verify

- Config defaults: new flags false; predicates reflect merges.
- Config category template: absent archives → `/category/:name/`; present → configured string.
- Index: optional title/description overrides appear in output; root behavior unchanged without overrides.
- FullIndex: concatenates markdown entries; omits non-markdown; uses scope title as H1.
- ScopeEnumerator categories: one scope per `site.categories` key; entries intersect EntrySet; path uses template + slugified name.
- ScopeEnumerator collections: one scope per included writeable collection label (not pages/posts); path `/{label}/`.
- ScopeEnumerator flags off: empty scopes.
- SiteWriter: `llms_full` writes `/llms-full.txt`; `categories` writes category paths; `collection_indexes` writes collection paths; combination with archives config; flags false → no new files.
- Edge: excluded / `llms: false` post in a category → absent from scoped index.
- Edge: empty category after filter → still write empty-ish index or skip? → **skip writing scopes with zero entries** (KISS, avoid empty noise).

### Test Infrastructure

- Framework: Minitest + `mutant/minitest/coverage`
- Test location: `test/jekyll/llms/`
- Conventions: `*_test.rb`, `cover "Jekyll::Llms::..."`, `build_site` helper in `test_helper.rb`
- New test files: `test/jekyll/llms/full_index_test.rb`, `test/jekyll/llms/scope_enumerator_test.rb` (Scope can be covered via enumerator or a tiny `scope_test.rb` if needed)

### Integration Tests

- `site_writer_test.rb`: end-to-end fixture site with posts in categories + a garden collection; assert dest paths and content snippets.
- Config archives soft-read via unit test with struct site (no need to load jekyll-archives gem).

## Implementation Plan

1. **Config flags + category template** (TDD)
    - Files: `lib/jekyll/llms/config.rb`, `test/jekyll/llms/config_test.rb`
    - Changes: DEFAULTS for three booleans; predicates; `category_path_template` reading archives then `/category/:name/`
    - Creative ref: superseded path decision (see Creative Supersession)

2. **Index title/description overrides** (TDD)
    - Files: `lib/jekyll/llms/index.rb`, `test/jekyll/llms/index_test.rb`
    - Changes: `initialize(..., title: nil, description: nil)` falling back to site config

3. **FullIndex** (TDD)
    - Files: `lib/jekyll/llms/full_index.rb` (new), `test/jekyll/llms/full_index_test.rb` (new)
    - Changes: `content` renderer; caller supplies title + entries with bodies (or FullIndex calls MarkdownSource — prefer SiteWriter passes precomputed body hash / only markdown entries with content strings to keep FullIndex pure)

4. **Scope + ScopeEnumerator** (TDD)
    - Files: `lib/jekyll/llms/scope.rb`, `lib/jekyll/llms/scope_enumerator.rb` (new), tests
    - Changes: enumerate category/collection scopes; filter entries; build path prefixes; slugify `:name`

5. **SiteWriter orchestration** (TDD)
    - Files: `lib/jekyll/llms/site_writer.rb`, `test/jekyll/llms/site_writer_test.rb`, `lib/jekyll/llms.rb`
    - Changes: write root full; write scoped index/full; require new files

6. **README**
    - Files: `README.md`
    - Changes: document flags + category path / archives soft-read

7. **Verification**
    - `bundle exec rake test` then `bundle exec mutant run`

## Technology Validation

No new technology - validation not required

## Challenges & Mitigations

- **Category key vs URL slug mismatch**: Mitigate with `Jekyll::Utils.slugify`; document that custom `slug_mode` in archives is out of scope for v1 (stock default only).
- **FullIndex needing rendered bodies**: Mitigate by reusing `MarkdownSource` in SiteWriter when writing full (same rescue/skip as sidecars); omit failed/HTML-only entries from full.
- **Mutation surface growth**: Keep Scope/FullIndex thin; prefer simplifying over exotic tests; follow `AGENTS.md` A/B rule.
- **Empty scopes**: Skip zero-entry scopes to avoid littering dest.

## Pre-Mortem

- **Shipped `category_permalink` or plural default “because creative said so”**: Plan already records supersession; preflight must reject drift back to creative path shape.
- **Scoped indexes re-implement include/exclude**: Invariant “filter once”; enumerator only intersects EntrySet with category/collection membership.
- **Soft-read treated as hard dependency**: Tests use plain config hashes; no gem add in gemspec.
- **PR bloat (authors, tags, HTML archive links)**: Explicit non-goals in brief; preflight checks scope.

## Status

- [x] Component analysis complete
- [x] Open questions resolved
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
