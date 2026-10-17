extends RefCounted
## Procedural art: outlined, shaded characters, creatures, props and light helpers.
## Drawn in world units (1 tile = 16); the camera zoom makes every stroke crisp at 1080p.

const OUT := Color("111820")
const PAL_MU := {"coat": Color("353a48"), "accent": Color("7a2a2e"), "skin": Color("c4a083"), "hair": Color("a8a6ae"), "boots": Color("1c1620"), "style": "short", "item": "sheath", "hood": true, "mail": true, "look": "mu"}
const PAL_WRAITH := {"coat": Color("3a5670"), "accent": Color("9fc4d8"), "skin": Color("a9c0cc"), "hair": Color("7f9fb8"), "boots": Color("1e2e40"), "style": "short", "item": "none", "hood": true, "look": "wraith"}
const PAL_ISOLDE := {"coat": Color("3e4a38"), "accent": Color("6e4a2e"), "skin": Color("c8a287"), "hair": Color("7a3a24"), "boots": Color("261c16"), "style": "braid", "item": "hammer", "mail": true, "look": "isolde"}
const PAL_GARGOYLE := {"coat": Color("565d6a"), "accent": Color("8a3a2e"), "skin": Color("6f7886"), "hair": Color("3e4550"), "boots": Color("2a303a"), "style": "short", "item": "none", "mail": true, "look": "gargoyle"}
const PAL_WREN := {"coat": Color("2e4852"), "accent": Color("9a7a2e"), "skin": Color("c09a7e"), "hair": Color("1c1620"), "boots": Color("261c16"), "style": "short", "item": "none", "hood": true, "look": "wren"}
const PAL_CORVIN := {"coat": Color("503426"), "accent": Color("8a8d98"), "skin": Color("a98462"), "hair": Color("6e6e78"), "boots": Color("1c1610"), "style": "beard", "item": "none", "mail": true, "look": "corvin"}
const PAL_ALDOUS := {"coat": Color("22212c"), "accent": Color("8a7436"), "skin": Color("c4a98a"), "hair": Color("b8b8c0"), "boots": Color("14121a"), "style": "beard", "item": "none", "look": "aldous"}

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


static func pine(c: CanvasItem, p: Vector2, size: float, wind: float, col: Color) -> void:
	c.draw_rect(Rect2(p + Vector2(-1, -48) * size, Vector2(2, 49) * size), col.lightened(0.035))
	for branch in 7:
		var height := -58.0 + branch * 7
		var reach := 3.0 + branch * 1.6
		var sway := snappedf(wind * (1.0 - branch / 8.0), 0.5)
		var points := PackedVector2Array([
			Vector2(sway, height - 9), Vector2(reach * 0.45 + sway, height - 1),
			Vector2(reach * 0.32 + sway, height - 1), Vector2(reach + sway, height + 5),
			Vector2(reach * 0.7 + sway, height + 5), Vector2(reach * 1.15 + sway, height + 8),
			Vector2(sway, height + 5), Vector2(-reach * 1.15 + sway, height + 8),
			Vector2(-reach * 0.7 + sway, height + 5), Vector2(-reach + sway, height + 5),
			Vector2(-reach * 0.32 + sway, height - 1), Vector2(-reach * 0.45 + sway, height - 1),
		])
		for i in points.size():
			points[i] = p + points[i] * size
		c.draw_colored_polygon(points, col.lightened((branch % 3) * 0.012))
		for needle in 4:
			var n := p + Vector2(sway - reach + needle * reach * 0.6, height + 5) * size
			c.draw_rect(Rect2(n, Vector2(size * 0.5, size)), col.lightened(0.04))


static func shadow(c: CanvasItem, r := 6.5, at := Vector2.ZERO, size := 1.0) -> void:
	c.draw_set_transform(at + Vector2(0, 5.5) * size, 0.0, Vector2(size, size * 0.4))
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


# Half-unit colour ramps keep cloth and metal readable without a smoothing filter.
static func _b(parts: Array, sh: Array, x: float, y: float, w: float, h: float, col: Color, shade := true) -> void:
	parts.append(["r", Rect2(x, y, w, h), col])
	if shade and w >= 2.0 and h >= 2.0:
		sh.append([Rect2(x, y, w, 1.0), Color(col.lightened(0.28), col.a)])
		sh.append([Rect2(x, y, 1.0, h), Color(col.lightened(0.14), col.a)])
		sh.append([Rect2(x + w - 1.0, y + 1.0, 1.0, h - 1.0), Color(col.darkened(0.3), col.a)])
		sh.append([Rect2(x, y + h - 1.0, w, 1.0), Color(col.darkened(0.25), col.a)])
		if w >= 4.0:
			sh.append([Rect2(x + 1.0, y + 1.0, 0.5, h - 2.0), Color(col.lightened(0.22), col.a)])
			sh.append([Rect2(x + w - 1.5, y + 1.0, 0.5, h - 2.0), Color(col.darkened(0.15), col.a)])
		if w >= 5.0 and h >= 5.0:
			var dk := Color(col.darkened(0.18), col.a)
			for i in int(h - 2.0):
				if i % 2 == 0:
					sh.append([Rect2(x + w - 2.0, y + 1.0 + i, 1.0, 1.0), dk])
			for i in int(w - 3.0):
				if i % 2 == 1:
					sh.append([Rect2(x + 1.0 + i, y + h - 2.0, 1.0, 1.0), dk])


