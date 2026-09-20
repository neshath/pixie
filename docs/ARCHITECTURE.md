# Pixie architecture

## Runtime

Godot owns the native process, window, input, drawing, and play preview. The root scene is a single `PixieApp` control so the first version stays easy to inspect and the square layout is deterministic.

## Workspaces

`pixie_app.gd` exposes these desks:

- HOME: cart entry point.
- GFX: editable 16×16 sprite frames, palette, tools, grid, onion skin.
- MAP: editable tile grid and collision overlay.
- SFX / MUSIC / CODE: explicit foundations instead of fake complete editors.
- RUN: playable map with movement, collision, NPC interaction, and dialogue.
- AGENT: MCP connection contract and visible tool inventory.

The shell uses real Godot `Button` controls for navigation and actions, while the stage is custom-drawn so pixel boundaries stay crisp and the square composition remains stable.

## Data

`pixie.project.json` is JSON by design:

- `sprite.frames` stores palette-indexed pixels.
- `sprite.palette` stores colors.
- `scene.tiles` stores tile indices.
- `scene.collision` stores independent collision flags.
- `scene.player`, `scene.npc`, and `scene.dialogue` store runtime fixtures.

The Godot app saves to `user://pixie.project.json`. The repository fixture remains human-readable for Git and MCP operations.

## Agent boundary

The model is not embedded in the game. A provider such as Claude or Codex connects to `tools/pixie_mcp.py` using MCP stdio. The server:

1. resolves a project root;
2. validates every input;
3. rejects path traversal;
4. writes only bounded JSON changes;
5. returns structured tool results.

This keeps provider credentials and model execution outside the game. It also makes the project usable offline without an agent.

