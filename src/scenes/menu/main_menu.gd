extends Control
## Title screen with an original gothic skyline, drawn procedurally.

var items: Array = []
var sel := 0
var t := 0.0
var font: Font
var stars: Array = []


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	items = ["New Game", "Quit"]
	if GameState.has_save():
		items = ["Continue", "New Game", "Quit"]
	for i in 60:
		stars.append(Vector2(randf() * 640.0, randf() * 220.0))
	Audio.play_music("chapel")


func _process(delta: float) -> void:
	t += delta
	if Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % items.size()
		Audio.sfx("menu")
	if Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + items.size()) % items.size()
		Audio.sfx("menu")
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_choose(items[sel])
	queue_redraw()


func _choose(item: String) -> void:
	Audio.sfx("bell")
	match item:
		"Continue":
			if GameState.load_game():
				get_tree().change_scene_to_file(GameState.LEVEL_SCENE)
		"New Game":
			GameState.new_game()
			get_tree().change_scene_to_file(GameState.LEVEL_SCENE)
		"Quit":
			get_tree().quit()


func _text(pos: Vector2, s: String, size: int, col: Color, center := true) -> void:
	var p := pos
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(font, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.8))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _spire(x: float, base: float, wd: float, ht: float, col: Color) -> void:
	draw_rect(Rect2(x - wd / 2, base - ht, wd, ht), col)
	draw_colored_polygon(PackedVector2Array([Vector2(x - wd / 2 - 2, base - ht), Vector2(x + wd / 2 + 2, base - ht), Vector2(x, base - ht - wd * 1.8)]), col)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b0716"))
	for i in 12:
		var y := i * 22.0
		draw_rect(Rect2(0, y, 640, 22), Color(0.12 + i * 0.012, 0.06 + i * 0.006, 0.2 + i * 0.01, 0.5))
	for s in stars:
		draw_rect(Rect2(s, Vector2(1, 1)), Color(1, 1, 1, 0.4 + 0.4 * sin(t * 2.0 + s.x)))
	draw_circle(Vector2(480, 90), 34.0, Color("e8e2f5"))
	draw_circle(Vector2(492, 84), 30.0, Color("0f0a1c"))
	var sil := Color("08050f")
	draw_rect(Rect2(0, 270, 640, 90), sil)
	_spire(80, 280, 22, 70, sil)
	_spire(140, 280, 14, 40, sil)
	_spire(250, 280, 26, 90, sil)
	_spire(310, 280, 16, 55, sil)
	_spire(400, 280, 30, 110, sil)
	_spire(470, 280, 14, 48, sil)
	_spire(560, 280, 24, 80, sil)
	draw_rect(Rect2(396, 200, 8, 16), Color("ffd166") if int(t * 2.0) % 3 != 0 else Color("a8741a"))
	_text(Vector2(320, 98), "ECHOES OF MU", 44, Color("e8dcff"))
	_text(Vector2(320, 124), "A Gothic Journey Through the Old World", 14, Color("b7a5d9"))
	for i in items.size():
		var sc := Color("ffd166") if i == sel else Color("9a90b5")
		_text(Vector2(320, 190 + i * 26), ("› " if i == sel else "") + items[i], 18, sc)
	_text(Vector2(320, 345), "WASD / Arrows · Space attack · E interact · Q shift form", 11, Color("6f6788"))
