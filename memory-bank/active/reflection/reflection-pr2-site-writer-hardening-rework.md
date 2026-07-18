---
task_id: pr2-site-writer-hardening-rework
date: 2026-07-18
complexity_level: 2
---

# Reflection: pr2-site-writer-hardening-rework

## Summary

Landed CodeRabbit items 1.2/2/3/4: fail-fast scope registration, uniq collection includes, validated path prefixes, and `super` in teardown. Coverage stayed at 100%.

## Requirements vs Outcome

All four rework items delivered. Memoize and FullIndex spacing stayed out of scope as requested.

## Plan Accuracy

Plan held. Item 4’s TestIsolation extract was correctly dropped once Mutant subject scope was checked. Path-prefix mutants needed an empty-segment duplicate test that the plan foreshadowed but did not spell out.

## Build & QA Observations

Build spent most of its time killing `normalized_path_prefix` message/segment mutants. QA only needed a README wording update.

## Insights

### Technical
- Trailing-slash normalization is not enough for duplicate detection when builders can emit `//`-style prefixes; empty segments must collapse first.

### Process
- Nothing notable

### Million-Dollar Question

Path validation belongs next to the write surface (`SiteWriter`) rather than on `Scope` construction — builders stay free to assemble prefixes, and one gate enforces the contract before any dest write.
