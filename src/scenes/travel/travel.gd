extends Control
## Journey cutscene between hubs: the party walks a night road toward the destination's skyline.

const DUR := 11.0

var t := 0.0
var done := false
var kind := "road"
var dest_name := ""
var lines: Array = []
var stars: Array = []
var font: Font
var fade := 1.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var to: String = GameState.journey_to
	var from: String = GameState.journey_from
	var target := to if from == "chapel" else from
	if target.ends_with("_arena"):
		kind = "echo"
		dest_name = "Through the Echo Gate"
		lines = ["The gate hums with a borrowed memory.", "Something old remembers being worshipped here.", "Steady. The echo will not hold for long."]
	elif target == "edinburgh":
		kind = "edinburgh"
		dest_name = "The road to Edinburgh"
		lines = ["Wind off the Firth. Wet cobbles, wetter boots.", "Isolde hums a hymn she half remembers.", "Corvin counts lamplights. Wren counts exits.", "Beneath the Old Town, something is ringing."]
	else:
		kind = "prague"
		dest_name = "The road to Prague"
		lines = ["Cart-ruts and church bells across the Vltava.", "Wren swears the spires lean closer at night.", "Corvin has never seen so many clocks.", "Even the hours are counted in bone here."]
		if from != "chapel":
			dest_name = "The road back to the Chapel"
	if from != "chapel" and not target.ends_with("_arena"):
		dest_name = "The road back to the Chapel"
		lines = ["The party turns toward the chapel bells.", "Fewer words now; more miles.", "Home is whatever door will still open."]
	for i in 90:
		stars.append(Vector3(randf(), randf() * 0.5, randf()))


func _process(delta: float) -> void:
	t += delta
	fade = clampf(1.0 - t / 1.2, 0.0, 1.0) if t < DUR - 1.4 else clampf((t - (DUR - 1.4)) / 1.4, 0.0, 1.0)
	if (t > DUR or (Input.is_action_just_pressed("ui_accept") and t > 1.5)) and not done:
		done = true
		get_tree().change_scene_to_file(GameState.LEVEL_SCENE)
	if Input.is_key_pressed(KEY_SHIFT):
		t += delta * 2.0
	queue_redraw()


