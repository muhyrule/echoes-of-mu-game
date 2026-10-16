extends CanvasLayer
## Dialogue box. Lines come from res://data/dialogue.json: {id: [{who, text, set?}]}.

signal finished

var active := false
var closed_frame := -10
var data: Dictionary = {}
var _lines: Array = []
var _i := 0
var _start_frame := 0
var _panel: Panel
var _name_label: Label
var _text: Label
var _prompt: Label
var _chars := 0.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.position = Vector2(24, 262)
	_panel.size = Vector2(592, 82)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.94)
	sb.border_color = Color(0.62, 0.5, 0.78)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	_name_label = Label.new()
	_name_label.position = Vector2(12, 4)
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45))
	_panel.add_child(_name_label)

	_text = Label.new()
	_text.position = Vector2(12, 24)
	_text.size = Vector2(568, 52)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 14)
	_text.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
	_panel.add_child(_text)

	_prompt = Label.new()
	_prompt.text = "▼"
	_prompt.position = Vector2(566, 62)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45))
	_panel.add_child(_prompt)


func blocking() -> bool:
	return active or Engine.get_process_frames() <= closed_frame + 1


func play(id: String) -> void:
	if not data.has(id):
		push_warning("Missing dialogue: " + id)
		return
	await play_lines(data[id])


func play_lines(lines: Array) -> void:
	_lines = lines
	_i = 0
	active = true
	_start_frame = Engine.get_process_frames()
	_panel.visible = true
	_show_line()
	await finished


func _show_line() -> void:
	var line: Dictionary = _lines[_i]
	var who: String = line.get("who", "")
	_name_label.text = who
	_text.text = line.get("text", "")
	_text.add_theme_color_override("font_color", Color(0.7, 0.72, 0.85) if who == "" else Color(0.92, 0.9, 0.96))
	_text.visible_characters = 0
	_chars = 0.0
	if line.has("set"):
		GameState.set_flag(line["set"])


func _process(delta: float) -> void:
	if not active:
		return
	var total := _text.get_total_character_count()
	if _chars < total:
		_chars += delta * 55.0
		_text.visible_characters = int(_chars)
	_prompt.visible = _chars >= total and int(Time.get_ticks_msec() / 400.0) % 2 == 0
	if Engine.get_process_frames() <= _start_frame:
		return
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		if _chars < total:
			_chars = total
			_text.visible_characters = -1
			return
		_i += 1
		if _i >= _lines.size():
			active = false
			closed_frame = Engine.get_process_frames()
			_panel.visible = false
			finished.emit()
		else:
			_show_line()
