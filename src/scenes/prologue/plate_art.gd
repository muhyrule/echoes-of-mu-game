extends Control
## One illustrated prologue plate. Set `art` and `t`; the controller cross-fades two of these.

var art := "age"
var t := 0.0
var duration := 30.0
var zoom := 1.0
var pan := Vector2.ZERO
var stars: Array = []
var glow_texture: GradientTexture2D


func _ready() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0)])
	glow_texture = GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.width = 256
	glow_texture.height = 256
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 120:
		stars.append(Vector3(rng.randf(), rng.randf() * 0.6, rng.randf()))


const OFF := Vector2(0, -110)
const CEN := Vector2(960, 420)
const FOCUS := {"farewell": Vector2(1300, 640), "listener": Vector2(650, 640), "belfry": Vector2(560, 640), "foundling": Vector2(800, 700), "price": Vector2(700, 640), "gift": Vector2(960, 620), "echo": Vector2(960, 600), "cloister": Vector2(960, 560), "binding": Vector2(960, 620), "crack": Vector2(960, 520), "carts": Vector2(1200, 660), "kirkyard": Vector2(1100, 640), "snowchapel": Vector2(1100, 660), "edin": Vector2(1240, 660), "praha": Vector2(1240, 660)}
const GRADE := {"rift": Color(0.6, 0.0, 0.0, 0.1), "abom": Color(0.5, 0.0, 0.0, 0.1), "crack": Color(0.5, 0.02, 0.0, 0.08), "toll": Color(0.5, 0.1, 0.0, 0.07), "foundry": Color(0.7, 0.3, 0.0, 0.09), "snowchapel": Color(0.5, 0.6, 0.9, 0.07), "foundling": Color(0.3, 0.4, 0.8, 0.07), "gift": Color(0.7, 0.1, 0.0, 0.07), "price": Color(0.5, 0.0, 0.0, 0.08), "cloister": Color(0.2, 0.3, 0.4, 0.06)}
const FLASH := ["rift", "abom", "foundling", "toll", "crack", "price"]
const INTERIORS := ["echo", "cloister", "kinds", "foundry", "binding", "belfry", "price", "gift", "gates"]
var cen := CEN
var shake := Vector2.ZERO


func _draw() -> void:
	var u := clampf(t / duration, 0.0, 1.0)
	var e := u * u * (3.0 - 2.0 * u)
	cen = FOCUS.get(art, CEN)
	var closeup := art in ["listener", "belfry", "price", "farewell", "foundling"]
	zoom = 1.0 + (0.36 if closeup else 0.12) * e
	pan = Vector2(-(u - 0.5) * 60.0, sin(t * 0.35) * 1.5)
	var pulse := 0.0
	if art in ["crack", "toll", "rift", "abom"]:
		pulse = exp(-absf(t - duration * 0.36) * 3.0)
	shake = Vector2(sin(t * 51.0), cos(t * 43.0)) * pulse * 4.0
	pan += shake
	plate(u)
	_cine()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _tf(p := Vector2.ZERO, r := 0.0, sc := Vector2.ONE) -> void:
	draw_set_transform(OFF + pan + cen * (1.0 - zoom) + p * zoom, r, sc * zoom)


func _beat(start: float, end: float) -> float:
	return smoothstep(duration * start, duration * end, t)


func _sky(a: Color, b: Color) -> void:
	for i in 27:
		draw_rect(Rect2(0, i * 40, 1920, 41), a.lerp(b, float(i) / 26.0))
	if art not in INTERIORS:
		for s in stars:
			var tw := 0.5 + 0.5 * sin(t * 0.6 + s.z * 20.0)
			draw_circle(Vector2(s.x * 1920.0, s.y * 1080.0), 1.0 + s.z, Color(1, 1, 1, 0.12 + 0.25 * tw))
		for band in 5:
			var cy := 270.0 + band * 65.0
			for cloud in 6:
				var cx := fposmod(cloud * 430.0 + band * 110.0 - t * (3.0 + band), 2600.0) - 350.0
				_tf(Vector2(cx, cy), 0, Vector2(2.5, 0.19))
				draw_circle(Vector2.ZERO, 100.0, Color(0.5, 0.55, 0.65, 0.035))
		_tf()
	else:
		_vaulted_hall()


func _moon(p: Vector2, r: float, col: Color) -> void:
	_glow(p, r * 2.8, col, 0.45)
	draw_circle(p, r, col)
	for i in 18:
		var a := i * 2.39996
		var d := sqrt((i + 1.0) / 20.0) * r * 0.78
		draw_circle(p + Vector2(cos(a), sin(a)) * d, r * (0.025 + (i % 4) * 0.02), Color(0.28, 0.3, 0.36, 0.1))


func _glow(p: Vector2, r: float, col: Color, a := 0.5) -> void:
	draw_texture_rect(glow_texture, Rect2(p - Vector2.ONE * r, Vector2.ONE * r * 2), false, Color(col, a))


func _brick(x: float, y: float, w: float, h: float, col: Color) -> void:
	var line := col.darkened(0.35)
	var rows := int(h / 22.0)
	for r in rows:
		draw_line(Vector2(x, y + r * 22.0), Vector2(x + w, y + r * 22.0), Color(line, 0.5), 1.0)
		for c in int(w / 44.0) + 1:
			var bx := x + c * 44.0 + (r % 2) * 22.0
			if bx < x + w:
				draw_line(Vector2(bx, y + r * 22.0), Vector2(bx, y + r * 22.0 + 22.0), Color(line, 0.4), 1.0)


func _window(c: Vector2, w: float, h: float, col: Color, ph: float) -> void:
	var fl := 0.82 + 0.18 * sin(t * 7.0 + ph * 3.1) * sin(t * 2.3 + ph)
	var pts := PackedVector2Array([Vector2(c.x - w / 2, c.y), Vector2(c.x - w / 2, c.y - h * 0.65), Vector2(c.x - w * 0.3, c.y - h * 0.9), Vector2(c.x, c.y - h), Vector2(c.x + w * 0.3, c.y - h * 0.9), Vector2(c.x + w / 2, c.y - h * 0.65), Vector2(c.x + w / 2, c.y)])
	draw_colored_polygon(pts, Color(col, 0.95 * fl))
	draw_colored_polygon(PackedVector2Array([Vector2(c.x - w / 2, c.y - h * 0.5), Vector2(c.x + w / 2, c.y - h * 0.5), Vector2(c.x + w / 2, c.y), Vector2(c.x - w / 2, c.y)]), Color(1.0, 0.95, 0.8, 0.18 * fl))
	draw_line(Vector2(c.x, c.y), Vector2(c.x, c.y - h), Color(0.05, 0.03, 0.03, 0.85), maxf(2.0, w * 0.07))
	draw_line(Vector2(c.x - w / 2, c.y - h * 0.4), Vector2(c.x + w / 2, c.y - h * 0.4), Color(0.05, 0.03, 0.03, 0.85), maxf(2.0, w * 0.06))
	draw_polyline(pts, Color("0a0608"), maxf(3.0, w * 0.12))
	_glow(c + Vector2(0, -h * 0.4), w * 3.0, col, 0.5 * fl)


func _chapel(x: float, y: float, s: float, lit: bool) -> void:
	var c := Color("1a1a2c")
	var lt := Color("2c2c44")
	var wc := Color("ffb860") if lit else Color("30304a")
	draw_rect(Rect2(x - 150 * s, y - 160 * s, 300 * s, 160 * s), c)
	_brick(x - 150 * s, y - 160 * s, 300 * s, 160 * s, c)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 170 * s, y - 160 * s), Vector2(x, y - 270 * s), Vector2(x + 170 * s, y - 160 * s)]), c.darkened(0.15))
	for r in 7:
		var u := r / 7.0
		draw_line(Vector2(x - (170 - 170 * u * 0.9) * s, y - (160 + 110 * u * 0.9) * s), Vector2(x + (170 - 170 * u * 0.9) * s, y - (160 + 110 * u * 0.9) * s), Color(0, 0, 0, 0.3), 1.5)
	draw_line(Vector2(x - 170 * s, y - 160 * s), Vector2(x, y - 270 * s), lt, 3.0)
	draw_rect(Rect2(x + 80 * s, y - 420 * s, 80 * s, 270 * s), c.lightened(0.04))
	_brick(x + 80 * s, y - 420 * s, 80 * s, 270 * s, c)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 70 * s, y - 420 * s), Vector2(x + 120 * s, y - 560 * s), Vector2(x + 170 * s, y - 420 * s)]), c.darkened(0.1))
	draw_line(Vector2(x + 120 * s, y - 560 * s), Vector2(x + 120 * s, y - 600 * s), lt, 3.0)
	draw_line(Vector2(x + 108 * s, y - 586 * s), Vector2(x + 132 * s, y - 586 * s), lt, 3.0)
	for g in 4:
		var gx := x + (86 + g * 24) * s
		draw_line(Vector2(gx, y - 420 * s), Vector2(gx + 6 * s, y - 396 * s), lt, 2.0)
	for b in 3:
		var bx := x - 150 * s + b * 150 * s
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 10 * s, y), Vector2(bx + 10 * s, y), Vector2(bx + 6 * s, y - 150 * s), Vector2(bx - 6 * s, y - 150 * s)]), c.lightened(0.05))
	for i in 3:
		_window(Vector2(x - 100 * s + i * 62 * s + 13 * s, y - 60 * s), 28 * s, 70 * s, wc, i + x * 0.01)
	_rose(Vector2(x - 38 * s, y - 205 * s), 24 * s, Color(wc, 0.8))
	_window(Vector2(x + 120 * s, y - 350 * s), 34 * s, 64 * s, wc, 4.0 + x * 0.01)
	draw_circle(Vector2(x + 120 * s, y - 380 * s), 3.0 * s, Color(0, 0, 0, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 24 * s, y), Vector2(x - 24 * s, y - 40 * s), Vector2(x, y - 62 * s), Vector2(x + 24 * s, y - 40 * s), Vector2(x + 24 * s, y)]), Color("0a0608"))
	if lit:
		_glow(Vector2(x, y - 10 * s), 140 * s, Color(1.0, 0.7, 0.35), 0.35)


