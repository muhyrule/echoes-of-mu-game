extends RefCounted
## Procedural art: outlined, shaded characters, creatures, props and light helpers.
## Drawn in world units (1 tile = 16); the camera zoom makes every stroke crisp at 1080p.

const OUT := Color("100d17")
const PAL_MU := {"coat": Color("5a3f86"), "accent": Color("d23b3b"), "skin": Color("f0cba6"), "hair": Color("e8e6f2"), "boots": Color("2a1f2e"), "style": "short", "item": "sheath"}
const PAL_WRAITH := {"coat": Color("5b9ad6"), "accent": Color("d6f1ff"), "skin": Color("d8eefb"), "hair": Color("9fd0ff"), "boots": Color("2c4a6b"), "style": "short", "item": "none"}
const PAL_ISOLDE := {"coat": Color("5f8a5c"), "accent": Color("a8693a"), "skin": Color("ecbf9a"), "hair": Color("b5502e"), "boots": Color("3a2a22"), "style": "braid", "item": "hammer"}
const PAL_ALDOUS := {"coat": Color("2e2c3a"), "accent": Color("c7a84f"), "skin": Color("e0bf9c"), "hair": Color("e6e6ee"), "boots": Color("1c1a22"), "style": "beard", "item": "none"}

static var _light_tex: GradientTexture2D


static func light_texture() -> GradientTexture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_light_tex = GradientTexture2D.new()
		_light_tex.gradient = g
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		_light_tex.width = 256
		_light_tex.height = 256
	return _light_tex


