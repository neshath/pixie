# Agents and MCP

Pixie exposes a local, provider-neutral MCP server. The correct model is the MCP host: Claude, Codex, or another compatible client decides when to call Pixie tools.

## Start manually

From the Pixie project root:

```sh
python3 tools/pixie_mcp.py --project /absolute/path/to/pixie
```

The server uses newline-delimited JSON-RPC on stdin/stdout.

## Claude-style configuration

Add the equivalent server entry to the MCP configuration used by your Claude client:

```json
{
  "mcpServers": {
    "pixie": {
      "command": "python3",
      "args": [
        "/absolute/path/to/pixie/tools/pixie_mcp.py",
        "--project",
        "/absolute/path/to/pixie"
      ]
    }
  }
}
```

## Codex-style configuration

Register the same command as a local stdio MCP server in the Codex MCP settings:

```json
{
  "command": "python3",
  "args": [
    "/absolute/path/to/pixie/tools/pixie_mcp.py",
    "--project",
    "/absolute/path/to/pixie"
  ]
}
```

Exact settings-file locations are client-specific. The command and arguments are the stable contract.

## Tool policy

The server can inspect the project, validate it, paint one tile, replace the current dialogue line, or create a bounded scene file. It cannot:

- access files outside the selected project root;
- use the network;
- read API keys;
- run arbitrary shell commands;
- install packages;
- invoke a model by itself.

For larger changes, ask the host agent to make a plan, call small tools, validate, and then show the diff.

