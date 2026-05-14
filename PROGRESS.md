## Goal
- Fix compilation errors in Fallout Dialogue Creator project after splitting concatenated Pascal units and repairing syntax issues
- Resolve all runtime errors including missing resources, form loading issues, and DFM-less form creation
- Implement WCAG AA color contrast compliance across all 5 themes (≥ 4.5:1 for all text/background combinations)

## Constraints & Preferences
- None

## Progress
### Done — Compiler Fixes
- Split `uSkillCheckEditor_temp.pas` into 4 separate units
- Fixed syntax, dependency, and type errors across 20+ units

### Done — Runtime DFM Fixes
10 dynamically-built forms without `.dfm` files now use `CreateNew` instead of `Create`:

| # | Form | File | Fix |
|---|------|------|-----|
| 1 | `TMainForm` | `uMainForm.pas` | `CreateNew` + `FormCreate(Self)` + close events |
| 2 | `TNodePropertiesForm` | `uNodeProperties.pas` | `CreateNew` + `FormCreate` + `FormShow` |
| 3 | `TPeviewForm` | `uPreviewSystem.pas` | `inherited` → `inherited CreateNew` |
| 4 | `TSkillCheckEditorForm` | `uSkillCheckEditor.pas` | `CreateNew` + explicit init |
| 5 | `TLocalizationForm` | `uLocalization.pas` | `CreateNew` + explicit init |
| 6 | `TfrmFloatMessageEditor` | `Source\Editors\FloatMessageEditor.pas` | `CreateNew` |
| 7 | `TFloatMessageForm` | `uFloatMessageEditor.pas` | Added explicit build/style calls |
| 8 | `TScriptEditorForm` | `uScriptEditor.pas` | `CreateNew` + explicit init |
| 9 | `TAssetBrowserForm` | `uAssetBrowser.pas` | `CreateNew` + explicit init |
| 10 | `TValidationForm` | `uValidationTools.pas` | `CreateNew` + `ValidateForm` call |

### Done — Date Format Fix
- `uDialogueTypes.pas`: `StrToDateTime` → `ISO8601ToDate` with space-to-`T` normalization

### Done — WCAG Color Contrast Audit

**Issues Found** — 20 color pairs checked across 5 themes, 15 pair/theme combinations were failing WCAG AA (< 4.5:1 contrast against `BgDark`):

**Colors Updated Across All 5 Themes:**

| Color | Amber Old→New | Green Old→New | Cyan Old→New | Red Old→New | White Old→New |
|-------|---------------|---------------|--------------|-------------|---------------|
| `TextDim` | 1.51:1 → 10.09:1 | 1.40:1 → 11.9:1 | 1.49:1 → 12.59:1 | 1.14:1 → 10.43:1 | 3.14:1 → 4.82:1 |
| `TextDisabled` | 1.22:1 → 5.21:1 | 1.11:1 → 7.08:1 | 1.12:1 → 7.53:1 | 1.04:1 → 9.31:1 | 1.50:1 → 6.71:1 |
| `AccentSecondary` | 3.37:1 → 8.92:1 | 4.58:1 → 8.58:1 | 5.92:1 → 9.21:1 | 1.73:1 → 6.20:1 | 3.27: → 5.83:1 |
| `AccentDim` | 1.56:1 → 6.33:1 | 1.40:1 → 6.42:1 | 1.49:1 → 6.79:1 | 1.10:1 → 5.31:1 | 1.29:1 → 4.79:1 |

Also improved Red `TextPrimary` from $004060FF (4.27:1) → $005070FF.

### Theme Manager Enhancements
- Added `ApplyToControl()` — recursive theme application to all child controls
- Added `ApplyToForm()` — applies theme to form and all nested controls
- Added `ApplyToListView()`, `ApplyToStatusBar()`, `ApplyToStringGrid()` for comprehensive coverage
- Removed duplicate `ThemeManager` unit from dpr (conflicting with `uThemeManager`)
- `uMainForm.pas` now uses `TThemeManager.ApplyToForm(Self)` for full recursive theming

### Done — SSL/MSG Import Parsers
- **`SSLImporter.pas`** — Self-contained .ssl parser; no dependency on `uAST`/`uLexer`/`uParser`
- **`MSGImporter.pas`** — Rewritten to properly parse `.msg` files and produce a complete `TDialogueProject` with linked nodes (not just log messages). Parses `{id}{}{text}` format, sorts by ID, chains nodes linearly via `NextNodeID`, sets `StartNodeID` on the first node
- Both integrated into main form Import menu

### Done — Import Menu Restructure
- Import moved from nested submenu under Export → standalone top-level **Import** menu (`miImport`)
- `miImportSSL` and `miImportMSG` are now children of the Import menu
- `miImportMSGClick` handler updated to use new `TMSGImportResult.Project` field — imports now create a usable project and load it into the UI

### Done — Dialogue Tester (Preview) Fix
- Fixed `BuildOptionButtons` in `uPreviewSystem.pas`: the "Continue" button now only appears when the node has **no** player options. Previously, nodes with both a `NextNodeID` (from `call`) and player options would show both a Continue button and the options simultaneously, which is incorrect Fallout-style dialogue behavior. Now: options only show player choices, and Continue only appears when there are no choices (automatic advance to next node).

### Done — SSL Import Stability & Performance Fixes
- **Completely rewritten SSL parser** with proper recursive descent:
  - Root cause: original parser had no `begin`/`end` depth tracking — any `end` inside an `if` block would prematurely terminate the enclosing procedure, corrupting all subsequent parsing
  - New `ParseBody(Depth)` method tracks nesting depth; `end` only closes its matching `begin`
  - `if/else/end` blocks properly skipped during procedure body parsing
