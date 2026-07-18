# Progress

Soft-read jekyll-archives `slug_mode` for built-in category scoped index paths so `:name` matches archives HTML URLs; update README; keep coverage at 100%.

**Complexity:** Level 1

## 2026-07-18 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Validated intent: built-in categories only; soft-read `slug_mode`; docs; no consumer helper API
    - Determined Level 1 — isolated path-parity fix in category slugification
* Decisions made
    - Level 1 (skip plan/creative/preflight/reflect/archive)
* Insights
    - Completing the archives soft-read contract, not adding a new product surface

## 2026-07-18 - BUILD - READY

* Work completed
    - Leaving COMPLEXITY-ANALYSIS; entering Level 1 Build
* Decisions made
    - Proceed directly to build (L1 skips plan/creative/preflight)

## 2026-07-18 - BUILD - COMPLETE

* Work completed
    - Added `Config#category_slug_mode` soft-read; wired into `ScopeEnumerator#category_path`
    - Tests for nil default and ascii `Café` → `/category/caf/`
    - README documents slug_mode soft-read
    - Verified 100% line + mutation coverage
* Decisions made
    - Pass `mode:` through to `Utils.slugify` (nil behaves as default)
* Insights
    - Completing the archives path soft-read; no gem-owned slug_mode knob
