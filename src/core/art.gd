extends RefCounted
## Procedural art: outlined, shaded characters, creatures, props and light helpers.
## Drawn in world units (1 tile = 16); the camera zoom makes every stroke crisp at 1080p.

const OUT := Color("100d17")
const PAL_MU := {"coat": Color("3a3048"), "accent": Color("7a2a2e"), "skin": Color("c4a083"), "hair": Color("a8a6ae"), "boots": Color("1c1620"), "style": "short", "item": "sheath", "hood": true, "mail": true}
const PAL_WRAITH := {"coat": Color("3a5670"), "accent": Color("9fc4d8"), "skin": Color("a9c0cc"), "hair": Color("7f9fb8"), "boots": Color("1e2e40"), "style": "short", "item": "none", "hood": true}
const PAL_ISOLDE := {"coat": Color("3e4a38"), "accent": Color("6e4a2e"), "skin": Color("c8a287"), "hair": Color("7a3a24"), "boots": Color("261c16"), "style": "braid", "item": "hammer", "mail": true}
const PAL_GARGOYLE := {"coat": Color("565d6a"), "accent": Color("8a3a2e"), "skin": Color("6f7886"), "hair": Color("3e4550"), "boots": Color("2a303a"), "style": "short", "item": "none", "mail": true}
const PAL_WREN := {"coat": Color("2e4852"), "accent": Color("9a7a2e"), "skin": Color("c09a7e"), "hair": Color("1c1620"), "boots": Color("261c16"), "style": "short", "item": "none", "hood": true}
const PAL_CORVIN := {"coat": Color("503426"), "accent": Color("8a8d98"), "skin": Color("a98462"), "hair": Color("6e6e78"), "boots": Color("1c1610"), "style": "beard", "item": "none", "mail": true}
const PAL_ALDOUS := {"coat": Color("22212c"), "accent": Color("8a7436"), "skin": Color("c4a98a"), "hair": Color("b8b8c0"), "boots": Color("14121a"), "style": "beard", "item": "none"}

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


# SNES-style chunky sprite: big head, bold outline, three-tone pixel shading.
static func _b(parts: Array, sh: Array, x: float, y: float, w: float, h: float, col: Color, shade := true) -> void:
	parts.append(["r", Rect2(x, y, w, h), col])
	if shade and w >= 2.0 and h >= 2.0:
		sh.append([Rect2(x, y, w, 1.0), Color(col.lightened(0.28), col.a)])
		sh.append([Rect2(x, y, 1.0, h), Color(col.lightened(0.14), col.a)])
		sh.append([Rect2(x + w - 1.0, y + 1.0, 1.0, h - 1.0), Color(col.darkened(0.3), col.a)])
		sh.append([Rect2(x, y + h - 1.0, w, 1.0), Color(col.darkened(0.25), col.a)])