func _spires(y: float, col: Color, off: float) -> void:
	for layer in 2:
		var lc := col.lightened(0.07) if layer == 0 else col
		var lo := off * (0.5 if layer == 0 else 1.0) + (60.0 if layer == 0 else 0.0)
		for i in 14:
			var x := i * 150.0 + lo
			var h := 160.0 + (i * 53 % 7) * 40.0
			if layer == 0:
				h *= 0.7
			var w := 56.0
			draw_rect(Rect2(x, y - h, w, h + 300), lc)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y - h), Vector2(x + 28, y - h - 120 - (i % 3) * 30), Vector2(x + 64, y - h)]), lc)
			if layer == 1:
				var tip := Vector2(x + 28, y - h - 120 - (i % 3) * 30)
				draw_line(tip, tip + Vector2(0, -26), lc, 3.0)
				draw_line(tip + Vector2(-9, -16), tip + Vector2(9, -16), lc, 3.0)
				for cr in 4:
					var u := (cr + 1) / 5.0
					draw_circle(Vector2(x - 8 + 36 * u * 0.5, y - h - (120 + (i % 3) * 30) * u * 0.9), 3.0, lc.lightened(0.2))
					draw_circle(Vector2(x + 64 - 36 * u * 0.5, y - h - (120 + (i % 3) * 30) * u * 0.9), 3.0, lc.lightened(0.2))
				draw_rect(Rect2(x + 22, y - h + 30, 12, 30), Color(0.02, 0.02, 0.03, 0.9))
				draw_line(Vector2(x, y - h + 6), Vector2(x + w, y - h + 6), lc.lightened(0.18), 2.0)
				if i % 4 == 1:
					_window(Vector2(x + 28, y - h + 120), 14, 34, Color("ffb860"), i)


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
	draw_rect(Rect2(-300, y, 2520, 1200 - y), col)
	if art == "snowchapel":
		for i in 28:
			draw_arc(Vector2(i * 80, y + 20 + (i % 3) * 12), 90, PI * 1.1, PI * 1.9, 16, Color(1, 1, 1, 0.12), 3.0)
		return
	var mortar := col.lightened(0.08)
	for row in 7:
		var near := row / 6.0
		var fy := y + near * near * (1200 - y)
		draw_line(Vector2(-300, fy), Vector2(2220, fy), Color(mortar, 0.65), 1.4)
	for i in 25:
		var x := -500.0 + i * 120.0
		draw_line(Vector2(960 + (x - 960) * 0.18, y), Vector2(x, 1200), Color(mortar, 0.5), 1.2)
	if art in ["foundling", "road", "edin", "praha", "carts", "toll"]:
		for i in 32:
			var px := 60.0 + fposmod(i * 173.0, 1800)
			var py := y + 12 + (i % 4) * 12.0
			var rw := 8.0 + (i % 7) * 4.0
			draw_line(Vector2(px - rw, py), Vector2(px + rw, py), Color(0.6, 0.65, 0.75, 0.08 + sin(t + i) * 0.025), 1.8)


func _arch_curve(c: Vector2, w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for side in 2:
		for k in 17:
			var u := k / 16.0 if side == 0 else 1.0 - k / 16.0
			var x := -w * 0.5 * (1.0 - u) if side == 0 else w * 0.5 * (1.0 - u)
			pts.append(c + Vector2(x, -h * (0.65 + 0.35 * sqrt(u))))
	return pts


func _vaulted_hall() -> void:
	var warm := art in ["foundry", "binding", "gift"]
	var stone := Color("242b34") if not warm else Color("302a25")
	draw_rect(Rect2(-250, 120, 2420, 780), stone.darkened(0.35))
	_brick(-250, 160, 2420, 650, stone)
	for bay in 5:
		var x := 160.0 + bay * 400.0
		var c := Vector2(x, 850)
		var arch := _arch_curve(c, 300, 610)
		var niche := PackedVector2Array(arch)
		niche.append(c + Vector2(150, 0))
		niche.append(c - Vector2(150, 0))
		draw_colored_polygon(niche, Color("090d14"))
		draw_polyline(arch, stone.lightened(0.12), 15.0)
		draw_polyline(_arch_curve(c, 270, 588), Color("111720"), 5.0)
		for side in [-1.0, 1.0]:
			var px: float = x + side * 150
			draw_rect(Rect2(px - 10, 454, 20, 400), stone)
			draw_line(Vector2(px - 7, 454), Vector2(px - 7, 850), stone.lightened(0.12), 2.0)
			draw_rect(Rect2(px - 20, 462, 40, 12), stone.lightened(0.06))
			draw_rect(Rect2(px - 18, 825, 36, 24), stone.darkened(0.2))
		if bay % 2 == 0:
			_window(Vector2(x, 520), 78, 180, Color("a87b45") if warm else Color("49657a"), bay)
			_rose(Vector2(x, 360), 24, Color("c5a873"))
	for side in [-1.0, 1.0]:
		var rib := PackedVector2Array()
		for k in 25:
			var u := k / 24.0
			rib.append(Vector2(960 + side * 1150 * (1.0 - u), 210 + 210 * pow(1.0 - u, 2.0)))
		draw_polyline(rib, stone.lightened(0.1), 8.0)
		draw_polyline(rib, Color(0, 0, 0, 0.4), 2.0)
	for i in 6:
		_candle(Vector2(110 + i * 345, 810), 0.8 + (i % 2) * 0.2, i)


func _candle(c: Vector2, s: float, ph: float) -> void:
	var fl := sin(t * 4.3 + ph) * 2.0
	draw_rect(Rect2(c.x - 15 * s, c.y - 5 * s, 30 * s, 5 * s), Color("4f3b2a"))
	draw_rect(Rect2(c.x - 6 * s, c.y - 46 * s, 12 * s, 41 * s), Color("b7a583"))
	draw_rect(Rect2(c.x + 1 * s, c.y - 46 * s, 5 * s, 41 * s), Color("74664d"))
	for drip in 3:
		draw_line(c + Vector2((-4 + drip * 4) * s, -43 * s), c + Vector2((-4 + drip * 4) * s, (-30 + drip * 4) * s), Color("d8c7a5"), 2 * s)
	var f := c + Vector2(0, -50 * s)
	_glow(f, 100 * s, Color("ffad50"), 0.6)
	draw_colored_polygon(PackedVector2Array([f + Vector2(-5 * s, 0), f + Vector2(fl * s, -19 * s), f + Vector2(5 * s, 0), f + Vector2(0, 4 * s)]), Color("e88935"))
	draw_line(f, f + Vector2(fl * s * 0.5, -10 * s), Color("ffe9ac"), 3 * s)


func _reliquary(c: Vector2, s: float, col: Color, kind: int) -> void:
	_tf(c, 0, Vector2.ONE * s)
	draw_rect(Rect2(-65, 0, 130, 16), Color("333039"))
	draw_rect(Rect2(-50, -18, 100, 18), Color("25232c"))
	var arch := _arch_curve(Vector2.ZERO, 100, 180)
	draw_polyline(arch, Color("8f7851"), 7.0)
	draw_line(Vector2(-50, -117), Vector2(-50, 0), Color("8f7851"), 7.0)
	draw_line(Vector2(50, -117), Vector2(50, 0), Color("8f7851"), 7.0)
	_glow(Vector2(0, -85), 100, col, 0.8)
	match kind % 3:
		0:
			for i in 3:
				var wave := PackedVector2Array()
				for k in 25:
					wave.append(Vector2(-32 + k * 2.7, -50 - i * 20 + sin(k * 0.3 + t * 1.5) * 7))
				draw_polyline(wave, col, 2.5)
		1:
			draw_circle(Vector2(0, -85), 32, col.darkened(0.3))
			draw_arc(Vector2(0, -85), 32, 0, TAU, 32, col, 3)
			for k in 8:
				var a := k * TAU / 8
				draw_line(Vector2(0, -85) + Vector2(cos(a), sin(a)) * 25, Vector2(0, -85) + Vector2(cos(a), sin(a)) * 30, col, 2)
			draw_line(Vector2(0, -85), Vector2(sin(t * 0.2) * 20, -105), col, 3)
		2:
			draw_circle(Vector2(0, -91), 22, col.darkened(0.35))
			for side in [-1.0, 1.0]:
				draw_circle(Vector2(side * 9, -94), 6, Color("100709"))
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -78), Vector2(8, -78), Vector2(0, -68)]), col)
			for tooth in 5:
				draw_line(Vector2(-12 + tooth * 6, -71), Vector2(-12 + tooth * 6, -64), col, 3)
	_tf()


func _rose(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, Color(col, 0.25))
	draw_arc(c, r, 0, TAU, 32, col, 4.0)
	draw_arc(c, r * 0.4, 0, TAU, 20, col, 3.0)
	for k in 12:
		var a := k * TAU / 12.0
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.4, c + Vector2(cos(a), sin(a)) * r, col, 3.0)
		draw_arc(c + Vector2(cos(a + 0.26), sin(a + 0.26)) * r * 0.7, r * 0.16, 0, TAU, 8, col, 2.0)


func _pointed(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(x - w / 2, y - h, w, h), col)
	draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, y - h), Vector2(x, y - h - w * 0.9), Vector2(x + w / 2, y - h)]), col)


func _crow(p: Vector2, ph: float) -> void:
	var fl := sin(t * 7.0 + ph) * 8.0
	draw_polyline(PackedVector2Array([p + Vector2(-14, -fl), p + Vector2(-4, 2), p + Vector2(0, 0), p + Vector2(4, 2), p + Vector2(14, -fl)]), Color("050408"), 3.0)


func _tomb(x: float, y: float, s: float, cross: bool) -> void:
	var c := Color("12121c")
	var hi := Color("2a2a3c")
	if cross:
		draw_rect(Rect2(x - 5 * s, y - 70 * s, 10 * s, 70 * s), c)
		draw_rect(Rect2(x - 22 * s, y - 52 * s, 44 * s, 9 * s), c)
		draw_line(Vector2(x - 5 * s, y - 70 * s), Vector2(x - 5 * s, y), hi, 1.5)
		draw_line(Vector2(x - 22 * s, y - 52 * s), Vector2(x + 22 * s, y - 52 * s), hi, 1.5)
		draw_circle(Vector2(x, y - 48 * s), 4 * s, hi)
	else:
		draw_rect(Rect2(x - 20 * s, y - 40 * s, 40 * s, 40 * s), c)
		draw_circle(Vector2(x, y - 40 * s), 20 * s, c)
		draw_arc(Vector2(x, y - 40 * s), 20 * s, PI, TAU, 14, hi, 1.5)
		draw_line(Vector2(x - 20 * s, y - 40 * s), Vector2(x - 20 * s, y), hi, 1.5)
		for l in 3:
			draw_line(Vector2(x - 9 * s, y - 36 * s + l * 7 * s), Vector2(x + 9 * s - l * 3 * s, y - 36 * s + l * 7 * s), Color(0, 0, 0, 0.5), 1.5)
	draw_circle(Vector2(x + 14 * s, y), 9 * s, Color(0.12, 0.2, 0.12, 0.5))
	draw_circle(Vector2(x - 12 * s, y + 1), 7 * s, Color(0.12, 0.2, 0.12, 0.5))


