extends Control
## New-game prologue: six illustrated plates narrated in an old gothic voice.

const SLIDE := 11.0
const PLATES := [
	{"art": "age", "title": "I. The Waning Age",
	"text": "In the age of candle and plague, when the kirkyards grew fatter than the fields, the dead did not rest as the priests had promised. Their griefs, their hungers and their last unfinished words soaked into the very stones, and the stones remembered. The learned folk named these remembrances the Echoes."},
	{"art": "rift", "title": "II. The Rending of the Veil",
	"text": "Seven Gates were wrought of old to bind the Echoes in seven forsaken places. Yet the binding was made with a bell, and a bell, being cast of mortal bronze, may crack. Thus, when the Veil wore thin, spectres of the old folklore walked abroad: the drowned horse, the hollow knight, the Plague Physician, and worse beside."},
	{"art": "foundling", "title": "III. The Foundling",
	"text": "On a night of sleet and thunder, a babe was laid upon the step of the Wayfarer's Chapel, and the great bell tolled of itself, though no hand had touched the rope. Father Aldous took up the child and named him Mu, which in the oldest tongue signifies only: 'the one who listens'."},
	{"art": "listener", "title": "IV. The One Who Listens",
	"text": "Mu grew up beneath the belfry, and whilst other children heard but wind, he heard voices in the walls, and a weeping beneath the floor. Aldous taught him the sword and the psalm alike, and warned him gravely: 'Heed the dead, lad, but never follow them.'"},
	{"art": "toll", "title": "V. The Bell Tolls Anew",
	"text": "Upon the eve of Mu's eighteenth winter, the bell began to toll once more, thrice by night and thrice by day. Far off in Edinburgh and in Praha, the Gates stood open, and the dead came crowding at the thresholds. Only one who could hear the Echoes might ever hope to quiet them."},
	{"art": "road", "title": "VI. The Long Road",
	"text": "So Mu took up his father's sword and a lantern, and went out into the dark. Companions would be met upon the road, each bearing a sorrow of their own, and each, in time, called homeward by a destiny that was theirs alone. Thus began the journey, and thus the telling of it."},
]

var t := 0.0
var idx := 0
var done := false
var font: Font
var stars: Array = []
var post: Node


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	seed(77)
	for i in 120:
		stars.append(Vector3(randf(), randf() * 0.6, randf()))
	Audio.play_music("prologue")
	post = CanvasLayer.new()
	post.set_script(load("res://src/core/post.gd"))
	post.set("grit", 1.1)
	add_child(post)


func _process(delta: float) -> void:
	t += delta * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	if Input.is_action_just_pressed("ui_cancel") and not done:
		_finish()
		return
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact")) and t > 0.8:
		if t < SLIDE - 3.0:
			t = SLIDE - 3.0
		else:
			t = SLIDE
	if t >= SLIDE:
		t = 0.0
		idx += 1
		if idx >= PLATES.size():
			_finish()
			return
	queue_redraw()


func _finish() -> void:
	if done:
		return
	done = true
	GameState.set_flag("prologue_seen", true)
	get_tree().change_scene_to_file(GameState.LEVEL_SCENE)


const OFF := Vector2(0, -110)


func _tf(p := Vector2.ZERO, r := 0.0, sc := Vector2.ONE) -> void:
	draw_set_transform(p + OFF, r, sc)


func _sky(a: Color, b: Color) -> void:
	for i in 27:
		draw_rect(Rect2(0, i * 40, 1920, 41), a.lerp(b, float(i) / 26.0))
	for s in stars:
		var tw := 0.5 + 0.5 * sin(t * 2.0 + s.z * 20.0)
		draw_circle(Vector2(s.x * 1920.0, s.y * 1080.0), 1.0 + s.z, Color(1, 1, 1, 0.2 + 0.5 * tw))


func _moon(p: Vector2, r: float, col: Color) -> void:
	for k in 5:
		draw_circle(p, r + 30.0 + k * 22.0, Color(col, 0.05))
	draw_circle(p, r, col)


func _chapel(x: float, y: float, s: float, lit: bool) -> void:
	var c := Color("1a1a2c")
	draw_rect(Rect2(x - 150 * s, y - 160 * s, 300 * s, 160 * s), c)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 170 * s, y - 160 * s), Vector2(x, y - 270 * s), Vector2(x + 170 * s, y - 160 * s)]), c)
	draw_rect(Rect2(x + 80 * s, y - 420 * s, 80 * s, 270 * s), c)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 70 * s, y - 420 * s), Vector2(x + 120 * s, y - 540 * s), Vector2(x + 170 * s, y - 420 * s)]), c)
	var wc := Color("ffb860") if lit else Color("30304a")
	for i in 3:
		draw_rect(Rect2(x - 100 * s + i * 62 * s, y - 120 * s, 26 * s, 60 * s), wc)
	draw_rect(Rect2(x + 106 * s, y - 385 * s, 28 * s, 50 * s), wc)


