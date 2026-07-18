---
task_id: scope-builder-extension
date: 2026-07-18
complexity_level: 2
---

# Reflection: scope-builder-extension

## Summary

Shipped a minimal `register_scope_builder` registry so consumers can contribute scoped `llms.txt` / `llms-full.txt` write targets; SiteWriter merges them with built-in scopes. 100% line and mutation coverage.

## Requirements vs Outcome

Delivered Option B as briefed: registry API, ungated builders, empty-scope skip, README consumer sketch. No built-in tag/author indexes (correctly out of scope). Mutant work added tests beyond the initial list but did not expand product scope.

## Plan Accuracy

Plan sequence and files were right. Surprises were mutant-only: `reset` to `[]` vs `nil`, `Array()` vs wrap/bare call, `next` vs `break` on empty scopes, and unused `site`/`config` builder args.

## Build & QA Observations

Build was smooth once registry + merge landed; iteration was almost entirely mutation kills. QA was clean aside from a one-line systemPatterns sync.

## Insights

### Technical
- Global registries cleared with `nil` pair better with `||= []` than assigning `[]`, or teardown masks lazy-init mutants.
- `next` vs `break` on empty contributed scopes only shows up when an empty scope precedes a non-empty one in the same builder result.

### Process
- Nothing notable — L2 with a locked creative was the right level; creative-first scope creep avoided a second design loop.

### Million-Dollar Question

If scope contribution had been assumed from the start, category/collection enumeration would likely be the first built-in builders registered on the same registry, with `ScopeEnumerator` as one implementation rather than a parallel path. What we shipped is the reversible half of that design; folding built-ins onto the registry can wait until a second consumer needs it.