static func person(c: CanvasItem, f: Vector2, t: float, pal: Dictionary, moving := false, alpha := 1.0, atk := 0.0, yoff := 0.0, roll := 0.0, at := Vector2.ZERO, size := 1.0) -> void:
	shadow(c, 6.0 * (0.8 if roll != 0.0 else 1.0), at, size)
	var lunge := f * (1.5 if atk > 0.0 else 0.0)
	if roll != 0.0:
		# tumble about the body centre, tucked in
		var ctr := Vector2(0, -6)
		c.draw_set_transform(at + (ctr - ctr.rotated(roll) * 0.8 + Vector2(0, yoff + 2.0)) * size, roll, Vector2.ONE * size * 0.8)
	else:
		c.draw_set_transform(at + (Vector2(0, yoff) + lunge) * size, 0.0, Vector2.ONE * size)
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
	var swing := snappedf(sin(ph) * 2.0, 0.5) if moving else 0.0
	var bob := snappedf(-absf(cos(ph)) * 0.8, 0.5) if moving else snappedf(sin(t * 1.8) * 0.3, 0.5)
	var parts: Array = []
	var sh: Array = []
	var eye := Color("18252d", a)
	var blink := fposmod(t + float(posmod(hash(pal.look), 17)) * 0.19, 4.4) < 0.12
	var head_col := coat.darkened(0.55) if hood else hair
	var ink := Color(OUT, a)
	var hem := snappedf(sin(t * (8.0 if moving else 2.0)) * (1.4 if moving else 0.5), 0.5)
	var cape := PackedVector2Array([Vector2(-4.5, -8 + bob), Vector2(4.5, -8 + bob), Vector2(6 + hem, 3), Vector2(3 + hem, 5), Vector2(hem, 3.5), Vector2(-4 + hem, 5), Vector2(-6 + hem, 3)])
	_paint(c, [["p", cape, coat_d]])
	for fold in 3:
		var fx := -3.0 + fold * 2.5
		c.draw_line(Vector2(fx, -6 + bob), Vector2(fx + hem, 3), Color(coat.lightened(0.08), a), 0.5)

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
		parts.append(["p", cape, coat_d.lightened(0.05)])
		if style == "braid":
			_b(parts, sh, -1.0, -10.0 + bob, 2.0, 9.0, hair.darkened(0.1))
	else:
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

	_look_extras(parts, sh, pal, side, up, sx, bob, swing, t, a, coat, acc, hair)
	if pal.item == "sheath" and not side:
		parts.append(["p", PackedVector2Array([Vector2(-6.0, -8.0 + bob), Vector2(-4.5, -9.0 + bob), Vector2(5.5, 3.0), Vector2(4.5, 4.0)]), Color("5a5f70", a)])
	elif pal.item == "hammer":
		var hx := -sx * 6.0 if side else -8.0
		_b(parts, sh, hx, -1.0, 1.0, 8.0, Color("6a4a30", a), false)
		_b(parts, sh, hx - 1.5, -3.0, 4.0, 3.0, Color("8d93a2", a))

	_paint(c, parts)
	for s in sh:
		c.draw_rect(s[0], s[1])
	if atk > 0.0:
		var hand := Vector2(sx * 2.0 if side else 3.0, -5.0 + bob) + f * 7.0
		var sh0 := Vector2(sx * 1.0 if side else 3.5, -5.5 + bob)
		c.draw_line(sh0, hand, ink, 4.0)
		c.draw_line(sh0, hand, coat.lightened(0.15), 2.4)
		c.draw_rect(Rect2(hand.x - 1.2, hand.y - 1.2, 2.4, 2.4), ink)
		c.draw_rect(Rect2(hand.x - 0.8, hand.y - 0.8, 1.6, 1.6), skin)
	# face details and gothic touches
	if not up and not side:
		if hood:
			c.draw_rect(Rect2(-4.0, -15.0 + bob, 8.0, 5.0), Color(0.03, 0.02, 0.06, a))
			if pal.look == "wraith":
				c.draw_rect(Rect2(-3.0, -13.0 + bob, 2.0, 1.0), Color("bce7f1", a))
				c.draw_rect(Rect2(1.0, -13.0 + bob, 2.0, 1.0), Color("bce7f1", a))
			else:
				c.draw_rect(Rect2(-3.0, -14.0 + bob, 6.0, 5.0), skin.darkened(0.12))
				c.draw_rect(Rect2(2.0, -14.0 + bob, 1.0, 5.0), skin.darkened(0.4))
				c.draw_rect(Rect2(-3.0, -14.5 + bob, 6.0, 1.0), hair)
				for ex in [-2.0, 1.0]:
					c.draw_rect(Rect2(ex, -12.5 + bob, 1.0, 0.5 if blink else 1.0), eye)
					c.draw_rect(Rect2(ex - 0.5, -13.5 + bob, 1.5, 0.5), hair.darkened(0.4))
				c.draw_rect(Rect2(-0.5, -12.0 + bob, 0.5, 1.5), skin.lightened(0.25))
				c.draw_rect(Rect2(-1, -9.5 + bob, 2, 0.5), skin.darkened(0.5))
		else:
			c.draw_rect(Rect2(-3.5, -13.0 + bob, 1.5, 0.5 if blink else 1.5), eye)
			c.draw_rect(Rect2(2.0, -13.0 + bob, 1.5, 0.5 if blink else 1.5), eye)
			if not blink:
				c.draw_rect(Rect2(-3.5, -13.0 + bob, 0.5, 0.5), Color("ebdfc3", a))
				c.draw_rect(Rect2(2.0, -13.0 + bob, 0.5, 0.5), Color("ebdfc3", a))
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
			if pal.look != "wraith":
				c.draw_rect(Rect2(sx * 1.0 - 1, -14.0 + bob, 3, 5), skin.darkened(0.15))
				c.draw_rect(Rect2(sx * 1.0 - 1, -14.5 + bob, 3, 1), hair)
				c.draw_rect(Rect2(sx * 3.0 - 0.5, -12.0 + bob, 1, 1.5), skin)
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 0.5 if blink else 1.0), Color("bce7f1", a) if pal.look == "wraith" else eye)
		else:
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 2.0), eye)
			c.draw_rect(Rect2(sx * 2.0 - 0.5, -13.0 + bob, 1.0, 1.0), Color(1, 1, 1, 0.8 * a))
			c.draw_rect(Rect2(sx * 1.5 - 1.0, -14.0 + bob, 2.5, 1.0), Color(hair.darkened(0.3), a))
		c.draw_rect(Rect2(-1.0, -2.0, 2.0, 1.0), Color("b89c52", a))
	_fine(c, pal, side, up, sx, bob, swing, a, coat, acc, skin, hair, boots)
	_hero_detail(c, pal, side, up, sx, bob, t, a, coat, acc, skin, hair)


