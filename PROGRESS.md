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

### Blocking
- None