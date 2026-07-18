# Task: pr2-site-writer-hardening-rework

* Task ID: pr2-site-writer-hardening-rework
* Complexity: Level 2
* Type: bug fix / hardening

Address CodeRabbit review items 1.2, 2, 3, and 4: fail-fast `register_scope_builder` without a block; uniq collection include labels; canonicalize/validate scope path prefixes; call `super` in test teardown.

## Test Plan (TDD)

### Behaviors to Verify

- [Item 1.2]: `Jekyll::Llms.register_scope_builder` with no block → raises `ArgumentError`; registry unchanged
- [Item 1.2 regression]: `register_scope_builder { … }` still appends and returns the block
- [Item 2]: `collection_indexes: true` with `include: [garden, garden]` (writable collection with entries) → exactly one `/garden/` scope; no duplicate-prefix error at write time
- [Item 3]: custom scope `path_prefix` with `..` segment (e.g. `/tags/../evil/`) → raises clear `ArgumentError` before write
- [Item 3]: custom scope `path_prefix` with `.` segment (e.g. `/tags/./fable/`) → raises (or canonicalizes to `/tags/fable/` — prefer reject for clarity)
- [Item 3]: empty or root-only prefix (`""` / `"/"`) → raises `ArgumentError`
- [Item 3]: `/tags/fable` and `/tags/./fable/` treated as the same effective prefix for duplicate detection (if `.` is rejected at normalize, duplicate via `./` is covered by reject; if canonicalize collapses `.`, duplicate of `/tags/fable/` vs `/tags/./fable/` raises duplicate)
- [Item 3 regression]: existing trailing-slash normalization and duplicate `/category/fable` vs `/category/fable/` still pass
- [Item 4]: `teardown` invokes `super` (observable via a test subclass that records superclass teardown, or by asserting method source / that Minitest lifecycle still runs — prefer a tiny subclass in `test_helper` test or `jekyll_llms_test` that overrides teardown to set a flag when `super` is called from our hook)

### Edge Cases

- Duplicate include with pages/posts labels only: still no collection scopes (unchanged)
- Path with Windows-style separators: not required (Jekyll paths are POSIX-style)
- `register_scope_builder(&nil)` / explicit nil proc: raising when `block` is nil covers both missing block and `&nil`

### Test Infrastructure

- Framework: Minitest (`bundle exec rake test`)
- Test location: `test/`
- Conventions: `cover "Jekyll::Llms::…"`, fixture helpers in `test_helper` / per-file helpers, `build_site` for integration
- New test files: none — extend `test/jekyll_llms_test.rb`, `test/jekyll/llms/scope_enumerator_test.rb`, `test/jekyll/llms/site_writer_test.rb`; item 4 may live in `test/jekyll_llms_test.rb` or a small assertion colocated with helper usage

## Implementation Plan

1. **Fail-fast register without block (item 1.2)**
   - Files: `test/jekyll_llms_test.rb`, `lib/jekyll/llms.rb`
   - Changes: failing test for no-block → `ArgumentError`; implement `raise ArgumentError, "…" unless block`; keep return/append behavior

2. **Dedupe collection include labels (item 2)**
   - Files: `test/jekyll/llms/scope_enumerator_test.rb`, optionally `test/jekyll/llms/site_writer_test.rb` for write-path smoke, `lib/jekyll/llms/scope_enumerator.rb`
   - Changes: test with `include: %w[garden garden]`; implement `config.includes.uniq.filter_map`

3. **Canonicalize/validate path prefixes (item 3)**
   - Files: `test/jekyll/llms/site_writer_test.rb`, `lib/jekyll/llms/site_writer.rb`
   - Changes: expand `normalized_path_prefix` to split on `/`, reject empty-after-normalize (root), reject `.` and `..` segments, rejoin with leading `/` and trailing `/`; use for both uniqueness and write paths; raise `ArgumentError` with prefix in message

4. **Call `super` in teardown (item 4)**
   - Files: `test/test_helper.rb`, plus a small test that proves `super` is invoked (subclass pattern)
   - Changes: add `super` after `reset_scope_builders!`

5. **Verify**
   - `bundle exec rake test` (100% line coverage)
   - `bundle exec mutant run` (100% mutation coverage; prefer `--fail-fast` while iterating)

6. **Delivery**
   - Push `cats-and-colls`
   - Cherry-pick product commit(s) onto `cats-and-colls-polish` (exclude memory-bank-only commits if separate)

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing Minitest + Mutant coverage requirements (`AGENTS.md`)
- No gem / dependency changes

## Challenges & Mitigations

- **Mutant on path normalization**: over-flexible canonicalize may leave mutants alive — keep validation strict (reject `.`/`..` rather than silently collapsing) so every branch is tested
- **Item 4 observability**: hard to assert `super` without a spy — use a one-off subclass in a test that overrides `Minitest::Test#teardown` chain, or test a dedicated helper; avoid stubbing SUT
- **Cherry-pick vs polish branch drift**: polish may already have overlapping SiteWriter changes — cherry-pick and resolve conflicts carefully; prefer a single focused product commit

## Pre-Mortem

- **Over-canonicalize breaks built-in category paths**: already covered — keep leading `/` + trailing `/`; only reject `.`/`..`/empty
- **Cherry-pick brings memory-bank onto polish**: plan response — isolate product fix in its own commit after memory-bank chore commits
- **Treating `.` collapse as success leaves duplicate-bypass untested**: prefer reject `.` so `/tags/./fable/` fails loudly (Challenge 1)

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