# Signature gear per hero so each reads at a glance: tabard and bell charm, dagger hilts and scarf, clockwork pack and lens, crest and sword hilt.
static func _hero_detail(c: CanvasItem, pal: Dictionary, side: bool, up: bool, sx: float, bob: float, t: float, a: float, coat: Color, acc: Color, skin: Color, hair: Color) -> void:
	var gold := Color("e0c27a", a)
	var ink := Color(OUT, a)
	var sway := sin(t * 3.0) * 0.8
	match pal.look:
		"mu":
			if up:
				c.draw_rect(Rect2(-3.0, -2.0, 6.0, 1.0), Color(acc.lightened(0.2), 0.8 * a))
				c.draw_rect(Rect2(-1.0, -10.0 + bob, 2.0, 7.0), Color(acc, 0.8 * a))
			else:
				c.draw_rect(Rect2(-6.5, -9.0 + bob, 2.5, 2.0), Color(acc.lightened(0.15), a))
				c.draw_rect(Rect2(4.0, -9.0 + bob, 2.5, 2.0), Color(acc.lightened(0.15), a))
				c.draw_rect(Rect2(-6.5, -9.0 + bob, 2.5, 0.5), Color(1, 1, 1, 0.35 * a))
				c.draw_rect(Rect2(3.5, 1.0, 1.5, 4.5), ink)
				c.draw_rect(Rect2(3.5, 0.0, 1.5, 1.5), gold)
				c.draw_rect(Rect2(2.8, 1.0, 3.0, 0.8), gold)
		"isolde":
			if not up:
				c.draw_rect(Rect2(-2.0, -7.0 + bob, 4.0, 7.0), Color(acc.lightened(0.2), 0.85 * a))
				c.draw_rect(Rect2(-0.5, -6.0 + bob, 1.0, 5.0), gold)
				c.draw_rect(Rect2(-1.5, -4.5 + bob, 3.0, 1.0), gold)
				c.draw_circle(Vector2(-4.0, 1.5), 1.6, ink)
				c.draw_circle(Vector2(-4.0, 1.5), 1.1, gold)
				c.draw_rect(Rect2(-4.4, 2.6, 0.8, 1.2), gold)
			else:
				c.draw_rect(Rect2(-2.0, -7.0 + bob, 4.0, 8.0), Color(acc.lightened(0.2), 0.85 * a))
			for i in 3:
				c.draw_rect(Rect2(-3.0 + i * 3.0, -8.5 + bob, 1.0, 0.8), Color(1, 1, 1, 0.5 * a))
		"wren":
			var bx := -sx * 3.0 if side else 0.0
			if not up:
				c.draw_line(Vector2(-5.0, -8.0 + bob), Vector2(4.0, -1.0), ink, 2.2)
				c.draw_line(Vector2(-5.0, -8.0 + bob), Vector2(4.0, -1.0), Color("6a4a2a", a), 1.2)
				for i in 3:
					c.draw_rect(Rect2(-3.0 + i * 2.5, -6.0 + i * 2.0 + bob, 1.2, 1.6), gold)
				c.draw_rect(Rect2(-6.5 + bx, 0.0, 1.0, 4.0), ink)
				c.draw_rect(Rect2(-7.0 + bx, -0.5, 2.0, 1.0), Color("b8bcc8", a))
				c.draw_rect(Rect2(5.5 + bx, 0.0, 1.0, 4.0), ink)
				c.draw_rect(Rect2(5.0 + bx, -0.5, 2.0, 1.0), Color("b8bcc8", a))
			c.draw_line(Vector2(-3.0, -9.0 + bob), Vector2(-8.0 - sway * 2.0, -5.0 + sway), ink, 2.4)
			c.draw_line(Vector2(-3.0, -9.0 + bob), Vector2(-8.0 - sway * 2.0, -5.0 + sway), acc, 1.2)
		"corvin":
			var px := -sx * 5.5 if side else 0.0
			if up or side:
				c.draw_rect(Rect2(-5.0 + px, -10.0 + bob, 10.0, 9.0), ink)
				c.draw_rect(Rect2(-4.0 + px, -9.0 + bob, 8.0, 7.0), Color("6a4a2e", a))
				c.draw_circle(Vector2(px, -5.5 + bob), 3.0, ink)
				c.draw_circle(Vector2(px, -5.5 + bob), 2.2, Color("b89c52", a))
				for i in 6:
					var ang := t * 2.0 + i * TAU / 6.0
					c.draw_rect(Rect2(px + cos(ang) * 2.6 - 0.5, -5.5 + bob + sin(ang) * 2.6 - 0.5, 1.0, 1.0), Color("b89c52", a))
				c.draw_circle(Vector2(px, -5.5 + bob), 0.9, ink)
			if not up:
				c.draw_rect(Rect2(-4.5, -16.0 + bob, 9.0, 1.5), ink)
				c.draw_rect(Rect2(-4.0, -16.0 + bob, 8.0, 1.0), Color("6a4a2e", a))
				c.draw_circle(Vector2(sx * 2.0 if side else 2.5, -14.5 + bob), 1.7, ink)
				c.draw_circle(Vector2(sx * 2.0 if side else 2.5, -14.5 + bob), 1.1, Color(0.6, 0.85, 0.95, 0.9 * a))
				c.draw_line(Vector2(-2.0, -7.0 + bob), Vector2(-3.5, 0.0), Color(gold, 0.8), 0.6)
				c.draw_circle(Vector2(-3.5, 0.5), 1.2, gold)