static func make_light(col: Color, scale: float, energy: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = col
	l.texture_scale = scale
	l.energy = energy
	return l


static func shadow(c: CanvasItem, r := 6.5) -> void:
	c.draw_set_transform(Vector2(0, 5.5), 0.0, Vector2(1.0, 0.4))
	c.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	c.draw_circle(Vector2.ZERO, r * 0.7, Color(0, 0, 0, 0.25))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# parts: [kind, data, color]; kind r=Rect2, p=PackedVector2Array, c=[Vector2 center, float radius]
static func _paint(c: CanvasItem, parts: Array, outline := true) -> void:
	if outline:
		for p in parts:
			var col := Color(OUT, p[2].a)
			match p[0]:
				"r":
					c.draw_rect((p[1] as Rect2).grow(0.8), col)
				"p":
					var pts: PackedVector2Array = p[1]
					var closed := pts.duplicate()
					closed.append(pts[0])
					c.draw_polyline(closed, col, 1.6)
					c.draw_colored_polygon(pts, col)
				"c":
					c.draw_circle(p[1][0], p[1][1] + 0.8, col)
	for p in parts:
		match p[0]:
			"r":
				c.draw_rect(p[1], p[2])
			"p":
				c.draw_colored_polygon(p[1], p[2])
			"c":
				c.draw_circle(p[1][0], p[1][1], p[2])


static func person(c: CanvasItem, f: Vector2, t: float, pal: Dictionary, moving := false, alpha := 1.0) -> void:
	shadow(c)
	var a := alpha
	var coat := Color(pal.coat, a)
	var coat_d := coat.darkened(0.35)
	var coat_l := coat.lightened(0.18)
	var acc := Color(pal.accent, a)
	var skin := Color(pal.skin, a)
	var hair := Color(pal.hair, a)
	var boots := Color(pal.boots, a)
	var style: String = pal.style
	var side := absf(f.x) > absf(f.y)
	var up := (not side) and f.y < 0.0
	var sx := 1.0 if f.x >= 0.0 else -1.0
	var ph := t * 11.0
	var swing := sin(ph) * 1.6 if moving else 0.0
	var bob := -absf(sin(ph)) * 0.8 if moving else 0.0
	var back: Array = []
	var mid: Array = []
	var front: Array = []

	var cape_pts := PackedVector2Array([Vector2(-4.6, -4 + bob), Vector2(4.6, -4 + bob), Vector2(6.0 + swing * 0.3, 6.5), Vector2(-6.0 - swing * 0.3, 6.5)])
	if side:
		cape_pts = PackedVector2Array([Vector2(-sx * 3.0, -4 + bob), Vector2(-sx * 4.5, -4 + bob), Vector2(-sx * (7.0 + absf(swing) * 0.5), 6.0), Vector2(-sx * 3.0, 6.0)])
	var cape := ["p", cape_pts, coat_d]
	if up:
		front.append(cape)
	else:
		back.append(cape)

	if side:
		mid.append(["r", Rect2(-1.8 + swing * 0.8, 2.5, 3.2, 3.6), boots])
		mid.append(["r", Rect2(-1.8 - swing * 0.8, 2.5, 3.2, 3.6 - absf(swing) * 0.2), boots.lightened(0.1)])
	else:
		mid.append(["r", Rect2(-3.6, 2.5, 3.0, 3.6 - maxf(0.0, swing) * 0.5), boots])
		mid.append(["r", Rect2(0.6, 2.5, 3.0, 3.6 + minf(0.0, swing) * 0.5), boots.lightened(0.1)])

	var torso := PackedVector2Array([Vector2(-4.2, -5.5 + bob), Vector2(4.2, -5.5 + bob), Vector2(5.0, 3.5), Vector2(-5.0, 3.5)])
	if side:
		torso = PackedVector2Array([Vector2(-3.4, -5.5 + bob), Vector2(3.4, -5.5 + bob), Vector2(4.0, 3.5), Vector2(-4.0, 3.5)])
	mid.append(["p", torso, coat])
	if not side:
		var shade := PackedVector2Array([Vector2(1.2, -5.5 + bob), Vector2(4.2, -5.5 + bob), Vector2(5.0, 3.5), Vector2(1.6, 3.5)])
		mid.append(["p", shade, Color(coat_d, 0.55 * a)])
	mid.append(["r", Rect2(-4.6, 0.2, 9.2, 1.4), Color("3a2a22", a)])
	mid.append(["r", Rect2(-0.8, 0.0, 1.6, 1.8), Color("d6b25a", a)])

	if side:
		mid.append(["r", Rect2(-1.0 - swing * 0.6, -4.2 + bob, 2.4, 6.5), coat_l])
		mid.append(["c", [Vector2(0.2 - swing * 0.6, 2.4 + bob), 1.3], skin])
	else:
		mid.append(["r", Rect2(-6.6, -4.2 + bob, 2.4, 6.2), coat_l])
		mid.append(["r", Rect2(4.2, -4.2 + bob, 2.4, 6.2), coat_d])
		mid.append(["c", [Vector2(-5.4, 2.2 + bob + swing * 0.2), 1.3], skin])
		mid.append(["c", [Vector2(5.4, 2.2 + bob - swing * 0.2), 1.3], skin])

	mid.append(["r", Rect2(-4.8 if not side else -3.8, -6.8 + bob, 9.6 if not side else 7.6, 2.6), acc])
	if style != "beard":
		var tail := PackedVector2Array([Vector2(-sx * 3.0, -5.0 + bob), Vector2(-sx * 5.0, -5.0 + bob), Vector2(-sx * (7.5 + swing * 0.3), -1.0 + bob), Vector2(-sx * 5.0, 0.5 + bob)])
		if not side:
			tail = PackedVector2Array([Vector2(2.5, -5.0 + bob), Vector2(5.0, -5.0 + bob), Vector2(5.5, 2.0 + bob), Vector2(3.5, 1.0 + bob)])
		mid.append(["p", tail, acc.darkened(0.2)])

	match pal.item:
		"hammer":
			var hx := -sx * 4.4 if side else -4.6
			mid.append(["r", Rect2(hx - 0.5, 0.0, 1.0, 5.0), Color("6a4a30", a)])
			mid.append(["r", Rect2(hx - 1.6, -0.6, 3.2, 2.0), Color("9aa0ae", a)])
		"sheath":
			var sp := PackedVector2Array([Vector2(-5.5, -6.0 + bob), Vector2(-4.5, -6.5 + bob), Vector2(5.0, 3.0), Vector2(4.0, 3.6)])
			if up:
				front.append(["p", sp, Color("8b93a8", a)])
			else:
				back.append(["p", sp, Color("8b93a8", a)])

	var hc := Vector2(0, -10.2 + bob)
	var head: Array = []
	head.append(["c", [hc, 4.3], skin])
	if up:
		head.append(["c", [hc + Vector2(0, 0.2), 4.6], hair])
		if style == "braid":
			head.append(["r", Rect2(-1.2, -9.0 + bob, 2.4, 9.0), hair.darkened(0.15)])
	elif side:
		head.append(["c", [hc + Vector2(-sx * 1.4, -0.4), 4.0], hair])
		head.append(["r", Rect2(hc.x - 3.5 if sx > 0 else hc.x - 1.0, hc.y - 4.8, 4.5, 3.0), hair])
		if style == "braid":
			head.append(["r", Rect2(-sx * 4.6 - 1.0, -9.0 + bob, 2.2, 8.5), hair.darkened(0.15)])
		head.append(["r", Rect2(sx * 2.4 - 0.6, -10.8 + bob, 1.2, 1.7), Color(0.08, 0.06, 0.12, a)])
		if style == "beard":
			head.append(["r", Rect2(sx * 0.5 - 2.0, -8.0 + bob, 4.0, 4.0), hair])
	else:
		var fringe := PackedVector2Array([Vector2(-4.6, -10.4 + bob), Vector2(-4.2, -13.2 + bob), Vector2(0, -14.8 + bob), Vector2(4.2, -13.2 + bob), Vector2(4.6, -10.4 + bob), Vector2(2.4, -11.6 + bob), Vector2(0, -10.8 + bob), Vector2(-2.4, -11.8 + bob)])
		head.append(["p", fringe, hair])
		head.append(["r", Rect2(-2.5, -10.4 + bob, 1.2, 1.7), Color(0.08, 0.06, 0.12, a)])
		head.append(["r", Rect2(1.3, -10.4 + bob, 1.2, 1.7), Color(0.08, 0.06, 0.12, a)])
		if style == "braid":
			head.append(["r", Rect2(-6.0, -11.0 + bob, 2.0, 6.0), hair.darkened(0.1)])
		if style == "beard":
			head.append(["p", PackedVector2Array([Vector2(-3.8, -8.4 + bob), Vector2(3.8, -8.4 + bob), Vector2(2.0, -3.0 + bob), Vector2(0, -2.0 + bob), Vector2(-2.0, -3.0 + bob)]), hair])
	if style == "beard" and not up:
		head.append(["r", Rect2(-3.6, -14.0 + bob, 7.2, 2.2), Color("2e2c3a", a)])

	if up:
		_paint(c, back + mid + head + front)
	else:
		_paint(c, back + mid + head)
	if not up and not side:
		c.draw_rect(Rect2(-2.1, -10.4 + bob, 0.5, 0.5), Color(1, 1, 1, 0.9 * a))
		c.draw_rect(Rect2(1.7, -10.4 + bob, 0.5, 0.5), Color(1, 1, 1, 0.9 * a))


static func rat(c: CanvasItem, f: Vector2, t: float, flash: float) -> void:
	shadow(c, 5.5)
	var s := 1.0 if f.x >= 0.0 else -1.0
	var run := absf(sin(t * 14.0)) * 0.8
	var fur := Color("85705a") if flash <= 0.0 else Color.WHITE
	var belly := fur.lightened(0.2)
	var parts: Array = []
	var tail_pts := PackedVector2Array()
	for i in 7:
		var k := float(i) / 6.0
		tail_pts.append(Vector2(-s * (5.0 + k * 6.0), -1.0 + sin(t * 8.0 + k * 3.0) * 1.5 * k))
	c.draw_polyline(tail_pts, Color(OUT), 2.2)
	c.draw_polyline(tail_pts, Color("c9a0a0") if flash <= 0.0 else Color.WHITE, 1.0)
	parts.append(["r", Rect2(-3.5, 1.5, 1.6, 2.4 + run), fur.darkened(0.35)])
	parts.append(["r", Rect2(2.0, 1.5, 1.6, 2.4 - run * 0.5), fur.darkened(0.35)])
	parts.append(["p", PackedVector2Array([Vector2(-6 * s, 0), Vector2(-3 * s, -4.5), Vector2(2 * s, -4.8), Vector2(5 * s, -2.5), Vector2(5 * s, 1.5), Vector2(-4 * s, 2.5)]), fur])
	parts.append(["p", PackedVector2Array([Vector2(-4 * s, 0.5), Vector2(3 * s, 0.5), Vector2(4 * s, 2.0), Vector2(-3 * s, 2.5)]), belly])
	parts.append(["p", PackedVector2Array([Vector2(4 * s, -3.8), Vector2(9 * s, -1.0), Vector2(4.5 * s, 1.8)]), fur.lightened(0.08)])
	parts.append(["c", [Vector2(3.0 * s, -5.2), 1.6], Color("d49a9a") if flash <= 0.0 else Color.WHITE])
	_paint(c, parts)
	c.draw_rect(Rect2(5.5 * s - 0.5, -2.4, 1.0, 1.0), Color("ff4040"))
	c.draw_circle(Vector2(9.0 * s, -1.0), 0.8, Color("2a1a1a"))
	c.draw_line(Vector2(8 * s, -0.5), Vector2(11 * s, 0.5), Color(1, 1, 1, 0.6), 0.4)
	c.draw_line(Vector2(8 * s, 0.2), Vector2(11 * s, 1.8), Color(1, 1, 1, 0.6), 0.4)


static func bat(c: CanvasItem, t: float, flash: float) -> void:
	var col := Color("463a5c") if flash <= 0.0 else Color.WHITE
	c.draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.0, 0.35))
	c.draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0, 0.3))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var fl := sin(t * 20.0)
	var parts: Array = []
	for sgn in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(sgn * 1.5, -2.5), Vector2(sgn * 6.0, -8.0 - fl * 4.0), Vector2(sgn * 11.0, -5.0 - fl * 5.0), Vector2(sgn * 9.0, -2.0 - fl * 3.0), Vector2(sgn * 7.0, 0.0 - fl * 2.0), Vector2(sgn * 5.0, -1.0), Vector2(sgn * 3.0, 1.5)])
		if sgn < 0.0:
			pts.reverse()
		parts.append(["p", pts, col.darkened(0.1)])
	parts.append(["p", PackedVector2Array([Vector2(-2.6, -6.0), Vector2(-1.5, -8.5), Vector2(-0.5, -6.0), Vector2(0.5, -6.0), Vector2(1.5, -8.5), Vector2(2.6, -6.0), Vector2(2.4, 1.5), Vector2(0, 3.0), Vector2(-2.4, 1.5)]), col.lightened(0.12)])
	_paint(c, parts)
	c.draw_rect(Rect2(-1.8, -4.4, 1.0, 1.0), Color("ffd166"))
	c.draw_rect(Rect2(0.8, -4.4, 1.0, 1.0), Color("ffd166"))
	c.draw_line(Vector2(-0.6, -1.5), Vector2(-0.6, -0.3), Color.WHITE, 0.5)
	c.draw_line(Vector2(0.6, -1.5), Vector2(0.6, -0.3), Color.WHITE, 0.5)


