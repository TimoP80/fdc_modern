# Changelog

All notable changes to the Fallout Dialogue Creator project are documented in this file.

## [1.0.5] — 2026-05-14

### Fixed
- **SSL imported nodes all positioned at (0,0)** — Added automatic hierarchical layout in `PostProcess` using BFS level assignment. Nodes now spread horizontally by dialogue depth (X = level × 300 + 50) and vertically by order within level (Y = index × 120 + 50). Works with complex scripts like `abraham.ssl`.

## [1.0.4] — 2026-05-14

### Fixed
- **SSL importer hang on regular if-statements** — `TryIf` was designed only for `skill_check` blocks. For plain `if (condition) then ...` lines (e.g., `if (dude_is_male)`), `TryIf` returned `False` but `ParseBody` still called `Continue` without advancing `FPos`, causing infinite loop. Fixed by making `TryIf` handle both `skill_check` and regular conditionals, always advancing `FPos` on entry and correctly skipping the entire block (including `else` branches). Now aborts with error on parse failure instead of hanging.

## [1.0.3] — 2026-05-14

### Fixed
- **SSL importer false-positive abort** — Removed `FMaxIterations` guard that incorrectly reported "Parser safety limit exceeded" on valid scripts. The guard was based on a counter that didn't correlate with actual line position and triggered early. All parser code paths now correctly advance `FPos`; natural loop exit condition (`FPos < FLines.Count`) is sufficient.

## [1.0.2] — 2026-05-14

### Fixed
- **SSL importer infinite loop** — `ParseBody` did not advance `FPos` after `TrySetStmt` matched, causing hang on any `set_*`, `give_*`, `float_msg`, etc. statement. Fixed by adding `Inc(FPos)` after `TrySetStmt` check.
- **Parser safety check false positives** — Replaced intrusive iteration counter with simple `FPos`-based guard at 1000× line count to avoid aborting on large/complex scripts.

### Changed
- SSL importer: improved `if/else` depth tracking to prevent premature `depth` decrement on `end` before `else`.

## [1.0.1] — 2026-05-14

### Fixed
- **Dialogue preview crash when selecting player options** — Added nil checks for `FCurrentNode` and `node.PlayerOptions` in `OptionButtonClick`; crash when selecting player options should no longer occur
- **Button destruction safety** — `ClearOptionButtons` now uses `PostMessage(btn.Handle, CM_RELEASE, ...)` instead of direct `Free` to prevent freeing buttons during their own click event
- **Float message editor** — Custom message text is now preserved when adding a new message (previously hardcoded to "New float message")
- **SSL importer infinite loop** — `TrySetStmt` matched statements without advancing `FPos`, causing hangs; now increments position correctly. Also improved `if/else` depth tracking to handle non-branching `then` blocks followed by `else`

### Changed
- Added parser iteration safety limit (`FSafetyLimit = linecount × 10`) to prevent infinite loops on malformed scripts
- Removed unused variables across `uPreviewSystem.pas` and `SSLImporter.pas`

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