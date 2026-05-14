# Build Instructions

## Prerequisites
- Delphi 12 Athens or newer
- Windows 10/11 64-bit

## Steps
1. Open `FalloutDialogueCreator.dproj` in Delphi IDE
2. Select **Win64** as target platform
3. Go to Project > Options > Application > High DPI and enable it
4. Build the project (Shift + F9)
5. Output executable is in `bin/FalloutDialogueCreator.exe`

## Notes
- The project uses VCL framework, no cross-platform support
- All source files are in `Source/` subdirectories
- Example projects are in `Examples/`
- JSON schema is in `Docs/JSONSchema.json`