static func warden(c: CanvasItem, f: Vector2, t: float, flash: float, winding: bool) -> void:
	shadow(c, 15.0)
	var steel := Color("6f7587") if flash <= 0.0 else Color.WHITE
	if winding and int(t * 20.0) % 2 == 0:
		steel = Color("c05555")
	var dark := steel.darkened(0.4)
	var parts: Array = []
	var rag := PackedVector2Array([Vector2(-13, -16), Vector2(13, -16), Vector2(16, 9), Vector2(11, 6 + sin(t * 3.0)), Vector2(6, 11), Vector2(0, 7), Vector2(-6, 11), Vector2(-11, 6 - sin(t * 3.0)), Vector2(-16, 9)])
	parts.append(["p", rag, Color("2a2438")])
	parts.append(["r", Rect2(-9, 5, 6.5, 8), dark])
	parts.append(["r", Rect2(2.5, 5, 6.5, 8), dark])
	parts.append(["r", Rect2(-8.5, 12, 7.5, 2.5), steel.darkened(0.2)])
	parts.append(["r", Rect2(1.0, 12, 7.5, 2.5), steel.darkened(0.2)])
	parts.append(["p", PackedVector2Array([Vector2(-11, -15), Vector2(11, -15), Vector2(9, 6), Vector2(-9, 6)]), steel])
	parts.append(["p", PackedVector2Array([Vector2(2, -15), Vector2(11, -15), Vector2(9, 6), Vector2(3, 6)]), Color(dark, 0.6)])
	parts.append(["r", Rect2(-9, -1.5, 18, 2.4), Color("3a2a22")])
	parts.append(["c", [Vector2(0, -0.3), 2.0], Color("d6b25a")])
	parts.append(["c", [Vector2(-14, -14), 5.5], steel.lightened(0.15)])
	parts.append(["c", [Vector2(14, -14), 5.5], steel.lightened(0.15)])
	parts.append(["p", PackedVector2Array([Vector2(-7.5, -17), Vector2(-6.5, -27), Vector2(0, -30), Vector2(6.5, -27), Vector2(7.5, -17)]), steel.lightened(0.05)])
	parts.append(["p", PackedVector2Array([Vector2(-1, -30), Vector2(1, -30), Vector2(3, -36 + sin(t * 4.0)), Vector2(-3, -36 - sin(t * 4.0))]), Color("8a2a3a")])
	_paint(c, parts)
	c.draw_rect(Rect2(-5.5, -24.5, 11.0, 2.6), Color("07060c"))
	var glow := 0.7 + 0.3 * sin(t * 6.0)
	c.draw_rect(Rect2(-4.5, -24.0, 3.0, 1.4), Color(0.4, 0.9, 1.0, glow))
	c.draw_rect(Rect2(1.5, -24.0, 3.0, 1.4), Color(0.4, 0.9, 1.0, glow))
	c.draw_line(Vector2(0, -8), f * 21.0, Color(OUT), 4.5)
	c.draw_line(Vector2(0, -8), f * 21.0, Color("d3d7e3"), 2.8)
	c.draw_line(Vector2(0, -8), f * 21.0, Color("8a93a8"), 0.8)
	c.draw_circle(Vector2(-15, 4), 3.2, Color(0.2, 0.15, 0.1))
	var lc := Color("ffcf70") if int(t * 6.0) % 2 == 0 else Color("e09a3a")
	c.draw_circle(Vector2(-15, 5), 2.2, lc)