func _bell(c: Vector2, s: float, col: Color, crack: float) -> void:
	var sw := sin(t * 1.4) * 0.03
	draw_rect(Rect2(c.x - 120 * s, c.y - 134 * s, 240 * s, 16 * s), Color("2a1c12"))
	draw_line(c + Vector2(-120 * s, -118 * s), c + Vector2(-90 * s, -80 * s), Color("2a1c12"), 8 * s)
	draw_line(c + Vector2(120 * s, -118 * s), c + Vector2(90 * s, -80 * s), Color("2a1c12"), 8 * s)
	draw_line(c + Vector2(0, -120 * s), c + Vector2(0, -80 * s), Color("2a2018"), 8.0 * s)
	_tf(c, sw, Vector2.ONE)
	var o := Vector2.ZERO
	var body := PackedVector2Array([o + Vector2(-34 * s, -80 * s), o + Vector2(34 * s, -80 * s), o + Vector2(50 * s, -20 * s), o + Vector2(90 * s, 50 * s), o + Vector2(-90 * s, 50 * s), o + Vector2(-50 * s, -20 * s)])
	draw_colored_polygon(body, col)
	draw_colored_polygon(PackedVector2Array([o + Vector2(8 * s, -80 * s), o + Vector2(34 * s, -80 * s), o + Vector2(50 * s, -20 * s), o + Vector2(90 * s, 50 * s), o + Vector2(30 * s, 50 * s)]), Color(0, 0, 0, 0.32))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-30 * s, -76 * s), o + Vector2(-18 * s, -76 * s), o + Vector2(-30 * s, 40 * s), o + Vector2(-70 * s, 44 * s), o + Vector2(-44 * s, -20 * s)]), Color(1, 1, 1, 0.12))
	for b in 3:
		var by := -40.0 + b * 26.0
		draw_line(o + Vector2(-(50 + b * 14) * s, by * s), o + Vector2((50 + b * 14) * s, by * s), col.lightened(0.25), 3.0 * s)
	for g in 8:
		var gx := -60.0 + g * 17.0
		draw_line(o + Vector2(gx * s, -4 * s), o + Vector2(gx * s, 16 * s), col.darkened(0.4), 2.0 * s)
	draw_rect(Rect2(o.x - 90 * s, o.y + 44 * s, 180 * s, 12 * s), col.darkened(0.3))
	draw_circle(o + Vector2(0, 68 * s + sin(t * 2.8) * 4.0 * s), 14 * s, Color("1a1410"))
	if crack > 0.0:
		var pts := PackedVector2Array([o + Vector2(-6 * s, -70 * s), o + Vector2(8 * s, -30 * s), o + Vector2(-10 * s, 0), o + Vector2(12 * s, 30 * s), o + Vector2(-4 * s, 50 * s)])
		draw_polyline(pts, Color(1.0, 0.25, 0.15, crack * 0.4), 14.0 * s)
		draw_polyline(pts, Color(1.0, 0.45, 0.3, crack), 5.0 * s)
		draw_polyline(pts, Color(1.0, 0.9, 0.7, crack), 1.8 * s)
	_tf()


func _fog(y: float, a: float) -> void:
	for layer in 2:
		for i in 7:
			var sp := 14.0 + layer * 22.0
			var fx := fposmod(i * 420.0 - t * sp * (1 + i % 2) + layer * 150.0, 2900.0) - 400.0
			var fy := y + (i % 3) * 22.0 + layer * 30.0 + sin(t * 0.4 + i) * 8.0
			_tf(Vector2(fx + 300, fy), 0, Vector2(1, 0.16 + 0.05 * layer))
			draw_circle(Vector2.ZERO, 300.0 + layer * 60.0, Color(0.75, 0.7, 0.74, a * (0.7 + 0.5 * layer)))
			_tf()


func _skyline(y: float, col: Color, glow: bool, clock: bool) -> void:
	for layer in 2:
		var lc := col.lightened(0.08) if layer == 0 else col
		for i in 16:
			var x := 60.0 + i * 120.0 + (50.0 if layer == 0 else 0.0)
			var h := 140.0 + ((i + layer * 3) * 71 % 9) * 36.0
			if layer == 0:
				h *= 0.75
			draw_rect(Rect2(x - 40, y - h, 80, h + 400), lc)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 48, y - h), Vector2(x, y - h - 70 - (i % 4) * 36), Vector2(x + 48, y - h)]), lc)
			draw_line(Vector2(x - 40, y - h), Vector2(x - 40, y), lc.lightened(0.15), 2.0)
			if layer == 1:
				for wy in 3:
					draw_rect(Rect2(x - 22 + (wy % 2) * 24, y - h + 50 + wy * 56, 12, 22), Color(0.02, 0.02, 0.03, 0.8))
				if glow and i % 2 == 0:
					_window(Vector2(x, y - h + 70), 18, 34, Color(1.0, 0.7, 0.3), i)
				draw_rect(Rect2(x + 22, y - h - 20, 10, 28), lc)
				var sm := fposmod(t * 0.2 + i * 0.13, 1.0)
				draw_circle(Vector2(x + 27 + sm * 30.0, y - h - 24 - sm * 120.0), 8.0 + sm * 20.0, Color(0.5, 0.5, 0.55, 0.12 * (1.0 - sm)))
	if clock:
		draw_circle(Vector2(960, y - 330), 80.0, Color("8a6a30"))
		draw_circle(Vector2(960, y - 330), 70.0, Color("c8a050"))
		draw_circle(Vector2(960, y - 330), 58.0, Color("1a1410"))
		for h in 12:
			var a := h * TAU / 12.0
			draw_line(Vector2(960, y - 330) + Vector2(cos(a), sin(a)) * 48.0, Vector2(960, y - 330) + Vector2(cos(a), sin(a)) * 56.0, Color("c8a050"), 3.0)
		draw_line(Vector2(960, y - 330), Vector2(960 + cos(t * 0.5) * 40, y - 330 + sin(t * 0.5) * 40), Color("c8a050"), 4.0)
		draw_line(Vector2(960, y - 330), Vector2(960, y - 380), Color("c8a050"), 3.0)
		_glow(Vector2(960, y - 330), 220.0, Color(1.0, 0.75, 0.4), 0.4)


func _cine() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if GRADE.has(art):
		draw_rect(Rect2(0, 100, 1920, 670), GRADE[art])
	if art in FLASH:
		var fh := absf(t - duration * 0.36)
		var fa := 0.12 * exp(-fh * 5.0)
		if fa > 0.0:
			draw_rect(Rect2(0, 100, 1920, 670), Color(1.0, 0.5, 0.45, fa) if art != "foundling" else Color(0.8, 0.85, 1.0, fa))
	if art == "foundling" or art == "road" or art == "toll":
		for i in 90:
			var rx := fposmod(i * 67.0 - t * 220.0, 2000.0)
			var ry := fposmod(i * 53.0 + t * 900.0, 700.0) + 100.0
			draw_line(Vector2(rx, ry), Vector2(rx - 8, ry + 30), Color(0.7, 0.75, 0.9, 0.22), 1.5)
	if art in ["foundry", "crack", "rift", "abom"]:
		for i in 50:
			var u := fposmod(t * 0.14 + i * 0.0377, 1.0)
			var ex := fposmod(i * 211.0 + sin(t + i) * 60.0, 1920.0)
			draw_circle(Vector2(ex, 770.0 - u * 670.0), 1.6 + (i % 3), Color(1.0, 0.5 + 0.3 * sin(i), 0.2, 0.8 * (1.0 - u)))
	var fgx := -pan.x * 1.8
	for side in (0 if art in INTERIORS else 2):
		var bx := 0.0 if side == 0 else 1920.0
		var sg := 1.0 if side == 0 else -1.0
		for i in 16:
			var gx := bx + sg * (10.0 + i * 24.0) + fgx * 0.4
			var gh := 40.0 + (i * 37 % 6) * 14.0 - i * 2.0
			var sway := sin(t * 1.3 + i * 0.7) * 8.0
			draw_colored_polygon(PackedVector2Array([Vector2(gx - 7, 770), Vector2(gx + sway + 2 * sg, 770 - gh), Vector2(gx + 7, 770)]), Color(0.01, 0.01, 0.015, 0.95))
		var tx := bx + sg * 20.0 + fgx * 0.5
		var tw := sin(t * 0.8 + side) * 6.0
		draw_polyline(PackedVector2Array([Vector2(tx, 100), Vector2(tx + sg * 60 + tw, 150), Vector2(tx + sg * 130 + tw, 170), Vector2(tx + sg * 210 + tw * 1.5, 230)]), Color(0.01, 0.01, 0.015, 0.9), 7.0)
		draw_polyline(PackedVector2Array([Vector2(tx + sg * 60 + tw, 150), Vector2(tx + sg * 90 + tw, 210), Vector2(tx + sg * 100 + tw, 250)]), Color(0.01, 0.01, 0.015, 0.9), 4.0)
		draw_polyline(PackedVector2Array([Vector2(tx + sg * 130 + tw, 170), Vector2(tx + sg * 190 + tw, 150), Vector2(tx + sg * 250 + tw, 160)]), Color(0.01, 0.01, 0.015, 0.9), 3.0)
	for k in 4:
		var sx := fposmod(300.0 + k * 520.0 + t * 12.0, 2200.0) - 150.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, 100), Vector2(sx + 90, 100), Vector2(sx - 160, 770), Vector2(sx - 290, 770)]), Color(1.0, 0.85, 0.6, 0.025 + 0.012 * sin(t * 0.7 + k)))
	for i in 70:
		var fx := fposmod(i * 131.0 + t * (6.0 + i % 7) + sin(t * 0.6 + i) * 30.0, 1920.0)
		var fy := fposmod(i * 71.0 - t * (4.0 + i % 5), 670.0) + 100.0
		var tw := 0.5 + 0.5 * sin(t * 1.3 + i * 2.1)
		draw_circle(Vector2(fx, fy), 1.2 + (i % 3) * 0.7, Color(1.0, 0.9, 0.75, 0.10 + 0.2 * tw))
	for k in 14:
		var a := 0.30 * pow(1.0 - k / 14.0, 2.0)
		draw_rect(Rect2(0, 100 + k * 9, 1920, 9), Color(0, 0, 0, a))
		draw_rect(Rect2(0, 770 - (k + 1) * 9, 1920, 9), Color(0, 0, 0, a))
		draw_rect(Rect2(k * 14, 100, 14, 670), Color(0, 0, 0, a))
		draw_rect(Rect2(1920 - (k + 1) * 14, 100, 14, 670), Color(0, 0, 0, a))
	draw_rect(Rect2(0, 100, 1920, 670), Color(0.0, 0.0, 0.0, 0.03 + 0.02 * sin(t * 23.0)))