static func person(c: CanvasItem, f: Vector2, t: float, pal: Dictionary, moving := false, alpha := 1.0) -> void:
	shadow(c, 6.0)
	var a := alpha
	var coat := Color(pal.coat, a)
	var coat_d := coat.darkened(0.4)
	var acc := Color(pal.accent, a)
	var skin := Color(pal.skin, a)
	var hair := Color(pal.hair, a)
	var boots := Color(pal.boots, a)
	var style: String = pal.style
	var hood: bool = pal.get("hood", false)
	var side := absf(f.x) > absf(f.y)
	var up := (not side) and f.y < 0.0
	var sx := 1.0 if f.x >= 0.0 else -1.0
	var ph := t * 11.0
	var swing := roundf(sin(ph) * 1.6) if moving else 0.0
	var bob := -1.0 if moving and sin(ph * 2.0) > 0.2 else 0.0
	var parts: Array = []
	var sh: Array = []
	var eye := Color(0.06, 0.04, 0.1, a)
	var head_col := coat.darkened(0.55) if hood else hair
	var ink := Color(OUT, a)

	if side:
		_b(parts, sh, -sx * 5.0 - 1.0, -7.0 + bob, 2.0, 11.0, coat_d)
		_b(parts, sh, -3.0 + swing, 3.0, 3.0, 3.0, boots)
		_b(parts, sh, 0.0 - swing, 3.0, 3.0, 3.0, boots.lightened(0.1))
		_b(parts, sh, -3.5, -1.0, 7.0, 5.0, coat)
		_b(parts, sh, -3.0, -7.0 + bob, 6.0, 6.0, coat)
		_b(parts, sh, -3.5, -2.0, 7.0, 1.0, acc, false)
		_b(parts, sh, -2.0 - sx * swing * 0.5, -6.0 + bob, 3.0, 5.0, coat.lightened(0.1))
		_b(parts, sh, -1.5 - sx * swing * 0.5, -1.0 + bob, 2.0, 2.0, skin, false)
		_b(parts, sh, -3.5, -8.0 + bob, 7.0, 2.0, acc)
		_b(parts, sh, -4.0 + sx * 0.5, -17.0 + bob, 8.0, 9.0, skin)
		_b(parts, sh, -4.5 - sx * 0.5 - (sx - 1.0) * 0.0, -17.0 + bob, 5.0, 9.0, head_col)
		_b(parts, sh, -4.5, -18.0 + bob, 9.0, 3.0, head_col)
		if style == "braid":
			_b(parts, sh, -sx * 5.5 - 1.0, -14.0 + bob, 2.0, 11.0, hair.darkened(0.1))
		if style == "beard":
			_b(parts, sh, sx * 0.5 - 1.5, -10.0 + bob, 4.0, 3.0, hair)
	elif up:
		_b(parts, sh, -4.0 + swing, 3.0, 3.5, 3.0, boots)
		_b(parts, sh, 0.5 - swing, 3.0, 3.5, 3.0, boots.lightened(0.1))
		_b(parts, sh, -4.0, -1.0, 8.0, 5.0, coat)
		_b(parts, sh, -4.0, -7.0 + bob, 8.0, 6.0, coat)
		_b(parts, sh, -6.0, -6.0 + bob, 2.0, 6.0, coat.lightened(0.1))
		_b(parts, sh, 4.0, -6.0 + bob, 2.0, 6.0, coat_d)
		_b(parts, sh, -5.5, -8.0 + bob, 11.0, 2.0, acc)
		_b(parts, sh, -5.0, -17.0 + bob, 10.0, 9.0, head_col)
		_b(parts, sh, -5.0, -18.0 + bob, 10.0, 2.0, head_col)
		_b(parts, sh, -5.5, -7.0 + bob, 11.0, 12.0, coat_d.lightened(0.05))
		if style == "braid":
			_b(parts, sh, -1.0, -10.0 + bob, 2.0, 9.0, hair.darkened(0.1))
	else:
		_b(parts, sh, -5.5, -7.0 + bob, 11.0, 12.0, coat_d)
		_b(parts, sh, -4.0, 3.0 + maxf(0.0, -swing) * 0.5, 3.5, 3.0, boots)
		_b(parts, sh, 0.5, 3.0 + maxf(0.0, swing) * 0.5, 3.5, 3.0, boots.lightened(0.1))
		_b(parts, sh, -5.0, -1.0, 10.0, 5.0, coat)
		_b(parts, sh, -4.0, -7.0 + bob, 8.0, 6.0, coat)
		_b(parts, sh, -6.0, -6.0 + bob, 2.0, 6.0, coat.lightened(0.1))
		_b(parts, sh, 4.0, -6.0 + bob, 2.0, 6.0, coat_d)
		_b(parts, sh, -6.0, 0.0 + bob + swing * 0.3, 2.0, 2.0, skin, false)
		_b(parts, sh, 4.0, 0.0 + bob - swing * 0.3, 2.0, 2.0, skin, false)
		_b(parts, sh, -4.0, -2.0, 8.0, 1.0, acc, false)
		_b(parts, sh, -5.5, -8.0 + bob, 11.0, 2.0, acc)
		_b(parts, sh, -1.0, -6.0 + bob, 2.0, 2.0, skin.darkened(0.15), false)
		_b(parts, sh, -5.0, -17.0 + bob, 10.0, 9.0, skin)
		_b(parts, sh, -5.5, -18.0 + bob, 11.0, 4.0, head_col)
		_b(parts, sh, -5.5, -15.0 + bob, 2.0, 6.0, head_col)
		_b(parts, sh, 3.5, -15.0 + bob, 2.0, 6.0, head_col)
		if style == "braid":
			_b(parts, sh, -7.0, -14.0 + bob, 2.0, 11.0, hair.darkened(0.1))
		if style == "beard":
			_b(parts, sh, -3.5, -10.0 + bob, 7.0, 4.0, hair)
		if style == "short" and not hood:
			for sxp in [-3.5, -0.5, 2.5]:
				_b(parts, sh, sxp, -20.5 + bob, 2.0, 3.0, hair, false)

	if pal.item == "sheath" and not side:
		parts.append(["p", PackedVector2Array([Vector2(-6.0, -8.0 + bob), Vector2(-4.5, -9.0 + bob), Vector2(5.5, 3.0), Vector2(4.5, 4.0)]), Color("5a5f70", a)])
	elif pal.item == "hammer":
		var hx := -sx * 6.0 if side else -8.0
		_b(parts, sh, hx, -1.0, 1.0, 8.0, Color("6a4a30", a), false)
		_b(parts, sh, hx - 1.5, -3.0, 4.0, 3.0, Color("8d93a2", a))

	_paint(c, parts)
	for s in sh:
		c.draw_rect(s[0], s[1])
	# face details and gothic touches
	if not up and not side:
		if hood:
			c.draw_rect(Rect2(-4.0, -15.0 + bob, 8.0, 5.0), Color(0.03, 0.02, 0.06, a))
			c.draw_rect(Rect2(-3.0, -13.0 + bob, 2.0, 1.0), Color(0.75, 0.9, 1.0, a))
			c.draw_rect(Rect2(1.0, -13.0 + bob, 2.0, 1.0), Color(0.75, 0.9, 1.0, a))
		else:
			c.draw_rect(Rect2(-3.5, -13.0 + bob, 1.0, 2.0), eye)
			c.draw_rect(Rect2(2.5, -13.0 + bob, 1.0, 2.0), eye)
			c.draw_rect(Rect2(-3.5, -13.0 + bob, 1.0, 1.0), Color(1, 1, 1, 0.8 * a))
			c.draw_rect(Rect2(2.5, -13.0 + bob, 1.0, 1.0), Color(1, 1, 1, 0.8 * a))
			c.draw_rect(Rect2(-4.0, -14.0 + bob, 3.0, 1.0), Color(hair.darkened(0.3), a))
			c.draw_rect(Rect2(1.0, -14.0 + bob, 3.0, 1.0), Color(hair.darkened(0.3), a))
			if style != "beard":
				c.draw_rect(Rect2(-1.0, -10.0 + bob, 2.0, 1.0), Color(skin.darkened(0.4), a))
		c.draw_rect(Rect2(-0.5, -4.0 + bob, 1.0, 5.0), Color(coat.darkened(0.5), 0.8 * a))
		c.draw_rect(Rect2(-1.0, -2.0, 2.0, 1.0), Color("b89c52", a))
		c.draw_rect(Rect2(-4.0, 4.0, 8.0, 1.0), Color(ink, 0.35 * a))
	elif side:
		if hood:
			c.draw_rect(Rect2(sx * 1.0 - 1.5, -14.0 + bob, 3.5, 4.0), Color(0.03, 0.02, 0.06, a))
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 1.0), Color(0.75, 0.9, 1.0, a))
		else:
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 2.0), eye)
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 1.0), Color(1, 1, 1, 0.8 * a))
			c.draw_rect(Rect2(sx * 1.5 - 1.0, -14.0 + bob, 2.5, 1.0), Color(hair.darkened(0.3), a))
		c.draw_rect(Rect2(-1.0, -2.0, 2.0, 1.0), Color("b89c52", a))


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
	var ink := Color(OUT, 0.7)
	# fur tufts, spine ridge, ribs, scar, mange patch
	for i in 6:
		var x := (-4.5 + i * 1.7) * s
		c.draw_line(Vector2(x, -4.4 + sin(i * 2.1) * 0.5), Vector2(x - s * 0.9, -5.8 + run * 0.3), fur.lightened(0.25), 0.5)
	for i in 3:
		c.draw_line(Vector2((-2.0 + i * 1.8) * s, -2.0), Vector2((-2.4 + i * 1.8) * s, 0.4), Color(ink, 0.45), 0.35)
	c.draw_line(Vector2(-1.0 * s, -3.4), Vector2(1.8 * s, -2.2), Color("c06060") if flash <= 0.0 else Color.WHITE, 0.5)
	c.draw_circle(Vector2(-2.6 * s, -1.8), 1.0, Color(fur.darkened(0.25), 0.7))
	# ear detail and inner ear
	c.draw_circle(Vector2(3.0 * s, -5.2), 0.8, Color("f0b8b8") if flash <= 0.0 else Color.WHITE)
	c.draw_line(Vector2(2.2 * s, -6.2), Vector2(2.8 * s, -5.6), ink, 0.4)
	# brow, nostril, teeth, claws, tail rings
	c.draw_line(Vector2(4.6 * s, -3.4), Vector2(6.6 * s, -2.8), ink, 0.5)
	c.draw_rect(Rect2(8.2 * s - 0.4, 0.0, 0.7, 1.0), Color("f4ecd0"))
	c.draw_rect(Rect2(7.2 * s - 0.4, 0.2, 0.6, 0.9), Color("f4ecd0"))
	c.draw_circle(Vector2(5.9 * s, -2.0), 1.4, Color(1.0, 0.2, 0.2, 0.18))
	for i in 3:
		c.draw_line(Vector2((-3.3 + i * 5.2) * s, 3.9 + run), Vector2((-2.4 + i * 5.2) * s, 4.4 + run), Color("e9e0cc"), 0.35)
	for i in 4:
		var k2 := (i + 1.5) / 7.0
		var tp := Vector2(-s * (5.0 + k2 * 6.0), -1.0 + sin(t * 8.0 + k2 * 3.0) * 1.5 * k2)
		c.draw_line(tp + Vector2(0, -0.9), tp + Vector2(0, 0.9), Color(ink, 0.5), 0.35)


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
	var ink := Color(OUT, 0.75)
	for sgn in [-1.0, 1.0]:
		# wing bones and membrane scallops
		var root := Vector2(sgn * 2.0, -2.2)
		var tips := [Vector2(sgn * 6.0, -8.0 - fl * 4.0), Vector2(sgn * 11.0, -5.0 - fl * 5.0), Vector2(sgn * 9.0, -2.0 - fl * 3.0), Vector2(sgn * 7.0, 0.0 - fl * 2.0)]
		for tp in tips:
			c.draw_line(root, tp, Color(col.lightened(0.35), 0.9), 0.45)
		c.draw_circle(tips[1], 0.6, Color("d9d2c0"))
		c.draw_line(Vector2(sgn * 4.0, -4.0), Vector2(sgn * 8.5, -4.5 - fl * 3.0), Color(ink, 0.5), 0.35)
		# ear inner and tuft
		c.draw_line(Vector2(sgn * 1.5, -6.2), Vector2(sgn * 1.2, -7.6), Color("c88aa8"), 0.5)
		c.draw_line(Vector2(sgn * 1.2, 0.8), Vector2(sgn * 1.7, 1.8), Color(col.lightened(0.3), 0.9), 0.4)
	# fur chest tufts, fangs, nose, glow
	for i in 3:
		c.draw_line(Vector2(-1.2 + i * 1.2, -1.0), Vector2(-1.4 + i * 1.2, 1.2), Color(col.lightened(0.3), 0.8), 0.35)
	c.draw_rect(Rect2(-1.0, -2.2, 0.8, 0.8), Color("fff8e0"))
	c.draw_rect(Rect2(0.2, -2.2, 0.8, 0.8), Color("fff8e0"))
	c.draw_rect(Rect2(-0.4, -2.9, 0.8, 0.5), Color("d88aa0"))
	c.draw_circle(Vector2(-1.3, -3.9), 1.7, Color(1.0, 0.8, 0.3, 0.2))
	c.draw_circle(Vector2(1.3, -3.9), 1.7, Color(1.0, 0.8, 0.3, 0.2))


