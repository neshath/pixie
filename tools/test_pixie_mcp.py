import json
import io
import tempfile
import unittest
from pathlib import Path

from pixie_mcp import PixieMcp, serve


class PixieMcpTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="pixie-mcp-test-"))
        (self.tmp / "pixie.project.json").write_text(json.dumps({
            "format": 1,
            "name": "test",
            "scene": {
                "id": "main",
                "width": 3,
                "height": 2,
                "tiles": [[0, 0, 0], [0, 0, 0]],
                "collision": [[False, False, False], [False, False, False]],
                "dialogue": "hello"
            }
        }), encoding="utf-8")
        self.server = PixieMcp(self.tmp)

    def test_snapshot_and_validation(self):
        self.assertEqual(self.server.call("validate_project", {}), {"valid": True, "name": "test"})
        self.assertEqual(self.server.snapshot()["scene"]["id"], "main")

    def test_paint_and_dialogue_are_persistent(self):
        self.server.call("paint_tile", {"x": 1, "y": 0, "tile": 4, "collision": True})
        self.server.call("set_dialogue", {"text": "A new line"})
        data = json.loads((self.tmp / "pixie.project.json").read_text(encoding="utf-8"))
        self.assertEqual(data["scene"]["tiles"][0][1], 4)
        self.assertTrue(data["scene"]["collision"][0][1])
        self.assertEqual(data["scene"]["dialogue"], "A new line")

    def test_scene_ids_are_contained(self):
        result = self.server.call("create_scene", {"id": "cave_01", "width": 2, "height": 2})
        self.assertEqual(result["path"], "scenes/cave_01.json")
        with self.assertRaises(ValueError):
            self.server.call("create_scene", {"id": "../escape"})

    def test_stdio_handshake_and_tool_listing(self):
        source = io.StringIO(
            json.dumps({"jsonrpc": "2.0", "id": 1, "method": "initialize"})
            + "\n"
            + json.dumps({"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
            + "\n"
        )
        sink = io.StringIO()
        serve(self.server, source, sink)
        messages = [json.loads(line) for line in sink.getvalue().splitlines()]
        self.assertEqual(messages[0]["result"]["serverInfo"]["name"], "pixie-mcp")
        self.assertEqual(len(messages[1]["result"]["tools"]), 5)


if __name__ == "__main__":
    unittest.main()