func _poly_outline(pts: PackedVector2Array, col: Color, w: float) -> void:
	var cl := PackedVector2Array(pts)
	cl.append(pts[0])
	draw_polyline(cl, col, w)


func _hand(h: Vector2, skin: Color, curl: float) -> void:
	var palm := PackedVector2Array([h + Vector2(-4, -5), h + Vector2(3, -5), h + Vector2(5, 0), h + Vector2(3, 6), h + Vector2(-3, 5)])
	draw_colored_polygon(palm, skin)
	_poly_outline(palm, skin.darkened(0.3), 0.9)
	for k in 3:
		var finger := h + Vector2(-2 + k * 2.0, 3)
		draw_line(finger, finger + Vector2(curl * 2, 4.0 - absf(k - 1.0)), skin.darkened(0.08), 1.7)
	draw_line(h + Vector2(3, -1), h + Vector2(6, 2 + curl), skin, 2.3)


# who: mu, kid, aldous, monk, bellman, echo, keeper. f = facing (+1 right, -1 left). gest 0..1 raises the front arm.
func _person(p: Vector2, s: float, who: String, f := 1.0, mood := "calm", lamp := false, ph := 0.0, gest := 0.0) -> void:
	var sw := sin(t * 1.7 + ph)
	var br := sin(t * 1.9 + ph) * 1.6
	var kid := who == "kid"
	var k := 0.62 if kid else 1.0
	var echo := who == "echo"
	var cloak := Color("353a48")
	var inner := Color("7a2a2e")
	var skin := Color("d8b090")
	var hair := Color("a8a6ae")
	var rim := Color(1.0, 0.72, 0.4, 0.55)
	match who:
		"aldous":
			cloak = Color("2a2430")
			inner = Color("40343c")
			skin = Color("c8a080")
			hair = Color("c8c4c0")
		"monk":
			cloak = Color("1a1416")
			inner = Color("2a2226")
			hair = Color("20161a")
		"bellman":
			cloak = Color("2a1c18")
			inner = Color("402a20")
			skin = Color("b89070")
			hair = Color("20161a")
		"smith":
			cloak = Color("33261f")
			inner = Color("71533a")
			skin = Color("b78e70")
			hair = Color("322b27")
		"echo":
			cloak = Color(0.45, 0.06, 0.08, 0.6)
			inner = Color(0.7, 0.12, 0.12, 0.5)
			skin = Color(0.85, 0.5, 0.45, 0.7)
			hair = Color(0.3, 0.04, 0.05, 0.7)
			rim = Color(1.0, 0.3, 0.2, 0.7)
		"keeper":
			cloak = Color("2e2a24")
			inner = Color("463e34")
			skin = Color("c0a088")
			hair = Color("8a8680")
		"kid":
			cloak = Color("353a48")
			inner = Color("7a2a2e")
			hair = Color("a8a6ae")
	var at := p + Vector2(0, -34)
	_tf(at, 0, Vector2(s * k * f, s * k))
	var ell := PackedVector2Array()
	for e in 16:
		ell.append(Vector2(cos(e * TAU / 16.0) * 56.0, 34.0 + sin(e * TAU / 16.0) * 9.0))
	draw_colored_polygon(ell, Color(0, 0, 0, 0.35))
	if echo:
		for r in 5:
			draw_circle(Vector2(0, -90), 150.0 - r * 24.0, Color(1.0, 0.2, 0.15, 0.03 + 0.012 * sin(t * 2.0)))
	var hem := sw * 7.0
	var body := PackedVector2Array([Vector2(-26, -128 + br), Vector2(26, -128 + br), Vector2(44 + hem, 0), Vector2(14, 6), Vector2(-14, 6), Vector2(-44 + hem, 0)])
	draw_colored_polygon(PackedVector2Array([Vector2(-30, 28), Vector2(-14, 24), Vector2(-8, 36), Vector2(-34, 36)]), Color("0a0608"))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 24), Vector2(24, 28), Vector2(32, 36), Vector2(4, 36)]), Color("0a0608"))
	draw_colored_polygon(body, cloak)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -128 + br), Vector2(26, -128 + br), Vector2(44 + hem, 0), Vector2(14, 6), Vector2(2, 5)]), Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -128 + br), Vector2(10, -128 + br), Vector2(22 + hem * 0.6, 0), Vector2(-6, 4)]), inner)
	for fold in 5:
		var fx := -22.0 + fold * 11.0
		draw_line(Vector2(fx * 0.6, -100 + br), Vector2(fx * 1.5 + hem * (fold / 4.0), -2), Color(0, 0, 0, 0.28), 2.0)
		draw_line(Vector2(fx * 0.6 + 2, -100 + br), Vector2(fx * 1.5 + hem * (fold / 4.0) + 2, -2), Color(1, 1, 1, 0.05), 1.5)
	draw_line(Vector2(-26, -126 + br), Vector2(-44 + hem, 0), rim, 2.5)
	_poly_outline(body, Color(0.02, 0.01, 0.02, 0.85), 2.5)
	draw_line(Vector2(-20, -74 + br), Vector2(20, -74 + br), Color("0c0808"), 5.0)
	draw_rect(Rect2(-4, -77 + br, 8, 6), Color("b89038"))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -128 + br), Vector2(0, -116 + br), Vector2(28, -128 + br), Vector2(22, -134 + br), Vector2(-22, -134 + br)]), inner.lightened(0.12))
	var back := Vector2(-35, -62 + br)
	if who == "aldous" or who == "keeper":
		var hp := Vector2(-42, -84 + br)
		draw_line(Vector2(-26, -126 + br), hp, cloak, 12.0)
		draw_line(Vector2(-42, -156), Vector2(-42, 36), Color("4a3826"), 5.0)
		draw_line(Vector2(-43, -156), Vector2(-43, 36), Color("7a6444"), 1.5)
		draw_circle(Vector2(-42, -160), 8.0, Color("8a7a50"))
		_hand(hp, skin, 0.1)
	else:
		draw_line(Vector2(-26, -126 + br), back, cloak, 14.0)
		draw_line(Vector2(-26, -126 + br), back, rim, 1.5)
		_hand(back, skin, 0.3)
	if (who == "mu" or who == "kid") and art not in ["farewell", "belfry", "listener", "crack"]:
		draw_line(Vector2(-4, -126), Vector2(14, -40), Color("6a5030"), 3.0)
		draw_line(Vector2(30, -60), Vector2(30, 6), Color("c0c4d0"), 4.0)
		draw_line(Vector2(28.5, -58), Vector2(28.5, 4), Color.WHITE, 1.2)
		draw_rect(Rect2(22, -64, 16, 6), Color("a88838"))
		draw_circle(Vector2(30, -69), 4.0, Color("a88838"))
	var shoulder := Vector2(27, -124 + br)
	var hnd := Vector2(39, -73 + br).lerp(Vector2(78, -126 + br - sin(t * 3.2 + ph) * 4.0), gest)
	if art == "foundling" and who == "aldous":
		hnd = Vector2(65, -70).lerp(Vector2(53, -112), _beat(0.25, 0.65))
	if lamp and gest < 0.2:
		hnd = Vector2(48, -92 + br)
	var elbow := shoulder.lerp(hnd, 0.5) + Vector2(8.0 * (1.0 - gest), 14.0 * (1.0 - gest))
	draw_line(shoulder, elbow, cloak, 12.0)
	draw_line(elbow, hnd, cloak, 11.0)
	draw_line(shoulder, elbow, rim, 1.2)
	_hand(hnd, skin, gest * 0.6)
	if lamp and gest < 0.2:
		draw_line(hnd, hnd + Vector2(0, 14), Color("5a4630"), 2.0)
		var lp := hnd + Vector2(0, 12.0)
		draw_rect(Rect2(lp.x - 8, lp.y, 16, 24), Color("2a1c10"))
		draw_rect(Rect2(lp.x - 5, lp.y + 3, 10, 17), Color(1.0, 0.82, 0.5, 0.9 + 0.1 * sin(t * 9.0 + ph)))
		_glow(lp + Vector2(0, 12), 220.0, Color(1.0, 0.72, 0.38), 0.7 + 0.2 * sin(t * 5.0 + ph))
	draw_rect(Rect2(-7, -140 + br, 14, 16), skin.darkened(0.25))
	var hc := Vector2(0, -156 + br + sin(t * 1.1 + ph) * 0.8)
	if who == "monk":
		draw_colored_polygon(PackedVector2Array([Vector2(-36, -118 + br), Vector2(-28, -170 + br), Vector2(0, -196 + br), Vector2(28, -170 + br), Vector2(36, -118 + br)]), cloak.lightened(0.06))
		draw_line(Vector2(-28, -170 + br), Vector2(-36, -118 + br), rim, 2.0)
		draw_circle(hc + Vector2(4, 2), 21.0, Color("070406"))
		draw_arc(hc + Vector2(4, 2), 22.0, 0, TAU, 20, Color("2a2024"), 3.0)
		draw_polyline(PackedVector2Array([hc + Vector2(-8, -4), hc + Vector2(2, 10), hc + Vector2(10, -4)]), Color("695444"), 1.5)
		_done()
		return
	draw_circle(hc + Vector2(-23, 1), 4.5, skin.darkened(0.12))
	draw_circle(hc + Vector2(23, 1), 4.5, skin.darkened(0.3))
	var jaw := PackedVector2Array([hc + Vector2(-20, -10), hc + Vector2(-16, -21), hc + Vector2(0, -26), hc + Vector2(17, -18), hc + Vector2(22, -3), hc + Vector2(18, 15), hc + Vector2(6, 26), hc + Vector2(-6, 24), hc + Vector2(-18, 13)])
	draw_colored_polygon(jaw, skin)
	_poly_outline(jaw, skin.darkened(0.35), 1.1)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(6, -20), hc + Vector2(20, -8), hc + Vector2(21, 6), hc + Vector2(12, 20), hc + Vector2(2, 26), hc + Vector2(8, 4)]), Color(0, 0, 0, 0.2))
	draw_arc(hc + Vector2(-2, 1), 21.0, PI * 0.62, PI * 1.12, 10, skin.lightened(0.25), 3.0)
	draw_arc(hc, 22.0, 0.2, PI * 0.9, 14, skin.darkened(0.35), 2.0)
	draw_circle(hc + Vector2(-14, 9), 5.0, Color(0.9, 0.4, 0.35, 0.18))
	draw_circle(hc + Vector2(14, 9), 5.0, Color(0.9, 0.4, 0.35, 0.14))
	draw_colored_polygon(PackedVector2Array([Vector2(hc.x - 1, hc.y - 4), Vector2(hc.x + 5, hc.y + 10), Vector2(hc.x - 1, hc.y + 11), Vector2(hc.x - 4, hc.y + 7)]), skin.darkened(0.22))
	draw_line(Vector2(hc.x - 1, hc.y - 4), Vector2(hc.x - 3, hc.y + 7), skin.lightened(0.3), 1.2)
	var blink := fmod(t + ph * 2.0, 4.2) < 0.13
	var look := Vector2(1.4 * sin(t * 0.5 + ph), 0.4 * sin(t * 0.7 + ph))
	for e in 2:
		var ec := hc + Vector2(-8.0 + e * 17.0, -2)
		draw_circle(ec + Vector2(0, 1), 5.0, Color(0.2, 0.08, 0.1, 0.12))
		if blink:
			draw_line(ec - Vector2(5, 0), ec + Vector2(5, 0), Color("1a1010"), 2.2)
			continue
		draw_colored_polygon(PackedVector2Array([ec + Vector2(-5.5, 0), ec + Vector2(-2, -2.5), ec + Vector2(2, -2.5), ec + Vector2(5.5, 0), ec + Vector2(2, 2), ec + Vector2(-3, 2)]), Color("d4cbc0"))
		var ic := Color("ff4030") if echo else (Color("6a6050") if who == "aldous" else Color("5a7898"))
		draw_circle(ec + look, 2.2, ic)
		draw_arc(ec + look, 2.2, 0, TAU, 12, ic.darkened(0.5), 0.8)
		draw_circle(ec + look, 1.2, Color("0a0808"))
		draw_circle(ec + look + Vector2(-0.8, -0.8), 0.65, Color.WHITE)
		draw_line(ec + Vector2(-5.5, -2.5), ec + Vector2(5.5, -2.8), Color("20141a"), 1.4)
		draw_line(ec + Vector2(-5, 3), ec + Vector2(5, 3), skin.darkened(0.2), 0.8)
		if echo:
			draw_line(ec + Vector2(0, 4), ec + Vector2(1, 14 + fposmod(t * 12.0 + e * 7.0, 14.0)), Color(1.0, 0.2, 0.15, 0.6), 1.8)
	var bl := Vector2(-8, -9)
	var br2 := Vector2(9, -9)
	var tilt := 0.0
	match mood:
		"worry":
			tilt = -3.0
		"stern":
			tilt = 3.0
		"awe":
			tilt = -2.0
			bl.y -= 3.0
			br2.y -= 3.0
	var bc := hair.darkened(0.1)
	if who == "aldous" or who == "keeper":
		bc = Color("d8d4d0")
	draw_line(hc + bl + Vector2(-5, tilt * -0.5), hc + bl + Vector2(5, tilt * 0.5), bc, 2.0)
	draw_line(hc + br2 + Vector2(-5, tilt * 0.5), hc + br2 + Vector2(5, tilt * -0.5), bc, 2.0)
	var talk := 0.5 + 0.5 * sin(t * 9.0 + ph)
	var lipc := Color("7a3a38")
	match mood:
		"worry":
			draw_arc(hc + Vector2(3, 20), 5.0, PI * 1.15, PI * 1.85, 8, lipc, 2.4)
		"awe":
			draw_line(hc + Vector2(-2, 16), hc + Vector2(7, 16.8), lipc, 1.8)
		"stern":
			draw_line(hc + Vector2(-3, 17), hc + Vector2(9, 17), lipc, 2.6)
			draw_line(hc + Vector2(-3, 18.5), hc + Vector2(8, 18.5), lipc.lightened(0.2), 1.2)
		"talk":
			var mo := 1.0 + talk * 5.0
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-3, 16), hc + Vector2(9, 16), hc + Vector2(7, 16 + mo), hc + Vector2(-1, 16 + mo)]), Color("4a1c20"))
			draw_line(hc + Vector2(-3, 16), hc + Vector2(9, 16), lipc, 1.8)
		_:
			draw_arc(hc + Vector2(3, 14), 5.0, PI * 0.2, PI * 0.8, 8, lipc, 2.4)
	if who == "bellman":
		for st in 14:
			draw_circle(hc + Vector2(-8 + (st % 7) * 3.4, 14 + (st / 7) * 4.0), 0.9, Color(0, 0, 0, 0.5))
	if who == "aldous" or who == "keeper":
		draw_line(hc + Vector2(-9, 2), hc + Vector2(-9, 6), Color(0, 0, 0, 0.2), 1.2)
		draw_line(hc + Vector2(8, 1), hc + Vector2(12, 4), Color(0, 0, 0, 0.2), 1.2)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-19, 8), hc + Vector2(-10, 14), hc + Vector2(1, 20), hc + Vector2(10, 14), hc + Vector2(21, 8), hc + Vector2(13, 32 + sw * 2.0), hc + Vector2(2, 42), hc + Vector2(-12, 32)]), Color("b6b5ae"))
		for st in 6:
			draw_line(hc + Vector2(-12 + st * 5, 18), hc + Vector2(-9 + st * 4, 31 + sw * 2.0), Color(0.9, 0.89, 0.85, 0.6), 1.2)
		draw_arc(hc, 24.0, PI * 0.9, TAU + PI * 0.1, 16, hair, 9.0)
		draw_line(hc + Vector2(-14, 12), hc + Vector2(3, 10), Color("8a5a50"), 2.0)
	elif who == "smith":
		draw_arc(hc, 24, PI * 0.95, TAU + 0.2, 20, Color("514539"), 12)
		draw_line(hc + Vector2(-26, -5), hc + Vector2(25, -5), Color("77614a"), 4)
		for st in 8:
			draw_line(hc + Vector2(-14 + st * 4, 16), hc + Vector2(-12 + st * 3.5, 25), Color("3d3029"), 1)
	elif who == "bellman":
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-26, -8), hc + Vector2(-16, -32), hc + Vector2(16, -32), hc + Vector2(26, -8), hc + Vector2(40, -2), hc + Vector2(-40, -2)]), Color("1a1210"))
		draw_line(hc + Vector2(-40, -2), hc + Vector2(40, -2), Color("3a2a20"), 2.5)
	else:
		draw_arc(hc, 23.0, PI * 1.02, TAU + 0.1, 16, hair, 9.0)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-22, -8), hc + Vector2(0, -27), hc + Vector2(22, -10), hc + Vector2(8, -14), hc + Vector2(-6, -12)]), hair)
		for st in 6:
			var sa := PI * 1.08 + st * 0.2
			draw_line(hc + Vector2(cos(sa), sin(sa)) * 20.0, hc + Vector2(cos(sa), sin(sa)) * 29.0 + Vector2(sw * 2.0, 0), hair.lightened(0.15), 1.5)
		draw_line(hc + Vector2(-22, -4), hc + Vector2(-29 + sw * 3.0, 20), hair, 6.0)
		draw_arc(hc + Vector2(-4, -18), 14.0, PI * 1.1, PI * 1.7, 8, hair.lightened(0.3), 1.8)
	_done()


