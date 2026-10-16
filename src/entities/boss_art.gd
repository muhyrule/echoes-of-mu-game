extends RefCounted
## Ornate gothic bodies for the arena bosses, drawn in world-pixel units (origin at the feet / waterline).

const OUT := Color("0e0a14")


static func _sm(pts: Array, closed := true, seg := 6) -> PackedVector2Array:
	var n := pts.size()
	var out := PackedVector2Array()
	var cnt := n if closed else n - 1
	for i in cnt:
		var p0: Vector2 = pts[(i - 1 + n) % n] if (closed or i > 0) else pts[i]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if (closed or i + 2 < n) else p2
		for k in seg:
			var u := float(k) / seg
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u))
	if not closed:
		out.append(pts[n - 1])
	return out


static func _fl(col: Color, f: float) -> Color:
	return col.lerp(Color.WHITE, 0.8) if f > 0.0 else col


static func _shape(c: CanvasItem, pts: PackedVector2Array, col: Color, f: float, hi := Color(0, 0, 0, 0), lw := 1.4) -> void:
	c.draw_colored_polygon(pts, _fl(col, f))
	var cl := pts.duplicate()
	cl.append(pts[0])
	if hi.a > 0.0:
		var half := PackedVector2Array()
		for i in int(pts.size() * 0.55):
			half.append(pts[(i + int(pts.size() * 0.7)) % pts.size()])
		if half.size() > 1:
			c.draw_polyline(half, _fl(hi, f), 1.6)
	c.draw_polyline(cl, OUT, lw)


static func _poly(c: CanvasItem, pts: Array, col: Color, f: float, lw := 1.4) -> void:
	_shape(c, PackedVector2Array(pts), col, f, Color(0, 0, 0, 0), lw)


static func _arch(c: CanvasItem, cx: float, by: float, w: float, h: float, col: Color, line: Color) -> void:
	var pts := PackedVector2Array([Vector2(cx - w, by), Vector2(cx - w, by - h * 0.55), Vector2(cx - w * 0.6, by - h * 0.82), Vector2(cx, by - h), Vector2(cx + w * 0.6, by - h * 0.82), Vector2(cx + w, by - h * 0.55), Vector2(cx + w, by)])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, line, 1.0)


static func _rose(c: CanvasItem, p: Vector2, r: float, t: float, glow: Color, gold: Color) -> void:
	c.draw_circle(p, r * 1.5, Color(glow, 0.16))
	c.draw_circle(p, r + 2.0, OUT)
	c.draw_circle(p, r, gold)
	c.draw_circle(p, r * 0.84, Color(glow.r * 0.5, glow.g * 0.4, glow.b * 0.3).lerp(glow, 0.55 + 0.25 * sin(t * 3.0)))
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.15
		c.draw_line(p, p + Vector2.from_angle(a) * r * 0.84, gold, 1.0)
		c.draw_circle(p + Vector2.from_angle(a + TAU / 16.0) * r * 0.56, r * 0.14, gold)
	c.draw_arc(p, r * 0.5, 0, TAU, 16, gold, 1.0)
	c.draw_circle(p, r * 0.16, Color(1, 0.95, 0.7))


static func _chain(c: CanvasItem, a: Vector2, b: Vector2, sag: float, links: int, col: Color) -> void:
	for i in links + 1:
		var u := float(i) / links
		var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag)
		c.draw_circle(p, 2.3, OUT)
		c.draw_circle(p, 1.4, col)


