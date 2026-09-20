extends Control
class_name PixieApp

const INK := Color("#eef0f7")
const MUTED := Color("#99a1bd")
const SHELL := Color("#111321")
const PANEL := Color("#1a1d32")
const PANEL_RAISED := Color("#242944")
const STAGE := Color("#090b18")
const ORANGE := Color("#ffac52")
const CYAN := Color("#5bdade")
const PURPLE := Color("#7f70dc")
const RED := Color("#f46676")
const GREEN := Color("#66d29b")

const WORKSPACES := ["HOME", "GFX", "MAP", "SFX", "MUSIC", "CODE", "RUN", "AGENT"]
const SAVE_PATH := "user://pixie.project.json"

var workspace := "HOME"
var mode := "SIMPLE"
var tools_open := false
var running := false
var show_grid := true
var onion_skin := false
var active_tool := "PENCIL"
var active_color := 3
var active_tile := 1
var active_frame := 0
var sprite_frames: Array = []
var palette: Array[Color] = []
var map_tiles: Array = []
var map_collision: Array = []
var map_width := 20
var map_height := 15
var player := Vector2i(5, 9)
var npc := Vector2i(13, 8)
var dialogue := "The little machine is ready. What will you make?"
var dialogue_open := false
var status := "READY · press MAKE to start"
var frame_clock := 0.0
var nav_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var tool_buttons: Array[Button] = []
var palette_buttons: Array[Button] = []
var title_label: Label
var status_label: Label
var mode_button: Button
var cart_label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    DisplayServer.window_set_min_size(Vector2i(720, 720))
    _seed_defaults()
    _load_project()
    _make_controls()
    _layout_controls()
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _layout_controls()
        queue_redraw()

func _process(delta: float) -> void:
    if running:
        frame_clock += delta
        queue_redraw()

func _seed_defaults() -> void:
    palette = [Color("#0d1024"), Color("#e7e8f0"), Color("#5bdade"), Color("#ffac52"), Color("#7f70dc")]
    sprite_frames = [_blank_sprite()]
    map_tiles.clear()
    map_collision.clear()
    for y in range(map_height):
        var tile_row: Array = []
        var collision_row: Array = []
        for x in range(map_width):
            tile_row.append(0 if y < map_height - 2 else 1)
            collision_row.append(x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1)
        map_tiles.append(tile_row)
        map_collision.append(collision_row)

func _blank_sprite() -> Array:
    var pixels: Array = []
    for y in range(16):
        var row: Array = []
        for x in range(16):
            row.append(0)
        pixels.append(row)
    return pixels

func _make_controls() -> void:
    title_label = Label.new()
    title_label.text = "PIXIE"
    title_label.add_theme_font_size_override("font_size", 21)
    title_label.add_theme_color_override("font_color", INK)
    add_child(title_label)

    cart_label = Label.new()
    cart_label.text = "untitled.px"
    cart_label.add_theme_color_override("font_color", CYAN)
    add_child(cart_label)

    for i in range(WORKSPACES.size()):
        var name: String = WORKSPACES[i]
        var button := _button(name, "%s · Ctrl+%d" % [name, i + 1])
        button.pressed.connect(_set_workspace.bind(name))
        nav_buttons.append(button)

    var run_button := _button("RUN", "Run or stop the current cart · Ctrl+R")
    run_button.pressed.connect(_toggle_run)
    action_buttons.append(run_button)

    var save_button := _button("SAVE", "Save project data · Ctrl+S")
    save_button.pressed.connect(_save_project)
    action_buttons.append(save_button)

    var tools_button := _button("TOOLS", "Show advanced controls")
    tools_button.pressed.connect(_toggle_tools)
    action_buttons.append(tools_button)

    mode_button = _button("SIMPLE", "Toggle Simple / Advanced · Ctrl+K")
    mode_button.pressed.connect(_toggle_mode)
    add_child(mode_button)

    for label in ["PENCIL", "ERASE", "FILL", "STAMP", "COLLISION"]:
        var tool_button := _button(label, "GFX/MAP tool")
        tool_button.pressed.connect(_set_tool.bind(label))
        tool_buttons.append(tool_button)

    for i in range(5):
        var swatch := _button(str(i + 1), "Palette color %d" % (i + 1))
        swatch.pressed.connect(_set_color.bind(i))
        palette_buttons.append(swatch)