func _done() -> void:
	_tf()


func _banner(c: Vector2, col: Color, ph: float) -> void:
	draw_line(c - Vector2(65, 0), c + Vector2(65, 0), Color("736044"), 6)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 17:
		var y := i * 13.0
		var sway := sin(t * 0.7 + i * 0.13 + ph) * 8.0 * i / 16.0
		left.append(c + Vector2(-50 + sway, y))
		right.append(c + Vector2(50 + sway, y))
	var cloth := PackedVector2Array(left)
	right.reverse()
	cloth.append_array(right)
	draw_colored_polygon(cloth, col)
	for seam in 5:
		var pts := PackedVector2Array()
		for i in 17:
			pts.append(c + Vector2(-40 + seam * 20 + sin(t * 0.7 + i * 0.13 + ph) * 8.0 * i / 16.0, i * 13))
		draw_polyline(pts, Color(0, 0, 0, 0.12), 3)
	draw_circle(c + Vector2(0, 76), 26, Color("9a8055"))
	draw_circle(c + Vector2(0, 76), 21, col)
	draw_line(c + Vector2(0, 44), c + Vector2(0, 111), Color("9a8055"), 3)
	draw_line(c + Vector2(-15, 66), c + Vector2(15, 66), Color("9a8055"), 3)


func _chain(a: Vector2, b: Vector2, sag: float) -> void:
	for i in 33:
		var u := i / 32.0
		var c := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag)
		draw_arc(c, 4.5, 0, TAU, 8, Color("766754"), 1.5)


func _memory_face(c: Vector2, s: float, col: Color, ph: float) -> void:
	var bob := Vector2(sin(t * 0.6 + ph) * 7, cos(t * 0.9 + ph) * 8)
	_tf(c + bob, sin(t * 0.4 + ph) * 0.05, Vector2.ONE * s)
	var pts := PackedVector2Array([Vector2(-24, -16), Vector2(-16, -32), Vector2(8, -34), Vector2(25, -14), Vector2(22, 10), Vector2(5, 31), Vector2(-10, 25), Vector2(-23, 8)])
	draw_colored_polygon(pts, Color(col, 0.14))
	_poly_outline(pts, Color(col, 0.35), 1.5)
	for side in [-1.0, 1.0]:
		var ec := Vector2(side * 9, -5)
		draw_arc(ec + Vector2(0, -4), 6, 0.2, PI - 0.2, 10, Color(col, 0.7), 1.5)
		draw_line(ec + Vector2(-5, -9), ec + Vector2(5, -12 * side), Color(col, 0.45), 1.3)
		var tear := fposmod(t * 9 + ph * 13, 18)
		draw_line(ec + Vector2(1, 2), ec + Vector2(1, 6 + tear), Color(col, 0.4), 1.2)
	draw_polyline(PackedVector2Array([Vector2(0, -6), Vector2(4, 8), Vector2(-2, 8)]), Color(col, 0.4), 1.3)
	draw_arc(Vector2(2, 24), 7, PI * 1.15, PI * 1.85, 10, Color(col, 0.6), 1.5)
	_tf()