# Half-unit detail pass so figures hold up at 2K: folds, stitching, rivets, rim light, face and hair strands.
static func _fine(c: CanvasItem, pal: Dictionary, side: bool, up: bool, sx: float, bob: float, swing: float, a: float, coat: Color, acc: Color, skin: Color, hair: Color, boots: Color) -> void:
	var fold := Color(coat.darkened(0.55), 0.55 * a)
	var lit := Color(coat.lightened(0.4), 0.5 * a)
	var thread := Color(acc.lightened(0.2), 0.7 * a)
	var rim := Color(0.75, 0.82, 1.0, 0.28 * a)
	var hood: bool = pal.get("hood", false)
	if up:
		for i in 4:
			c.draw_line(Vector2(-3.0 + i * 2.0, -6.0 + bob), Vector2(-3.6 + i * 2.0, 3.0), fold, 0.5)
		c.draw_rect(Rect2(-4.5, -16.5 + bob, 1.0, 5.0), rim)
		c.draw_rect(Rect2(-1.0, -7.0 + bob, 2.0, 1.0), thread)
		return
	if side:
		c.draw_line(Vector2(-2.0, -5.0 + bob), Vector2(-3.0, 3.0), fold, 0.5)
		c.draw_line(Vector2(0.0, -6.0 + bob), Vector2(-0.5, 2.0), fold, 0.5)
		c.draw_rect(Rect2(-3.5, -1.0, 7.0, 0.5), Color(boots.lightened(0.5), 0.5 * a))
		c.draw_rect(Rect2(-0.5, -2.5, 1.5, 1.5), Color("8a6a3a", a))
		c.draw_rect(Rect2(-0.5, -2.5, 1.5, 0.5), Color("d6b25a", a))
		c.draw_rect(Rect2(-sx * 4.0 - 0.5, -16.0 + bob, 0.5, 8.0), rim)
		c.draw_rect(Rect2(sx * 2.5, -11.5 + bob, 1.0, 0.5), Color(skin.darkened(0.35), a))
		for i in 3:
			c.draw_line(Vector2(-3.0 + i * 1.5, -17.0 + bob), Vector2(-3.6 + i * 1.5, -11.0 + bob), Color(hair.lightened(0.25), 0.55 * a), 0.4)
		return
	for i in 3:
		c.draw_line(Vector2(-3.0 + i * 3.0, -6.0 + bob), Vector2(-3.5 + i * 3.2, -1.0), fold, 0.5)
	for i in 6:
		c.draw_rect(Rect2(-3.5 + i * 1.4, 4.0, 0.7, 0.5), thread)
	c.draw_rect(Rect2(-5.0, -7.0 + bob, 0.5, 5.0), lit)
	c.draw_rect(Rect2(-5.5, -7.5 + bob, 1.2, 1.2), Color("c8b070", a))
	c.draw_rect(Rect2(4.3, -7.5 + bob, 1.2, 1.2), Color("c8b070", a))
	c.draw_rect(Rect2(-1.5, -2.5, 3.0, 2.0), Color("8a6a3a", a))
	c.draw_rect(Rect2(-1.0, -2.0, 2.0, 1.0), Color("e0c27a", a))
	c.draw_rect(Rect2(3.0, -1.0, 2.0, 2.5), Color("4a3422", a))
	c.draw_rect(Rect2(3.0, -1.0, 2.0, 0.5), Color("7a5a3a", a))
	c.draw_rect(Rect2(-4.0, 3.5, 3.5, 0.5), Color(boots.lightened(0.5), 0.6 * a))
	c.draw_rect(Rect2(0.5, 3.5, 3.5, 0.5), Color(boots.lightened(0.5), 0.6 * a))
	c.draw_rect(Rect2(-5.0, -16.5 + bob, 0.5, 6.0), rim)
	if not hood:
		c.draw_rect(Rect2(-0.5, -12.0 + bob, 1.0, 1.5), Color(skin.lightened(0.25), a))
		c.draw_rect(Rect2(-2.0, -9.5 + bob, 4.0, 0.5), Color(skin.darkened(0.45), a))
		c.draw_rect(Rect2(-4.0, -11.0 + bob, 1.5, 1.0), Color(0.8, 0.3, 0.3, 0.18 * a))
		c.draw_rect(Rect2(2.5, -11.0 + bob, 1.5, 1.0), Color(0.8, 0.3, 0.3, 0.18 * a))
		for i in 4:
			c.draw_line(Vector2(-4.5 + i * 2.8, -18.0 + bob), Vector2(-4.8 + i * 2.8, -14.0 + bob), Color(hair.lightened(0.25), 0.55 * a), 0.4)
	else:
		c.draw_rect(Rect2(-4.5, -15.5 + bob, 9.0, 0.5), Color(coat.lightened(0.3), 0.5 * a))
		c.draw_line(Vector2(-4.0, -16.0 + bob), Vector2(-5.0, -9.0 + bob), fold, 0.5)
		c.draw_line(Vector2(4.0, -16.0 + bob), Vector2(5.0, -9.0 + bob), fold, 0.5)


