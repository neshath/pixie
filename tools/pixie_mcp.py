#!/usr/bin/env python3
"""Local MCP server for Pixie.

This server is intentionally provider-neutral. Claude, Codex, or another MCP
host owns the model and asks Pixie for small, validated project operations.
No API key is read or stored here.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

SERVER_NAME = "pixie-mcp"
PROTOCOL_VERSION = "2024-11-05"
SAFE_ID = re.compile(r"^[A-Za-z0-9_-]{1,48}$")


class PixieMcp:
    def __init__(self, root: Path) -> None:
        self.root = root.resolve()
        self.project_file = self.root / "pixie.project.json"

    def _safe_path(self, relative: str) -> Path:
        candidate = (self.root / relative).resolve()
        if candidate != self.root and self.root not in candidate.parents:
            raise ValueError("path escapes the Pixie project root")
        return candidate

    def _read_project(self) -> dict[str, Any]:
        if not self.project_file.exists():
            raise ValueError("pixie.project.json is missing")
        data = json.loads(self.project_file.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError("project root must be an object")
        return data

    def _write_project(self, data: dict[str, Any]) -> None:
        self._validate(data)
        fd, temp_name = tempfile.mkstemp(prefix=".pixie-", suffix=".json", dir=self.root)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                json.dump(data, stream, indent=2)
                stream.write("\n")
            os.replace(temp_name, self.project_file)
        finally:
            if os.path.exists(temp_name):
                os.unlink(temp_name)

    def _validate(self, data: dict[str, Any]) -> None:
        if data.get("format") != 1:
            raise ValueError("unsupported Pixie project format")
        scene = data.get("scene")
        if not isinstance(scene, dict):
            raise ValueError("scene is required")
        width = scene.get("width")
        height = scene.get("height")
        if not isinstance(width, int) or not isinstance(height, int):
            raise ValueError("scene dimensions must be integers")
        if not 1 <= width <= 512 or not 1 <= height <= 512:
            raise ValueError("scene dimensions are outside the safe range")
        tiles = scene.get("tiles", [])
        collision = scene.get("collision", [])
        if tiles and (len(tiles) != height or any(len(row) != width for row in tiles)):
            raise ValueError("tile grid dimensions do not match scene")
        if collision and (len(collision) != height or any(len(row) != width for row in collision)):
            raise ValueError("collision grid dimensions do not match scene")

    def snapshot(self) -> dict[str, Any]:
        data = self._read_project()
        self._validate(data)
        return {
            "name": data.get("name", "untitled"),
            "format": data.get("format"),
            "scene": data.get("scene", {}),
            "sprite": data.get("sprite", {}),
            "files": sorted(path.relative_to(self.root).as_posix() for path in self.root.rglob("*") if path.is_file() and ".git" not in path.parts),
        }

    def paint_tile(self, args: dict[str, Any]) -> dict[str, Any]:
        data = self._read_project()
        scene = data["scene"]
        x, y = int(args["x"]), int(args["y"])
        width, height = scene["width"], scene["height"]
        if not (0 <= x < width and 0 <= y < height):
            raise ValueError("tile coordinates are outside the scene")
        tile = int(args.get("tile", 0))
        if not 0 <= tile <= 255:
            raise ValueError("tile must be between 0 and 255")
        tiles = scene.setdefault("tiles", [[0 for _ in range(width)] for _ in range(height)])
        collision = scene.setdefault("collision", [[False for _ in range(width)] for _ in range(height)])
        tiles[y][x] = tile
        if "collision" in args:
            collision[y][x] = bool(args["collision"])
        self._write_project(data)
        return {"scene": scene["id"], "x": x, "y": y, "tile": tile, "collision": collision[y][x]}

    def set_dialogue(self, args: dict[str, Any]) -> dict[str, Any]:
        data = self._read_project()
        text = str(args.get("text", "")).strip()
        if not text or len(text) > 1000:
            raise ValueError("dialogue must contain 1-1000 characters")
        data["scene"]["dialogue"] = text
        self._write_project(data)
        return {"dialogue": text}

    def create_scene(self, args: dict[str, Any]) -> dict[str, Any]:
        scene_id = str(args.get("id", ""))
        if not SAFE_ID.fullmatch(scene_id):
            raise ValueError("scene id must use letters, numbers, _ or -")
        width = max(1, min(64, int(args.get("width", 20))))
        height = max(1, min(64, int(args.get("height", 15))))
        scene = {
            "id": scene_id,
            "width": width,
            "height": height,
            "tiles": [[0 for _ in range(width)] for _ in range(height)],
            "collision": [[False for _ in range(width)] for _ in range(height)],
            "player": [1, 1],
            "npc": [min(4, width - 1), min(4, height - 1)],
            "dialogue": "A new scene is waiting.",
        }
        target = self._safe_path(f"scenes/{scene_id}.json")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(scene, indent=2) + "\n", encoding="utf-8")
        return {"path": target.relative_to(self.root).as_posix(), "scene": scene}

    def call(self, name: str, args: dict[str, Any]) -> Any:
        if name == "get_project_snapshot":
            return self.snapshot()
        if name == "validate_project":
            data = self._read_project()
            self._validate(data)
            return {"valid": True, "name": data.get("name", "untitled")}
        if name == "paint_tile":
            return self.paint_tile(args)
        if name == "set_dialogue":
            return self.set_dialogue(args)
        if name == "create_scene":
            return self.create_scene(args)
        raise ValueError(f"unknown tool: {name}")


TOOLS = [
    {
        "name": "get_project_snapshot",
        "description": "Read the validated Pixie project snapshot and file list.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "validate_project",
        "description": "Validate the Pixie JSON contract without changing files.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "paint_tile",
        "description": "Paint one tile and optionally set its collision flag.",
        "inputSchema": {
            "type": "object",
            "required": ["x", "y"],
            "properties": {
                "x": {"type": "integer", "minimum": 0, "maximum": 511},
                "y": {"type": "integer", "minimum": 0, "maximum": 511},
                "tile": {"type": "integer", "minimum": 0, "maximum": 255},
                "collision": {"type": "boolean"},
            },
            "additionalProperties": False,
        },
    },
    {
        "name": "set_dialogue",
        "description": "Replace the current scene dialogue text.",
        "inputSchema": {
            "type": "object",
            "required": ["text"],
            "properties": {"text": {"type": "string", "minLength": 1, "maxLength": 1000}},
            "additionalProperties": False,
        },
    },
    {
        "name": "create_scene",
        "description": "Create a bounded blank scene under scenes/.",
        "inputSchema": {
            "type": "object",
            "required": ["id"],
            "properties": {
                "id": {"type": "string", "pattern": "^[A-Za-z0-9_-]{1,48}$"},
                "width": {"type": "integer", "minimum": 1, "maximum": 64},
                "height": {"type": "integer", "minimum": 1, "maximum": 64},
            },
            "additionalProperties": False,
        },
    },
]


def response(request_id: Any, result: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def error_response(request_id: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def serve(server: PixieMcp, source: Any, sink: Any) -> None:
    for raw in source:
        if not raw.strip():
            continue
        try:
            request = json.loads(raw)
            method = request.get("method")
            request_id = request.get("id")
            if method == "initialize":
                result = {
                    "protocolVersion": PROTOCOL_VERSION,
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": SERVER_NAME, "version": "0.1.0"},
                }
            elif method == "notifications/initialized":
                continue
            elif method == "tools/list":
                result = {"tools": TOOLS}
            elif method == "tools/call":
                params = request.get("params", {})
                value = server.call(params.get("name", ""), params.get("arguments", {}))
                result = {"content": [{"type": "text", "text": json.dumps(value, indent=2)}], "isError": False}
            else:
                if request_id is None:
                    continue
                sink.write(json.dumps(error_response(request_id, -32601, f"unknown method: {method}")) + "\n")
                sink.flush()
                continue
            if request_id is not None:
                sink.write(json.dumps(response(request_id, result)) + "\n")
                sink.flush()
        except Exception as exc:  # keep the MCP process alive for the next request
            if "request_id" in locals() and request_id is not None:
                sink.write(json.dumps(error_response(request_id, -32000, str(exc))) + "\n")
                sink.flush()


def main() -> None:
    parser = argparse.ArgumentParser(description="Pixie local MCP server")
    parser.add_argument("--project", default=".", help="Pixie project root")
    args = parser.parse_args()
    serve(PixieMcp(Path(args.project)), sys.stdin, sys.stdout)


if __name__ == "__main__":
    main()