func _infant(c: Vector2, s: float) -> void:
	_tf(c, -0.15, Vector2.ONE * s)
	draw_colored_polygon(PackedVector2Array([Vector2(-62, 5), Vector2(-48, -25), Vector2(15, -38), Vector2(62, -10), Vector2(56, 26), Vector2(-36, 28)]), Color("4e5666"))
	for fold in 5:
		draw_line(Vector2(-36 + fold * 17, -14), Vector2(-17 + fold * 16, 24), Color("818696"), 2)
	draw_circle(Vector2(-26, -12), 16, Color("d4ae8e"))
	draw_arc(Vector2(-26, -12), 19, PI * 0.8, TAU + PI * 0.1, 22, Color("9b9b99"), 7)
	for side in [-1.0, 1.0]:
		draw_arc(Vector2(-26 + side * 6, -12), 3, 0, PI, 10, Color("493332"), 1.3)
	draw_line(Vector2(-29, -3), Vector2(-24, -2), Color("81504b"), 1.5)
	_tf()


func _cart(c: Vector2) -> void:
	draw_rect(Rect2(c.x, c.y - 100, 300, 84), Color("382a24"))
	for slat in 9:
		var x := c.x + slat * 34
		draw_line(Vector2(x, c.y - 98), Vector2(x, c.y - 18), Color("1b1413"), 3)
		draw_line(Vector2(x + 6, c.y - 88), Vector2(x + 6, c.y - 26), Color("5b4230"), 1)
	for band in 2:
		draw_rect(Rect2(c.x, c.y - 90 + band * 56, 300, 7), Color("17191d"))
		for rivet in 10:
			draw_circle(Vector2(c.x + 12 + rivet * 30, c.y - 86 + band * 56), 2, Color("807264"))
	for w in 2:
		var hub := c + Vector2(58 + w * 185, 0)
		draw_circle(hub, 44, Color("100f13"))
		draw_arc(hub, 42, 0, TAU, 36, Color("67503b"), 5)
		draw_arc(hub, 46, 0, TAU, 36, Color("292a30"), 3)
		for spoke in 10:
			var a := spoke * TAU / 10 + t * 0.65
			draw_line(hub, hub + Vector2(cos(a), sin(a)) * 38, Color("594431"), 3)
		draw_circle(hub, 7, Color("8d7251"))
	draw_line(c + Vector2(290, -35), c + Vector2(410, -24), Color("493526"), 8)
	for bundle in 3:
		var x := c.x + 45 + bundle * 85
		draw_colored_polygon(PackedVector2Array([Vector2(x - 35, c.y - 102), Vector2(x - 22, c.y - 128), Vector2(x + 12, c.y - 134), Vector2(x + 43, c.y - 104)]), Color("615b53"))
		draw_line(Vector2(x - 13, c.y - 126), Vector2(x + 2, c.y - 104), Color("32302f"), 2)



