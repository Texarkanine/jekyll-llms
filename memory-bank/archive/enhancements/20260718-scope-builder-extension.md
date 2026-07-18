---
task_id: scope-builder-extension
complexity_level: 2
date: 2026-07-18
status: completed
---

# TASK ARCHIVE: scope-builder-extension

## SUMMARY

Shipped a minimal `Jekyll::Llms.register_scope_builder` registry so consumers can contribute scoped `llms.txt` / `llms-full.txt` write targets. `SiteWriter#write_scopes` merges builder results with built-in `ScopeEnumerator` scopes. 100% line and mutation coverage. Design locked as creative Option B (scope-builder registry over compose-alongside, entry-source registry, or fat write-context callback).

## REQUIREMENTS

### User story

As a Jekyll site operator, I want to register additional scoped LLM indexes for aggregations the gem does not know about (tags, authors, custom archives) so those archive URLs get `llms.txt` / optional `llms-full.txt` without forking the gem.

### Functional requirements (all met)

1. `register_scope_builder` / `scope_builders` / `reset_scope_builders!` (Option B).
2. `SiteWriter#write_scopes` concatenates built-in scopes with builder results; same Index / FullIndex write path.
3. Builders always run (not gated on `categories?` / `collection_indexes?`).
4. Gem-side skip of empty contributed scopes.
5. README documents consumer registration (tag-shaped sketch).
6. Builders receive and should subset the root `entries` list (filter once).

### Constraints

- No built-in tag/author indexes, no entry-source registry, no fat write-context callback.
- Unused registry is a no-op; existing sites unchanged.
- 100% line and mutation coverage.

## IMPLEMENTATION

### Architecture (creative Option B)

Creative selected **Option B — Scope-builder registry** over A (compose-alongside), C (+ entry sources), and D (fat callback). Tags/authors are aggregations over documents already in `EntrySet`; scope injection is the load-bearing need.

### Key files

| File | Change |
|------|--------|
| `lib/jekyll/llms.rb` | `scope_builders`, `register_scope_builder`, `reset_scope_builders!` (`nil` clear for `\|\|= []`) |
| `lib/jekyll/llms/site_writer.rb` | `extra_scopes` via `flat_map` + `Array(...)`; empty scopes `next` |
| `test/jekyll_llms_test.rb` | Registry API tests |
| `test/jekyll/llms/site_writer_test.rb` | Contributed write, empty skip, ungated, coexistence, Array coercion |
| `test/test_helper.rb` | Teardown `reset_scope_builders!` |
| `README.md` | Custom scopes section; `llms_full` bullet mentions contributed scopes |

### Behavioral edges that mattered for mutant

- `reset` to `nil` (not `[]`) so lazy `||= []` init stays observable.
- `Array(builder.call)` needs array-return and nil-return tests.
- Empty-scope policy must use `next` (not `break`) so a later non-empty scope in the same result still writes.
- Builder `site` / `config` args need builders that read them.

## TESTING

- TDD plan executed: registry tests → registry impl → SiteWriter merge tests → merge impl → README → verify.
- Preflight PASS; QA PASS (semantic review vs brief/creative/plan).
- Final verification: 79 tests, `bundle exec rake test` and `bundle exec mutant run` both green at 100%.

## LESSONS LEARNED

- Global registries cleared with `nil` pair better with `||= []` than assigning `[]`, or teardown masks lazy-init mutants.
- `next` vs `break` on empty contributed scopes only shows up when an empty scope precedes a non-empty one in the same builder result.
- L2 with a locked creative was the right level; creative-first avoided a second design loop.

## PROCESS IMPROVEMENTS

Nothing notable for this run — locked creative + linear TDD plan held. Mutant-driven tests expanded coverage beyond the initial behavior list without expanding product scope; keep treating that as expected for this repo’s coverage bar.

## TECHNICAL IMPROVEMENTS

If scope contribution had been assumed from the start, category/collection enumeration would likely be the first built-in builders on the same registry, with `ScopeEnumerator` as one implementation rather than a parallel path. What shipped is the reversible half of that design; folding built-ins onto the registry can wait until a second consumer needs it.

Deferred (from creative, still valid): `register_entry_source` for non-collection documents; optional per-scope artifact flags; extract `ScopeWriter` only if duplication appears.

## NEXT STEPS

None for the gem. Consumer wiring (e.g. `../devblog` tag/author builders via `_plugins`) is outside this archive.
