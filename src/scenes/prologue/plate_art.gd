extends Control
## One illustrated prologue plate. Set `art` and `t`; the controller cross-fades two of these.

var art := "age"
var t := 0.0
var zoom := 1.0
var stars: Array = []


func _ready() -> void:
	seed(77)
	for i in 120:
		stars.append(Vector3(randf(), randf() * 0.6, randf()))


func _draw() -> void:
	zoom = 1.0 + 0.07 * clampf(t / 24.0, 0.0, 1.0)
	plate(clampf(t / 24.0, 0.0, 1.0))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


const OFF := Vector2(0, -110)
const CEN := Vector2(960, 420)


func _tf(p := Vector2.ZERO, r := 0.0, sc := Vector2.ONE) -> void:
	draw_set_transform(OFF + CEN * (1.0 - zoom) + p * zoom, r, sc * zoom)


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


func plate(p: float) -> void:
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
			_sky(Color("120204"), Color("4a0a12"))
			var c := Vector2(960, 380)
			for k in 9:
				draw_circle(c, 80.0 + k * 42.0 + sin(t * 2.0 + k) * 8.0, Color(0.85, 0.08, 0.06, 0.06))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -280), c + Vector2(36, -40), c + Vector2(-12, 40), c + Vector2(46, 280), c + Vector2(-36, 60), c + Vector2(12, -30)]), Color("ff5030"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -240), c + Vector2(16, -40), c + Vector2(-2, 30), c + Vector2(22, 240), c + Vector2(-16, 50), c + Vector2(2, -30)]), Color("1a0000"))
			_spires(760.0, Color("0a0204"), drift)
			for i in 9:
				var a := t * 0.4 + i * TAU / 9.0
				var q := c + Vector2(cos(a) * (440 + i * 20), sin(a) * 150 + 80)
				draw_circle(q, 20.0, Color(0.3, 0.0, 0.0, 0.7))
				draw_circle(q + Vector2(-6, -2), 3.5, Color("ff3020"))
				draw_circle(q + Vector2(6, -2), 3.5, Color("ff3020"))
				draw_colored_polygon(PackedVector2Array([q + Vector2(-18, 8), q + Vector2(18, 8), q + Vector2(8, 80 + 12 * sin(t * 3 + i)), q + Vector2(-8, 56)]), Color(0.5, 0.05, 0.05, 0.3))
			_ground(860.0, Color("060102"))
		"echo":
			_sky(Color("080a14"), Color("26304a"))
			_ground(860.0, Color("06060c"))
			draw_rect(Rect2(380, 160, 1160, 700), Color("1c1c28"))
			for i in 7:
				for j in 4:
					draw_rect(Rect2(380 + i * 166 + (j % 2) * 40, 160 + j * 175, 160, 168), Color("22222f"))
			var pulse := 0.5 + 0.5 * sin(t * 1.6)
			var fig := Vector2(960, 520)
			for k in 6:
				draw_arc(fig + Vector2(0, -40), 120.0 + k * 50.0 + fposmod(t * 30.0, 50.0), 0, TAU, 40, Color(0.6, 0.8, 1.0, 0.18 - k * 0.025), 3.0)
			draw_circle(fig + Vector2(0, -150), 44.0, Color(0.7, 0.85, 1.0, 0.18 + 0.15 * pulse))
			draw_colored_polygon(PackedVector2Array([fig + Vector2(-70, -100), fig + Vector2(70, -100), fig + Vector2(110, 260), fig + Vector2(-110, 260)]), Color(0.7, 0.85, 1.0, 0.1 + 0.12 * pulse))
			draw_line(fig + Vector2(-60, -60), fig + Vector2(-130, 40), Color(0.7, 0.85, 1.0, 0.2), 6.0)
			draw_line(fig + Vector2(60, -60), fig + Vector2(120, -170), Color(0.7, 0.85, 1.0, 0.2), 6.0)
		"bellward":
			_sky(Color("0a0c1a"), Color("34385a"))
			_ground(850.0, Color("07070d"))
			_chapel(1400.0, 850.0, 1.4, true)
			for i in 26:
				var u := fposmod(t * 0.07 + i * 0.0385, 1.0)
				var q := Vector2(150 + u * 1150.0, 800.0 - sin(u * PI) * 330.0 - (i % 5) * 28.0)
				draw_circle(q, 12.0, Color(0.7, 0.9, 1.0, 0.5))
				draw_colored_polygon(PackedVector2Array([q + Vector2(-9, 4), q + Vector2(9, 4), q + Vector2(0, 54)]), Color(0.7, 0.9, 1.0, 0.18))
			for k in 4:
				draw_arc(Vector2(1520, 400), 50.0 + fposmod(t * 80.0 + k * 90.0, 360.0), 0, TAU, 40, Color(1.0, 0.8, 0.5, 0.25), 3.0)
		"gates":
			_sky(Color("0a0612"), Color("2a1a44"))
			_ground(880.0, Color("050308"))
			for i in 7:
				var gx := 260.0 + i * 233.0
				var gy := 700.0 - sin(float(i) / 6.0 * PI) * 260.0
				var lit := 0.4 + 0.3 * sin(t * 1.5 + i)
				var col := Color(0.55, 0.4, 0.9, lit)
				draw_rect(Rect2(gx - 56, gy - 90, 112, 190), Color("0c0a14"))
				draw_circle(Vector2(gx, gy - 90), 56.0, Color("0c0a14"))
				draw_circle(Vector2(gx, gy - 10), 40.0, col)
				draw_rect(Rect2(gx - 40, gy - 10, 80, 100), col)
				draw_arc(Vector2(gx, gy - 90), 66.0, PI, TAU, 16, Color(0.7, 0.6, 1.0, 0.4), 3.0)
		"abom":
			_sky(Color("100204"), Color("3a0810"))
			_ground(860.0, Color("050102"))
			var bb := sin(t * 1.2) * 14.0
			draw_colored_polygon(PackedVector2Array([Vector2(700, 860), Vector2(760, 380 + bb), Vector2(860, 300 + bb), Vector2(1060, 300 + bb), Vector2(1160, 380 + bb), Vector2(1220, 860)]), Color("0a0204"))
			for k in 8:
				var tx := 700.0 + k * 74.0
				draw_colored_polygon(PackedVector2Array([Vector2(tx, 340 + bb), Vector2(tx + 38, 130 - (k % 3) * 40 + bb), Vector2(tx + 74, 340 + bb)]), Color("0a0204"))
			var ey := 440.0 + bb
			for sx in [860.0, 1060.0]:
				draw_circle(Vector2(sx, ey), 40.0, Color(1.0, 0.1, 0.05, 0.18))
				draw_colored_polygon(PackedVector2Array([Vector2(sx - 36, ey - 8), Vector2(sx + 4, ey - 24), Vector2(sx + 36, ey + 8), Vector2(sx, ey + 14)]), Color("ff3a20"))
			for i in 14:
				var hx := 90.0 + i * 130.0
				draw_circle(Vector2(hx, 800.0 + (i % 3) * 20.0), 18.0, Color(0.1, 0.0, 0.0))
				draw_circle(Vector2(hx - 5, 796.0 + (i % 3) * 20.0), 3.0, Color("ff3020"))
		"gift":
			_sky(Color("0a0e1c"), Color("304060"))
			_ground(860.0, Color("06070c"))
			_hero(Vector2(960, 880), 2.2, false)
			for k in 4:
				var a0 := t * 0.8 + k * TAU / 4.0
				var pc: Color = [Color("ff9a40"), Color("60c0ff"), Color("c0ff80"), Color("e080ff")][k]
				for j in 10:
					var u := fposmod(t * 0.25 + j * 0.1 + k * 0.05, 1.0)
					var r := 520.0 * (1.0 - u)
					draw_circle(Vector2(960, 640) + Vector2(cos(a0 + u * 5.0), sin(a0 + u * 5.0) * 0.6) * r, 8.0 * (1.0 - u) + 2.0, Color(pc, 0.7))
			for r in 5:
				draw_circle(Vector2(960, 700), 90.0 + r * 40.0, Color(0.6, 0.8, 1.0, 0.04))
		"farewell":
			_sky(Color("1a1018"), Color("5a3a48"))
			_ground(850.0, Color("0a080c"))
			_chapel(420.0, 850.0, 1.5, true)
			draw_rect(Rect2(640, 520, 130, 330), Color("2a1c10"))
			draw_circle(Vector2(705, 520), 65.0, Color("2a1c10"))
			draw_rect(Rect2(660, 540, 90, 310), Color(1.0, 0.7, 0.35, 0.55))
			_hero(Vector2(1120, 890), 1.9, false)
			draw_colored_polygon(PackedVector2Array([Vector2(1450, 890), Vector2(1470, 560), Vector2(1550, 560), Vector2(1570, 890)]), Color("2a2438"))
			draw_circle(Vector2(1510, 520), 36.0, Color("c0a890"))
			draw_arc(Vector2(1510, 512), 38.0, PI, TAU, 12, Color("c8c8d0"), 14.0)
			draw_line(Vector2(1450, 700), Vector2(1260, 690), Color("2a2438"), 12.0)
			draw_line(Vector2(1230, 650), Vector2(1230, 790), Color("c8c8d8"), 8.0)
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


