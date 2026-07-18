---
task_id: category-collection-llms-indexes
date: 2026-07-17
complexity_level: 3
---

# Reflection: category-collection-llms-indexes

## Summary

Shipped optional root `llms-full.txt` plus per-category and per-collection scoped `llms.txt` / `llms-full.txt`, reusing `EntrySet`, with category paths soft-read from jekyll-archives or defaulting to `/category/:name/`. Line and mutation coverage both at 100%.

## Requirements vs Outcome

Delivered every acceptance criterion in the brief: three opt-in flags (default false), archives soft-read without a gem path knob, collection paths under `/{label}/`, filter-once membership, Index/FullIndex split, and no author/tag/HTML-archive scope. No requirements dropped; no scope creep added.

## Plan Accuracy

The ordered TDD units (Config → Index → FullIndex → ScopeEnumerator → SiteWriter → README → verify) matched the real dependency order. Challenges that materialized were mostly mutation surface (flag guards, empty-scope skips, `pages`/`posts` exclusion) rather than the pre-mortem risks — those were already mitigated by the supersession table and preflight. Surprise cost was mutant iteration on ScopeEnumerator/SiteWriter, not redesign.

## Creative Phase Review

Option A (native scopes over EntrySet) held up cleanly. The creative doc’s path/config shape (`category_permalink`, plural `/categories/`) was correctly superseded before build; treating creative as guidance avoided shipping YAGNI. Soft-read-as-only-customization was the right call once intent clarification landed.

## Build & QA Observations

Build was straightforward once the contract was pinned; the long pole was killing mutants that revealed redundant SiteWriter guards already enforced by ScopeEnumerator/FullIndex (simplify) versus missing observations (tests). QA was clean — one trivial README intro sync; no substantive findings.

## Cross-Phase Analysis

Intent clarification → creative supersession in the plan → preflight encoding of tests-first steps prevented the main pre-mortem failure mode (shipping creative path shape). Preflight’s advisory on `slug_mode` became a README note without blocking build. Planning the “filter once” invariant kept scoped indexes from re-implementing include/exclude.

## Insights

### Technical
- When a later stage already filters (enumerator flags, FullIndex nil/empty bodies), an earlier guard often survives mutation — prefer one owner of each rule over layered identical checks.
- Mutant’s `cover` mapping means optional kwargs used only from another class’s tests may not be selected for the callee’s subject; kill those defaults from the class’s own unit tests.

### Process
- Recording creative supersession explicitly in `tasks.md` (not just chat) stopped “creative said so” drift during build and QA.
