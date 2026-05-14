# Changelog

All notable changes to the Fallout Dialogue Creator project are documented in this file.

## [1.0.0] — 2026-05-14

### Fixed
- **`uNodeCanvas.pas(585): E2003 Undeclared identifier: 'accent'`** — Added `accent` to local var declaration in `DrawNode`
- Removed dead code: stale `accent` assignment using `NODE_ACCENT_COLORS` (now theme-driven) and unused loop counter `i` in `DrawNodeBody`
- Fully removed CRT scanline effect from `TNodeCanvas.DrawScanlines` — hindered text readability
- Node body/header backgrounds now use theme colors (`BgMedium`/`BgLight`) instead of per-type hardcoded `node.Color`
- Fixed `DrawNodeHeader` signature to accept `headerColor` parameter for consistent theming

### Changed
- `uNodeCanvas.pas` — Theme-driven rendering throughout; removed hardcoded color lookups
- `PROGRESS.md` — Deduplicated entries, added 2026-05-14 bug fix entry
- `README.md` — Removed scanline reference from feature list