# Pixie

Pixie is a square-window 2D game workstation built in Godot. It combines an approachable fantasy-console loop with the sprite, tileset, map, dialogue, and runtime foundations needed for larger pixel games.

This is a new project identity and setup. It does not reuse the previous Omasprite application shell or its artwork viewer.

## What it is

- A 960×960 native workstation with a 720×720 minimum.
- A single-cart workflow: **GFX → MAP → RUN**.
- A small default surface for beginners, with Advanced tools revealed on demand.
- A data-backed sprite grid, palette, frame, onion-skin, tilemap, collision, NPC, dialogue, and play loop.
- A local MCP server so Claude, Codex, or another MCP host can inspect and safely edit project data.

Pixie takes structural cues from fantasy consoles and from the practical sprite/tile workflow of Aseprite. It does not copy Aseprite code, assets, or UI.

## Run

Godot 4.x is required:

```sh
godot --editor --path .
```

Or run headless validation when Godot is available:

```sh
godot --headless --path . --editor --quit
```

Godot 4.7.2 is the current local verification version. If Godot is not installed on another machine, install Godot 4.x before opening the project.

## MCP agent layer

Pixie is provider-neutral. Claude, Codex, or another MCP host owns the model and connects to this local stdio server:

```sh
python3 tools/pixie_mcp.py --project .
```

The exposed tools are:

- `get_project_snapshot`
- `validate_project`
- `paint_tile`
- `set_dialogue`
- `create_scene`

They are local, bounded to the selected project root, and do not read provider keys. See [docs/AGENTS.md](docs/AGENTS.md) and [agent/mcp.json](agent/mcp.json).

Run the server tests:

```sh
python3 -m unittest discover -s tools -p 'test_*.py'
```

## Keyboard

| Key | Action |
| --- | --- |
| Ctrl+1…8 | HOME, GFX, MAP, SFX, MUSIC, CODE, RUN, AGENT |
| Ctrl+S | Save project JSON |
| Ctrl+R | Run or stop |
| Ctrl+K | Simple / Advanced |
| Esc | Stop or close tools |
| Arrow keys | Move in RUN |
| Enter | Talk in RUN |

## Repository map

- `project.godot` — square Godot project configuration.
- `scenes/main.tscn` — application entry scene.
- `scripts/pixie_app.gd` — shell, authoring surfaces, runtime preview, and local project state.
- `pixie.project.json` — human-readable starter cart.
- `tools/pixie_mcp.py` — safe stdio MCP server.
- `docs/ARCHITECTURE.md` — system boundaries.
- `docs/AGENTS.md` — Claude/Codex/other MCP setup.
- `docs/VERIFICATION.md` — current proof and environment limits.

## Design direction

PICO-8 demonstrates the value of strict, friendly limits and an integrated cartridge loop. Picotron demonstrates how the same idea can grow into a small fantasy workstation with workspaces and built-in tools. Pixie uses those principles as inspiration while keeping its own name, data format, and UI.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