static func _glyph(c: CanvasItem, p: Vector2, g: int, col: Color) -> void:
	match g:
		0:
			c.draw_line(p + Vector2(-4, -5), p + Vector2(3, -5), col, 1.8)
			c.draw_line(p + Vector2(3, -5), p + Vector2(-3, 5), col, 1.8)
			c.draw_line(p + Vector2(-4, 5), p + Vector2(4, 5), col, 1.8)
		1:
			c.draw_line(p + Vector2(-4, -5), p + Vector2(4, -5), col, 1.8)
			c.draw_line(p + Vector2(4, -5), p + Vector2(4, 5), col, 1.8)
			c.draw_line(p + Vector2(-4, 5), p + Vector2(-4, 1), col, 1.8)
		_:
			c.draw_line(p + Vector2(-5, -5), p + Vector2(5, -5), col, 1.8)
			c.draw_line(p + Vector2(0, -5), p + Vector2(0, 5), col, 1.8)
			c.draw_line(p + Vector2(-5, 5), p + Vector2(5, 5), col, 1.8)


# ====================================================================== Golem

static func golem(c: CanvasItem, t: float, ph: int, flash: float, winding: bool, exposed: float, moving: bool) -> void:
	var f := flash
	var clay := Color("8a6048")
	var clay_d := Color("56382a")
	var clay_l := Color("a87c5c")
	var stone := Color("5a5260")
	var gold := Color("d8a848")
	var glow := Color(1.0, 0.62, 0.2) if ph < 3 else Color(1.0, 0.32 + 0.2 * sin(t * 10.0), 0.15)
	var br := sin(t * 1.8) * 1.2
	var step := sin(t * 3.0) * 3.0 if moving else 0.0
	for i in 3:
		c.draw_colored_polygon(_ellipse(Vector2(0, 3), 72.0 - i * 8.0, 15.0 - i * 2.0), Color(0, 0, 0, 0.16))
	# legs and greaves
	for s in [-1.0, 1.0]:
		var lift: float = step * s * 0.6
		var leg := PackedVector2Array([Vector2(s * 8, -44), Vector2(s * 36, -44), Vector2(s * 38, -10 + lift), Vector2(s * 44, 0 + lift), Vector2(s * 4, 0 + lift), Vector2(s * 8, -10 + lift)])
		_shape(c, leg, clay_d, f)
		var greave := PackedVector2Array([Vector2(s * 10, -40), Vector2(s * 34, -40), Vector2(s * 35, -18 + lift * 0.5), Vector2(s * 22, -8 + lift * 0.5), Vector2(s * 9, -18 + lift * 0.5)])
		_shape(c, greave, stone, f)
		_arch(c, s * 22, -18 + lift * 0.5, 7.0, 18.0, Color(0.1, 0.08, 0.14), Color("8a8094"))
		for k in 3:
			c.draw_line(Vector2(s * (14 + k * 8), -40), Vector2(s * (14 + k * 8), -34), Color("8a8094"), 1.0)
		c.draw_circle(Vector2(s * 22, -42), 3.0, gold)
	# tassets / skirt with hanging chains
	var skirt := PackedVector2Array([Vector2(-44, -52), Vector2(44, -52), Vector2(40, -36), Vector2(-40, -36)])
	_shape(c, skirt, stone, f)
	for i in 7:
		var x := -36.0 + i * 12.0
		_arch(c, x, -36, 5.0, 12.0, Color(0.1, 0.08, 0.14), Color("8a8094"))
	c.draw_line(Vector2(-44, -52), Vector2(44, -52), gold, 2.0)
	# torso
	var torso := _sm([Vector2(-50, -52), Vector2(50, -52), Vector2(60, -94), Vector2(46, -124), Vector2(-46, -124), Vector2(-60, -94)], true, 5)
	for i in torso.size():
		torso[i].y += br * 0.3 * (1.0 if torso[i].y < -80 else 0.0)
	_shape(c, torso, clay, f, clay_l)
	# ribbed buttresses and flying arches
	for s in [-1.0, 1.0]:
		for k in 4:
			var y := -60.0 - k * 14.0
			c.draw_line(Vector2(s * 56, y), Vector2(s * 30, y - 6), clay_d, 2.0)
			c.draw_line(Vector2(s * 56, y + 1), Vector2(s * 30, y - 5), clay_l, 0.8)
		_arch(c, s * 40, -58.0, 9.0, 36.0, Color(0.14, 0.09, 0.08), Color("e0b878"))
	# belt with iron buckle
	c.draw_rect(Rect2(-48, -60, 96, 7), OUT)
	c.draw_rect(Rect2(-47, -59, 94, 5), stone)
	for i in 9:
		c.draw_circle(Vector2(-40.0 + i * 10.0, -56.5), 1.3, gold)
	_poly(c, [Vector2(-9, -62), Vector2(9, -62), Vector2(9, -50), Vector2(0, -46), Vector2(-9, -50)], gold, f)
	# rose window heart
	_rose(c, Vector2(0, -92 + br * 0.3), 19.0, t, glow, gold)
	# carved plates over chest
	for s in [-1.0, 1.0]:
		var pl := PackedVector2Array([Vector2(s * 24, -78), Vector2(s * 42, -80), Vector2(s * 48, -104), Vector2(s * 30, -112), Vector2(s * 24, -100)])
		_shape(c, pl, clay_d, f)
		c.draw_line(Vector2(s * 28, -84), Vector2(s * 42, -88), gold, 1.0)
		c.draw_line(Vector2(s * 28, -92), Vector2(s * 44, -96), gold, 1.0)
		c.draw_circle(Vector2(s * 36, -100), 2.0, gold)
	# scratched runes down the sides
	for s in [-1.0, 1.0]:
		for k in 5:
			var rp := Vector2(s * 52, -66.0 - k * 9.0)
			c.draw_line(rp, rp + Vector2(s * -4, -4), Color(glow, 0.7), 1.0)
			c.draw_line(rp + Vector2(s * -4, -4), rp + Vector2(s * -1, -7), Color(glow, 0.7), 1.0)
	# glowing cracks
	var ca := 0.35 + 0.2 * ph
	var cr := [[Vector2(-30, -120), Vector2(-24, -108), Vector2(-30, -98), Vector2(-22, -86), Vector2(-28, -70)], [Vector2(34, -122), Vector2(28, -112), Vector2(36, -100), Vector2(30, -88)], [Vector2(8, -56), Vector2(14, -48), Vector2(8, -40)]]
	for pts in cr:
		c.draw_polyline(PackedVector2Array(pts), Color(glow, ca * 0.4), 4.0)
		c.draw_polyline(PackedVector2Array(pts), Color(1.0, 0.85, 0.5, ca), 1.2)
	# chains across chest
	_chain(c, Vector2(-56, -112), Vector2(0, -58), 14.0, 13, Color("8a8094"))
	_chain(c, Vector2(56, -112), Vector2(0, -58), 14.0, 13, Color("8a8094"))
	# arms
	var raise := 0.0
	if winding:
		raise = 1.0
	elif exposed > 0.0:
		raise = 0.4
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 58, -112)
		var sw := sin(t * 1.4 + (0.0 if s < 0 else 1.6)) * 4.0
		var el := Vector2(s * (78 + raise * 14), -86 - raise * 30 + sw)
		var fist := Vector2(s * (82 + raise * 6), -44 - raise * 96 + sw * 1.4 + (step * s * 0.8))
		c.draw_line(sh, el, OUT, 25.0)
		c.draw_line(sh, el, _fl(clay, f), 22.0)
		c.draw_line(el, fist, OUT, 23.0)
		c.draw_line(el, fist, _fl(clay_d, f), 20.0)
		c.draw_line(sh + Vector2(-s * 4, -4), el + Vector2(-s * 4, -4), clay_l, 2.0)
		var mid := el.lerp(fist, 0.55)
		c.draw_line(mid + Vector2(-11, 0), mid + Vector2(11, 0), OUT, 6.0)
		c.draw_line(mid + Vector2(-10, 0), mid + Vector2(10, 0), stone, 4.0)
		for k in 3:
			c.draw_circle(mid + Vector2(-6 + k * 6, 0), 1.2, gold)
		# fist with knuckle spikes
		var fp := _sm([fist + Vector2(-13, -8), fist + Vector2(13, -8), fist + Vector2(15, 12), fist + Vector2(0, 18), fist + Vector2(-15, 12)], true, 4)
		_shape(c, fp, clay, f, clay_l)
		for k in 4:
			var kx := -9.0 + k * 6.0
			_poly(c, [fist + Vector2(kx - 2, 12), fist + Vector2(kx + 2, 12), fist + Vector2(kx, 20)], stone, f, 1.0)
		# pauldron with gothic spires
		var pd := _sm([sh + Vector2(-s * 14, 6), sh + Vector2(s * 22, 8), sh + Vector2(s * 24, -10), sh + Vector2(s * 6, -22), sh + Vector2(-s * 14, -14)], true, 4)
		_shape(c, pd, stone, f, Color("a098b0"))
		for k in 3:
			var bx: float = sh.x + s * (-8 + k * 11)
			_poly(c, [Vector2(bx - 4, sh.y - 16 + k * 2), Vector2(bx + 4, sh.y - 16 + k * 2), Vector2(bx + s * 1.5, sh.y - 36 + k * 4)], Color("7a7288"), f, 1.2)
		c.draw_circle(sh + Vector2(s * 6, -2), 4.0, gold)
		c.draw_circle(sh + Vector2(s * 6, -2), 2.0, glow)
	# head with spired crown
	var hy := -128.0 + br
	var hood := _sm([Vector2(-21, hy + 4), Vector2(-23, hy - 18), Vector2(-14, hy - 34), Vector2(0, hy - 42), Vector2(14, hy - 34), Vector2(23, hy - 18), Vector2(21, hy + 4)], true, 5)
	_shape(c, hood, clay, f, clay_l)
	var face := PackedVector2Array([Vector2(-13, hy), Vector2(-14, hy - 22), Vector2(0, hy - 32), Vector2(14, hy - 22), Vector2(13, hy)])
	c.draw_colored_polygon(face, _fl(Color(0.18, 0.1, 0.08), f))
	c.draw_polyline(face, OUT, 1.0)
	# crown spires
	for k in 5:
		var cx := -16.0 + k * 8.0
		var h := 14.0 if k % 2 == 0 else 22.0
		if k == 2:
			h = 34.0
		var by := hy - 32.0 + absf(k - 2) * 3.0
		_poly(c, [Vector2(cx - 3.5, by), Vector2(cx + 3.5, by), Vector2(cx, by - h)], stone, f, 1.0)
		c.draw_circle(Vector2(cx, by - h), 1.4, gold)
	c.draw_line(Vector2(-18, hy - 30), Vector2(18, hy - 30), gold, 1.6)
	# eyes
	for s in [-1.0, 1.0]:
		var ep := Vector2(s * 6.5, hy - 14)
		c.draw_circle(ep, 5.5, Color(glow, 0.25))
		c.draw_line(ep + Vector2(-3, -1), ep + Vector2(3, 0.5 * s), Color(1.0, 0.9, 0.5), 2.2)
	# brow rune: EMET, losing its first letter in the last phase
	var gl := 3 if ph < 3 else 2
	var gs := -8.0 if ph < 3 else -4.0
	c.draw_circle(Vector2(0, hy - 25), 9.0, Color(glow, 0.15))
	for g in gl:
		_glyph(c, Vector2(gs + g * 8.0, hy - 25), g + (0 if ph < 3 else 1), Color(glow, 1.0) if ph >= 3 else Color(1.0, 0.8, 0.4))
	# mouth grille
	for k in 5:
		c.draw_line(Vector2(-6 + k * 3, hy - 2), Vector2(-6 + k * 3, hy + 2), Color(glow, 0.8), 1.0)
	# loose dust motes
	for k in 6:
		var u := fmod(t * 0.4 + k * 0.17, 1.0)
		c.draw_circle(Vector2(-50 + k * 20 + sin(t + k) * 5, -30 - u * 110), 1.0, Color(0.9, 0.7, 0.45, 0.5 * (1.0 - u)))