func _button(text_value: String, tip: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.tooltip_text = tip
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 12)
    button.add_theme_color_override("font_color", INK)
    button.add_theme_color_override("font_hover_color", INK)
    add_child(button)
    return button

func _layout_controls() -> void:
    if not title_label:
        return
    title_label.position = Vector2(24, 14)
    title_label.size = Vector2(110, 30)
    cart_label.position = Vector2(112, 18)
    cart_label.size = Vector2(160, 24)

    var x := 24.0
    for button in nav_buttons:
        button.position = Vector2(x, 64)
        button.size = Vector2(82, 34)
        x += 84.0

    var action_x := max(650.0, size.x - 270.0)
    for button in action_buttons:
        button.position = Vector2(action_x, 14)
        button.size = Vector2(80, 32)
        action_x += 84.0
    mode_button.position = Vector2(size.x - 104, 64)
    mode_button.size = Vector2(80, 34)

    for button in tool_buttons:
        button.visible = workspace == "GFX" or workspace == "MAP"
    for button in palette_buttons:
        button.visible = workspace == "GFX"

    var tool_x := 32.0
    for button in tool_buttons:
        button.position = Vector2(tool_x, size.y - 74)
        button.size = Vector2(92, 30)
        tool_x += 98.0
    var palette_x := size.x - 250.0
    for i in range(palette_buttons.size()):
        var button: Button = palette_buttons[i]
        button.position = Vector2(palette_x + i * 44.0, size.y - 74)
        button.size = Vector2(36, 30)
        button.add_theme_color_override("font_color", palette[i] if i < palette.size() else INK)

func _set_workspace(name: String) -> void:
    workspace = name
    if name != "RUN":
        running = false
        dialogue_open = false
    status = "%s · ready" % name
    _layout_controls()
    queue_redraw()

func _set_tool(name: String) -> void:
    active_tool = name
    status = "%s · tool selected" % name
    queue_redraw()

func _set_color(index: int) -> void:
    active_color = index
    active_tool = "PENCIL"
    status = "GFX · palette %d selected" % (index + 1)
    queue_redraw()

func _toggle_tools() -> void:
    tools_open = not tools_open
    status = "TOOLS · advanced controls %s" % ("open" if tools_open else "closed")
    queue_redraw()

func _toggle_mode() -> void:
    mode = "ADVANCED" if mode == "SIMPLE" else "SIMPLE"
    mode_button.text = mode
    status = "MODE · %s" % mode
    queue_redraw()

func _toggle_run() -> void:
    running = not running
    workspace = "RUN" if running else workspace
    dialogue_open = false
    status = "RUNNING · arrows move · Enter interacts" if running else "EDITING · runtime stopped"
    _layout_controls()
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is not InputEventKey or not event.pressed:
        return
    var key_event := event as InputEventKey
    if key_event.ctrl_pressed:
        if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_8:
            _set_workspace(WORKSPACES[key_event.keycode - KEY_1])
            return
        if key_event.keycode == KEY_S:
            _save_project()
            return
        if key_event.keycode == KEY_R:
            _toggle_run()
            return
        if key_event.keycode == KEY_K:
            _toggle_mode()
            return
    if key_event.keycode == KEY_ESCAPE:
        if running:
            _toggle_run()
        else:
            tools_open = false
            queue_redraw()
        return
    if running:
        var direction := Vector2i.ZERO
        if key_event.keycode == KEY_UP:
            direction = Vector2i.UP
        elif key_event.keycode == KEY_DOWN:
            direction = Vector2i.DOWN
        elif key_event.keycode == KEY_LEFT:
            direction = Vector2i.LEFT
        elif key_event.keycode == KEY_RIGHT:
            direction = Vector2i.RIGHT
        if direction != Vector2i.ZERO:
            _move_player(direction)
        elif key_event.keycode == KEY_ENTER:
            _interact()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var point := event.position
        if workspace == "GFX":
            _paint_sprite(point)
        elif workspace == "MAP":
            _paint_map(point)

