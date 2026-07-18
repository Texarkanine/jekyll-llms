# Project Brief

## User Story

As a Jekyll site operator, I want scoped LLM artifact generation to honor `llms_txt` / `llms_full` and to fail clearly on bad custom scopes so that disabling indexes is consistent everywhere and custom builders cannot silently overwrite or mangle paths.

## Use-Case(s)

### Use-Case 1

With `categories: true` (or `collection_indexes` / custom builders) and `llms_txt: false`, no `llms.txt` is written at root or under any scope; `llms_full: true` may still write full indexes.

### Use-Case 2

A custom scope builder returns a `path_prefix` without a trailing slash; the gem still writes `…/llms.txt` under that prefix.

### Use-Case 3

Two scopes share the same effective output prefix; the build fails with a clear error instead of silently overwriting.

## Requirements

1. Gate scoped `llms.txt` writes on `config.llms_txt?` (same as root).
2. Gate scoped `llms-full.txt` writes on `config.llms_full?` (already true; keep).
3. Normalize `path_prefix` before joining filenames so missing trailing slashes cannot produce paths like `/tags/foolms.txt`.
4. Reject duplicate active scope path prefixes before writing; raise a clear error.
5. Update README so flag semantics match: categories/collections bring scopes into play; `llms_txt` / `llms_full` / `markdown` control what is generated for each scope.
6. Push fixes to `cats-and-colls`; when done, merge only product code into `cats-and-colls-polish` (no memory-bank, `.cursor`, ai-rizz, etc.).

## Constraints

1. 100% line coverage (`bundle exec rake test`) and 100% mutation coverage (`bundle exec mutant run`).
2. TDD; do not stub/mock the system under test; no Mutant ignores.
3. Fail-fast for raising scope builders remains (do not rescue/skip).

## Acceptance Criteria

1. `llms_txt: false` yields no `llms.txt` anywhere, including category/collection/custom scopes.
2. `llms_txt: false` + `llms_full: true` yields only full indexes (root and scoped when scopes enabled).
3. Custom `path_prefix` without trailing `/` still produces correct filenames.
4. Duplicate `path_prefix` among non-empty scopes raises a clear error.
5. README documents the corrected flag semantics.
6. Changes are on `cats-and-colls` and pushed; code-only cherry/merge into `cats-and-colls-polish`.