static func rat(c: CanvasItem, f: Vector2, t: float, flash: float) -> void:
	shadow(c, 6.0)
	var s := 1.0 if f.x >= 0.0 else -1.0
	var run := roundf(sin(t * 14.0))
	var hit := flash > 0.0
	var fur := Color.WHITE if hit else Color("6e5c4c")
	var belly := fur.lightened(0.18)
	var pink := Color.WHITE if hit else Color("c78a8a")
	var parts: Array = []
	var sh: Array = []
	var tail_pts := PackedVector2Array()
	for i in 7:
		var k := float(i) / 6.0
		tail_pts.append(Vector2(-s * (5.0 + k * 7.0), 0.0 + roundf(sin(t * 8.0 + k * 3.0) * 1.5 * k)))
	c.draw_polyline(tail_pts, Color(OUT), 2.6)
	c.draw_polyline(tail_pts, pink.darkened(0.15), 1.2)
	var rx := func(x: float, w: float) -> float: return x if s > 0.0 else -x - w
	_b(parts, sh, rx.call(-4.0, 2.0), 2.0 + maxf(0.0, run), 2.0, 2.0, fur.darkened(0.4), false)
	_b(parts, sh, rx.call(1.0, 2.0), 2.0 + maxf(0.0, -run), 2.0, 2.0, fur.darkened(0.4), false)
	_b(parts, sh, rx.call(-5.0, 9.0), -4.0, 9.0, 6.0, fur)
	_b(parts, sh, rx.call(-4.0, 7.0), 0.0, 7.0, 2.0, belly, false)
	_b(parts, sh, rx.call(3.0, 5.0), -4.0, 5.0, 5.0, fur.lightened(0.06))
	_b(parts, sh, rx.call(8.0, 3.0), -2.0, 3.0, 2.0, fur.lightened(0.1), false)
	_b(parts, sh, rx.call(3.0, 2.0), -7.0, 2.0, 3.0, pink)
	_paint(c, parts)
	for q in sh:
		c.draw_rect(q[0], q[1])
	var ink := Color(OUT, 0.8)
	for i in 4:
		c.draw_rect(Rect2(rx.call(-4.0 + i * 2.0, 1.0), -5.0, 1.0, 1.0), fur.lightened(0.25))
	c.draw_rect(Rect2(rx.call(6.0, 1.0), -3.0, 1.0, 1.0), Color("ff3030"))
	c.draw_rect(Rect2(rx.call(10.0, 1.0), -2.0, 1.0, 1.0), ink)
	c.draw_rect(Rect2(rx.call(8.0, 1.0), -0.5, 1.0, 1.0), Color("f4ecd0"))
	c.draw_line(Vector2(rx.call(-3.0, 0.0), -3.0), Vector2(rx.call(-1.0, 0.0), 0.0), Color(0.45, 0.1, 0.1, 0.8), 0.6)
	c.draw_line(Vector2(rx.call(10.0, 0.0), -1.0), Vector2(rx.call(13.0, 0.0), -2.0), Color(1, 1, 1, 0.5), 0.4)
	c.draw_line(Vector2(rx.call(10.0, 0.0), -1.0), Vector2(rx.call(13.0, 0.0), 0.0), Color(1, 1, 1, 0.5), 0.4)


