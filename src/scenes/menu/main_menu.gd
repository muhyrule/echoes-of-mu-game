extends Control

const Art = preload("res://src/core/art.gd")
const UI = preload("res://src/core/pixel_ui.gd")
const Materials = preload("res://src/core/pixel_materials.gd")
## Title screen with an original gothic skyline, drawn procedurally.

var items: Array = []
var sel := 0
var t := 0.0
var font: Font
var stars: Array = []
var embers: Array = []
var bats: Array = []
var flash := 0.0
var next_flash := 4.0
var intro := 0.0
const LINES := [
	"Beneath the old towns, the bells ring on their own.",
	"Mu and his companions follow the echoes across a gothic world.",
	"Each friend carries a story of their own. Not all will walk to the end.",
]
const PostScript = preload("res://src/core/post.gd")
const FigureScript = preload("res://src/scenes/menu/menu_figure.gd")


func _ready() -> void:
	font = ThemeDB.fallback_font
	var post := CanvasLayer.new()
	post.set_script(PostScript)
	post.set("grit", 1.0)
	post.set("scratches", 0.0)
	add_child(post)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	items = ["New Game", "Quit"]
	if GameState.has_save():
		items = ["Continue", "New Game", "Quit"]
	for i in 60:
		stars.append(Vector2(randf() * 640.0, randf() * 220.0))
	for i in 50:
		embers.append([randf() * 640.0, randf() * 360.0, randf_range(8.0, 22.0), randf() * 6.0])
	for i in 4:
		bats.append([randf() * 640.0, randf_range(40.0, 170.0), randf_range(30.0, 60.0), randf() * 6.0])
	var figs := [[Art.PAL_MU, 128.0, 300.0], [Art.PAL_ISOLDE, 154.0, 304.0]]
	for fd in figs:
		var fg := Node2D.new()
		fg.set_script(FigureScript)
		fg.pal = fd[0]
		fg.position = Vector2(fd[1], fd[2]) * 3.0
		fg.scale = Vector2(6, 6)
		add_child(fg)
	Audio.play_music("menu")
	Audio.preload_music(["prologue", "chapel", "road"])


func _process(delta: float) -> void:
	t += delta
	intro = minf(intro + delta * 0.5, 1.0)
	next_flash -= delta
	if next_flash <= 0.0:
		flash = 1.0
		next_flash = randf_range(5.0, 11.0)
	flash = maxf(0.0, flash - delta * 2.2)
	for e in embers:
		e[1] -= e[2] * delta
		e[0] += sin(t + e[3]) * 6.0 * delta
		if e[1] < -4.0:
			e[1] = 364.0
			e[0] = randf() * 640.0
	for b in bats:
		b[0] += b[2] * delta
		if b[0] > 680.0:
			b[0] = -40.0
			b[1] = randf_range(40.0, 170.0)
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
			get_tree().change_scene_to_file("res://src/scenes/prologue/Prologue.tscn")
		"Quit":
			get_tree().quit()


func _text(pos: Vector2, s: String, size: int, col: Color, center := true) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	size *= 3
	var p := pos * 3.0
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(font, p + Vector2(3, 3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.8))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))


func _tower(x: float, base: float, wd: float, ht: float, col: Color, lit := false) -> void:
	draw_rect(Rect2(x - wd / 2, base - ht, wd, ht), col)
	draw_colored_polygon(PackedVector2Array([Vector2(x - wd / 2 - 1.5, base - ht), Vector2(x + wd / 2 + 1.5, base - ht), Vector2(x, base - ht - wd * 2.4)]), col)
	draw_rect(Rect2(x - 1, base - ht - wd * 2.4 - 6, 1, 6), col)
	if lit:
		draw_texture_rect(Materials.texture("vault", 1), Rect2(x - wd / 2, base - ht, wd, ht), true, Color("71818a"))
		draw_rect(Rect2(x - wd / 2, base - ht, 1, ht), col.lightened(0.16))
		draw_rect(Rect2(x + wd / 2 - 1, base - ht, 1, ht), col.darkened(0.4))
		draw_rect(Rect2(x - 1, base - ht + 8, 2, 5), Color("ffd166") if int(t * 1.1 + x) % 5 != 0 else Color("7a5a1a"))
		draw_rect(Rect2(x - 1, base - ht + 20, 2, 5), Color("ffd166") if int(t * 0.9 + x) % 4 != 0 else Color("7a5a1a"))