# ====================================================================== Kelpie

static func kelpie(c: CanvasItem, t: float, ph: int, flash: float, winding: bool, exposed: float) -> void:
	var f := flash
	var body := Color("2a6878")
	var body_l := Color("62c0c8")
	var bone := Color("c8dcd4")
	var gold := Color("c8a050")
	var weed := Color("2e7a4a")
	var weed_l := Color("5fb878")
	var rear := 6.0 * sin(t * 1.3) + (10.0 if winding else 0.0)
	var wob := sin(t * 1.7) * 2.0
	# pool
	for i in 4:
		var r := 52.0 + i * 14.0 + fmod(t * 9.0, 14.0)
		c.draw_arc(Vector2(0, 4), r, 0.0, TAU, 40, Color(0.5, 0.9, 0.95, 0.4 - i * 0.09), 1.2)
	c.draw_colored_polygon(_ellipse(Vector2(0, 6), 66.0, 22.0), Color(0.05, 0.16, 0.22, 0.85))
	c.draw_colored_polygon(_ellipse(Vector2(0, 5), 52.0, 16.0), Color(0.08, 0.26, 0.32, 0.8))
	# trailing kelp tail
	for k in 6:
		var pts: Array = []
		for j in 5:
			pts.append(Vector2(-40 - j * 11 - k * 2, -22 + j * 3 + sin(t * 2.0 + j * 0.9 + k) * (4 + j * 2) + k * 4))
		c.draw_polyline(_sm(pts, false, 5), OUT, 6.0)
		c.draw_polyline(_sm(pts, false, 5), weed if k % 2 == 0 else weed_l, 3.6)
	# hindquarters submerged
	var hind := _sm([Vector2(-50, 4), Vector2(-56, -20), Vector2(-46, -46), Vector2(-24, -58), Vector2(0, -54), Vector2(10, -30), Vector2(6, 4)], true, 5)
	_shape(c, hind, body, f, body_l)
	# chest and barrel
	var chest := _sm([Vector2(-26, -50 - rear * 0.3), Vector2(2, -76 - rear * 0.5), Vector2(28, -86 - rear * 0.6), Vector2(40, -62), Vector2(34, -28), Vector2(16, -6), Vector2(-10, -10), Vector2(-30, -30)], true, 6)
	_shape(c, chest, body, f, body_l)
	# exposed ribcage in gothic arches
	for k in 5:
		var rx := -10.0 + k * 9.0
		var ry := -30.0 - sin(float(k) / 4.0 * PI) * 18.0 - rear * 0.2
		c.draw_arc(Vector2(rx, ry + 22), 12.0, PI * 1.05, PI * 1.95, 10, OUT, 3.2)
		c.draw_arc(Vector2(rx, ry + 22), 12.0, PI * 1.05, PI * 1.95, 10, _fl(bone, f), 1.8)
	c.draw_circle(Vector2(12, -36), 6.0, Color(0.4, 1.0, 0.9, 0.22))
	c.draw_circle(Vector2(12, -36), 2.5, Color(0.7, 1.0, 0.95, 0.7 + 0.2 * sin(t * 4.0)))
	# chest armour: barnacled shell plate with pointed arches
	var plate := PackedVector2Array([Vector2(18, -78 - rear * 0.5), Vector2(38, -66), Vector2(34, -44), Vector2(22, -38), Vector2(12, -52)])
	_shape(c, plate, Color("52606a"), f, Color("9aa8b0"))
	_arch(c, 26, -42, 5.0, 20.0, Color(0.06, 0.1, 0.14), Color("c8d4dc"))
	c.draw_circle(Vector2(30, -62), 2.0, gold)
	# raised forelegs, hooves lashing
	for s in [0, 1]:
		var base := Vector2(22 + s * 6, -66 - rear * 0.4)
		var knee := base + Vector2(26 + s * 8, -6 - s * 12 + sin(t * 2.2 + s) * 3)
		var hoof := knee + Vector2(14 - s * 4, 22 + s * 8 + sin(t * 2.6 + s * 2.0) * 4 - rear * 0.2)
		c.draw_line(base, knee, OUT, 20.0 - s * 2)
		c.draw_line(base, knee, _fl(body if s == 0 else Color("1f5060"), f), 16.0 - s * 2)
		c.draw_line(knee, hoof, OUT, 16.0 - s * 2)
		c.draw_line(knee, hoof, _fl(body_l if s == 0 else body, f), 12.0 - s * 2)
		c.draw_circle(knee, 5.0, OUT)
		c.draw_circle(knee, 3.5, _fl(bone, f))
		_poly(c, [hoof + Vector2(-5, -2), hoof + Vector2(5, -2), hoof + Vector2(6, 7), hoof + Vector2(-6, 7)], Color("2a2630"), f, 1.2)
		c.draw_circle(hoof + Vector2(0, 8), 3.0, Color(0.7, 1.0, 0.95, 0.5))
	# dorsal spines (gothic pinnacles) along the back and neck
	for k in 9:
		var u := float(k) / 8.0
		var p := Vector2(-28 + u * 36, -64 - u * 22 - rear * 0.4 * u)
		if k >= 6:
			p = Vector2(8 + (u - 0.75) * 60, -88 - (u - 0.75) * 190)
		var h := 14.0 - absf(u - 0.5) * 8.0
		_poly(c, [p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(-5, -h)], Color("6ac0c8"), f, 1.0)
	# neck
	var neck := _sm([Vector2(0, -74 - rear * 0.5), Vector2(8, -104 - rear), Vector2(22, -132 - rear), Vector2(40, -150 - rear + wob), Vector2(62, -156 - rear + wob), Vector2(64, -138 - rear + wob), Vector2(50, -120 - rear), Vector2(44, -96 - rear * 0.5), Vector2(40, -66), Vector2(26, -80)], true, 6)
	_shape(c, neck, body, f, body_l)
	# neck bands of ornate gold collars
	for k in 3:
		var u := 0.25 + k * 0.22
		var a := Vector2(10 + u * 36, -88 - u * 56 - rear * u)
		c.draw_line(a, a + Vector2(26, 6 - k), OUT, 5.0)
		c.draw_line(a, a + Vector2(26, 6 - k), gold, 3.0)
		c.draw_circle(a + Vector2(13, 3), 1.8, Color(0.7, 1.0, 0.95))
	# flowing weed mane
	for k in 16:
		var u := float(k) / 15.0
		var root := Vector2(2 + u * 40, -80 - u * 72 - rear * (0.5 + u * 0.5) + wob * u)
		var pts: Array = [root]
		for j in 4:
			pts.append(root + Vector2(-8 - j * 9 - u * 6, 4 + j * 6 + sin(t * 2.4 + u * 6.0 + j) * (3 + j * 1.5)))
		var sm := _sm(pts, false, 4)
		c.draw_polyline(sm, OUT, 4.6)
		c.draw_polyline(sm, weed if k % 2 == 0 else weed_l, 2.6)
	# head
	var hx := 62.0
	var hy := -156.0 - rear + wob
	var hd := _sm([Vector2(hx - 24, hy - 2), Vector2(hx - 10, hy - 16), Vector2(hx + 14, hy - 12), Vector2(hx + 42, hy + 8), Vector2(hx + 48, hy + 20), Vector2(hx + 38, hy + 28), Vector2(hx + 12, hy + 22), Vector2(hx - 8, hy + 22), Vector2(hx - 18, hy + 12)], true, 5)
	_shape(c, hd, body, f, body_l)
	# ears and crest
	_poly(c, [Vector2(hx - 14, hy - 12), Vector2(hx - 8, hy - 36), Vector2(hx - 2, hy - 14)], body_l, f, 1.2)
	_poly(c, [Vector2(hx - 2, hy - 14), Vector2(hx + 6, hy - 32), Vector2(hx + 10, hy - 12)], body, f, 1.2)
	_poly(c, [Vector2(hx - 22, hy), Vector2(hx - 34, hy - 20), Vector2(hx - 14, hy - 8)], Color("6ac0c8"), f, 1.0)
	# jaw bone and fangs
	_poly(c, [Vector2(hx + 4, hy + 20), Vector2(hx + 40, hy + 26), Vector2(hx + 30, hy + 34), Vector2(hx + 8, hy + 30)], _fl(bone, f), f, 1.0)
	for k in 4:
		_poly(c, [Vector2(hx + 18 + k * 6, hy + 24), Vector2(hx + 22 + k * 6, hy + 24), Vector2(hx + 20 + k * 6, hy + 31)], Color.WHITE, f, 0.8)
	# eye and nostril mist
	var eye := Color(0.6, 1.0, 0.95) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	c.draw_circle(Vector2(hx + 6, hy + 4), 9.0, Color(eye, 0.25))
	c.draw_circle(Vector2(hx + 6, hy + 4), 4.2, OUT)
	c.draw_circle(Vector2(hx + 6, hy + 4), 3.0, eye)
	c.draw_line(Vector2(hx + 1, hy + 1), Vector2(hx + 12, hy - 1), Color(OUT, 0.9), 1.4)
	c.draw_circle(Vector2(hx + 40, hy + 14), 1.8, OUT)
	for k in 3:
		var u := fmod(t * 0.9 + k * 0.33, 1.0)
		c.draw_circle(Vector2(hx + 46 + u * 20, hy + 14 - u * 8), 2.0 + u * 3.0, Color(0.8, 1.0, 1.0, 0.35 * (1.0 - u)))
	# ornate bridle with a lantern
	c.draw_line(Vector2(hx - 12, hy + 14), Vector2(hx + 38, hy + 14), OUT, 3.4)
	c.draw_line(Vector2(hx - 12, hy + 14), Vector2(hx + 38, hy + 14), gold, 1.8)
	c.draw_line(Vector2(hx + 2, hy - 8), Vector2(hx + 22, hy + 22), gold, 1.4)
	c.draw_circle(Vector2(hx + 20, hy + 14), 3.0, gold)
	var lp := Vector2(hx + 34 + sin(t * 2.0) * 3.0, hy + 52 + sin(t * 2.6) * 2.0)
	c.draw_line(Vector2(hx + 36, hy + 26), lp + Vector2(0, -8), gold, 1.2)
	_poly(c, [lp + Vector2(-5, -6), lp + Vector2(5, -6), lp + Vector2(6, 6), lp + Vector2(-6, 6)], Color("3a2a1a"), f, 1.0)
	c.draw_circle(lp, 9.0, Color(1.0, 0.8, 0.3, 0.2))
	_arch(c, lp.x, lp.y + 5, 3.4, 10.0, Color(1.0, 0.85, 0.4), Color("3a2a1a"))
	_poly(c, [lp + Vector2(-6, -6), lp + Vector2(6, -6), lp + Vector2(0, -13)], gold, f, 1.0)
	# cascading water and drips
	for k in 12:
		var x := -30.0 + k * 8.0
		var u := fmod(t * 0.8 + k * 0.23, 1.0)
		c.draw_line(Vector2(x, -50 + u * 52), Vector2(x, -42 + u * 52), Color(0.7, 0.95, 1.0, 0.45 * (1.0 - u)), 1.4)
	# glowing teal runes on the flank
	for k in 4:
		var rp := Vector2(-26 + k * 9.0, -34.0 - sin(k * 0.9) * 8.0)
		c.draw_line(rp, rp + Vector2(4, -5), Color(0.5, 1.0, 0.9, 0.8), 1.0)
		c.draw_line(rp + Vector2(4, -5), rp + Vector2(0, -9), Color(0.5, 1.0, 0.9, 0.8), 1.0)


static func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