- **Fixed wrong option argument mapping** — `giq_option(reaction, NAME, msg_id, target, skill)` had 5 args but parser extracted only 2, grabbing `reaction` as msg and `NAME` as target. Added `ExtractFive()` to correctly map arg3→option text, arg4→target node.
- **Added Fallout 2 dialogue command support**: `gsay_reply`, `gsay_message`, `display_msg`
- **Fixed forward declaration handling**: `procedure name;` lines now properly skipped
- **Added `#include`/`#define` preprocessor skipping**
- **Added `call(target)` parenthesized form alongside `call target;`**
- **Added parser safety limit** — exits after `FLines.Count * 4` iterations

### Done — Bug Fixes (this session)
- Fixed 26+ compilation errors in `SSLImporter.pas`:
  - Moved method declarations (`ExtractStringArg`, `SkillNameToEnum`, `ParseSetStatement`) from private to public visibility
  - Replaced `CurrentLine` references with `FCurrentLine` field + `GetLine` method
  - Removed `NodeTypes` from uses clause to resolve type collision (`TDialogueNode`, `TSkillType` exist in both `NodeTypes` and `uDialogueTypes`)
  - Added missing units: `System.StrUtils` (PosEx), `System.IOUtils` (TFile), `System.Character` (CharInSet)
  - Fixed WideChar-in-set warnings using `CharInSet`
  - Changed `node.FID`/`node.FText` to use public properties `node.ID`/`node.Text`
- Fixed `uDialogueTypes.pas`: made `ID` property writable (`read FID write FID`)
- Fixed `MSGImporter.pas`:
  - Changed `{ }` comment to `(* *)` comment to avoid premature close on `}`, `Messages`
  - Added missing units: `System.Generics.Collections`, `System.StrUtils`, `System.IOUtils`
  - Fixed `PosEx` availability, `TList<>` generic, unused `p3` variable
- Fixed `uMainForm.pas`: Added `miImportSSL`, `miImportMSG` to private field declarations
- Fixed `NodePalette.pas`: Replaced hardcoded Windows colors (`clGreen`, `clBlack`, `clLime`) with theme system colors (`TThemeManager.Current.BgMedium`, `TThemeManager.Current.BgDark`, `TThemeManager.Current.TextPrimary`)

### Done — Build Status
- **Compiler output: 0 errors**, only pre-existing hints (unused variables/symbols)
- All 10485 lines compile successfully in 0.48 seconds

### Done — Bug Fixes (2026-05-14)
- Fixed `uNodeCanvas.pas(585): E2003 Undeclared identifier: 'accent'` — added `accent` to local var declaration in `DrawNode`
  - Cleaned up dead code: removed stale `accent` assignment using `NODE_ACCENT_COLORS` (now theme-driven) and unused loop counter `i` in `DrawNodeBody`
- Fixed node connection lines: Changed `i` to `j` in `DrawConnections` sy calculation — connectors now use correct Y position per option
- Added mouse-based node connection: Added `PortAtPoint` function and modified `MouseDown` to start connection mode when clicking output ports
- Implemented MRU system: Added `FRecentProjects` field, `UpdateRecentProjects`, `PopulateRecentMenu`, and `miRecentClick` handler to track and display recently opened projects in File menu

### Phase 1: Procedural Dialogue Generator (Tools\DialogueGenerator\)
- **context_manager.py**: Short-term `ShortTermMemory` (deque-based) and `LongTermMemory` (file-persistent) with hybrid context management
- **persona.py**: `CharacterPersona` class with traits, speech patterns, emotional states; 4 Fallout-themed personas (vault_dweller, brotherhood_knight, raider_chief, ghoul_philosopher)
- **dialogue_generator.py**: Main `DialogueGenerator` class with Ollama CLI integration for offline use
- **README.md**: Usage documentation with examples

### Done — FMFImporter Fixes (2026-05-14)
- Added `ParseNPCText` to interface section declaration
- Fixed `ParseOptionLine` signature mismatch (`const ALine, ASource: string` → `const ALine: string; ASource: string`)
- Fixed `TPlayerOption.Conditions.Add(cond)` → array resize pattern (`SetLength` + index assignment)
- Fixed `FProject.GlobalVars.Values[]` → `FProject.GlobalVars.Add(key, value)` for `TDictionary<string, string>`
- Added `miImportFMF` field declaration in uMainForm.pas
- Added FMFImporter to DPR uses clause
- **Compiler output: 0 errors**, 11 hints only

### Done — SSL Importer Infinite Loop Fix (2026-05-14)
- **Root cause**: `TrySetStmt` is a predicate returning `True` but does not advance `FPos`. `ParseBody` used `Continue` after it, which skipped the final `Inc(FPos)`, causing infinite loop on any `set_*`, `give_*`, `float_msg` line.
- **Fix**: Added `Inc(FPos)` immediately after `if TrySetStmt then` in `ParseBody` (line 515)
- **Cleanup**: Removed intrusive `FSafetyCount` iteration counter (was falsely triggering on nested loops). Replaced with `FPos`-based guard at 1000× file size as defensive measure, but later removed entirely as unnecessary since all code paths increment `FPos` naturally.
- **Bonus**: Improved `if/else` depth tracking in `TryIf` — `end` before `else` no longer prematurely decrements `depth`

### Blocking
- None