func _bat(p: Vector2, ph: float, col: Color) -> void:
	var fl := sin(t * 14.0 + ph) * 3.0
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(-7, -2 - fl), p + Vector2(-4, 1), p + Vector2(0, 2), p + Vector2(4, 1), p + Vector2(7, -2 - fl)]), col)


func _glow_text(pos: Vector2, s: String, size: int, col: Color, glow: Color) -> void:
	for o in [Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(0, -1.5), Vector2(0, 1.5), Vector2(-3, 0), Vector2(3, 0)]:
		_text(pos + o, s, size, Color(glow, 0.22 * intro))
	_text(pos, s, size, Color(col, intro))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	var fl := flash * flash
	for i in 12:
		var y := i * 30.0
		var k := float(i) / 12.0
		draw_rect(Rect2(0, y, 640, 30), Color("101a25").lerp(Color("455359"), k).lightened(fl * 0.3))
	for s in stars:
		draw_rect(Rect2(s, Vector2(1, 1)), Color(1, 1, 1, (0.35 + 0.35 * sin(t * 2.0 + s.x)) * (1.0 - fl)))
	# moon and echo rings: the premise, ripples that spread across the world
	var moon := Vector2(500, 78)
	draw_texture_rect(Art.light_texture(), Rect2(moon - Vector2(70, 70), Vector2(140, 140)), false, Color(0.7, 0.77, 0.75, 0.16))
	draw_circle(moon, 32.0, Color("e3dcc4"))
	draw_circle(moon + Vector2(-8, 6), 5.0, Color("e6babe"))
	draw_circle(moon + Vector2(9, -7), 3.5, Color("e6babe"))
	for i in 4:
		var ph := fmod(t * 0.18 + i * 0.25, 1.0)
		draw_arc(Vector2(320, 120), 20.0 + ph * 340.0, 0.0, TAU, 96, Color(1.00, 0.51, 0.55, 0.16 * (1.0 - ph) * intro), 1.2)
	for cx in [90.0, 300.0, 520.0]:
		var drift := fmod(t * 4.0 + cx, 760.0) - 60.0
		draw_rect(Rect2(drift, 40 + fmod(cx, 90.0), 140, 10), Color(0.24, 0.28, 0.40, 0.5))
		draw_rect(Rect2(drift + 25, 34 + fmod(cx, 90.0), 90, 8), Color(0.24, 0.28, 0.40, 0.45))
	# far layer: Edinburgh crag and castle
	var far := Color("25343c").lightened(fl * 0.12)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 270), Vector2(0, 175), Vector2(30, 168), Vector2(50, 150), Vector2(95, 146), Vector2(130, 182), Vector2(175, 215), Vector2(230, 270)]), far)
	for cx in range(54, 96, 8):
		draw_rect(Rect2(cx, 140, 5, 7), far)
	draw_rect(Rect2(58, 118, 22, 30), far)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 118), Vector2(82, 118), Vector2(69, 100)]), far)
	draw_rect(Rect2(68, 124, 2, 4), Color("ffd166"))
	# far layer: Prague twin spires
	for sx in [560.0, 590.0]:
		_tower(sx, 270, 12, 70, far, true)
	draw_rect(Rect2(540, 222, 70, 48), far)
	_tower(520, 270, 10, 52, far)
	# mid layer: the cathedral with its rose window
	var mid := Color("15252e").lightened(fl * 0.1)
	draw_rect(Rect2(230, 190, 180, 90), mid)
	draw_texture_rect(Materials.texture("vault", 0), Rect2(230, 190, 180, 90), true, Color("667781"))
	draw_rect(Rect2(250, 150, 140, 40), mid)
	for tx in [236.0, 404.0]:
		_tower(tx, 280, 18, 110, mid, true)
	draw_colored_polygon(PackedVector2Array([Vector2(250, 150), Vector2(390, 150), Vector2(320, 100)]), mid)
	for buttress in [246.0, 276.0, 362.0, 392.0]:
		draw_rect(Rect2(buttress, 195, 4, 85), Color("3e4b50"))
		draw_rect(Rect2(buttress, 195, 1, 85), Color("657173"))
		draw_rect(Rect2(buttress - 2, 249, 8, 3), Color("192a32"))
	var glow_a := 0.7 + 0.2 * sin(t * 1.4)
	for wx in [262.0, 288.0, 346.0, 372.0]:
		draw_rect(Rect2(wx - 3, 252, 6, 18), Color("ffd166") if int(t * 0.7 + wx) % 6 != 0 else Color("3a2a14"))
	draw_colored_polygon(PackedVector2Array([Vector2(314, 280), Vector2(314, 268), Vector2(320, 262), Vector2(326, 268), Vector2(326, 280)]), Color(1.0, 0.7, 0.35, 0.5 * glow_a))
	# near rooftops and ground
	var sil := Color("0a1017")
	draw_rect(Rect2(0, 270, 640, 90), sil)
	for rx in [20.0, 175.0, 440.0, 600.0]:
		_tower(rx, 275, 16, 48 + fmod(rx, 30.0), sil, true)
	# fog
	for i in 5:
		var drift := fmod(t * (5.0 + i * 2.0) + i * 140.0, 800.0) - 80.0
		draw_rect(Rect2(drift, 252 + i * 7, 200, 12), Color(0.5, 0.58, 0.59, 0.06 + 0.02 * (i % 2)))
	# ledge with the travellers
	draw_rect(Rect2(60, 306, 130, 54), Color("14101c"))
	draw_rect(Rect2(60, 306, 130, 2), Color("353a48"))
	for bx in range(64, 190, 14):
		draw_rect(Rect2(bx, 312, 1, 48), Color("07040d"))
	draw_circle(Vector2(141, 296), 16.0, Color(1.0, 0.72, 0.35, 0.07))
	draw_circle(Vector2(141, 296), 7.0, Color(1.0, 0.72, 0.35, 0.12))
	draw_rect(Rect2(140, 294, 3, 4), Color("ffd98a"))
	for b in bats:
		_bat(Vector2(b[0], b[1] + sin(t * 2.0 + b[3]) * 8.0), b[3], Color("06030b"))
	for e in embers:
		draw_rect(Rect2(e[0], e[1], 1, 1), Color(1.0, 0.62, 0.25, 0.55 + 0.3 * sin(t * 5.0 + e[3])))
	draw_rect(Rect2(0, 0, 640, 360), Color(1, 1, 1, fl * 0.25))
	# vignette
	for i in 6:
		draw_rect(Rect2(0, 0, 640, 360).grow(-i * 5.0), Color(0, 0, 0, 0.0))
	draw_rect(Rect2(0, 0, 640, 14), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(0, 346, 640, 14), Color(0, 0, 0, 0.35))
	# title
	_glow_text(Vector2(320, 70 + 4.0 * (1.0 - intro)), "ECHOES OF MU", 46, Color("ffcfd3"), Color("f0515f"))
	_text(Vector2(320, 98), "A Gothic Journey Through the Old World", 13, Color(UI.PAPER, intro))
	_text(Vector2(320, 114), "EDINBURGH   ·   PRAGUE   ·   and beyond", 9, Color(UI.GOLD, intro * (0.6 + 0.3 * sin(t * 1.5))))
	UI.panel(self, Rect2(236, 151, 168, 15 + items.size() * 24), 0.9)
	for i in items.size():
		var sc := UI.LIGHT if i == sel else UI.PAPER.darkened(0.28)
		_text(Vector2(320, 176 + i * 24), ("✦ " if i == sel else "") + items[i] + (" ✦" if i == sel else ""), 18, sc)
	var li := int(t / 6.0) % LINES.size()
	var la := clampf(minf(fmod(t, 6.0), 6.0 - fmod(t, 6.0)) * 1.2, 0.0, 1.0)
	_text(Vector2(320, 330), LINES[li], 11, Color(0.95, 0.69, 0.72, la))
	_text(Vector2(320, 346), "WASD / Arrows · Space attack · E interact · Q shift form", 8, Color("885d61"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
