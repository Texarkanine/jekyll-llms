# Current Task: archives-category-slug-mode

**Complexity:** Level 1

## Fix

- [x] Soft-read `jekyll-archives.slug_mode` via `Config#category_slug_mode`
- [x] Pass mode into `Utils.slugify` in `ScopeEnumerator#category_path`
- [x] Tests: config nil/absent + ascii present; enumerator path for `Café` → `/category/caf/`
- [x] README Category Paths documents `slug_mode` soft-read
- [x] `bundle exec rake test` — 82 tests, 100% line coverage
- [x] `bundle exec mutant run` — 100% mutation coverage

### What broke / why

Built-in category paths soft-read archives permalink templates but always slugified with Jekyll's default mode, so non-default `slug_mode` sites got LLM indexes on a different path than HTML archives.

### What changed

| File | Change |
|------|--------|
| `lib/jekyll/llms/config.rb` | `category_slug_mode(site)` soft-read |
| `lib/jekyll/llms/scope_enumerator.rb` | `Utils.slugify(name, mode: …)` |
| `test/jekyll/llms/config_test.rb` | slug_mode reader tests |
| `test/jekyll/llms/scope_enumerator_test.rb` | ascii path assertion |
| `README.md` | document slug_mode; remove v1 caveat |
