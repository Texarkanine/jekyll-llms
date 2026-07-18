# Task: scope-builder-extension

* Task ID: scope-builder-extension
* Complexity: Level 2
* Type: simple enhancement

Minimal consumer extension: `Jekyll::Llms.register_scope_builder` registry; `SiteWriter#write_scopes` merges builder-produced `Scope`s with `ScopeEnumerator` results and writes scoped `llms.txt` / optional `llms-full.txt`. Design locked in `memory-bank/active/creative/creative-scope-builder-extension.md` (Option B).

## Test Plan (TDD)

### Behaviors to Verify

- Register append: `register_scope_builder { … }` → builder appears in `scope_builders` (ordered; multiple builders accumulate)
- Reset: `reset_scope_builders!` → `scope_builders` is empty
- Contributed write: register builder returning one non-empty `Scope` → `SiteWriter` writes `{path_prefix}llms.txt` with that scope’s entries
- Full corpus: same + `llms_full: true` → also writes `{path_prefix}llms-full.txt`
- Empty skip: builder returns a `Scope` with empty `entries` → no files written for that scope
- Ungated: builders run when `categories` / `collection_indexes` are false → contributed scopes still written
- Coexistence: built-in scopes enabled + builder → both sets of paths written
- No builders: registry empty → behavior unchanged vs current built-in-only scopes (existing tests remain green)
- Array coercion: builder returns a single `Scope` (not an Array) → still written (`Array(…)`)

### Test Infrastructure

- Framework: Minitest + `mutant/minitest/coverage` (`cover "…"`)
- Test location: `test/`
- Conventions: `test/jekyll/llms/<unit>_test.rb` or `test/jekyll_llms_test.rb` for `Jekyll::Llms`; fixtures via `build_site` / `build_site_without_plugin_output` in `test/test_helper.rb` and support helpers
- New test files: none preferred — extend `test/jekyll_llms_test.rb` (registry API) and `test/jekyll/llms/site_writer_test.rb` (write merge). Add `teardown` / helper reset of builders in `test/test_helper.rb` so registry never leaks across tests

## Implementation Plan

1. **Registry API tests (failing)**
   - Files: `test/jekyll_llms_test.rb`, `test/test_helper.rb`
   - Changes: tests for `scope_builders` / `register_scope_builder` / `reset_scope_builders!` (order + reset); global teardown calls `reset_scope_builders!`

2. **Registry API implementation**
   - Files: `lib/jekyll/llms.rb`
   - Changes: add class methods per creative (`scope_builders`, `register_scope_builder`, `reset_scope_builders!`)

3. **SiteWriter contributed-scope tests (failing)**
   - Files: `test/jekyll/llms/site_writer_test.rb`
   - Changes: register builders that subset entries and assert path writes; cover empty skip, ungated flags, coexistence with categories, `llms_full`, single-Scope return
   - Registration timing: register *before* `build_site` when the post_write hook should fire once; use `build_site_without_plugin_output` + explicit `SiteWriter#write` only when the test must mutate `site.config["llms"]` after process (same pattern as existing full-index tests)

4. **SiteWriter merge implementation**
   - Files: `lib/jekyll/llms/site_writer.rb`
   - Changes: `write_scopes` iterates `built_in_scopes + extra_scopes` (or equivalent); `extra_scopes` = `Llms.scope_builders.flat_map { Array(_1.call(site, config, entries)) }`; skip when `scope.entries.empty?`

5. **README consumer docs**
   - Files: `README.md`
   - Changes: short “Custom scopes” section documenting `register_scope_builder` + tag-shaped sketch (authors note optional); clarify not gated on `categories` / `collection_indexes`; note empty scopes skipped; amend the `llms_full` bullet so it mentions contributed scopes too (today it only names category/collection)

6. **Verification**
   - Commands: `bundle exec rake test`, `bundle exec mutant run`
   - Changes: none beyond fixes required for green line + mutation coverage

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing `Scope`, `ScopeEnumerator`, `Index`, `FullIndex`, `SiteWriter#write_index` / `#write_full`
- Creative Option B API shape (no new gems)

## Challenges & Mitigations

- **Global registry leaks across tests / mutant**: Mitigate with `teardown` `reset_scope_builders!` in `test_helper`; keep reset method public for explicit test setup
- **Builders ignore EntrySet and invent membership**: Document invariant in README; gem trusts builders (same as creative); tests only assert subsetting when the registered builder subsets
- **Mutant kills on unused reset/append edges**: Ensure both register and reset are observed; assert order of multiple builders if needed for mutation survival

## Pre-Mortem

- **Plan treated this as needing another creative / Option C entry sources**: Scope cut stays firm — tags/authors are aggregations; entry sources out of scope (already briefed)
- **Devblog `_config.yaml` expected as gem knobs for tags/authors**: Clarified intent — consumer `_plugins` registration, not gem config flags; README sketch is the deliverable for consumer wiring
- **Empty-scope policy left to consumers and tests flake**: Plan already requires gem-side empty skip (Implementation step 4)

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [ ] Build
- [ ] QA

## Preflight Amendments

- Clarified builder registration timing vs `build_site` / `build_site_without_plugin_output`
- README step must update the existing `llms_full` config bullet for contributed scopes