func _spires(y: float, col: Color, off: float) -> void:
	for i in 14:
		var x := i * 150.0 + off
		var h := 160.0 + (i * 53 % 7) * 40.0
		draw_rect(Rect2(x, y - h, 56, h + 300), col)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y - h), Vector2(x + 28, y - h - 120 - (i % 3) * 30), Vector2(x + 64, y - h)]), col)


func _hero(p: Vector2, s: float, lamp: bool, kid := false) -> void:
	var k := 0.6 if kid else 1.0
	_tf(p, 0, Vector2(s * k, s * k))
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -90), Vector2(22, -90), Vector2(30, 0), Vector2(-30, 0)]), Color("1a2440"))
	draw_circle(Vector2(0, -112), 20.0, Color("d0a888"))
	draw_arc(Vector2(0, -116), 21.0, PI, TAU, 12, Color("14101c"), 10.0)
	draw_line(Vector2(26, -60), Vector2(26, 20), Color("b8b8c8"), 4.0)
	if lamp:
		draw_line(Vector2(-26, -70), Vector2(-48, -50), Color("1a2440"), 6.0)
		for r in 5:
			draw_circle(Vector2(-50, -40), 160.0 - r * 28.0, Color(1.0, 0.75, 0.4, 0.04))
		draw_circle(Vector2(-50, -42), 9.0, Color("ffd890"))
	_tf()


func _ground(y: float, col: Color) -> void:
	draw_rect(Rect2(0, y, 1920, 1080 - y), col)