func plate(p: float) -> void:
	_tf()
	var drift := (p - 0.5) * 60.0
	match art:
		"age":
			_sky(Color("0e1224"), Color("3a3458"))
			_moon(Vector2(1400, 260), 70.0, Color("d8d8e8"))
			_spires(700.0, Color("0b0b16"), -drift)
			_ground(840.0, Color("08080e"))
			_chapel(380, 830, 0.85, false)
			_chain(Vector2(60, 680), Vector2(650, 680), 45)
			for i in 5:
				_candle(Vector2(780 + i * 31, 834), 0.55 + (i % 3) * 0.2, i)
			for i in 40:
				var gx := fposmod(i * 97.0 + t * 8.0, 1920.0)
				draw_rect(Rect2(gx, 820 - (i % 5) * 12, 6, 40 + (i % 4) * 14), Color("14141e"))
				draw_line(Vector2(gx - 8, 836 - (i % 5) * 12), Vector2(gx + 14, 836 - (i % 5) * 12), Color("14141e"), 4.0)
			for i in 18:
				var u := fposmod(t * 0.12 + i * 0.173, 1.0)
				draw_circle(Vector2(100 + i * 100.0 + sin(t + i) * 30.0, 820.0 - u * 380.0), 4.0, Color(1.0, 0.45, 0.3, 0.45 * (1.0 - u)))
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
			for shard in 18:
				var a := shard * 2.39996
				var spread := 150 + shard * 18 + _beat(0.2, 0.7) * 100
				var debris := c + Vector2(cos(a) * spread, sin(a) * spread * 0.65 + 170)
				draw_colored_polygon(PackedVector2Array([debris + Vector2(-6, -14), debris + Vector2(12, 0), debris + Vector2(0, 8)]), Color("5a2521"))
		"echo":
			_sky(Color("080a14"), Color("26304a"))
			_ground(860.0, Color("06060c"))
			draw_rect(Rect2(640, 430, 640, 410), Color("20242b"))
			_brick(640, 430, 640, 410, Color("4c4b4a"))
			_chain(Vector2(640, 470), Vector2(1280, 470), 100)
			_reliquary(Vector2(420, 830), 1.5, Color("b36952"), 2)
			_reliquary(Vector2(1500, 830), 1.5, Color("b36952"), 2)
			var pulse := 0.5 + 0.5 * sin(t * 1.6)
			var fig := Vector2(960, 520)
			for k in 6:
				draw_arc(fig + Vector2(0, -40), 120.0 + k * 50.0 + fposmod(t * 30.0, 50.0), 0, TAU, 40, Color(1.0, 0.45, 0.3, 0.18 - k * 0.025), 3.0)
			draw_circle(fig + Vector2(0, -150), 44.0, Color(1.0, 0.4, 0.32, 0.18 + 0.15 * pulse))
			draw_colored_polygon(PackedVector2Array([fig + Vector2(-70, -100), fig + Vector2(70, -100), fig + Vector2(110, 260), fig + Vector2(-110, 260)]), Color(1.0, 0.4, 0.32, 0.1 + 0.12 * pulse))
			draw_line(fig + Vector2(-60, -60), fig + Vector2(-130, 40), Color(1.0, 0.4, 0.32, 0.2), 6.0)
			draw_line(fig + Vector2(60, -60), fig + Vector2(120, -170), Color(1.0, 0.4, 0.32, 0.2), 6.0)
			_person(Vector2(960, 900 - _beat(0.12, 0.6) * 65), 2.7, "echo", 1.0, "worry", false, 0.5, _beat(0.3, 0.6) * 0.7)
		"bellward":
			_sky(Color("0a0c1a"), Color("34385a"))
			_ground(850.0, Color("07070d"))
			_chapel(1400.0, 850.0, 1.4, true)
			for i in 26:
				var u := fposmod(t * 0.07 + i * 0.0385, 1.0)
				var q := Vector2(150 + u * 1150.0, 800.0 - sin(u * PI) * 330.0 - (i % 5) * 28.0)
				draw_circle(q, 12.0, Color(1.0, 0.38, 0.3, 0.5))
				draw_colored_polygon(PackedVector2Array([q + Vector2(-9, 4), q + Vector2(9, 4), q + Vector2(0, 54)]), Color(1.0, 0.38, 0.3, 0.18))
			for k in 4:
				draw_arc(Vector2(1520, 400), 50.0 + fposmod(t * 80.0 + k * 90.0, 360.0), 0, TAU, 40, Color(1.0, 0.8, 0.5, 0.25), 3.0)
		"gates":
			_sky(Color("0a0612"), Color("2a1a44"))
			_ground(880.0, Color("050308"))
			for i in 7:
				var gx := 260.0 + i * 233.0
				var gy := 700.0 - sin(float(i) / 6.0 * PI) * 260.0
				var lit := 0.4 + 0.3 * sin(t * 1.5 + i)
				var col: Color = [Color("d02a30"), Color("e0a030"), Color("30a88a"), Color("8a8a96"), Color("e8e0c8"), Color("4a80c0"), Color("e0602a")][i]
				col.a = lit
				draw_rect(Rect2(gx - 56, gy - 90, 112, 190), Color("0c0a14"))
				draw_circle(Vector2(gx, gy - 90), 56.0, Color("0c0a14"))
				draw_circle(Vector2(gx, gy - 10), 40.0, col)
				draw_rect(Rect2(gx - 40, gy - 10, 80, 100), col)
				draw_arc(Vector2(gx, gy - 90), 66.0, PI, TAU, 16, Color(0.9, 0.75, 0.4, 0.4), 3.0)
				_reliquary(Vector2(gx, gy + 130), 0.85, col, i)
				_chain(Vector2(gx - 64, gy - 45), Vector2(gx + 64, gy - 45), 40)
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
			for side in [-1.0, 1.0]:
				var jaw := PackedVector2Array([Vector2(960 + side * 200, 490 + bb), Vector2(960 + side * 130, 560 + bb), Vector2(960 + side * 65, 590 + bb), Vector2(960, 620 + bb)])
				draw_polyline(jaw, Color("6d2924"), 5)
				var arm := PackedVector2Array([Vector2(960 + side * 220, 450 + bb), Vector2(960 + side * 340, 590 + bb), Vector2(960 + side * 400, 760 + sin(t * 0.7) * 15)])
				draw_polyline(arm, Color("120608"), 50)
				draw_polyline(arm, Color("402023"), 3)
				for claw in 4:
					var cp := Vector2(960 + side * (380 + claw * 16), 750)
					draw_polyline(PackedVector2Array([cp, cp + Vector2(side * 10, 45 + claw * 4), cp + Vector2(-side * 5, 60 + claw * 3)]), Color("817163"), 4)
			for rib in 6:
				draw_arc(Vector2(960, 590 + rib * 32 + bb), 65 + rib * 11, PI * 0.05, PI * 0.95, 24, Color(0.55, 0.24, 0.2, 0.28), 3)
			for tooth in 9:
				var tx := 890 + tooth * 17.0
				draw_colored_polygon(PackedVector2Array([Vector2(tx, 560 + bb), Vector2(tx + 10, 560 + bb), Vector2(tx + 5, 575 + bb + tooth % 3 * 6)]), Color("a17c63"))
			for i in 14:
				var hx := 90.0 + i * 130.0
				draw_circle(Vector2(hx, 800.0 + (i % 3) * 20.0), 18.0, Color(0.1, 0.0, 0.0))
				draw_circle(Vector2(hx - 5, 796.0 + (i % 3) * 20.0), 3.0, Color("ff3020"))
		"gift":
			_sky(Color("0a0e1c"), Color("304060"))
			_ground(860.0, Color("06070c"))
			_person(Vector2(960, 880), 2.5, "mu", 1.0, "awe", false, 0.0, 0.6 + 0.4 * sin(t * 1.2))
			for k in 4:
				var a0 := t * 0.8 + k * TAU / 4.0
				var pc: Color = [Color("ff9a40"), Color("ff3a30"), Color("ffd070"), Color("d02a40")][k]
				for j in 10:
					var u := fposmod(t * 0.25 + j * 0.1 + k * 0.05, 1.0)
					var r := 520.0 * (1.0 - u)
					draw_circle(Vector2(960, 640) + Vector2(cos(a0 + u * 5.0), sin(a0 + u * 5.0) * 0.6) * r, 8.0 * (1.0 - u) + 2.0, Color(pc, 0.7))
			for r in 5:
				draw_circle(Vector2(960, 700), 90.0 + r * 40.0, Color(1.0, 0.45, 0.3, 0.04))
			_reliquary(Vector2(420, 820), 1.8, Color("55b4a5"), 0)
			_reliquary(Vector2(1500, 820), 1.8, Color("c8a050"), 1)
			for side in [-1.0, 1.0]:
				var stream := PackedVector2Array()
				for k in 40:
					var u := k / 39.0
					stream.append(Vector2(960 + side * 520 * (1 - u), 670 - sin(u * PI) * 130 + sin(u * 18 - t * 2) * 12))
				draw_polyline(stream, Color(0.95, 0.62, 0.35, 0.12 + _beat(0.2, 0.6) * 0.3), 4)
		"farewell":
			_sky(Color("1a1018"), Color("5a3a48"))
			_ground(850.0, Color("0a080c"))
			_chapel(420.0, 850.0, 1.5, true)
			draw_rect(Rect2(640, 520, 130, 330), Color("2a1c10"))
			draw_circle(Vector2(705, 520), 65.0, Color("2a1c10"))
			draw_rect(Rect2(660, 540, 90, 310), Color(1.0, 0.7, 0.35, 0.55))
			_banner(Vector2(860, 300), Color("382226"), 0)
			var reach := _beat(0.25, 0.45)
			var accept := _beat(0.5, 0.68)
			_person(Vector2(1080, 890), 2.2, "mu", 1.0, "worry" if accept < 0.5 else "stern", false, 0.0, accept)
			_person(Vector2(1500, 890), 2.2, "aldous", -1.0, "talk" if accept < 0.7 else "worry", false, 2.0, reach * (1 - accept))
			var give_hand := Vector2(1500, 856) + Vector2(-1, 1) * Vector2(39, -73).lerp(Vector2(78, -126), reach) * 2.2
			var take_hand := Vector2(1080, 856) + Vector2(39, -73).lerp(Vector2(78, -126), accept) * 2.2
			var hilt := give_hand.lerp(take_hand, accept)
			var blade_dir := Vector2.LEFT.rotated(-PI * 0.5 * accept)
			var blade_side := blade_dir.orthogonal()
			draw_line(hilt + blade_dir * 20, hilt + blade_dir * 155, Color("a7b4be"), 8)
			draw_line(hilt + blade_dir * 20 + blade_side * 2, hilt + blade_dir * 155 + blade_side * 2, Color("e5e5de"), 2)
			draw_line(hilt + blade_dir * 20 - blade_side * 24, hilt + blade_dir * 20 + blade_side * 24, Color("b3985c"), 7)
			draw_line(hilt, hilt + blade_dir * 18, Color("49392c"), 8)
			draw_circle(hilt - blade_dir * 6, 6, Color("b3985c"))
		"carts":
			_sky(Color("0c0a10"), Color("3a2c30"))
			_moon(Vector2(500, 230), 60.0, Color("c8c0b8"))
			_skyline(700.0, Color("0b0a10"), false, false)
			_ground(820.0, Color("07060a"))
			_fog(790.0, 0.07)
			var cx := 320 + p * 580
			_cart(Vector2(cx, 800 + sin(t * 2.7) * 2))
			_person(Vector2(cx + 400, 830), 1.8, "bellman", 1.0, "stern", true)
			draw_circle(Vector2(cx + 330, 720), 12.0, Color("e8a040"))
			for r in 4:
				draw_circle(Vector2(cx + 330, 720), 50.0 + r * 28.0, Color(1.0, 0.65, 0.3, 0.04))
		"kirkyard":
			_sky(Color("08080e"), Color("2a2a3c"))
			_moon(Vector2(1500, 240), 80.0, Color("d8d4cc"))
			_ground(780.0, Color("07070b"))
			for i in 16:
				_tomb(80.0 + i * 118.0, 800.0 + (i % 3) * 36.0, 1.0 + (i % 3) * 0.3, i % 3 == 0)
			draw_line(Vector2(300, 780), Vector2(330, 420), Color("050408"), 16.0)
			for b in 7:
				draw_line(Vector2(330, 520 - b * 14), Vector2(330 + (b % 2 * 2 - 1) * (90 - b * 8), 440 - b * 28), Color("050408"), 6.0)
			for i in 6:
				_crow(Vector2(1000 + i * 90 + sin(t * 0.6 + i) * 60.0, 300 + (i % 3) * 50 + cos(t * 0.5 + i) * 20.0), i * 1.3)
			_person(Vector2(1100, 840), 2.1, "keeper", -1.0, "worry", false, 5.0)
			_fog(840.0, 0.09)
		"cloister":
			_sky(Color("06060a"), Color("14141c"))
			for i in 6:
				var ax := 160.0 + i * 320.0
				_pointed(ax, 760.0, 150.0, 400.0, Color("1a1a24"))
				_pointed(ax, 760.0, 96.0, 360.0, Color("08080c"))
			_ground(760.0, Color("0c0c12"))
			var gx := 630.0 + sin(t * 0.15) * 180
			draw_colored_polygon(PackedVector2Array([Vector2(gx - 40, 740), Vector2(gx + 40, 740), Vector2(gx + 56, 340), Vector2(gx - 56, 340)]), Color(1.0, 0.4, 0.32, 0.14))
			_person(Vector2(gx, 800), 2.3, "echo", 1.0, "worry", false, 1.0, _beat(0.2, 0.55))
			_banner(Vector2(1480, 340), Color("2c313c"), 2)
			_chain(Vector2(1400, 680), Vector2(1560, 680), 50)
			draw_circle(Vector2(gx, 300), 36.0, Color(1.0, 0.4, 0.32, 0.22))
			draw_arc(Vector2(gx, 300), 60.0 + sin(t * 3.0) * 8.0, 0, TAU, 24, Color(1.0, 0.3, 0.25, 0.3), 3.0)
		"kinds":
			_sky(Color("0a0a12"), Color("22222c"))
			_ground(830.0, Color("06060a"))
			var kc := [Color("30a88a"), Color("c8a050"), Color("d02a30")]
			for i in 3:
				var ax := 420.0 + i * 540.0
				_pointed(ax, 830.0, 260.0, 440.0, Color("12121a"))
				_rose(Vector2(ax, 360), 90.0, Color(kc[i], 0.5))
				var by := 560.0 + sin(t * 1.4 + i * 2.0) * 16.0
				for r in 5:
					draw_circle(Vector2(ax, by), 40.0 + r * 22.0, Color(kc[i], 0.07))
				draw_circle(Vector2(ax, by), 30.0, kc[i])
				_reliquary(Vector2(ax, 820), 1.8, kc[i], i)
		"foundry":
			_sky(Color("0e0806"), Color("2a1810"))
			_ground(820.0, Color("08040a"))
			_chain(Vector2(740, 200), Vector2(960, 280), 20)
			_chain(Vector2(1180, 200), Vector2(960, 280), 20)
			draw_rect(Rect2(560, 560, 800, 300), Color("1a0c08"))
			_brick(560, 560, 800, 300, Color("554035"))
			var gl := 0.7 + 0.3 * sin(t * 5.0)
			draw_rect(Rect2(660, 640, 600, 120), Color(1.0, 0.45, 0.1, 0.8 * gl))
			for r in 6:
				draw_circle(Vector2(960, 700), 140.0 + r * 50.0, Color(1.0, 0.45, 0.1, 0.05))
			_bell(Vector2(960, 360), 1.5, Color("a87830"), 0.0)
			for h in 3:
				var hx := 360.0 + h * 600.0
				_person(Vector2(hx, 870), 1.9, "smith", 1 if h == 0 else -1, "stern", false, h, 0.5 + sin(t * 0.8 + h) * 0.3)
				_candle(Vector2(hx - 60, 850), 1.3, h)
			var pour := _beat(0.18, 0.4) * (1 - _beat(0.7, 0.85))
			draw_line(Vector2(1000, 230), Vector2(1330, 230), Color("594637"), 14)
			_chain(Vector2(1030, 230), Vector2(1090, 450), 0)
			_chain(Vector2(1300, 230), Vector2(1200, 455), 0)
			_tf(Vector2(1140, 500), -0.6 * pour, Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([Vector2(-65, -50), Vector2(65, -50), Vector2(45, 45), Vector2(-45, 45)]), Color("4a3d32"))
			draw_line(Vector2(-60, -46), Vector2(60, -46), Color("ffc569"), 8)
			draw_arc(Vector2.ZERO, 72, PI, TAU, 24, Color("75624b"), 7)
			_tf()
			if pour > 0.05:
				draw_polyline(PackedVector2Array([Vector2(1070, 490), Vector2(1050, 530), Vector2(1060, 630), Vector2(1060, 680)]), Color(1, 0.55, 0.15, pour), 8)
				_glow(Vector2(1060, 680), 130, Color("ff9430"), pour)
		"binding":
			_sky(Color("0a0a12"), Color("2a2a36"))
			_ground(860.0, Color("060608"))
			_pointed(960.0, 860.0, 420.0, 560.0, Color("14141c"))
			_pointed(960.0, 860.0, 300.0, 520.0, Color("050508"))
			for k in 8:
				var a := t * 0.6 + k * TAU / 8.0
				draw_arc(Vector2(960, 560), 220.0 + k * 10.0, a, a + 1.4, 20, Color(1.0, 0.8, 0.45, 0.6), 4.0)
			_bell(Vector2(500, 420), 1.1, Color("b88838"), 0.0)
			for k in 4:
				draw_arc(Vector2(500, 500), 80.0 + fposmod(t * 90.0 + k * 90.0, 360.0), 0, TAU, 40, Color(1.0, 0.8, 0.5, 0.25), 3.0)
			_rose(Vector2(960, 330), 100.0, Color(0.9, 0.7, 0.35, 0.7))
			for m in 3:
				_person(Vector2(740 + m * 220.0, 860), 2.1, "monk", 1.0, "calm", false, m * 1.7)
		"snowchapel":
			_sky(Color("101420"), Color("485068"))
			_moon(Vector2(1500, 230), 56.0, Color("e8eaf0"))
			_spires(760.0, Color("141624"), -drift)
			_chapel(560.0, 860.0, 1.6, true)
			_ground(860.0, Color("c8ccd8"))
			_ground(900.0, Color("a0a4b4"))
			for i in 110:
				var sx := fposmod(i * 83.0 + sin(t + i) * 30.0, 1960.0)
				var sy := fposmod(i * 57.0 + t * (60.0 + (i % 5) * 18.0), 1000.0)
				draw_circle(Vector2(sx, sy), 2.0 + (i % 3), Color(1, 1, 1, 0.7))
			_person(Vector2(1100, 880), 2.1, "keeper", -1.0, "calm", true, 2.5)
		"crack":
			_sky(Color("0a0408"), Color("2a0c12"))
			_ground(880.0, Color("050204"))
			var cr := 0.4 + 0.4 * sin(t * 2.5)
			_bell(Vector2(960, 440), 3.0, Color("8a6428"), 0.5 + cr * 0.5)
			for r in 6:
				draw_circle(Vector2(960, 480), 200.0 + r * 70.0, Color(1.0, 0.15, 0.1, 0.03 + 0.02 * cr))
			for k in 14:
				var u := fposmod(t * 0.3 + k * 0.071, 1.0)
				draw_circle(Vector2(900 + k * 18.0, 560.0 - u * 400.0), 4.0, Color(1.0, 0.3, 0.2, 0.7 * (1.0 - u)))
			_person(Vector2(440, 880), 2.2, "aldous", 1.0, "awe", false, 1.0)
			_person(Vector2(1480, 880), 2.2, "kid", -1.0, "worry", false, 2.0)
		"edin":
			_sky(Color("101420"), Color("7a6a72"))
			_moon(Vector2(1500, 230), 56.0, Color("d8d0c8"))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 880), Vector2(200, 420), Vector2(700, 380), Vector2(900, 880)]), Color("0e0e16"))
			for i in 7:
				draw_rect(Rect2(260 + i * 70, 300 - (i % 3) * 30, 52, 120), Color("0e0e16"))
			_skyline(780.0, Color("0b0b12"), true, false)
			draw_rect(Rect2(60, 660, 820, 240), Color("292a30"))
			_brick(60, 660, 820, 240, Color("515056"))
			for vault in 4:
				var vx := 160 + vault * 190.0
				_pointed(vx, 870, 120, 85, Color("090b11"))
				for bar in 5:
					draw_line(Vector2(vx - 40 + bar * 20, 755), Vector2(vx - 40 + bar * 20, 875), Color("4b4541"), 3)
				_chain(Vector2(vx - 45, 800), Vector2(vx + 45, 800), 16)
			_ground(820.0, Color("060608"))
			for i in 6:
				var u := fposmod(t * 0.08 + i * 0.17, 1.0)
				draw_circle(Vector2(1000 + i * 120.0 + u * 60.0, 640.0 - u * 400.0), 40.0 + u * 70.0, Color(0.5, 0.5, 0.52, 0.12 * (1.0 - u)))
			_person(Vector2(1240, 880), 1.9, "keeper", -1.0, "stern", true, 1.0)
			_fog(850.0, 0.08)
		"praha":
			_sky(Color("140e12"), Color("8a5a40"))
			_moon(Vector2(400, 230), 52.0, Color("e8d0a8"))
			_skyline(780.0, Color("0c0808"), true, true)
			for pillar in 4:
				var px := 180 + pillar * 260.0
				draw_rect(Rect2(px - 65, 730, 130, 180), Color("39302a"))
				_brick(px - 65, 730, 130, 180, Color("6e5949"))
				_reliquary(Vector2(px, 744), 0.6, Color("bdac83"), 2)
				if pillar < 3:
					_chain(Vector2(px + 65, 790), Vector2(px + 195, 790), 22)
			_ground(820.0, Color("060404"))
			_person(Vector2(1240, 880), 1.9, "bellman", -1.0, "stern", true, 2.0)
			_fog(850.0, 0.07)
		"belfry":
			_sky(Color("0a0a10"), Color("1a1a24"))
			for i in 5:
				draw_rect(Rect2(120 + i * 400, 100, 40, 760), Color("12121a"))
			draw_rect(Rect2(0, 120, 1920, 36), Color("0e0e16"))
			_rose(Vector2(960, 300), 160.0, Color(0.85, 0.6, 0.35, 0.5))
			_bell(Vector2(1300, 380), 1.6, Color("a87830"), 0.0)
			_ground(860.0, Color("0a0a10"))
			draw_rect(Rect2(710, 460, 300, 400), Color("383a40"))
			_brick(710, 460, 300, 400, Color("66666a"))
			for mask in 3:
				_memory_face(Vector2(780 + mask * 68, 580), 0.7, Color("ad6c5c"), mask)
			_person(Vector2(560 + _beat(0.1, 0.3) * 35, 880), 2.7, "kid", 1.0, "awe", false, 0, _beat(0.2, 0.45))
			_chain(Vector2(1300, 520), Vector2(1325, 850), 8)
			_candle(Vector2(430, 840), 1.2, 1)
		"price":
			_sky(Color("0a0408"), Color("2a1018"))
			_ground(880.0, Color("050204"))
			_person(Vector2(700, 890), 2.6, "mu", 1.0, "worry")
			for i in 7:
				var a := i * 0.45 - 1.5
				var pos := Vector2(1180 + cos(a) * 280, 580 + sin(a) * 230)
				_memory_face(pos, 1.2 + i * 0.06, Color("d88676"), i)
				var thread := PackedVector2Array()
				for k in 25:
					var u := k / 24.0
					thread.append(pos.lerp(Vector2(790, 690), u) + Vector2(0, sin(u * PI) * 80 + sin(u * 10 + t) * 5))
				draw_polyline(thread, Color(0.8, 0.18, 0.13, 0.15 + _beat(0.1, 0.6) * 0.2), 1.5)
			draw_arc(Vector2(790, 700), 28.0 + sin(t * 4.0) * 3.0, 0, TAU, 16, Color(1.0, 0.25, 0.2, 0.7), 5.0)
		"foundling":
			_sky(Color("0a0c18"), Color("3c4060"))
			for i in 80:
				var rx := fposmod(i * 61.0 - t * 160.0, 1960.0)
				var ry := fposmod(i * 97.0 + t * 700.0, 1080.0)
				draw_line(Vector2(rx, ry), Vector2(rx - 10, ry + 34), Color(0.7, 0.75, 0.9, 0.35), 2.0)
			_chapel(700.0, 820.0, 1.6, true)
			_ground(820.0, Color("08080c"))
			var rescue := _beat(0.25, 0.65)
			for r in 4:
				draw_circle(Vector2(705, 780), 60.0 + r * 30.0, Color(1.0, 0.8, 0.5, 0.05))
			_person(Vector2(960 - _beat(0.05, 0.25) * 110, 830 + rescue * 30), 2.0, "aldous", -1.0, "worry" if rescue < 0.5 else "calm", false, 3.0, rescue)
			_infant(Vector2(705, 794).lerp(Vector2(741, 613), rescue), 0.9)
			_tf(Vector2(1180, 290), sin(t * 3.0) * 0.12, Vector2.ONE)
			draw_circle(Vector2.ZERO, 36.0, Color("c8a050"))
			draw_circle(Vector2(0, 10), 14.0, Color("14101c"))
			_tf()
		"listener":
			_sky(Color("1a1624"), Color("584868"))
			_moon(Vector2(500, 300), 60.0, Color("e8d8c8"))
			_chapel(1320.0, 830.0, 1.5, true)
			_ground(830.0, Color("0c0a10"))
			_person(Vector2(500, 860), 2.6, "kid", 1.0, "awe")
			_person(Vector2(800, 860), 2.2, "aldous", -1.0, "talk", false, 1.0, 0.5 + 0.5 * sin(t * 0.8))
			_candle(Vector2(1050, 820), 1.7, 2)
			_banner(Vector2(1080, 320), Color("302b3b"), 3)
			for i in 9:
				var u := fposmod(t * 0.2 + i * 0.11, 1.0)
				var q := Vector2(1100 + sin(t + i) * 40.0, 780.0 - u * 460.0)
				draw_circle(q, 10.0, Color(1.0, 0.38, 0.3, 0.5 * (1.0 - u)))
			draw_arc(Vector2(560, 760), 70.0 + fmod(t * 40.0, 120.0), 0, TAU, 30, Color(1.0, 0.38, 0.3, 0.3), 3.0)
		"toll":
			_sky(Color("1a0c14"), Color("703030"))
			_moon(Vector2(960, 320), 110.0, Color("e8a888"))
			_chapel(560.0, 880.0, 1.7, true)
			_spires(900.0, Color("0a0508"), 900.0 + drift)
			_ground(880.0, Color("060306"))
			_person(Vector2(1000, 880), 1.9, "aldous", 1.0, "worry", false, 4.0)
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
			for fp in 12:
				var px := fposmod(fp * 260.0 - t * 160.0, 3200.0) - 200.0
				draw_rect(Rect2(px, 780, 14, 80), Color("0a0810"))
				draw_line(Vector2(px, 800), Vector2(px - 260, 806), Color("0a0810"), 5.0)
			_person(Vector2(960, 900 - wob - p * 40.0), 2.3 - p * 0.8, "mu", 1.0, "stern", true)
			_chapel(360.0, 830.0, 1.0, true)