func _ridge(base: float, amp: float, sp: float, col: Color, seed_: float, step := 40.0) -> void:
	var pts := PackedVector2Array()
	var off := t * sp
	pts.append(Vector2(0, 1080))
	var x := 0.0
	while x <= 1960.0:
		var wx := x + off
		var y := base - amp * (0.5 * sin(wx * 0.004 + seed_) + 0.3 * sin(wx * 0.011 + seed_ * 2.0) + 0.2 * sin(wx * 0.027 + seed_ * 3.0))
		pts.append(Vector2(x, y))
		x += step
	pts.append(Vector2(1960, 1080))
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var sky_a := Color("141830")
	var sky_b := Color("4a4a78")
	var glow := Color("6a4a5a")
	match kind:
		"prague":
			sky_b = Color("3a2c3c")
			glow = Color("a07040")
		"echo":
			sky_a = Color("0c0618")
			sky_b = Color("3a1a5a")
			glow = Color("8a4ac0")
	for i in 27:
		draw_rect(Rect2(0, i * 40, 1920, 41), sky_a.lerp(sky_b, float(i) / 26.0))
	for s in stars:
		var tw := 0.5 + 0.5 * sin(t * 2.0 + s.z * 20.0)
		draw_circle(Vector2(s.x * 1920.0, s.y * 1080.0), 1.0 + s.z, Color(1, 1, 1, 0.25 + 0.5 * tw))
	var moon := Vector2(1450, 210)
	draw_circle(moon, 90.0, Color(glow, 0.1))
	draw_circle(moon, 52.0, Color("d8d8e8") if kind != "echo" else Color("c8a0f0"))
	draw_circle(moon + Vector2(14, -8), 44.0, sky_b.lerp(sky_a, 0.2))
	draw_circle(moon, 52.0, Color(1, 1, 1, 0.0))
	_ridge(640.0, 160.0, 6.0, sky_b.lerp(Color("26264a"), 0.5), 1.0)
	_skyline()
	_ridge(740.0, 120.0, 18.0, Color("1c1c34"), 4.0)
	_ridge(840.0, 90.0, 42.0, Color("121220"), 9.0)
	for i in 6:
		var mx := fposmod(i * 420.0 - t * 30.0, 2200.0) - 150.0
		draw_set_transform(Vector2(mx + 260, 785 + (i % 3) * 30), 0, Vector2(1, 0.12))
		draw_circle(Vector2.ZERO, 260.0, Color(0.7, 0.75, 0.9, 0.06))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(0, 900, 1920, 180), Color("07070c"))
	for k in 24:
		var rx := fposmod(k * 110.0 - t * 150.0, 2640.0) - 160.0
		draw_rect(Rect2(rx, 930 + (k % 4) * 6, 60, 3), Color("1a1a26"))
	_party()
	_foreground()
	draw_rect(Rect2(0, 0, 1920, 110), Color(0, 0, 0, 0.9))
	draw_rect(Rect2(0, 970, 1920, 110), Color(0, 0, 0, 0.9))
	_caption()
	if fade > 0.0:
		draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, fade))
	draw_string(font, Vector2(1740, 1050), "[Enter] skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.7, 0.7, 0.8, 0.45))


func _skyline() -> void:
	var rise := smoothstep(0.35 * DUR, DUR, t)
	var base := 740.0 + (1.0 - rise) * 90.0
	var x0 := 1180.0
	var col := Color("181830")
	match kind:
		"edinburgh":
			draw_rect(Rect2(x0, base - 20, 700, 120), col)
			draw_colored_polygon(PackedVector2Array([Vector2(x0 + 120, base - 20), Vector2(x0 + 360, base - 150), Vector2(x0 + 600, base - 20)]), col)
			for i in 7:
				var hx := x0 + 20 + i * 98
				draw_rect(Rect2(hx, base - 70 - (i % 3) * 26, 56, 90), col)
				draw_colored_polygon(PackedVector2Array([Vector2(hx - 4, base - 70 - (i % 3) * 26), Vector2(hx + 28, base - 100 - (i % 3) * 26), Vector2(hx + 60, base - 70 - (i % 3) * 26)]), col)
				draw_rect(Rect2(hx + 20, base - 50 - (i % 3) * 26, 8, 12), Color(1.0, 0.8, 0.4, 0.4 + 0.5 * rise))
			draw_rect(Rect2(x0 + 340, base - 260, 40, 120), col)
			draw_colored_polygon(PackedVector2Array([Vector2(x0 + 334, base - 260), Vector2(x0 + 360, base - 320), Vector2(x0 + 386, base - 260)]), col)
		"prague":
			draw_rect(Rect2(x0, base - 10, 720, 110), col)
			for i in 6:
				var hx := x0 + 10 + i * 118
				var th := 130 + (i * 53) % 120
				draw_rect(Rect2(hx, base - th, 54, th + 20), col)
				draw_colored_polygon(PackedVector2Array([Vector2(hx - 3, base - th), Vector2(hx + 27, base - th - 120 - (i % 2) * 50), Vector2(hx + 57, base - th)]), col)
				draw_circle(Vector2(hx + 27, base - th - 120 - (i % 2) * 50), 3.0, Color("c8a050"))
				draw_rect(Rect2(hx + 22, base - th + 24, 9, 14), Color(1.0, 0.75, 0.35, 0.35 + 0.5 * rise))
			draw_circle(Vector2(x0 + 640, base - 70), 26.0, Color(0.9, 0.75, 0.4, 0.2 + 0.5 * rise))
		"echo":
			for i in 5:
				var a := t * 0.5 + i
				var c := Vector2(x0 + 360, base - 120)
				draw_arc(c, 60.0 + i * 38.0, a, a + 4.2, 40, Color(0.7, 0.4, 1.0, 0.2 + 0.4 * rise), 4.0)
			draw_rect(Rect2(x0 + 300, base - 220, 120, 260), col)
			draw_circle(Vector2(x0 + 360, base - 160), 50.0, Color(0.6, 0.3, 0.9, 0.3 + 0.6 * rise))


func _party() -> void:
	var cols := [Color("2a3a5a"), Color("5a3a1a"), Color("2a1a4a"), Color("3a3a2a")]
	for i in 4:
		var x := 560.0 - i * 78.0
		var bob := absf(sin(t * 6.0 + i * 0.7)) * 5.0
		var y := 910.0 + (i % 2) * 14.0 - bob
		draw_set_transform(Vector2(x, y + 30), 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.5))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var sw := sin(t * 6.0 + i * 0.7) * 9.0
		draw_line(Vector2(x - 6, y), Vector2(x - 6 + sw, y + 30), Color("0b0b12"), 7.0)
		draw_line(Vector2(x + 6, y), Vector2(x + 6 - sw, y + 30), Color("0b0b12"), 7.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 16, y - 50), Vector2(x + 16, y - 50), Vector2(x + 20, y + 6), Vector2(x - 20, y + 6)]), cols[i])
		draw_circle(Vector2(x + 2, y - 64), 13.0, Color("d0a888") if i != 3 else Color("8a8a96"))
		draw_arc(Vector2(x + 2, y - 66), 14.0, PI, TAU, 10, Color("1a1420"), 7.0)
	var lp := Vector2(560.0 + 34.0, 880.0 - absf(sin(t * 6.0)) * 5.0)
	draw_line(lp + Vector2(0, -20), lp + Vector2(0, 20), Color("2a2018"), 3.0)
	for r in 5:
		draw_circle(lp + Vector2(0, -22), 150.0 - r * 26.0, Color(1.0, 0.75, 0.4, 0.035))
	draw_circle(lp + Vector2(0, -22), 7.0, Color("ffd890"))


func _foreground() -> void:
	for i in 9:
		var fx := fposmod(i * 300.0 - t * 260.0, 2800.0) - 200.0
		draw_rect(Rect2(fx, 790, 12, 300), Color("050508"))
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 60, 840), Vector2(fx + 6, 640 - (i % 3) * 40), Vector2(fx + 72, 840)]), Color("050508"))
	for i in 26:
		var u := fposmod(t * 0.2 + i * 0.137, 1.0)
		draw_circle(Vector2(fposmod(i * 193.0 + t * 20.0, 1920.0), 300 + u * 600), 1.5, Color(0.8, 0.85, 1.0, 0.35 * (1.0 - u)))


func _caption() -> void:
	var a := clampf(t / 1.5, 0.0, 1.0) * (1.0 - clampf((t - (DUR - 2.0)) / 1.5, 0.0, 1.0))
	draw_string(font, Vector2(0, 66), dest_name, HORIZONTAL_ALIGNMENT_CENTER, 1920, 44, Color(0.92, 0.88, 0.98, a))
	if lines.is_empty():
		return
	var per := (DUR - 2.0) / lines.size()
	var idx := clampi(int(t / per), 0, lines.size() - 1)
	var lt := fmod(t, per) / per
	var la := sin(clampf(lt, 0.0, 1.0) * PI)
	la = clampf(la * 2.2, 0.0, 1.0)
	draw_string(font, Vector2(0, 1030), lines[idx], HORIZONTAL_ALIGNMENT_CENTER, 1920, 30, Color(0.85, 0.85, 0.95, la))