func _stage_rect() -> Rect2:
    return Rect2(32, 126, size.x - 64, size.y - 220)

func _paint_sprite(point: Vector2) -> void:
    var stage := _stage_rect()
    var side := min(stage.size.x * 0.68, stage.size.y - 34.0)
    var rect := Rect2(stage.position + Vector2(24, 22), Vector2(side, side))
    if not rect.has_point(point):
        return
    var cell := side / 16.0
    var p := Vector2i(int((point.x - rect.position.x) / cell), int((point.y - rect.position.y) / cell))
    if p.x < 0 or p.y < 0 or p.x >= 16 or p.y >= 16:
        return
    var pixels: Array = sprite_frames[active_frame]
    if active_tool == "ERASE":
        pixels[p.y][p.x] = 0
    elif active_tool == "FILL":
        _flood_sprite(p.x, p.y, pixels[p.y][p.x], active_color, pixels)
    else:
        pixels[p.y][p.x] = active_color
    status = "GFX · frame %d changed" % (active_frame + 1)
    queue_redraw()

func _flood_sprite(x: int, y: int, old_value: int, new_value: int, pixels: Array) -> void:
    if old_value == new_value:
        return
    var pending: Array[Vector2i] = [Vector2i(x, y)]
    while pending.size() > 0:
        var point: Vector2i = pending.pop_back()
        if point.x < 0 or point.y < 0 or point.x >= 16 or point.y >= 16:
            continue
        if pixels[point.y][point.x] != old_value:
            continue
        pixels[point.y][point.x] = new_value
        pending.append(Vector2i(point.x + 1, point.y))
        pending.append(Vector2i(point.x - 1, point.y))
        pending.append(Vector2i(point.x, point.y + 1))
        pending.append(Vector2i(point.x, point.y - 1))

func _paint_map(point: Vector2) -> void:
    var rect := _map_rect()
    if not rect.has_point(point):
        return
    var cell := rect.size.x / float(map_width)
    var p := Vector2i(int((point.x - rect.position.x) / cell), int((point.y - rect.position.y) / cell))
    if p.x < 0 or p.y < 0 or p.x >= map_width or p.y >= map_height:
        return
    if active_tool == "COLLISION":
        map_collision[p.y][p.x] = not map_collision[p.y][p.x]
    elif active_tool == "ERASE":
        map_tiles[p.y][p.x] = 0
    else:
        map_tiles[p.y][p.x] = active_tile
    status = "MAP · tile %d,%d changed" % [p.x, p.y]
    queue_redraw()

func _map_rect() -> Rect2:
    var stage := _stage_rect()
    var side := min(stage.size.x - 48.0, stage.size.y - 42.0)
    return Rect2(stage.position + Vector2(24, 22), Vector2(side, side * 0.75))

func _move_player(direction: Vector2i) -> void:
    var next := player + direction
    if next.x < 0 or next.y < 0 or next.x >= map_width or next.y >= map_height:
        return
    if map_collision[next.y][next.x]:
        status = "RUNNING · blocked tile"
        return
    player = next
    status = "RUNNING · position %d,%d" % [player.x, player.y]
    if player == npc:
        status = "RUNNING · press Enter to talk"
    queue_redraw()

func _interact() -> void:
    if player.distance_to(npc) <= 1.5:
        dialogue_open = not dialogue_open
        status = "RUNNING · dialogue open" if dialogue_open else "RUNNING · dialogue closed"
    else:
        status = "RUNNING · move next to the character first"
    queue_redraw()