static func bat(c: CanvasItem, t: float, flash: float) -> void:
	var hit := flash > 0.0
	var col := Color.WHITE if hit else Color("434e68")
	c.draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.0, 0.35))
	c.draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0, 0.3))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var fl := roundf(sin(t * 20.0) * 2.0) / 2.0
	var parts: Array = []
	var sh: Array = []
	for sgn in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(sgn * 2.0, -3.0), Vector2(sgn * 7.0, -9.0 - fl * 4.0), Vector2(sgn * 12.0, -6.0 - fl * 5.0), Vector2(sgn * 10.0, -3.0 - fl * 3.0), Vector2(sgn * 8.0, -3.0 - fl * 2.0), Vector2(sgn * 6.0, 0.0), Vector2(sgn * 4.0, -1.0), Vector2(sgn * 2.5, 2.0)])
		if sgn < 0.0:
			pts.reverse()
		parts.append(["p", pts, col.darkened(0.15)])
	_b(parts, sh, -3.0, -3.0, 6.0, 7.0, col.lightened(0.08))
	_b(parts, sh, -3.0, -8.0, 6.0, 5.0, col.lightened(0.14))
	_b(parts, sh, -3.0, -11.0, 2.0, 3.0, col, false)
	_b(parts, sh, 1.0, -11.0, 2.0, 3.0, col, false)
	_paint(c, parts)
	for q in sh:
		c.draw_rect(q[0], q[1])
	for sgn in [-1.0, 1.0]:
		var root := Vector2(sgn * 3.0, -3.0)
		for tp in [Vector2(sgn * 7.0, -9.0 - fl * 4.0), Vector2(sgn * 12.0, -6.0 - fl * 5.0), Vector2(sgn * 9.0, -3.0 - fl * 3.0)]:
			c.draw_line(root, tp, col.lightened(0.3), 0.5)
		c.draw_rect(Rect2(sgn * 1.5 - 0.5, -10.0, 1.0, 1.0), Color("c86871"))
	c.draw_rect(Rect2(-2.0, -6.0, 1.0, 1.0), Color("ffd040"))
	c.draw_rect(Rect2(1.0, -6.0, 1.0, 1.0), Color("ffd040"))
	c.draw_rect(Rect2(-1.0, -3.5, 1.0, 1.5), Color.WHITE)
	c.draw_rect(Rect2(0.0, -3.5, 1.0, 1.5), Color.WHITE)
	for i in 3:
		c.draw_rect(Rect2(-2.0 + i * 1.5, 0.0, 1.0, 1.0), col.lightened(0.3))


