# Pixie verification

## Source inspection

The supplied `aseprite.exe` was inspected without executing it:

- Type: PE32+ Windows x86-64 GUI executable.
- Size: 21,597,696 bytes.
- SHA-256: `86e9d18e403ed943fe4085996050daaf1125ef20ef96d5520548cd053d3c8991`.
- The binary strings expose the expected Aseprite feature vocabulary: sprite sheets, tilesets, layers, tags, slices, palettes, and tilemap export.

It is not a native macOS/Linux executable, so the inspection here is metadata/strings only.

## Automated checks

- `python3 tools/test_pixie_mcp.py`: expected pass once committed.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: expected pass.
- Godot 4.7.2 headless editor check: pass after fixing typed GDScript and duplicate-node errors.
- Godot runtime launch: pass; the project starts as a real OpenGL/Metal process without script/runtime errors in the terminal output.

## Native evidence boundary

The Godot application should still be visually checked on a machine with Godot 4 to verify:

1. square window and PIXIE title;
2. GFX pixel painting;
3. MAP stamps and collision;
4. RUN movement/dialogue;
5. save/reload;
6. AGENT workspace and MCP documentation.

A passing Python MCP test proves the project-agent contract only. The Godot headless check proves scripts load; it does not prove a provider is connected. The desktop accessibility inspector exposed the Godot editor title but did not expose the standalone runtime window, so pixel-level visual inspection remains a manual check.