static func heart(c: CanvasItem, pos: Vector2, size: float, col: Color) -> void:
	c.draw_circle(pos + Vector2(-size * 0.5, 0), size * 0.58, Color(OUT))
	c.draw_circle(pos + Vector2(size * 0.5, 0), size * 0.58, Color(OUT))
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-size * 1.15, size * 0.25), pos + Vector2(size * 1.15, size * 0.25), pos + Vector2(0, size * 1.5)]), Color(OUT))
	c.draw_circle(pos + Vector2(-size * 0.5, 0), size * 0.5, col)
	c.draw_circle(pos + Vector2(size * 0.5, 0), size * 0.5, col)
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-size * 1.0, size * 0.25), pos + Vector2(size * 1.0, size * 0.25), pos + Vector2(0, size * 1.35)]), col)
	c.draw_circle(pos + Vector2(-size * 0.7, -size * 0.15), size * 0.16, Color(1, 1, 1, 0.55))


static func candle(c: CanvasItem, t: float, seed_v: float) -> void:
	c.draw_rect(Rect2(-3.5, 6.0, 7.0, 2.0), Color("5a4a2a"))
	c.draw_rect(Rect2(-2.4, -2.0, 4.8, 8.4), Color(OUT))
	c.draw_rect(Rect2(-1.8, -1.5, 3.6, 7.5), Color("e8dcc0"))
	c.draw_rect(Rect2(-1.8, -1.5, 1.2, 7.5), Color(1, 1, 1, 0.3))
	var fl := sin(t * 9.0 + seed_v) * 0.7
	c.draw_colored_polygon(PackedVector2Array([Vector2(-1.6, -1.8), Vector2(1.6, -1.8), Vector2(0.8 + fl * 0.4, -5.5), Vector2(0, -8.0 - fl), Vector2(-0.8 + fl * 0.4, -5.5)]), Color("ff9a2a"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-0.8, -1.8), Vector2(0.8, -1.8), Vector2(0, -5.5 - fl)]), Color("fff1a8"))


static func torch(c: CanvasItem, t: float, seed_v: float) -> void:
	c.draw_rect(Rect2(-1.2, -1.0, 2.4, 8.0), Color("4a3524"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-3.4, -3.0), Vector2(3.4, -3.0), Vector2(2.0, 1.0), Vector2(-2.0, 1.0)]), Color("6a6a76"))
	var fl := sin(t * 11.0 + seed_v)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-2.8, -3.0), Vector2(2.8, -3.0), Vector2(1.6 + fl * 0.6, -8.0), Vector2(0, -12.0 - fl * 1.5), Vector2(-1.6 + fl * 0.6, -8.0)]), Color("ff7a1a"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-1.6, -3.0), Vector2(1.6, -3.0), Vector2(0.2, -7.5), Vector2(0, -9.0 - fl)]), Color("ffe08a"))