func _plate(art: String, p: float) -> void:
	_tf()
	var drift := (p - 0.5) * 60.0
	match art:
		"age":
			_sky(Color("0e1224"), Color("3a3458"))
			_moon(Vector2(1400, 260), 70.0, Color("d8d8e8"))
			_spires(700.0, Color("0b0b16"), -drift)
			_ground(840.0, Color("08080e"))
			for i in 40:
				var gx := fposmod(i * 97.0 + t * 8.0, 1920.0)
				draw_rect(Rect2(gx, 820 - (i % 5) * 12, 6, 40 + (i % 4) * 14), Color("14141e"))
				draw_line(Vector2(gx - 8, 836 - (i % 5) * 12), Vector2(gx + 14, 836 - (i % 5) * 12), Color("14141e"), 4.0)
			for i in 18:
				var u := fposmod(t * 0.12 + i * 0.173, 1.0)
				draw_circle(Vector2(100 + i * 100.0 + sin(t + i) * 30.0, 820.0 - u * 380.0), 4.0, Color(0.6, 0.8, 1.0, 0.45 * (1.0 - u)))
		"rift":
			_sky(Color("0a0414"), Color("3a1450"))
			var c := Vector2(960, 380)
			for k in 8:
				draw_circle(c, 80.0 + k * 40.0 + sin(t * 2.0 + k) * 6.0, Color(0.6, 0.3, 0.9, 0.06))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, -260), c + Vector2(30, -40), c + Vector2(-10, 40), c + Vector2(40, 260), c + Vector2(-30, 60), c + Vector2(10, -30)]), Color("e8c8ff"))
			_spires(760.0, Color("07040e"), drift)
			for i in 7:
				var a := t * 0.5 + i * TAU / 7.0
				var q := c + Vector2(cos(a) * (420 + i * 20), sin(a) * 140 + 80)
				draw_circle(q, 18.0, Color(0.7, 0.9, 1.0, 0.5))
				draw_colored_polygon(PackedVector2Array([q + Vector2(-16, 6), q + Vector2(16, 6), q + Vector2(6, 70 + 10 * sin(t * 3 + i)), q + Vector2(-6, 50)]), Color(0.7, 0.9, 1.0, 0.25))
			_ground(860.0, Color("050309"))
		"foundling":
			_sky(Color("0a0c18"), Color("3c4060"))
			for i in 80:
				var rx := fposmod(i * 61.0 - t * 160.0, 1960.0)
				var ry := fposmod(i * 97.0 + t * 700.0, 1080.0)
				draw_line(Vector2(rx, ry), Vector2(rx - 10, ry + 34), Color(0.7, 0.75, 0.9, 0.35), 2.0)
			if fmod(t, 4.0) < 0.15:
				draw_rect(Rect2(0, 0, 1920, 1080), Color(0.9, 0.9, 1.0, 0.25))
			_chapel(700.0, 820.0, 1.6, true)
			_ground(820.0, Color("08080c"))
			draw_rect(Rect2(660, 800, 90, 24), Color("1a1a24"))
			draw_circle(Vector2(705, 790), 15.0, Color("e8d0b8"))
			draw_rect(Rect2(690, 796, 30, 14), Color("8a6a50"))
			for r in 4:
				draw_circle(Vector2(705, 780), 60.0 + r * 30.0, Color(1.0, 0.8, 0.5, 0.05))
			_tf(Vector2(1180, 290), sin(t * 3.0) * 0.12, Vector2.ONE)
			draw_circle(Vector2.ZERO, 36.0, Color("c8a050"))
			draw_circle(Vector2(0, 10), 14.0, Color("14101c"))
			_tf()
		"listener":
			_sky(Color("1a1624"), Color("584868"))
			_moon(Vector2(500, 300), 60.0, Color("e8d8c8"))
			_chapel(1320.0, 830.0, 1.5, true)
			_ground(830.0, Color("0c0a10"))
			_hero(Vector2(560, 860), 1.8, false, true)
			for i in 9:
				var u := fposmod(t * 0.2 + i * 0.11, 1.0)
				var q := Vector2(1100 + sin(t + i) * 40.0, 780.0 - u * 460.0)
				draw_circle(q, 10.0, Color(0.7, 0.9, 1.0, 0.5 * (1.0 - u)))
			draw_arc(Vector2(560, 760), 70.0 + fmod(t * 40.0, 120.0), 0, TAU, 30, Color(0.7, 0.9, 1.0, 0.3), 3.0)
		"toll":
			_sky(Color("1a0c14"), Color("703030"))
			_moon(Vector2(960, 320), 110.0, Color("e8a888"))
			_chapel(560.0, 880.0, 1.7, true)
			_spires(900.0, Color("0a0508"), 900.0 + drift)
			_ground(880.0, Color("060306"))
			var swing := sin(t * 3.0) * 0.25
			_tf(Vector2(1500, 280), swing, Vector2.ONE)
			draw_line(Vector2.ZERO, Vector2(0, 60), Color("2a2018"), 6.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, 60), Vector2(14, 60), Vector2(48, 150), Vector2(-48, 150)]), Color("b88838"))
			_tf()
			for k in 4:
				draw_arc(Vector2(1500, 360), 60.0 + fposmod(t * 90.0 + k * 90.0, 360.0), 0, TAU, 40, Color(1.0, 0.8, 0.5, 0.25 * (1.0 - fposmod(t * 90.0 + k * 90.0, 360.0) / 360.0)), 3.0)
		_:
			_sky(Color("0c1020"), Color("584a68"))
			_moon(Vector2(1450, 240), 60.0, Color("e0e0f0"))
			_spires(620.0, Color("120e1c"), -drift)
			_ground(820.0, Color("0a0810"))
			draw_colored_polygon(PackedVector2Array([Vector2(820, 1080), Vector2(1100, 1080), Vector2(1020, 820), Vector2(900, 820)]), Color("141018"))
			var wob := absf(sin(t * 5.0)) * 4.0
			_hero(Vector2(960, 900 - wob - p * 40.0), 1.5 - p * 0.4, true)
			_chapel(360.0, 830.0, 1.0, true)


func _draw() -> void:
	var pl: Dictionary = PLATES[idx]
	var p := t / SLIDE
	_plate(pl.art, p)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var fa := clampf(t / 1.2, 0.0, 1.0) * clampf((SLIDE - t) / 1.2, 0.0, 1.0)
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 1.0 - fa))
	draw_rect(Rect2(0, 0, 1920, 100), Color(0, 0, 0, 0.92))
	draw_rect(Rect2(0, 770, 1920, 310), Color(0, 0, 0, 0.88))
	draw_rect(Rect2(0, 770, 1920, 2), Color(0.62, 0.5, 0.78, 0.6 * fa))
	draw_string(font, Vector2(0, 66), pl.title, HORIZONTAL_ALIGNMENT_CENTER, 1920, 44, Color(0.92, 0.82, 0.55, fa))
	var full: String = pl.text
	var shown := int(clampf((t - 0.8) / (SLIDE - 3.5), 0.0, 1.0) * full.length())
	draw_multiline_string(font, Vector2(180, 840), full.substr(0, shown), HORIZONTAL_ALIGNMENT_LEFT, 1560, 34, 6, Color(0.9, 0.88, 0.94, fa))
	draw_string(font, Vector2(0, 1050), "Enter: next    Esc: skip", HORIZONTAL_ALIGNMENT_RIGHT, 1860, 20, Color(0.7, 0.7, 0.8, 0.6))
