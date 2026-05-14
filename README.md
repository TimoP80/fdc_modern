# Fallout Dialogue Creator
### A Professional RPG Dialogue Authoring Suite — Delphi VCL Edition

```
 ╔══════════════════════════════════════════════════════════════════╗
 ║  FALLOUT DIALOGUE CREATOR  v1.0.0  ║  Delphi VCL  ║  Win32/64  ║
 ╚══════════════════════════════════════════════════════════════════╝
```

---

## Overview

**Fallout Dialogue Creator (FDC)** is a professional-grade desktop application for
authoring branching dialogue trees compatible with classic isometric post-apocalyptic
RPG engines. Built entirely in Embarcadero Delphi using the VCL framework with
zero external dependencies.

Designed for:
- Large-scale RPG modding projects
- Standalone RPG game development
- Fallout 1/2/Tactics modders
- Anyone needing a visual dialogue authoring tool

---

## Feature Set

### Core Editor
| Feature | Status |
|---------|--------|
| Visual node-based canvas editor | ✅ Full |
| Drag-and-drop node positioning | ✅ Full |
| Zoom / pan / minimap | ✅ Full |
| Grid snapping | ✅ Full |
| Auto-layout | ✅ Full |
| Multi-select editing | ✅ Full |
| Node type palette | ✅ Full |
| Project tree sidebar | ✅ Full |
| Right-click context menu | ✅ Full |
| Bezier connection curves | ✅ Full |
| Color-coded node types | ✅ Full |

### Node Types
| Node | Purpose |
|------|---------|
| **NPC Dialogue** | NPC speech with portrait + voice |
| **Player Reply** | Player response options |
| **Conditional** | Logic branching (AND/OR/NOT) |
| **Random** | Weighted random branches |
| **Script** | Inline SSL script execution |
| **Combat Trigger** | Initiates combat |
| **Quest Update** | Modifies quest state |
| **Trade** | Opens barter screen |
| **End Dialogue** | Terminates conversation |
| **Comment** | Developer annotations |

### Dialogue Logic
- 11 condition types: skill, stat, reputation, karma, global/local vars,
  quest flags, inventory, time-of-day, companion, random
- Boolean operators: AND, OR, NOT
- Full comparison operators: ==, !=, <, >, <=, >=

### Skill Check System
- 12 skills: Speech, Barter, Science, Repair, Lockpick, Sneak,
  Medicine, Survival, Gambling, Energy Weapons, Small Guns, Big Guns
- Difficulty slider (1-100%)
- Critical success/failure branches
- XP reward configuration
- Real-time probability preview
- 10-roll simulation test

### Export Formats
| Format | Extension | Description |
|--------|-----------|-------------|
| Dialogue JSON | `.json` | Full project data |
| Fallout Message | `.msg` | Classic `{line}{sound}{text}` format |
| SSL Script | `.ssl` | Fallout script source code |
| Localization Pack | `.json` | Translation strings |
| Engine Package | folder | All formats bundled with manifest |

### Preview System
- In-engine style dialogue simulator
- Real-time skill check simulation
- Variable inspector (edit during simulation)
- Skill values editable mid-playthrough
- Inventory simulation
- Quest flag tracking
- Keyboard navigation (1-9 for options, Enter/Esc)
- Step-back navigation

### Additional Tools
- **Float Message Editor** — ambient barks, combat taunts, weighted randomization
- **Script Editor** — SSL/Pascal-style scripting with function reference browser
- **Validation Tools** — broken link detection, orphan node finder, flow analysis
- **Localization Manager** — multi-language support, export/import translation packs
- **Asset Browser** — browse portraits, audio, scripts with image preview

---

## Project Structure

```
FalloutDialogueCreator/
├── FalloutDialogueCreator.dpr      # Main project file
├── FalloutDialogueCreator.dproj    # IDE project settings
│
├── uMainForm.pas           # Main application window
├── uDialogueTypes.pas      # Core data types & structures
├── uDialogueNode.pas       # Node compatibility shim
├── uNodeCanvas.pas         # Visual node editor (GDI+)
├── uThemeManager.pas       # Retro terminal theme system
├── uProjectManager.pas     # File I/O & recent projects
├── uExportManager.pas      # Export pipeline (.msg, .ssl, .json, pkg)
│
├── uNodeProperties.pas     # Node properties dialog (full editor)
├── uPreviewSystem.pas      # Dialogue preview/simulator
├── uFloatMessageEditor.pas # Float message editor
├── uSkillCheckEditor.pas   # Skill check configuration
├── uScriptEditor.pas       # Script code editor
├── uValidationTools.pas    # Project validation & search
├── uLocalization.pas       # Localization manager
├── uAssetBrowser.pas       # Asset file browser
└── uSearchPanel.pas        # Search helper functions
```