func _save_project() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        status = "SAVE FAILED · cannot open user data"
        return
    file.store_string(JSON.stringify(_project_data(), "\t"))
    file.close()
    status = "SAVED · user://pixie.project.json"
    queue_redraw()

func _load_project() -> void:
    var path := SAVE_PATH if FileAccess.file_exists(SAVE_PATH) else "res://pixie.project.json"
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var data: Dictionary = parsed
    if data.has("scene"):
        var scene_data: Dictionary = data["scene"]
        var saved_player: Array = scene_data.get("player", [5, 9])
        var saved_npc: Array = scene_data.get("npc", [13, 8])
        player = Vector2i(int(saved_player[0]), int(saved_player[1]))
        npc = Vector2i(int(saved_npc[0]), int(saved_npc[1]))
        dialogue = scene_data.get("dialogue", dialogue)
    if data.has("sprite"):
        var sprite_data: Dictionary = data["sprite"]
        var loaded_palette: Array = []
        for value in sprite_data.get("palette", []):
            loaded_palette.append(Color(value))
        if loaded_palette.size() > 0:
            palette = loaded_palette
        if sprite_data.has("frames"):
            sprite_frames = sprite_data["frames"]
    _ensure_map_shape()

func _ensure_map_shape() -> void:
    if map_tiles.size() != map_height or map_collision.size() != map_height:
        _seed_defaults()
        return
    for y in range(map_height):
        if map_tiles[y].size() != map_width or map_collision[y].size() != map_width:
            _seed_defaults()
            return

func _project_data() -> Dictionary:
    var palette_values: Array = []
    for color in palette:
        palette_values.append(color.to_html(false))
    return {
        "format": 1,
        "name": "first_snow",
        "display": {"width": 320, "height": 240, "tile_size": 16},
        "sprite": {
            "width": 16,
            "height": 16,
            "frames": sprite_frames,
            "palette": palette_values
        },
        "scene": {
            "id": "first_snow",
            "width": map_width,
            "height": map_height,
            "tiles": map_tiles,
            "collision": map_collision,
            "player": [player.x, player.y],
            "npc": [npc.x, npc.y],
            "dialogue": dialogue
        }
    }

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), SHELL)
    draw_rect(Rect2(0, 52, size.x, 44), PANEL)
    draw_line(Vector2(0, 96), Vector2(size.x, 96), PANEL_RAISED, 1.0)
    draw_line(Vector2(0, size.y - 42), Vector2(size.x, size.y - 42), PANEL_RAISED, 1.0)
    var stage := _stage_rect()
    draw_rect(stage, STAGE)
    draw_rect(stage, PANEL_RAISED, false, 1.0)

    if workspace == "HOME":
        _draw_home(stage)
    elif workspace == "GFX":
        _draw_gfx(stage)
    elif workspace == "MAP":
        _draw_map(stage)
    elif workspace == "RUN":
        _draw_run(stage)
    elif workspace == "AGENT":
        _draw_agent(stage)
    else:
        _draw_foundation(stage, workspace)

    draw_string(ThemeDB.fallback_font, Vector2(24, size.y - 16), ("● " if running else "○ ") + status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ORANGE if running else CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 180, size.y - 16), "%s · %s" % [mode, "untitled.px"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
    if tools_open:
        _draw_tools()

func _draw_home(stage: Rect2) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 42), "MAKE SOMETHING SMALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 68), "One cart. One machine. Endless little worlds.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MUTED)
    var card := Rect2(stage.position + Vector2(24, 96), Vector2(min(stage.size.x - 48, 520), min(stage.size.y - 142, 330)))
    draw_rect(card, Color("#111a33"))
    draw_rect(card, PANEL_RAISED, false, 2.0)
    draw_string(ThemeDB.fallback_font, card.position + Vector2(22, 34), "untitled.px", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CYAN)
    draw_string(ThemeDB.fallback_font, card.position + Vector2(22, 60), "A tiny place to begin.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    _draw_world_thumbnail(Rect2(card.position + Vector2(22, 84), card.size - Vector2(44, 112)))
    draw_string(ThemeDB.fallback_font, card.position + Vector2(22, card.size.y - 24), "GFX → MAP → RUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ORANGE)

func _draw_gfx(stage: Rect2) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 34), "GFX DESK", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 56), "Pixel, palette, frame, play.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
    var side := min(stage.size.x * 0.62, stage.size.y - 112.0)
    var rect := Rect2(stage.position + Vector2(24, 78), Vector2(side, side))
    draw_rect(rect, Color("#11172c"))
    var cell := side / 16.0
    var pixels: Array = sprite_frames[active_frame]
    if onion_skin and sprite_frames.size() > 1:
        _draw_sprite_frame(rect, sprite_frames[(active_frame + sprite_frames.size() - 1) % sprite_frames.size()], 0.22)
    _draw_sprite_frame(rect, pixels, 1.0)
    if show_grid:
        for i in range(17):
            var x := rect.position.x + i * cell
            var y := rect.position.y + i * cell
            draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(1, 1, 1, 0.10), 1.0)
            draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(1, 1, 1, 0.10), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y + 28), "FRAME %d / %d" % [active_frame + 1, sprite_frames.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y + 50), "Click the grid to paint · %s" % active_tool, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(stage.position.x + side + 62, stage.position.y + 122), "PALETTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
    for i in range(palette.size()):
        var swatch_rect := Rect2(stage.position + Vector2(side + 62, 144 + i * 34), Vector2(28, 28))
        draw_rect(swatch_rect, palette[i])
        if i == active_color:
            draw_rect(swatch_rect.grow(2), INK, false, 2.0)
        draw_string(ThemeDB.fallback_font, swatch_rect.position + Vector2(40, 20), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)