static func warden(c: CanvasItem, f: Vector2, t: float, flash: float, winding: bool, brass := false) -> void:
	shadow(c, 15.0)
	var steel := (Color("7a6238") if brass else Color("4c5262")) if flash <= 0.0 else Color.WHITE
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
	var ink := Color(OUT, 0.8)
	var hi := steel.lightened(0.35)
	var rune := Color(0.4, 0.9, 1.0, 0.5 + 0.4 * sin(t * 3.0)) if not brass else Color(1.0, 0.7, 0.3, 0.5 + 0.4 * sin(t * 3.0))
	# plate seams, rivets and highlights on the cuirass
	c.draw_line(Vector2(0, -14.5), Vector2(0, 5.5), ink, 0.7)
	c.draw_line(Vector2(-10, -9), Vector2(10, -9), ink, 0.6)
	c.draw_line(Vector2(-9.5, -4), Vector2(9.5, -4), ink, 0.6)
	c.draw_line(Vector2(-9.8, -14), Vector2(-8.6, 5), Color(hi, 0.7), 0.8)
	for i in 4:
		c.draw_circle(Vector2(-8.0 + i * 5.3, -13.5), 0.6, hi)
		c.draw_circle(Vector2(-8.0 + i * 5.3, -9.7), 0.5, hi)
	# chest sigil
	c.draw_arc(Vector2(0, -6.5), 2.6, 0.0, TAU, 14, rune, 0.7)
	c.draw_line(Vector2(0, -9.5), Vector2(0, -3.5), rune, 0.6)
	c.draw_line(Vector2(-2.4, -6.5), Vector2(2.4, -6.5), rune, 0.6)
	# tassets, knee plates, greaves lines
	for i in 5:
		c.draw_line(Vector2(-8.0 + i * 3.6, 3.0), Vector2(-8.6 + i * 3.8, 7.5), ink, 0.5)
	c.draw_circle(Vector2(-5.5, 8.5), 1.8, hi)
	c.draw_circle(Vector2(5.5, 8.5), 1.8, hi)
	c.draw_circle(Vector2(-5.5, 8.5), 0.7, ink)
	c.draw_circle(Vector2(5.5, 8.5), 0.7, ink)
	# pauldron spikes and trim
	for sg in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(sg * 12.0, -17.5), Vector2(sg * 16.0, -22.5), Vector2(sg * 16.5, -16.0)]), Color(OUT))
		c.draw_colored_polygon(PackedVector2Array([Vector2(sg * 12.8, -17.0), Vector2(sg * 15.6, -21.0), Vector2(sg * 15.8, -16.6)]), hi)
		c.draw_arc(Vector2(sg * 14.0, -14.0), 4.2, 0.0, TAU, 12, ink, 0.5)
	# helm: brow ridge, cheek vents, crest ridge, glowing eye halos
	c.draw_line(Vector2(-6.5, -22.3), Vector2(6.5, -22.3), hi, 0.8)
	for i in 4:
		c.draw_line(Vector2(-3.0 + i * 2.0, -21.0), Vector2(-3.0 + i * 2.0, -19.2), ink, 0.5)
	c.draw_line(Vector2(0, -29.5), Vector2(0, -23.5), hi, 0.7)
	c.draw_circle(Vector2(-3.0, -23.3), 2.6, Color(0.4, 0.9, 1.0, 0.12 * glow) if not brass else Color(1.0, 0.7, 0.3, 0.12 * glow))
	c.draw_circle(Vector2(3.0, -23.3), 2.6, Color(0.4, 0.9, 1.0, 0.12 * glow) if not brass else Color(1.0, 0.7, 0.3, 0.12 * glow))
	# sword details: fuller, crossguard and pommel
	var perp := Vector2(-f.y, f.x)
	var gp := Vector2(0, -8) + f * 4.0
	c.draw_line(gp - perp * 3.4, gp + perp * 3.4, Color(OUT), 2.2)
	c.draw_line(gp - perp * 3.0, gp + perp * 3.0, Color("d6b25a"), 1.0)
	c.draw_line(Vector2(0, -8) + f * 6.0, Vector2(0, -8) + f * 19.0, Color(hi, 0.8), 0.4)
	c.draw_circle(Vector2(0, -8) - f * 0.5, 1.5, Color("d6b25a"))
	# hanging chains and tattered cape stitches
	for i in 6:
		c.draw_circle(Vector2(-11.0 + i * 0.4, -2.0 + i * 1.6), 0.55, Color("9aa0ae"))
		c.draw_circle(Vector2(11.0 - i * 0.4, -2.0 + i * 1.6), 0.55, Color("9aa0ae"))
	for i in 5:
		c.draw_line(Vector2(-12.0 + i * 6.0, -15.0), Vector2(-12.5 + i * 6.2, 8.0), Color(0.5, 0.4, 0.65, 0.25), 0.5)
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
