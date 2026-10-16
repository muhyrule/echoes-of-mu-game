extends Control
## HUD: hearts, keys, form, location banner, interaction hint, fades, pause, death.

const Art = preload("res://src/core/art.gd")

var level: Node2D
var banner_title := ""
var banner_sub := ""
var banner_t := 0.0
var hint := ""
var notice := ""
var notice_t := 0.0
var fade := 0.0
var paused := false
var death_text := false
var font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func show_banner(title: String, sub: String) -> void:
	banner_title = title
	banner_sub = sub
	banner_t = 4.0


func show_notice(text: String) -> void:
	notice = text
	notice_t = 3.0


func fade_to(a: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "fade", a, secs)
	await tw.finished


func _process(delta: float) -> void:
	banner_t = maxf(0.0, banner_t - delta)
	notice_t = maxf(0.0, notice_t - delta)
	if Input.is_action_just_pressed("pause") and not Dialogue.blocking() and not level.frozen:
		paused = not paused
		get_tree().paused = paused
	if paused and Input.is_action_just_pressed("form"):
		get_tree().paused = false
		GameState.save_game()
		get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
	queue_redraw()


func _txt(pos: Vector2, s: String, size: int, col: Color, center := false) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	size *= 3
	var p := pos * 3.0
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(font, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	for i in GameState.max_hp:
		var col := Color("d6455d") if i < GameState.hp else Color("3a2a36")
		Art.heart(self, Vector2(18 + i * 18, 18), 5.0, col)
	draw_rect(Rect2(10, 32, 90, 18), Color(0, 0, 0, 0.0))
	_txt(Vector2(12, 52), "Key x%d" % GameState.keys, 12, Color("e6c15a"))
	var fname := "Wraith" if GameState.form == "wraith" else "Mu"
	var hint_q := "  [Q]" if GameState.forms.size() > 1 else ""
	_txt(Vector2(12, 68), "Form: %s%s" % [fname, hint_q], 12, Color("9fd0ff") if GameState.form == "wraith" else Color("d9c9ff"))
	if banner_t > 0.0:
		var a := minf(1.0, banner_t)
		_txt(Vector2(320, 120), banner_title, 22, Color(0.95, 0.88, 1.0, a), true)
		_txt(Vector2(320, 144), banner_sub, 13, Color(0.75, 0.7, 0.85, a), true)
	if hint != "" and not Dialogue.blocking():
		_txt(Vector2(320, 238), hint, 13, Color(1, 0.95, 0.7), true)
	if notice_t > 0.0:
		_txt(Vector2(320, 90), notice, 14, Color(0.7, 1.0, 0.85, minf(1.0, notice_t)), true)
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size / 3.0), Color(0, 0, 0, fade))
		if death_text:
			_txt(Vector2(320, 180), "The echoes fade...", 22, Color(0.8, 0.7, 0.9, fade), true)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, size / 3.0), Color(0, 0, 0, 0.6))
		_txt(Vector2(320, 150), "PAUSED", 24, Color.WHITE, true)
		_txt(Vector2(320, 185), "Esc — resume     Q — save & quit to menu", 13, Color(0.8, 0.8, 0.9), true)
		_txt(Vector2(320, 215), "WASD/Arrows move · Space attack · E interact · Q form · R reset puzzle", 11, Color(0.65, 0.65, 0.8), true)
