# Current Task: pr2-site-writer-hardening

**Complexity:** Level 1

## Fix

- **What broke:** Scoped `llms.txt` ignored `llms_txt: false`; custom `path_prefix` without `/` mangled filenames; duplicate prefixes silently overwrote.
- **Why:** `write_scopes` always called `write_index`; string-concatenated prefixes; no uniqueness check.
- **What changed:** Gate scoped index/full writes on config flags; normalize prefixes; `group_by` + raise on duplicate prefixes; README flag semantics.
- **Files:** `lib/jekyll/llms/site_writer.rb`, `test/jekyll/llms/site_writer_test.rb`, `README.md`

## QA

- **Result:** PASS
- KISS/DRY/YAGNI/completeness/regression/integrity/docs: clean
