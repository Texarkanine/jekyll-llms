# Active Context

## Current Task: scope-builder-extension
**Phase:** BUILD - COMPLETE

## What Was Done
- Registry API on `Jekyll::Llms` (`register_scope_builder` / `scope_builders` / `reset_scope_builders!` → nil)
- `SiteWriter#write_scopes` merges built-in + contributed scopes; skips empty; always runs builders
- README Custom scopes section + `llms_full` wording
- 79 tests; 100% line; 100% mutation

## Files Modified
- `/home/mobaxterm/git/jekyll-llms/lib/jekyll/llms.rb`
- `/home/mobaxterm/git/jekyll-llms/lib/jekyll/llms/site_writer.rb`
- `/home/mobaxterm/git/jekyll-llms/test/jekyll_llms_test.rb`
- `/home/mobaxterm/git/jekyll-llms/test/jekyll/llms/site_writer_test.rb`
- `/home/mobaxterm/git/jekyll-llms/test/test_helper.rb`
- `/home/mobaxterm/git/jekyll-llms/test/jekyll/llms/file_writer_test.rb`
- `/home/mobaxterm/git/jekyll-llms/README.md`

## Key Decisions
- `reset_scope_builders!` assigns `nil` so `scope_builders` lazy-init via `||= []` is exercised (mutant)
- Empty-then-nonempty contributed scopes must continue (`next` not `break`)

## Deviations
- None material — mutant-driven tests expanded beyond the minimum plan list

## Next Step
- QA review (automatic per L2 workflow)