func _draw_sprite_frame(rect: Rect2, pixels: Array, opacity: float) -> void:
    var cell := rect.size.x / 16.0
    for y in range(16):
        for x in range(16):
            var index: int = int(pixels[y][x])
            if index == 0:
                continue
            var color: Color = palette[min(index, palette.size() - 1)]
            color.a = opacity
            draw_rect(Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell), color)

func _draw_map(stage: Rect2) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 34), "MAP DESK", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 56), "Terrain, objects, collision, paths.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
    var rect := _map_rect()
    var cell := rect.size.x / float(map_width)
    for y in range(map_height):
        for x in range(map_width):
            var tile: int = map_tiles[y][x]
            var color := Color("#1a2c4d") if tile == 0 else Color("#245b55")
            if tile == 2:
                color = Color("#7f70dc")
            elif tile == 3:
                color = Color("#ffac52")
            draw_rect(Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell), color)
            if map_collision[y][x]:
                draw_rect(Rect2(rect.position + Vector2(x, y) * cell + Vector2(cell * 0.28, cell * 0.28), Vector2.ONE * cell * 0.44), Color("#f46676"))
            elif show_grid:
                draw_rect(Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell), Color(1, 1, 1, 0.08), false, 1.0)
    draw_circle(rect.position + (Vector2(player) + Vector2(0.5, 0.5)) * cell, cell * 0.32, CYAN)
    draw_circle(rect.position + (Vector2(npc) + Vector2(0.5, 0.5)) * cell, cell * 0.32, ORANGE)
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y + 28), "Click to stamp · %s" % active_tool, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y + 50), "Red = collision · cyan = player · orange = NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)