static func warden(c: CanvasItem, f: Vector2, t: float, flash: float, winding: bool, brass := false) -> void:
	shadow(c, 15.0)
	var steel := (Color("a07c3c") if brass else Color("636a7e")) if flash <= 0.0 else Color.WHITE
	if winding and int(t * 20.0) % 2 == 0:
		steel = Color("c05555")
	var dark := steel.darkened(0.4)
	var glow_c := Color(1.0, 0.6, 0.25) if brass else Color(0.4, 0.9, 1.0)
	var glow := 0.7 + 0.3 * sin(t * 6.0)
	var parts: Array = []
	var sh: Array = []
	var sway := roundf(sin(t * 3.0))
	parts.append(["p", PackedVector2Array([Vector2(-13, -18), Vector2(13, -18), Vector2(17, 10), Vector2(11, 7 + sway), Vector2(6, 12), Vector2(0, 8), Vector2(-6, 12), Vector2(-11, 7 - sway), Vector2(-17, 10)]), Color("242936")])
	_b(parts, sh, -9.0, 5.0, 7.0, 8.0, dark)
	_b(parts, sh, 2.0, 5.0, 7.0, 8.0, dark)
	_b(parts, sh, -10.0, 11.0, 9.0, 4.0, steel.darkened(0.15))
	_b(parts, sh, 1.0, 11.0, 9.0, 4.0, steel.darkened(0.15))
	_b(parts, sh, -11.0, -16.0, 22.0, 20.0, steel)
	_b(parts, sh, -10.0, 1.0, 20.0, 5.0, dark.lightened(0.05))
	_b(parts, sh, -11.0, -2.0, 22.0, 3.0, Color("3a2a22"), false)
	_b(parts, sh, -2.0, -3.0, 4.0, 4.0, Color("d6b25a"))
	_b(parts, sh, -17.0, -19.0, 9.0, 8.0, steel.lightened(0.1))
	_b(parts, sh, 8.0, -19.0, 9.0, 8.0, steel.lightened(0.1))
	_b(parts, sh, -8.0, -29.0, 16.0, 13.0, steel.lightened(0.05))
	_b(parts, sh, -2.0, -33.0, 4.0, 5.0, Color("8a2a3a"), false)
	parts.append(["p", PackedVector2Array([Vector2(-8, -26), Vector2(-14, -34), Vector2(-9, -30)]), steel.darkened(0.1)])
	parts.append(["p", PackedVector2Array([Vector2(8, -26), Vector2(14, -34), Vector2(9, -30)]), steel.darkened(0.1)])
	for sg in [-1.0, 1.0]:
		parts.append(["p", PackedVector2Array([Vector2(sg * 14.0, -19.0), Vector2(sg * 17.0, -25.0), Vector2(sg * 18.0, -18.0)]), steel.lightened(0.15)])
	_paint(c, parts)
	for q in sh:
		c.draw_rect(q[0], q[1])
	var ink := Color(OUT, 0.85)
	var hi := steel.lightened(0.35)
	c.draw_rect(Rect2(-6.0, -25.0, 12.0, 3.0), Color("07060c"))
	c.draw_rect(Rect2(-5.0, -24.5, 3.0, 2.0), Color(glow_c, glow))
	c.draw_rect(Rect2(2.0, -24.5, 3.0, 2.0), Color(glow_c, glow))
	c.draw_circle(Vector2(-3.5, -23.5), 3.0, Color(glow_c, 0.12 * glow))
	c.draw_circle(Vector2(3.5, -23.5), 3.0, Color(glow_c, 0.12 * glow))
	for i in 4:
		c.draw_rect(Rect2(-3.0 + i * 2.0, -20.0, 1.0, 3.0), ink)
	c.draw_line(Vector2(0, -15.0), Vector2(0, 0.0), ink, 0.8)
	c.draw_line(Vector2(-10.0, -8.0), Vector2(10.0, -8.0), ink, 0.7)
	for i in 4:
		c.draw_rect(Rect2(-8.0 + i * 5.0, -14.5, 1.0, 1.0), hi)
		c.draw_rect(Rect2(-8.0 + i * 5.0, -9.5, 1.0, 1.0), hi)
	var rune := Color(glow_c, 0.5 + 0.4 * sin(t * 3.0))
	c.draw_arc(Vector2(0, -12.0), 2.6, 0.0, TAU, 14, rune, 0.7)
	c.draw_line(Vector2(0, -15.0), Vector2(0, -9.0), rune, 0.6)
	for i in 5:
		c.draw_line(Vector2(-8.0 + i * 4.0, 2.0), Vector2(-8.0 + i * 4.0, 6.0), ink, 0.5)
	c.draw_rect(Rect2(-7.0, 8.0, 3.0, 2.0), hi)
	c.draw_rect(Rect2(4.0, 8.0, 3.0, 2.0), hi)
	var perp := Vector2(-f.y, f.x)
	var base := Vector2(0, -8)
	c.draw_line(base, base + f * 22.0, Color(OUT), 5.0)
	c.draw_line(base, base + f * 22.0, Color("c8ccd8"), 3.0)
	c.draw_line(base + f * 5.0, base + f * 21.0, Color("7a8298"), 1.0)
	c.draw_line(base + f * 4.0 - perp * 3.6, base + f * 4.0 + perp * 3.6, Color(OUT), 3.0)
	c.draw_line(base + f * 4.0 - perp * 3.2, base + f * 4.0 + perp * 3.2, Color("d6b25a"), 1.4)
	c.draw_circle(base - f * 0.5, 1.8, Color("d6b25a"))
	for i in 6:
		c.draw_rect(Rect2(-12.0 + i * 0.5 - 0.5, -1.0 + i * 1.7, 1.0, 1.0), Color("9aa0ae"))
		c.draw_rect(Rect2(12.0 - i * 0.5 - 0.5, -1.0 + i * 1.7, 1.0, 1.0), Color("9aa0ae"))
	var lc := Color("ffcf70") if int(t * 6.0) % 2 == 0 else Color("e09a3a")
	c.draw_circle(Vector2(-15, 4), 3.2, Color(0.2, 0.15, 0.1))
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


