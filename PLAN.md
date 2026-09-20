# Pixie Godot + MCP Implementation Plan

**Goal:** Build a new square-window Godot fantasy workstation named Pixie, with Aseprite-class sprite/tile authoring foundations, a playable 2D runtime surface, and a safe local MCP server for Claude, Codex, and other MCP hosts.

**Architecture:** Godot 4 owns the native editor shell, sprite/map canvases, runtime preview, project data, and user interaction. A separate Python stdio MCP server owns the agent boundary: it exposes constrained project tools, validates paths and data, and never stores provider credentials. AI clients connect to the MCP server; Pixie remains usable without an AI account.

**Tech Stack:** Godot 4.x / GDScript, JSON project data, Python 3 stdio JSON-RPC MCP server, GitHub-ready documentation and configuration.

## Product contract

- 960×960 default native window, 720×720 minimum.
- New identity: PIXIE; no Omasprite shell or artwork viewer.
- Workspaces: HOME, GFX, MAP, RUN, AGENT.
- Beginner-first Simple mode with Advanced controls revealed on demand.
- Sprite pixels, animation frames, palettes, tilemap painting, collision, dialogue, and play preview are data-backed.
- MCP tools are local-first and safe-by-default.

## Tasks

### 1. Godot shell

- Create `project.godot` with square window, input actions, display settings, and main scene.
- Create `scenes/main.tscn` with a `PixieApp` root.
- Create `scripts/pixie_app.gd` with the shell, workspace switching, simple/advanced modes, keyboard commands, stage drawing, and native runtime preview.

### 2. Authoring surfaces

- Add GFX pixel grid with pencil, erase, fill, palette swatches, animation frames, onion-skin toggle, and zoom.
- Add MAP tile grid with terrain stamps, object stamps, collision toggle, and map save.
- Add RUN surface with player movement, collision against blocked tiles, NPC interaction, dialogue, and reset.
- Add AGENT surface with provider-neutral MCP setup, tool list, and safe connection instructions.

### 3. Project data

- Add `pixie.project.json` and `scenes/first_snow.json`.
- Keep sprite frames, palette, map tiles, collision, NPC dialogue, and spawn data in JSON.
- Add save/load and deterministic validation in GDScript.

### 4. MCP bridge

- Create `tools/pixie_mcp.py` with stdio JSON-RPC MCP methods: initialize, tools/list, tools/call.
- Expose `get_project_snapshot`, `validate_project`, `paint_tile`, `set_dialogue`, and `create_scene`.
- Enforce project-root path containment and reject unknown tools or malformed parameters.
- Add `agent/mcp.json` and `docs/AGENTS.md` for Claude/Codex/other MCP hosts.

### 5. Documentation and verification

- Add README, ARCHITECTURE, MCP, ROADMAP, and VERIFICATION docs.
- Run Python syntax/contract tests.
- Run Godot headless checks if Godot is installed; otherwise state the environment blocker.
- Initialize git, commit, create `neshath/pixie` if permitted, push, and report the exact branch/commit/URL.

## Acceptance test

A fresh checkout should be able to:

1. launch Pixie into a square HOME;
2. switch to GFX and paint a pixel;
3. switch to MAP and stamp terrain/collision;
4. switch to RUN and move/interact;
5. save JSON and reload it;
6. start the MCP server and list safe tools;
7. let an MCP host inspect and modify only the project files;
8. run project validation without provider credentials.