---

## Architecture

### Data Model
```
TDialogueProject
 ├── Nodes: TObjectList<TDialogueNode>
 │    ├── TDialogueNode
 │    │    ├── PlayerOptions: TObjectList<TPlayerOption>
 │    │    │    └── TPlayerOption (with TSkillCheck)
 │    │    ├── Conditions: TList<TCondition>
 │    │    └── Scripts: TObjectList<TNodeScript>
 │    └── ...
 ├── FloatMessages: TObjectList<TFloatMessage>
 ├── GlobalVars: TDictionary<string, string>
 └── Locales: TStringList
```

### Canvas Rendering
The `TNodeCanvas` is a custom `TCustomControl` with:
- Software GDI rendering (no third-party libs)
- Double-buffered `TBitmap` back-buffer
- Bezier curve connections (20-segment approximation)
- Culling for off-screen nodes
- CRT scanline overlay effect
- Minimap with viewport indicator

### Export Pipeline
```
TExportManager.Export(opts)
 ├── efJSON         → Project JSON (formatted or minified)
 ├── efMSG          → Fallout .msg format with voice refs
 ├── efSSL          → Fallout .ssl script with goto labels
 ├── efLocalization → Translation JSON pack
 └── efPackage      → All formats + manifest.json
```

---

## Build Requirements

### Required
- **Embarcadero Delphi** 11 Alexandria or later (or 10.4 Sydney minimum)
- Windows 10/11 (32-bit or 64-bit target)
- VCL framework (included with Delphi)

### Included Units Used
- `System.JSON` — JSON serialization
- `System.Generics.Collections` — TList<T>, TDictionary<K,V>
- `System.IOUtils` — TDirectory, TFile, TPath
- `Vcl.Imaging.PNGImage` — PNG portrait loading
- `Vcl.Imaging.Jpeg` — JPEG loading
- All standard VCL controls

### No External Dependencies
- No NuGet / external packages needed
- No third-party libraries
- Pure Delphi/VCL solution

---

## Build Instructions

### Method 1: Delphi IDE
1. Open `FalloutDialogueCreator.dproj` in Delphi IDE
2. Select target platform (Win32 or Win64)
3. Press **F9** to build and run

### Method 2: Command Line (MSBuild)
```cmd
:: Debug build
msbuild FalloutDialogueCreator.dproj /p:Config=Debug /p:Platform=Win32

:: Release build
msbuild FalloutDialogueCreator.dproj /p:Config=Release /p:Platform=Win32

:: 64-bit release
msbuild FalloutDialogueCreator.dproj /p:Config=Release /p:Platform=Win64
```

### Method 3: DCC32 (Direct compiler)
```cmd
dcc32.exe FalloutDialogueCreator.dpr -B -O+ -Q
```

### Output
- Debug: `Win32\Debug\FalloutDialogueCreator.exe`
- Release: `bin\FalloutDialogueCreator.exe`

---

## Getting Started

### First Run
1. Launch `FalloutDialogueCreator.exe`
2. Click **File → Create Sample Project** to load the "Harold the Ghoul" demo
3. Explore the node canvas — nodes are color-coded by type
4. Double-click any node to open its full property editor
5. Press **Ctrl+P** to run the dialogue preview simulator

### Creating a New Dialogue
1. **File → New Project**
2. Fill in Project Name, NPC Name in the right panel → **Project** tab
3. Right-click the canvas → **Add Node → NPC Dialogue**
4. Double-click the node to set the dialogue text
5. Add **Player Reply** nodes with response options
6. Connect nodes by setting Target Node IDs in the properties editor
7. Set the first node as the Start Node (right-click → Set as Start Node)
8. Press **Ctrl+P** to preview

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Ctrl+N | New Project |
| Ctrl+O | Open Project |
| Ctrl+S | Save |
| Ctrl+Shift+S | Save As |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Ctrl+A | Select All Nodes |
| Delete | Delete Selected |
| Ctrl+P | Preview Dialogue |
| Ctrl+F | Fit All Nodes |
| Ctrl+= | Zoom In |
| Ctrl+- | Zoom Out |
| Ctrl+G | Toggle Grid |
| Mouse Wheel | Zoom (centered on cursor) |
| Middle Mouse | Pan canvas |
| Right Click | Context menu |
| Double Click | Edit node properties |

---

## File Format (.fdc / .json)

FDC saves projects as structured JSON:

```json
{
  "name": "Harold the Ghoul",
  "npcName": "Harold",
  "npcScript": "harold_dialogue",
  "startNodeId": "N_ABC123DEF456",
  "nodes": [
    {
      "id": "N_ABC123DEF456",
      "type": 0,
      "text": "Oh, another wanderer...",
      "speaker": "Harold",
      "x": 60, "y": 80,
      "isStartNode": true,
      "options": [
        {
          "id": "N_OPT001",
          "text": "I need information.",
          "targetNodeId": "N_XYZ789",
          "hasSkillCheck": true,
          "skillCheck": {
            "skill": 0,
            "difficulty": 60,
            "xpReward": 50,
            "successNode": "N_SUCCESS",
            "failNode": "N_FAIL"
          }
        }
      ],
      "conditions": [],
      "scripts": []
    }
  ],
  "floatMessages": [...],
  "globalVars": [...]
}
```

---

## Export Examples

### .MSG File Output
```
# [NPC Dialogue] Harold ID:N_ABC123DEF4
{100}{}{Oh, another wanderer passing through the wasteland.}

# Option [SKILL:Speech]
{110}{}{[Speech 60%] Maybe we can help each other out.}
# Skill check success
{120}{}{Your silver tongue works its magic.}
# Skill check failure
{130}{}{Harold sees right through you.}
```

### .SSL Script Output
```c
/* ========================================
 * Auto-generated SSL Script
 * ======================================== */
#include "HEADERS\DEFINE.H"
#include "HEADERS\DIALOG.H"

procedure talk begin
  goto node_N_ABC123DEF456;
end

node_N_ABC123DEF456:
begin
  (* NPC speaks *)
  Reply(node_N_ABC123DEF456_text_id);
end;
```

---

## Terminal Themes

| Theme | Color Scheme | Inspired By |
|-------|-------------|-------------|
| 🟠 **Amber Terminal** | Orange/amber on black | Classic CRT monitors |
| 🟢 **Green Phosphor** | Green on black | Fallout Pip-Boy |
| 🔵 **Cyan Digital** | Cyan/yellow on dark | Vault-Tec terminals |
| 🔴 **Red Alert** | Red on very dark | Combat terminals |
| ⬜ **Vault-Tec White** | Off-white/gold on dark | Vault-Tec aesthetic |

---

## Extending the Application

### Adding a New Node Type
1. Add entry to `TNodeType` enum in `uDialogueTypes.pas`
2. Add name to `NODE_TYPE_NAMES` constant array
3. Add color to `NODE_DEFAULT_COLORS` and `NODE_ACCENT_COLORS`
4. Handle the new type in `TNodeCanvas.DrawNodeBody`
5. Handle export in `TExportManager.GenerateSSLNode`

### Adding a New Export Format
1. Add entry to `TExportFormat` enum in `uExportManager.pas`
2. Implement the export function
3. Add case to `TExportManager.Export`
4. Add menu item in `TMainForm.BuildMenu`

### Adding a New Skill
1. Add entry to `TSkillType` enum in `uDialogueTypes.pas`
2. Add name to `SKILL_NAMES` constant
3. Skill check editor will automatically pick it up

---

## Known Limitations & Notes

1. **Undo/Redo**: The current implementation is placeholder. A full production
   version should use a Command Pattern with deep-cloning of the project state.

2. **SSL Export**: The generated SSL uses a simplified goto-based structure.
   Real Fallout SSL requires the proper Fallout SSL compiler (sslc.exe) and
   may need manual adjustments for complex dialogue trees.

3. **Audio Playback**: Audio preview requires Windows Media Foundation.
   The asset browser shows files but doesn't play them in this version.

4. **Canvas Performance**: For very large trees (1000+ nodes), consider
   implementing spatial indexing (quadtree) for hit-testing optimization.

5. **Form Registration**: All forms use `RegisterClass` for Delphi streaming
   compatibility. If you add new forms, ensure they're registered.

---

## Project Roadmap (Future Versions)

- [ ] Full undo/redo with command pattern
- [ ] Audio preview playback (WAV/OGG/MP3)
- [ ] Lip-sync timing markers
- [ ] Git integration for version control
- [ ] AI-assisted dialogue suggestions
- [ ] Procedural NPC dialogue generation
- [ ] Quest dependency visualization
- [ ] Voice generation integration
- [ ] Multi-user collaboration
- [ ] Plugin SDK with Delphi package support
- [ ] Mod packaging wizard

---

## License

This project is provided as open-source software for educational and
modding purposes. See LICENSE file for details.

---

*"War never changes. But how you talk about it might."*
```
     ____  ____  ____
    |  __|  _ \  ____|
    | |_ | | | | |
    |  _|| |_| | |___
    |_|  |____/|_____|
    Fallout Dialogue Creator
```