# Per-character silhouette extras: tails, hoods, hats, pauldrons, satchels, staffs, wisps.
static func _look_extras(parts: Array, sh: Array, pal: Dictionary, side: bool, up: bool, sx: float, bob: float, swing: float, t: float, a: float, coat: Color, acc: Color, hair: Color) -> void:
	var coat_d := coat.darkened(0.4)
	var sway := roundf(sin(t * 3.0 + 1.0) * 1.0)
	var steel := Color("7d8294", a)
	match pal.look:
		"mu":
			for sg in [-1.0, 1.0]:
				parts.insert(0, ["p", PackedVector2Array([Vector2(sg * 3.0, 1.0), Vector2(sg * 5.5, 2.5), Vector2(sg * 5.0, 6.0 + sway * 0.5), Vector2(sg * 2.5, 6.5 + sway * 0.5)]), coat_d])
				if not side:
					_b(parts, sh, sg * 5.0 - 1.5, -9.0 + bob, 3.0, 2.5, acc)
		"wraith":
			for i in 3:
				parts.append(["p", PackedVector2Array([Vector2(-4.0 + i * 3.0, 4.0), Vector2(-1.0 + i * 3.0, 4.0), Vector2(-2.5 + i * 3.0 + sway, 9.0 + i % 2)]), Color(coat, 0.7 * a)])
		"isolde":
			if not side:
				_b(parts, sh, 4.0, -1.0, 4.0, 5.0, Color("5a3a24", a))
				_b(parts, sh, 4.0, -2.0, 4.0, 1.0, Color("8a6a44", a), false)
				_b(parts, sh, -8.0, -9.0, 4.0, 3.0, Color("4a3426", a))
		"wren":
			parts.append(["p", PackedVector2Array([Vector2(-4.0, -17.0 + bob), Vector2(4.0, -17.0 + bob), Vector2(sway * 2.0 + 1.0, -26.0 + bob)]), coat.darkened(0.5)])
			if not up:
				_b(parts, sh, 4.0 + (1.0 if side else 0.0), -8.0 + bob, 2.0, 9.0 + sway, acc.darkened(0.1))
		"corvin":
			if not side:
				_b(parts, sh, -9.0, -10.0 + bob, 5.0, 5.0, steel)
				_b(parts, sh, 4.0, -10.0 + bob, 5.0, 5.0, steel.darkened(0.15))
				_b(parts, sh, -6.0, -7.0 + bob, 12.0, 4.0, coat.lightened(0.05))
			else:
				_b(parts, sh, -3.0, -10.0 + bob, 6.0, 5.0, steel)
		"aldous":
			parts.append(["p", PackedVector2Array([Vector2(-8.0, -17.0 + bob), Vector2(8.0, -17.0 + bob), Vector2(5.0, -19.0 + bob), Vector2(sway, -31.0 + bob), Vector2(-5.0, -19.0 + bob)]), Color("1a1822", a)])
			parts.append(["r", Rect2(-8.0, -18.0 + bob, 16.0, 2.0), Color("2a2836", a)])
			var stx := -sx * 7.0 if side else 8.0
			_b(parts, sh, stx, -14.0, 1.0, 20.0, Color("4a3524", a), false)
			parts.append(["c", [Vector2(stx + 0.5, -15.0), 2.0], Color("c7a84f", a)])
		"gargoyle":
			if not side:
				_b(parts, sh, -9.0, -10.0 + bob, 5.0, 5.0, coat.lightened(0.1))
				_b(parts, sh, 4.0, -10.0 + bob, 5.0, 5.0, coat.darkened(0.1))
			parts.insert(0, ["p", PackedVector2Array([Vector2(-2.0, 4.0), Vector2(2.0, 4.0), Vector2(sway * 3.0 + 6.0, 9.0), Vector2(sway * 3.0 + 4.0, 10.0)]), coat_d])


# Multi-part boss: oversized armored body, floating horned crown and two detached claws.
static func colossus(c: CanvasItem, f: Vector2, t: float, flash: float, winding: bool) -> void:
	c.draw_set_transform(Vector2(0, -6), 0.0, Vector2(1.7, 1.7))
	warden(c, f, t, flash, winding, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var col := Color("a07c3c") if flash <= 0.0 else Color.WHITE
	if winding and int(t * 20.0) % 2 == 0:
		col = Color("c05555")
	var glow := Color(1.0, 0.6, 0.25, 0.6 + 0.3 * sin(t * 5.0))
	for sg in [-1.0, 1.0]:
		var o := Vector2(sg * (38.0 + sin(t * 2.0 + sg) * 3.0), -22.0 + cos(t * 2.5 + sg) * 4.0)
		var parts: Array = []
		var sh: Array = []
		_b(parts, sh, o.x - 6.0, o.y - 5.0, 12.0, 10.0, col)
		for i in 3:
			parts.append(["p", PackedVector2Array([Vector2(o.x - 5.0 + i * 4.5, o.y + 5.0), Vector2(o.x - 3.0 + i * 4.5, o.y + 5.0), Vector2(o.x - 4.0 + i * 4.5, o.y + 13.0)]), col.darkened(0.15)])
		_paint(c, parts)
		for q in sh:
			c.draw_rect(q[0], q[1])
		c.draw_circle(o, 2.0, glow)
		c.draw_line(Vector2(sg * 20.0, -30.0), o - Vector2(sg * 6.0, 0), Color(glow, 0.25), 1.0)
	for sg in [-1.0, 1.0]:
		var hp := PackedVector2Array([Vector2(sg * 9.0, -50.0), Vector2(sg * 17.0, -66.0 + sin(t * 3.0) * 1.5), Vector2(sg * 13.0, -48.0)])
		c.draw_colored_polygon(hp, Color(OUT))
		c.draw_colored_polygon(PackedVector2Array([hp[0] + Vector2(-sg, -1), hp[1] + Vector2(-sg * 1.5, 2), hp[2] + Vector2(-sg * 2, -1)]), col.lightened(0.1))