func _draw_run(stage: Rect2) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 34), "RUN DESK", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 56), "Play the current cart. Nothing here is a screenshot.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
    var rect := _map_rect()
    var cell := rect.size.x / float(map_width)
    for y in range(map_height):
        for x in range(map_width):
            var tile: int = map_tiles[y][x]
            var color := Color("#1d3350") if tile == 0 else Color("#2a695e")
            draw_rect(Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell), color)
            if map_collision[y][x]:
                draw_rect(Rect2(rect.position + Vector2(x, y) * cell, Vector2.ONE * cell), Color("#0a0c17"))
    draw_circle(rect.position + (Vector2(player) + Vector2(0.5, 0.5)) * cell, cell * 0.34, CYAN)
    draw_circle(rect.position + (Vector2(npc) + Vector2(0.5, 0.5)) * cell, cell * 0.34, ORANGE)
    if dialogue_open:
        var box := Rect2(stage.position + Vector2(24, stage.size.y - 132), Vector2(stage.size.x - 48, 92))
        draw_rect(box, Color("#eef0f7"))
        draw_rect(box, SHELL, false, 2.0)
        draw_string(ThemeDB.fallback_font, box.position + Vector2(16, 28), "MIRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PURPLE)
        draw_string(ThemeDB.fallback_font, box.position + Vector2(16, 56), dialogue, HORIZONTAL_ALIGNMENT_LEFT, int(box.size.x - 32), 14, SHELL)
    else:
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y + 28), "Arrows move · Enter talks · Esc stops", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)

func _draw_foundation(stage: Rect2, desk: String) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 42), "%s DESK" % desk, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 72), "This desk is ready for the next authoring slice.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MUTED)
    var items := ["TITLE LOOP", "STEP SNOW", "START", "TALK", "CHANGE MAP"]
    for i in range(items.size()):
        var row := Rect2(stage.position + Vector2(24, 116 + i * 48), Vector2(min(430.0, stage.size.x - 48), 36))
        draw_rect(row, PANEL)
        draw_rect(row, PANEL_RAISED, false, 1.0)
        draw_string(ThemeDB.fallback_font, row.position + Vector2(14, 23), items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
        draw_string(ThemeDB.fallback_font, row.position + Vector2(row.size.x - 62, 23), "EMPTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)

func _draw_agent(stage: Rect2) -> void:
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 38), "AGENT DESK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 66), "Connect an MCP host; keep the project local and inspectable.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MUTED)
    var providers := ["Claude", "Codex", "OpenAI-compatible", "Local model"]
    for i in range(providers.size()):
        var row := Rect2(stage.position + Vector2(24, 102 + i * 46), Vector2(min(410.0, stage.size.x - 48), 34))
        draw_rect(row, PANEL)
        draw_string(ThemeDB.fallback_font, row.position + Vector2(14, 22), providers[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
        draw_string(ThemeDB.fallback_font, row.position + Vector2(row.size.x - 84, 22), "MCP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CYAN)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 318), "tools/pixie_mcp.py", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ORANGE)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 346), "get_project_snapshot", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 370), "validate_project", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 394), "paint_tile · set_dialogue · create_scene", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, stage.position + Vector2(24, 444), "No provider key is stored by Pixie.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GREEN)

func _draw_tools() -> void:
    var panel := Rect2(size.x - 264, 108, 240, size.y - 166)
    draw_rect(panel, PANEL)
    draw_rect(panel, CYAN, false, 1.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 30), "TOOLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 56), "Advanced controls stay on demand.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 98), "DISPLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CYAN)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 124), "grid: %s" % ("on" if show_grid else "off"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 148), "onion skin: %s" % ("on" if onion_skin else "off"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 192), "AI HOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CYAN)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 218), "MCP stdio / local only", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 244), "Provider executes outside Pixie.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)

func _draw_world_thumbnail(rect: Rect2) -> void:
    for y in range(8):
        for x in range(12):
            var color := Color("#213b58") if y < 4 else Color("#285f5b")
            draw_rect(Rect2(rect.position + Vector2(x, y) * Vector2(rect.size.x / 12.0, rect.size.y / 8.0), Vector2(rect.size.x / 12.0, rect.size.y / 8.0)), color)
    draw_circle(rect.position + Vector2(rect.size.x * 0.32, rect.size.y * 0.62), 12.0, CYAN)
    draw_circle(rect.position + Vector2(rect.size.x * 0.67, rect.size.y * 0.45), 12.0, ORANGE)
