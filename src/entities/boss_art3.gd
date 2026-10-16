extends RefCounted
## Refined bodies for the Barghest of Whitby, Il Medico della Peste and Cacus of the Aventine (world-pixel units, origin at the feet).

const BA = preload("res://src/entities/boss_art.gd")
const B2 = preload("res://src/entities/boss_art2.gd")
const OUT := Color("0e0a14")


# Tapered limb through a list of joints, with outline, base colour, a rim highlight and optional width list.
static func _limb(c: CanvasItem, pts: Array, widths: Array, col: Color, hi: Color, f: float) -> void:
	var base := BA._fl(col, f)
	for pass_i in 3:
		for i in pts.size() - 1:
			var w0: float = widths[i]
			var w1: float = widths[i + 1]
			var steps := 4
			for k in steps:
				var u0 := float(k) / steps
				var u1 := float(k + 1) / steps
				var a: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], u0)
				var b: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], u1)
				var w := lerpf(w0, w1, (u0 + u1) * 0.5)
				if pass_i == 0:
					c.draw_line(a, b, OUT, w + 3.0)
				elif pass_i == 1:
					c.draw_line(a, b, base, w)
				else:
					c.draw_line(a + Vector2(-w * 0.18, -w * 0.22), b + Vector2(-w * 0.18, -w * 0.22), BA._fl(hi, f), maxf(1.0, w * 0.22))
	for i in pts.size():
		var w: float = widths[i]
		if _is_joint(i, pts.size()):
			c.draw_circle(pts[i], w * 0.5, base)


static func _is_joint(i: int, n: int) -> bool:
	return i > 0 and i < n - 1


# ====================================================================== Barghest of Whitby

static func barghest(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var fur := Color("23202f")
	var fur_l := Color("4c4770")
	var fur_d := Color("0a0810")
	var ghost := Color(0.55, 0.9, 1.0) if ph < 3 else Color(0.8, 0.6, 1.0)
	var bone := Color("d8d8e0")
	var iron := Color("7a7a8c")
	var eye := Color(1.0, 0.4, 0.15) if exposed <= 0.0 else Color(1.0, 0.95, 0.5)
	var br := sin(t * 1.9) * 1.6
	var rear := 16.0 if winding else 0.0
	var crouch := 8.0 if winding else 0.0
	B2._shadow(c, 96.0)
	# ghostly mist pooling around the paws
	for i in 6:
		var u := fmod(t * 0.4 + i * 0.17, 1.0)
		c.draw_circle(Vector2(-84 + i * 36 + sin(t + i) * 6.0, -6 - u * 16.0), 9.0 + u * 8.0, Color(ghost, 0.18 * (1.0 - u)))
	# far-side legs first (darker), then near ones over the body
	var gait := t * 4.2 if moving else 0.0
	for pass_i in 2:
		var far := pass_i == 0
		var tone := fur_d if far else fur
		var rim := fur if far else fur_l
		var hind_x := [-58.0, -40.0] if far else [-50.0, -30.0]
		var front_x := [34.0, 56.0] if far else [28.0, 50.0]
		for k in 2:
			var hx: float = hind_x[k]
			var ph_k := gait + k * 2.4 + (1.2 if far else 0.0)
			var lift: float = maxf(0.0, sin(ph_k)) * 8.0 if moving else 0.0
			var sw: float = cos(ph_k) * 6.0 if moving else 0.0
			# hind leg: thigh -> hock -> pastern -> paw
			var hip := Vector2(hx + 6, -86 + crouch * 0.5)
			var hock := Vector2(hx - 16 + sw * 0.5, -42 - lift * 0.4)
			var pas := Vector2(hx - 6 + sw, -14 - lift)
			var paw := Vector2(hx + 4 + sw, -3 - lift)
			_limb(c, [hip, hock, pas, paw], [30.0, 18.0, 11.0, 12.0], tone, rim, f)
			if not far:
				c.draw_colored_polygon(BA._ellipse(Vector2(hx - 2, -72), 17.0, 22.0), BA._fl(fur, f))
				c.draw_arc(Vector2(hx - 2, -72), 17.0, 3.6, 5.4, 8, BA._fl(fur_l, f), 1.4)
			_paw(c, paw, 1.0, f, bone, ghost, t)
		for k in 2:
			var fx: float = front_x[k]
			var ph_k := gait + k * 2.4 + (3.6 if far else 2.4)
			var lift: float = maxf(0.0, sin(ph_k)) * 8.0 if moving else 0.0
			var sw: float = cos(ph_k) * 6.0 if moving else 0.0
			var sh := Vector2(fx - 4, -96 + br + crouch * 0.4)
			var el := Vector2(fx - 8 + sw * 0.4, -52 - lift * 0.3 + crouch * 0.4)
			var wr := Vector2(fx + 2 + sw, -16 - lift)
			var pw := Vector2(fx + 10 + sw, -3 - lift)
			_limb(c, [sh, el, wr, pw], [28.0, 17.0, 11.0, 12.0], tone, rim, f)
			_paw(c, pw, 1.0, f, bone, ghost, t)
	# lashing tail wreathed in ghost fire
	var tp: Array = []
	for j in 7:
		tp.append(Vector2(-84 - j * 8, -98 - j * 4 + sin(t * 3.0 + j * 0.6) * 6.0 + rear * j * 0.3))
	for j in 6:
		var w := 9.0 - j * 1.1
		c.draw_line(tp[j], tp[j + 1], OUT, w + 2.0)
		c.draw_line(tp[j], tp[j + 1], BA._fl(fur, f), w)
	for j in 5:
		B2._flame(c, tp[j + 2], 14.0 + j * 1.5, t + j, ghost, 3.5)
	# body: deep ribbed chest, tucked waist, heavy haunch
	var body := BA._sm([Vector2(-88, -100 + br), Vector2(-56, -122 + br), Vector2(-8, -116 + br - rear * 0.3), Vector2(36, -132 + br - rear * 0.6), Vector2(68, -112 - rear * 0.6), Vector2(66, -76), Vector2(28, -64), Vector2(-20, -74), Vector2(-60, -72), Vector2(-90, -82)], true, 5)
	BA._shape(c, body, fur, f, fur_l)
	# exposed ribs and spectral hollows showing through the hide
	for i in 6:
		var rx := 6.0 + i * 8.0
		c.draw_arc(Vector2(rx - 16, -92 + br), 22.0 - i * 0.6, -0.5, 1.3, 8, Color(bone, 0.6), 1.6)
	c.draw_colored_polygon(BA._ellipse(Vector2(-30, -96 + br), 16.0, 9.0), Color(ghost, 0.18 + 0.08 * sin(t * 3.0)))
	for k in 5:
		c.draw_line(Vector2(-74 + k * 4, -108 + br), Vector2(-68 + k * 4, -86), Color(fur_d, 0.7), 1.2)
	# shaggy fur tufts along the spine and belly
	for i in 17:
		var x := -80.0 + i * 9.5
		var y := -114.0 + br - (rear * 0.4 if x > 0 else 0.0) - (14.0 if x > 10 else 0.0) * ((x - 10.0) / 60.0) - (6.0 if i % 2 == 0 else 0.0)
		BA._poly(c, [Vector2(x - 3, y + 8), Vector2(x + sin(t * 3.0 + i) * 1.6, y - 10), Vector2(x + 4, y + 8)], fur_l, f, 0.8)
	for i in 11:
		var x := -70.0 + i * 12.0
		BA._poly(c, [Vector2(x - 3, -72), Vector2(x, -58 + (i % 3) * 3), Vector2(x + 3, -72)], fur, f, 0.8)
	# ghost-fire licking along the spine
	for i in 8:
		B2._flame(c, Vector2(-70.0 + i * 20.0, -118.0 + br - (rear * 0.5 if i > 4 else 0.0) - (i * 2.0 if i > 3 else 0.0)), 16.0 + (i % 2) * 8.0 + (ph - 1) * 5.0, t + i * 0.7, ghost, 4.0)
	# broken iron shackles and chains
	for sx in [-34.0, 6.0]:
		BA._chain(c, Vector2(sx, -78), Vector2(sx + 14, -34), 8.0, 7, iron)
		c.draw_circle(Vector2(sx + 14, -34), 5.0, OUT)
		c.draw_arc(Vector2(sx + 14, -34), 4.2, 0, TAU, 10, Color("a8a8bc"), 1.6)
	# heavy front shoulder mass and the great ruff of spiked fur
	var neck := BA._sm([Vector2(36, -132 + br - rear * 0.6), Vector2(64, -156 - rear), Vector2(94, -150 - rear), Vector2(98, -104 - rear * 0.2), Vector2(64, -76)], true, 4)
	BA._shape(c, neck, fur, f, fur_l)
	for i in 10:
		var a := -2.6 + i * 0.36
		var p0 := Vector2(72, -118 - rear * 0.5)
		BA._poly(c, [p0 + Vector2.from_angle(a - 0.12) * 22.0, p0 + Vector2.from_angle(a) * (44.0 + (i % 2) * 8.0), p0 + Vector2.from_angle(a + 0.12) * 22.0], Color("3e3856") if i % 2 == 0 else fur_l, f, 1.0)
	# spiked iron collar
	var col_a := Vector2(86, -140 - rear)
	var col_b := Vector2(92, -104 - rear * 0.3)
	c.draw_line(col_a, col_b, OUT, 11.0)
	c.draw_line(col_a, col_b, iron, 8.0)
	c.draw_line(col_a + Vector2(-2, 0), col_b + Vector2(-2, 0), Color("b8b8cc"), 2.0)
	for k in 5:
		var sp := col_a.lerp(col_b, 0.12 + k * 0.19)
		BA._poly(c, [sp + Vector2(-3, 0), sp + Vector2(10, -2 - k % 2 * 3), sp + Vector2(3, 6)], Color("c8c8da"), f, 0.8)
	var hx := 108.0
	var hy := -144.0 - rear
	# head: heavy brow, long muzzle, wrinkled snarl
	var skull := BA._sm([Vector2(hx - 26, hy - 2), Vector2(hx - 12, hy - 24), Vector2(hx + 10, hy - 24), Vector2(hx + 26, hy - 12), Vector2(hx + 56, hy + 2), Vector2(hx + 62, hy + 14), Vector2(hx + 24, hy + 16), Vector2(hx - 14, hy + 20)], true, 5)
	BA._shape(c, skull, fur, f, fur_l)
	BA._poly(c, [Vector2(hx - 2, hy - 20), Vector2(hx + 30, hy - 8), Vector2(hx + 22, hy - 2), Vector2(hx - 2, hy - 8)], fur_d, f, 1.2)
	for k in 4:
		c.draw_line(Vector2(hx + 34 + k * 5, hy + 2 - k * 0.5), Vector2(hx + 40 + k * 5, hy - 6 + k), Color(fur_l, 0.9), 1.2)
	var jaw_open := 8.0 + (16.0 if winding else 0.0) + sin(t * 3.0) * 1.6
	var jaw := PackedVector2Array([Vector2(hx - 10, hy + 16), Vector2(hx + 58, hy + 16 + jaw_open * 0.5), Vector2(hx + 46, hy + 26 + jaw_open), Vector2(hx - 2, hy + 30 + jaw_open * 0.6)])
	BA._shape(c, jaw, fur_d, f)
	c.draw_colored_polygon(PackedVector2Array([Vector2(hx + 2, hy + 16), Vector2(hx + 56, hy + 16 + jaw_open * 0.4), Vector2(hx + 44, hy + 22 + jaw_open * 0.8), Vector2(hx + 4, hy + 22 + jaw_open * 0.5)]), Color("7a0c1c"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(hx + 20, hy + 20 + jaw_open * 0.3), Vector2(hx + 36, hy + 20 + jaw_open * 0.35), Vector2(hx + 30, hy + 28 + jaw_open * 0.7)]), Color("c0405a"))
	# upper fangs (two big canines plus a row of teeth) and lower tusks
	for k in 6:
		var tx := hx + 14.0 + k * 7.5
		var tl := 12.0 if k == 0 or k == 5 else 6.0
		BA._poly(c, [Vector2(tx, hy + 15), Vector2(tx + 2.5, hy + 15 + tl + jaw_open * 0.15), Vector2(tx + 5, hy + 15)], Color("f0f0f8"), f, 0.8)
	for k in 5:
		var tx := hx + 16.0 + k * 8.0
		BA._poly(c, [Vector2(tx, hy + 22 + jaw_open * 0.9), Vector2(tx + 2.5, hy + 12 + jaw_open * 0.5 - (4.0 if k % 4 == 0 else 0.0)), Vector2(tx + 5, hy + 22 + jaw_open * 0.9)], Color("d8d8e4"), f, 0.8)
	# ghost fire drooling from the maw
	for k in 4:
		var u := fmod(t * 0.9 + k * 0.25, 1.0)
		c.draw_circle(Vector2(hx + 20 + k * 9, hy + 24 + jaw_open * 0.8 + u * 20.0), 2.2 * (1.0 - u * 0.5), Color(ghost, 0.8 * (1.0 - u)))
	if winding:
		B2._flame(c, Vector2(hx + 40, hy + 22 + jaw_open * 0.6), 22.0, t, ghost, 6.0)
	# swept-back ears with torn tips
	BA._poly(c, [Vector2(hx - 20, hy - 14), Vector2(hx - 26, hy - 46), Vector2(hx - 14, hy - 38), Vector2(hx - 4, hy - 18)], fur, f, 1.2)
	BA._poly(c, [Vector2(hx - 6, hy - 18), Vector2(hx + 2, hy - 44), Vector2(hx + 8, hy - 36), Vector2(hx + 12, hy - 16)], fur_l, f, 1.2)
	BA._poly(c, [Vector2(hx - 2, hy - 20), Vector2(hx + 2, hy - 36), Vector2(hx + 6, hy - 22)], Color("7a2a3a"), f, 0.6)
	# burning eyes under a snarling brow
	c.draw_circle(Vector2(hx + 14, hy - 4), 16.0, Color(eye, 0.16))
	c.draw_circle(Vector2(hx + 14, hy - 4), 9.0, Color(eye, 0.28))
	BA._poly(c, [Vector2(hx + 4, hy - 4), Vector2(hx + 16, hy - 10), Vector2(hx + 28, hy - 2), Vector2(hx + 16, hy + 2)], OUT, f, 0.8)
	BA._poly(c, [Vector2(hx + 6, hy - 3), Vector2(hx + 16, hy - 7), Vector2(hx + 25, hy - 2), Vector2(hx + 16, hy + 0)], eye, f, 0.6)
	c.draw_line(Vector2(hx + 16, hy - 7), Vector2(hx + 16, hy + 0), OUT, 1.4)
	B2._flame(c, Vector2(hx + 14, hy - 10), 16.0, t, eye, 3.5)
	BA._poly(c, [Vector2(hx + 0, hy - 12), Vector2(hx + 30, hy - 8), Vector2(hx + 28, hy - 14), Vector2(hx + 2, hy - 20)], fur_d, f, 0.8)
	# scarred snout, nostril, trailing breath
	c.draw_line(Vector2(hx + 30, hy - 10), Vector2(hx + 46, hy + 6), Color(0.55, 0.3, 0.4, 0.9), 1.6)
	c.draw_circle(Vector2(hx + 58, hy + 6), 3.0, OUT)
	for k in 4:
		var u := fmod(t * 0.9 + k * 0.25, 1.0)
		c.draw_circle(Vector2(hx + 62 + u * 26, hy + 4 - u * 10), 2.0 + u * 4.0, Color(ghost, 0.4 * (1.0 - u)))
	# drifting spirits
	for i in 6:
		var u := fmod(t * 0.35 + i * 0.17, 1.0)
		c.draw_circle(Vector2(-60 + i * 34, -30 - u * 90), 3.2 - u * 2.0, Color(ghost, 0.32 * (1.0 - u)))


static func _paw(c: CanvasItem, p: Vector2, s: float, f: float, bone: Color, ghost: Color, t: float) -> void:
	c.draw_colored_polygon(BA._ellipse(p + Vector2(5, 0), 12.0 * s, 5.0 * s), OUT)
	c.draw_colored_polygon(BA._ellipse(p + Vector2(5, -0.5), 10.6 * s, 4.0 * s), BA._fl(Color("2a263a"), f))
	c.draw_circle(p + Vector2(4, 2), 4.0, Color(ghost, 0.3 + 0.1 * sin(t * 5.0)))
	for j in 4:
		var bx := p.x + 8.0 + j * 3.0
		BA._poly(c, [Vector2(bx, p.y - 2), Vector2(bx + 7, p.y + 3), Vector2(bx, p.y + 2)], bone, f, 0.7)


# ====================================================================== Il Medico della Peste

static func plague(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var coat := Color("2a2430")
	var coat_l := Color("504560")
	var wax := Color("5a4a3a")
	var gold := Color("c8a858")
	var bone := Color("eee6d2")
	var bone_d := Color("b8ac90")
	var eye := Color(0.5, 1.0, 0.45) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var miasma := Color(0.5, 0.85, 0.35)
	var br := sin(t * 1.5) * 1.3
	var lift_arm := 14.0 if winding else 0.0
	B2._shadow(c, 68.0)
	# plague rats at his feet
	for i in 4:
		var rx := -70.0 + i * 46.0 + sin(t * 2.0 + i) * 6.0
		c.draw_colored_polygon(BA._ellipse(Vector2(rx, -4), 8.0, 4.5), OUT)
		c.draw_colored_polygon(BA._ellipse(Vector2(rx, -4.5), 6.8, 3.6), Color("4a4038"))
		c.draw_circle(Vector2(rx + 7, -5), 2.4, Color("4a4038"))
		BA._poly(c, [Vector2(rx + 6, -7), Vector2(rx + 7, -10), Vector2(rx + 9, -7)], Color("7a5a5a"), f, 0.6)
		c.draw_circle(Vector2(rx + 8.4, -5.6), 0.7, Color(1, 0.3, 0.3))
		c.draw_line(Vector2(rx - 7, -4), Vector2(rx - 16, -2 + sin(t * 3.0 + i) * 2.5), Color("8a6a6a"), 1.0)
	# boots and legs
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		BA._poly(c, [Vector2(s * 6, -50), Vector2(s * 18, -50), Vector2(s * 17, -12 + lift), Vector2(s * 26, -2 + lift), Vector2(s * 24, 2 + lift), Vector2(s * 5, 2 + lift)], Color("1a1418"), f, 1.2)
		c.draw_line(Vector2(s * 8, -30 + lift * 0.4), Vector2(s * 16, -30 + lift * 0.4), gold, 1.0)
		c.draw_rect(Rect2(s * 14 - 2, -16 + lift * 0.6, 5, 3), gold)
	# long waxed-leather coat with flared skirts
	var sway := sin(t * 2.0) * 3.0
	var coatp := BA._sm([Vector2(-22, -134 + br), Vector2(22, -134 + br), Vector2(32, -96), Vector2(54 + sway, -14), Vector2(24, -6), Vector2(0, -22), Vector2(-24, -6), Vector2(-54 - sway, -14), Vector2(-32, -96)], true, 4)
	BA._shape(c, coatp, coat, f, coat_l)
	for k in 7:
		c.draw_line(Vector2(-22 + k * 7.5, -110), Vector2(-38 + k * 12.6 + (sway if k > 3 else -sway), -16), Color(0.05, 0.04, 0.08, 0.55), 1.2)
	c.draw_line(Vector2(0, -132 + br), Vector2(0, -22), gold, 1.2)
	for k in 6:
		c.draw_circle(Vector2(0, -122 + k * 16), 1.8, gold)
	c.draw_line(Vector2(-48, -18), Vector2(-24, -10), gold, 1.2)
	c.draw_line(Vector2(48, -18), Vector2(24, -10), gold, 1.2)
	# winged lion of St Mark embroidered on the breast
	var lp := Vector2(-11, -112 + br)
	c.draw_circle(lp, 8.0, OUT)
	c.draw_circle(lp, 7.0, Color("1a3a6a"))
	for s in [-1.0, 1.0]:
		BA._poly(c, [lp + Vector2(s * 1, -1), lp + Vector2(s * 8, -7), lp + Vector2(s * 6, 0), lp + Vector2(s * 7, 4)], gold, f, 0.6)
	c.draw_circle(lp + Vector2(0, 1), 2.4, gold)
	# bandolier of vials, belt of herb bundles, hourglass
	c.draw_line(Vector2(-20, -128 + br), Vector2(20, -74), OUT, 4.0)
	c.draw_line(Vector2(-20, -128 + br), Vector2(20, -74), wax, 2.4)
	for k in 5:
		var vp := Vector2(-16.0 + k * 8.0, -122.0 + k * 10.8 + br)
		c.draw_rect(Rect2(vp + Vector2(-1.6, 0), Vector2(3.2, 7)), OUT)
		c.draw_rect(Rect2(vp + Vector2(-0.9, 1), Vector2(1.8, 5)), Color(0.4 + 0.1 * k, 0.9 - 0.1 * k, 0.4 + 0.1 * (k % 2), 0.85))
	c.draw_rect(Rect2(-24, -72, 48, 6), OUT)
	c.draw_rect(Rect2(-23, -71, 46, 4), wax)
	c.draw_rect(Rect2(-3, -73, 6, 8), gold)
	for k in 5:
		var hp := Vector2(-20.0 + k * 9.0, -66)
		c.draw_line(hp, hp + Vector2(0, 10), Color("5a7a3a"), 2.0)
		c.draw_circle(hp + Vector2(0, 11), 1.6, Color("8a5aa0"))
	BA._poly(c, [Vector2(14, -64), Vector2(26, -64), Vector2(20, -54), Vector2(26, -44), Vector2(14, -44), Vector2(20, -54)], Color(0.9, 0.85, 0.6, 0.85), f, 0.8)
	c.draw_line(Vector2(13, -64), Vector2(27, -64), gold, 1.6)
	c.draw_line(Vector2(13, -44), Vector2(27, -44), gold, 1.6)
	# black shoulder cape with gold trim
	BA._poly(c, [Vector2(-28, -130 + br), Vector2(28, -130 + br), Vector2(38, -110), Vector2(0, -100), Vector2(-38, -110)], Color("1a1620"), f, 1.2)
	c.draw_line(Vector2(-36, -110), Vector2(0, -100), gold, 1.4)
	c.draw_line(Vector2(0, -100), Vector2(36, -110), gold, 1.4)
	# left arm with the long hooked cane and lantern
	var cane_a := Vector2(-48, -2)
	var cane_b := Vector2(-52, -158)
	c.draw_line(cane_a, cane_b, OUT, 5.0)
	c.draw_line(cane_a, cane_b, Color("3a2a20"), 3.0)
	BA._rivets(c, cane_a + Vector2(0, -10), cane_b + Vector2(0, 10), 8, gold)
	c.draw_arc(cane_b + Vector2(8, 0), 8.0, PI, TAU + 0.8, 10, OUT, 4.0)
	c.draw_arc(cane_b + Vector2(8, 0), 8.0, PI, TAU + 0.8, 10, gold, 2.4)
	var lan := cane_b + Vector2(15, 12)
	c.draw_rect(Rect2(lan + Vector2(-4, -5), Vector2(8, 11)), OUT)
	c.draw_rect(Rect2(lan + Vector2(-3, -4), Vector2(6, 9)), Color(miasma, 0.5 + 0.2 * sin(t * 6.0)))
	c.draw_circle(lan, 9.0, Color(miasma, 0.14))
	BA._poly(c, [Vector2(-20, -122 + br), Vector2(-34, -116), Vector2(-50, -98), Vector2(-46, -92), Vector2(-28, -106), Vector2(-16, -112)], coat_l, f, 1.2)
	c.draw_circle(Vector2(-48, -98), 5.0, Color("2a1a14"))
	for k in 3:
		c.draw_line(Vector2(-50 + k * 2, -96), Vector2(-52 + k * 2, -90), Color("1a1018"), 1.4)
	# right arm lifting a swinging censer of green fumes
	var ha := Vector2(46, -92 - lift_arm)
	BA._poly(c, [Vector2(20, -122 + br), Vector2(32, -118), ha + Vector2(4, -3), ha + Vector2(-2, 4), Vector2(26, -106), Vector2(14, -112)], coat_l, f, 1.2)
	c.draw_circle(ha, 5.0, Color("2a1a14"))
	for k in 3:
		c.draw_line(ha + Vector2(2 + k * 2, 2), ha + Vector2(5 + k * 2, 9), Color("1a1018"), 1.4)
	var cp := ha + Vector2(sin(t * 2.6) * 10.0 + 8.0, 28.0 + cos(t * 2.6) * 2.0)
	c.draw_line(ha + Vector2(2, 4), cp + Vector2(0, -7), Color("8a8070"), 1.2)
	BA._poly(c, [cp + Vector2(-8, -6), cp + Vector2(8, -6), cp + Vector2(7, 4), cp + Vector2(0, 9), cp + Vector2(-7, 4)], gold, f, 1.2)
	for k in 4:
		c.draw_line(cp + Vector2(-5 + k * 3.4, -5), cp + Vector2(-5 + k * 3.4, 3), Color("5a3a18"), 1.0)
	c.draw_circle(cp, 12.0, Color(miasma, 0.12))
	for k in 5:
		var u := fmod(t * 0.7 + k * 0.2, 1.0)
		c.draw_circle(cp + Vector2(sin(t * 2.0 + k * 2.0) * 7.0 * u, -8.0 - u * 50.0), 3.0 + u * 5.0, Color(miasma, 0.4 * (1.0 - u)))
	# deep hood and leather collar under the mask
	var hy := -152.0 + br
	BA._poly(c, [Vector2(-18, hy + 6), Vector2(-24, hy + 32), Vector2(24, hy + 32), Vector2(18, hy + 6)], Color("14101a"), f, 1.0)
	c.draw_line(Vector2(-22, hy + 28), Vector2(22, hy + 28), gold, 1.4)
	# the beaked mask: rounded cowl and a long, razor-sharp curved beak
	var mask := BA._sm([Vector2(-13, hy - 6), Vector2(11, hy - 6), Vector2(16, hy + 8), Vector2(10, hy + 22), Vector2(-8, hy + 22), Vector2(-15, hy + 10)], true, 4)
	BA._shape(c, mask, bone, f, Color.WHITE)
	var beak := PackedVector2Array([Vector2(6, hy + 2), Vector2(20, hy + 6), Vector2(36, hy + 14), Vector2(52, hy + 28), Vector2(70, hy + 52), Vector2(54, hy + 40), Vector2(36, hy + 34), Vector2(18, hy + 28), Vector2(4, hy + 22)])
	BA._shape(c, beak, bone, f, Color.WHITE, 1.6)
	# shading under the beak and a dark ridge along its top
	c.draw_colored_polygon(PackedVector2Array([Vector2(18, hy + 28), Vector2(36, hy + 34), Vector2(54, hy + 40), Vector2(70, hy + 52), Vector2(62, hy + 43), Vector2(44, hy + 33), Vector2(26, hy + 26)]), Color(bone_d, 0.85))
	c.draw_polyline(PackedVector2Array([Vector2(8, hy + 4), Vector2(22, hy + 8), Vector2(38, hy + 16), Vector2(54, hy + 30), Vector2(68, hy + 50)]), Color(0.5, 0.45, 0.36), 1.2)
	c.draw_polyline(PackedVector2Array([Vector2(8, hy + 20), Vector2(28, hy + 28), Vector2(48, hy + 36)]), Color(0.45, 0.4, 0.32, 0.8), 1.0)
	# stitched leather seam, rivets, nostril slits
	for k in 6:
		var sp := Vector2(12.0 + k * 9.0, hy + 14.0 + k * 5.0 + k * k * 0.4)
		c.draw_line(sp, sp + Vector2(3, -3), Color(0.35, 0.3, 0.25), 1.0)
	for k in 2:
		c.draw_circle(Vector2(22 + k * 8, hy + 18 + k * 5), 1.1, Color(0.3, 0.26, 0.22))
	c.draw_circle(Vector2(0, hy + 14), 1.4, gold)
	# tinted lenses
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 7.0, OUT)
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 5.6, gold)
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 4.2, Color(eye.r * 0.5, eye.g * 0.5, eye.b * 0.4).lerp(eye, 0.6 + 0.2 * sin(t * 3.0)))
		c.draw_circle(Vector2(s * 6 + 1, hy + 5), 1.1, Color(1, 1, 1, 0.8))
	# wide-brimmed hat with a raven feather
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 6), 40.0, 8.5), OUT)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 7), 38.0, 7.0), Color("1c1824"))
	c.draw_arc(Vector2(0, hy - 8), 36.0, 0.2, 2.9, 12, Color("3a3248"), 1.2)
	BA._poly(c, [Vector2(-17, hy - 7), Vector2(-13, hy - 28), Vector2(13, hy - 28), Vector2(17, hy - 7)], Color("1c1824"), f, 1.2)
	c.draw_rect(Rect2(-17, hy - 13, 34, 4), gold)
	var fe := PackedVector2Array([Vector2(8, hy - 26), Vector2(26, hy - 46), Vector2(40, hy - 54), Vector2(30, hy - 40), Vector2(14, hy - 24)])
	c.draw_colored_polygon(fe, Color("2a2438"))
	c.draw_polyline(fe, OUT, 1.2)
	# perched raven on the shoulder
	var rv := Vector2(-30, -134 + br)
	c.draw_colored_polygon(BA._ellipse(rv, 9.0, 6.0), OUT)
	c.draw_colored_polygon(BA._ellipse(rv, 7.6, 4.8), Color("2a2438"))
	c.draw_circle(rv + Vector2(-7, -5), 3.4, Color("2a2438"))
	BA._poly(c, [rv + Vector2(-9, -6), rv + Vector2(-16, -4), rv + Vector2(-9, -3)], gold, f, 0.6)
	c.draw_circle(rv + Vector2(-8, -6), 0.7, Color(1, 0.9, 0.4))
	for i in 3:
		var u := fmod(t * 0.5 + i * 0.33, 1.0)
		c.draw_circle(Vector2(-40 + i * 40, -20 - u * 130), 4.0 + u * 6.0, Color(miasma, 0.12 * (1.0 - u)))


# ====================================================================== Cacus of the Aventine

static func cacus(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var skin := Color("6a4a3c")
	var skin_l := Color("94705a")
	var skin_d := Color("3e2a22")
	var gold := Color("b89048")
	var fire := Color(1.0, 0.55, 0.15) if ph < 3 else Color(1.0, 0.3 + 0.2 * sin(t * 10.0), 0.1)
	var eye := Color(1.0, 0.7, 0.2) if exposed <= 0.0 else Color(1.0, 1.0, 0.7)
	var bone := Color("d8ceb8")
	var br := sin(t * 1.7) * 1.8
	var raise := 22.0 if winding else 0.0
	B2._shadow(c, 86.0)
	# smoke curling up from the cave behind
	for i in 6:
		var u := fmod(t * 0.35 + i * 0.17, 1.0)
		c.draw_circle(Vector2(-60 + i * 24 + sin(t + i) * 8.0, -60 - u * 120.0), 10.0 + u * 14.0, Color(0.2, 0.18, 0.2, 0.22 * (1.0 - u)))
	# powerful, properly proportioned legs: thigh, knee, shin, cloven hoof
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 2.6 + s) * 3.0 if moving else 0.0
		_limb(c, [Vector2(s * 20, -76), Vector2(s * 26, -42 + lift * 0.4), Vector2(s * 28, -8 + lift)], [38.0, 28.0, 20.0], skin, skin_l, f)
		c.draw_colored_polygon(BA._ellipse(Vector2(s * 26, -50 + lift * 0.4), 12.0, 10.0), BA._fl(skin_l, f))
		c.draw_arc(Vector2(s * 26, -50 + lift * 0.4), 12.0, 0.0, TAU, 10, OUT, 1.0)
		c.draw_rect(Rect2(s * 28 - 11, -26 + lift * 0.7, 22, 5), gold)
		BA._poly(c, [Vector2(s * 14, 2 + lift), Vector2(s * 44, 2 + lift), Vector2(s * 42, -6 + lift), Vector2(s * 20, -8 + lift)], Color("2a1c18"), f, 1.2)
		for k in 2:
			BA._poly(c, [Vector2(s * (36 + k * 6), -4 + lift), Vector2(s * (40 + k * 6), 6 + lift), Vector2(s * (32 + k * 6), 4 + lift)], Color("e8e0d0"), f, 0.6)
	# cattle-hide kilt with fur trim and a belt of skulls
	var kilt := PackedVector2Array([Vector2(-34, -74), Vector2(34, -74), Vector2(42, -42), Vector2(26, -34), Vector2(12, -42), Vector2(0, -32), Vector2(-12, -42), Vector2(-26, -34), Vector2(-42, -42)])
	BA._shape(c, kilt, Color("4a3228"), f, Color("7a5a42"))
	for k in 5:
		c.draw_line(Vector2(-28 + k * 14, -72), Vector2(-34 + k * 17, -38), Color(0.1, 0.06, 0.04, 0.5), 2.0)
	c.draw_rect(Rect2(-38, -80, 76, 8), OUT)
	c.draw_rect(Rect2(-37, -79, 74, 6), Color("2a1c18"))
	for k in 5:
		B2._skull(c, Vector2(-28.0 + k * 14.0, -76), 4.4, bone)
	# torso: broad V-shaped back and chest tapering to a hard waist
	var torso := BA._sm([Vector2(-34, -78), Vector2(34, -78), Vector2(48, -112 + br), Vector2(60, -146 + br), Vector2(30, -158 + br), Vector2(-30, -158 + br), Vector2(-60, -146 + br), Vector2(-48, -112 + br)], true, 5)
	BA._shape(c, torso, skin, f, skin_l)
	# pectoral plates, abdominal blocks, serratus
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 3, -146 + br), Vector2(s * 40, -148 + br), Vector2(s * 46, -126 + br), Vector2(s * 26, -114 + br), Vector2(s * 3, -118 + br)], skin_l, f, 1.4)
		c.draw_line(Vector2(s * 8, -124 + br), Vector2(s * 38, -128 + br), skin_d, 1.4)
		for k in 3:
			c.draw_line(Vector2(s * (30 + k * 3), -110 + br + k * 6), Vector2(s * (40 + k * 2), -108 + br + k * 6), skin_d, 1.4)
		for k in 3:
			BA._poly(c, [Vector2(s * 4, -108 + k * 10 + br * 0.4), Vector2(s * 22, -108 + k * 10 + br * 0.4), Vector2(s * 22, -100 + k * 10), Vector2(s * 4, -100 + k * 10)], skin_l, f, 1.0)
	c.draw_line(Vector2(0, -150 + br), Vector2(0, -80), skin_d, 2.0)
	var cr := [[Vector2(-34, -150), Vector2(-26, -136), Vector2(-34, -122), Vector2(-24, -108)], [Vector2(28, -148), Vector2(34, -132), Vector2(26, -118), Vector2(32, -100)], [Vector2(2, -96), Vector2(-4, -86), Vector2(4, -80)]]
	for pts in cr:
		c.draw_polyline(PackedVector2Array(pts), Color(fire, 0.4 + 0.3 * sin(t * 4.0)), 3.0)
		c.draw_polyline(PackedVector2Array(pts), Color(1.0, 0.9, 0.5, 0.9), 1.0)
	# necklace of skulls
	for k in 7:
		var u := k / 6.0
		B2._skull(c, Vector2(-30 + u * 60, -156 + br + sin(u * PI) * 20.0), 3.6, bone)
	# massive arms: shoulder cap, bicep, elbow, forearm, fist
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 56, -144 + br)
		var hand := Vector2(s * (70 - raise * 0.9), -62 - raise * 5.2 + sin(t * 2.0 + s) * 2.0)
		var elbow := Vector2(s * (84 - raise * 0.4), -102 - raise * 2.4)
		_limb(c, [sh, elbow, hand], [34.0, 28.0, 24.0], skin, skin_l, f)
		var mid := sh.lerp(elbow, 0.5)
		c.draw_colored_polygon(BA._ellipse(mid + Vector2(-s * 3, 0), 12.0, 14.0), BA._fl(skin_l, f))
		c.draw_arc(mid + Vector2(-s * 3, 0), 12.0, 0.0, TAU, 10, Color(OUT, 0.6), 1.0)
		var fm := elbow.lerp(hand, 0.45)
		c.draw_colored_polygon(BA._ellipse(fm, 11.0, 13.0), BA._fl(skin, f))
		c.draw_circle(sh, 18.0, OUT)
		c.draw_circle(sh, 16.5, BA._fl(skin_l, f))
		c.draw_arc(sh, 16.5, 3.4, 5.6, 10, skin_d, 1.4)
		c.draw_rect(Rect2(elbow.lerp(hand, 0.55) + Vector2(-12, -3), Vector2(24, 7)), gold)
		c.draw_rect(Rect2(elbow.lerp(hand, 0.55) + Vector2(-12, -3), Vector2(24, 2)), Color("e0c070"))
		c.draw_circle(hand, 14.0, OUT)
		c.draw_circle(hand, 12.6, BA._fl(skin_d, f))
		for k in 4:
			c.draw_line(hand + Vector2(-8 + k * 5, 3), hand + Vector2(-8 + k * 5, 10), OUT, 1.6)
			c.draw_circle(hand + Vector2(-7 + k * 4.6, 2), 1.6, BA._fl(skin_l, f))
	# bull-horn pauldrons: trophies of the stolen cattle
	for s in [-1.0, 1.0]:
		var pc := Vector2(s * 62, -154 + br)
		BA._poly(c, [pc + Vector2(-s * 8, -6), pc + Vector2(s * 12, -10), pc + Vector2(s * 18, 8), pc + Vector2(-s * 4, 12)], Color("3a2a22"), f, 1.4)
		var horn: Array = [pc + Vector2(s * 8, -8), pc + Vector2(s * 24, -14), pc + Vector2(s * 31, -30), pc + Vector2(s * 31, -46)]
		_limb(c, horn, [10.0, 8.0, 5.0, 1.5], Color("e0d4b8"), Color("fff4d8"), f)
		c.draw_rect(Rect2(pc + Vector2(-2, -2), Vector2(4, 4)), gold)
	if winding:
		var bp := Vector2(0, -62 - raise * 5.2 - 22.0)
		var rock := BA._sm([bp + Vector2(-28, 6), bp + Vector2(-22, -16), bp + Vector2(-2, -24), bp + Vector2(22, -16), bp + Vector2(30, 4), bp + Vector2(10, 16), bp + Vector2(-12, 16)], true, 3)
		BA._shape(c, rock, Color("6a625e"), f, Color("a8a098"))
		c.draw_line(bp + Vector2(-8, -12), bp + Vector2(2, 0), Color("2a2624"), 1.4)
		c.draw_line(bp + Vector2(2, 0), bp + Vector2(-4, 10), Color("2a2624"), 1.4)
		c.draw_circle(bp + Vector2(12, -6), 2.0, Color(fire, 0.7))
	_cacus_head(c, t, f, -180.0 + br, winding, skin, skin_l, skin_d, bone, fire, eye)
	# embers rising around the body
	for i in 5:
		var u := fmod(t * 0.5 + i * 0.2, 1.0)
		c.draw_rect(Rect2(-50 + i * 24, -u * 160, 2, 2), Color(fire, 0.9 * (1.0 - u)))


# A brutish, low-slung head sunk between hunched shoulders, with great bull horns and a snarling furnace maw.
static func _cacus_head(c: CanvasItem, t: float, f: float, hy: float, winding: bool, skin: Color, skin_l: Color, skin_d: Color, bone: Color, fire: Color, eye: Color) -> void:
	var mo := 6.0 + (12.0 if winding else 0.0) + sin(t * 3.0) * 1.2
	# charred mane swept back behind the skull
	for k in 9:
		var x := -30.0 + k * 7.5
		BA._poly(c, [Vector2(x - 5, hy - 10), Vector2(x - 8 + sin(t * 2.0 + k) * 2.0, hy - 38 - (k % 3) * 7), Vector2(x + 5, hy - 12)], Color("1c1210"), f, 0.8)
	# bull horns sweeping out from the temples
	for s in [-1.0, 1.0]:
		var horn: Array = [Vector2(s * 24, hy - 6), Vector2(s * 44, hy - 12), Vector2(s * 56, hy - 32), Vector2(s * 50, hy - 56)]
		_limb(c, horn, [15.0, 12.0, 8.0, 1.5], bone, Color("fff4d8"), f)
		c.draw_line(Vector2(s * 30, hy - 8), Vector2(s * 50, hy - 24), Color("a89870"), 1.0)
		c.draw_rect(Rect2(Vector2(s * 26 - 4, hy - 12), Vector2(8, 5)), Color("b89048"))
	# thick neck and trapezius hump
	BA._poly(c, [Vector2(-52, hy + 44), Vector2(-34, hy + 18), Vector2(-18, hy + 8), Vector2(18, hy + 8), Vector2(34, hy + 18), Vector2(52, hy + 44)], skin, f, 1.4)
	# skull: heavy, flat-topped, wide across the cheekbones
	var head := BA._sm([Vector2(-30, hy - 4), Vector2(-24, hy - 20), Vector2(0, hy - 25), Vector2(24, hy - 20), Vector2(30, hy - 4), Vector2(28, hy + 14), Vector2(19, hy + 30), Vector2(0, hy + 34), Vector2(-19, hy + 30), Vector2(-28, hy + 14)], true, 5)
	BA._shape(c, head, skin, f, skin_l)
	# lava-scarred cracks
	c.draw_polyline(PackedVector2Array([Vector2(-22, hy - 16), Vector2(-16, hy - 6), Vector2(-24, hy + 4)]), Color(fire, 0.8), 1.4)
	c.draw_polyline(PackedVector2Array([Vector2(20, hy - 14), Vector2(14, hy - 2), Vector2(22, hy + 12)]), Color(fire, 0.8), 1.4)
	c.draw_line(Vector2(10, hy + 2), Vector2(24, hy + 22), skin_d, 1.6)
	# crushing brow ridge angled into a scowl
	BA._poly(c, [Vector2(-32, hy - 10), Vector2(-4, hy + 2), Vector2(4, hy + 2), Vector2(32, hy - 10), Vector2(30, hy + 4), Vector2(4, hy + 8), Vector2(-4, hy + 8), Vector2(-30, hy + 4)], skin_d, f, 1.4)
	# burning eyes sunk in shadow
	for s in [-1.0, 1.0]:
		var ec := Vector2(s * 13, hy + 10)
		c.draw_circle(ec, 9.0, Color(eye, 0.2 + 0.05 * sin(t * 5.0)))
		c.draw_rect(Rect2(ec + Vector2(-6, -2.4), Vector2(12, 5)), OUT)
		c.draw_rect(Rect2(ec + Vector2(-4.6, -1.4), Vector2(9.2, 3)), eye)
		c.draw_rect(Rect2(ec + Vector2(-1.2, -1.4), Vector2(2.4, 3)), OUT)
		c.draw_line(ec + Vector2(-s * 7, -5), ec + Vector2(s * 7, -1), OUT, 2.2)
	c.draw_line(Vector2(-3, hy + 12), Vector2(3, hy + 12), skin_d, 1.2)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 4, hy + 17), 1.6, OUT)
	# jutting underbite jaw and gaping furnace mouth
	var jaw := PackedVector2Array([Vector2(-24, hy + 18), Vector2(24, hy + 18), Vector2(28, hy + 32 + mo * 0.5), Vector2(15, hy + 42 + mo), Vector2(-15, hy + 42 + mo), Vector2(-28, hy + 32 + mo * 0.5)])
	BA._shape(c, jaw, skin_d, f, skin)
	c.draw_rect(Rect2(-17, hy + 20, 34, 3 + mo), Color("2a0a08"))
	c.draw_rect(Rect2(-14, hy + 22, 28, 1 + mo * 0.8), Color(fire, 0.85))
	for k in 6:
		BA._poly(c, [Vector2(-17 + k * 6, hy + 20), Vector2(-14 + k * 6, hy + 27), Vector2(-11 + k * 6, hy + 20)], bone, f, 0.6)
	for k in 5:
		BA._poly(c, [Vector2(-14 + k * 6, hy + 24 + mo), Vector2(-11 + k * 6, hy + 18 + mo), Vector2(-8 + k * 6, hy + 24 + mo)], Color("c8bea8"), f, 0.6)
	# great lower tusks
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 16, hy + 26 + mo), Vector2(s * 22, hy + 22 + mo), Vector2(s * 26, hy + 4), Vector2(s * 20, hy + 20 + mo)], bone, f, 1.0)
	for k in 3:
		B2._flame(c, Vector2(-6 + k * 6, hy + 26 + mo * 0.5), 10.0 + mo * 0.7, t + k, fire, 3.0)
	# short singed beard with ember sparks
	for k in 7:
		var bx := -15.0 + k * 5.0
		BA._poly(c, [Vector2(bx - 3, hy + 38 + mo), Vector2(bx + sin(t * 2.0 + k) * 1.5, hy + 50 + mo + (k % 3) * 3), Vector2(bx + 3, hy + 38 + mo)], Color("2a1c18"), f, 0.8)
	for k in 6:
		var u := fmod(t * 0.9 + k * 0.17, 1.0)
		c.draw_rect(Rect2(-14 + k * 5, hy + 30 - u * 44, 2, 2), Color(fire, 1.0 - u))


# ====================================================================== Strigoi of Poenari

static func strigoi(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var cloak := Color("45182a")
	var cloak_l := Color("7a2a44")
	var lining := Color("a82438")
	var skin := Color("d4ccd8")
	var skin_d := Color("8a7c92")
	var gold := Color("d0a858")
	var armor := Color("2a2230")
	var eye := Color(1.0, 0.25, 0.25) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var br := sin(t * 1.6) * 1.5
	var rear := 10.0 if winding else 0.0
	B2._shadow(c, 74.0)
	# blood mist pooling on the ground
	for i in 5:
		var u := fmod(t * 0.3 + i * 0.2, 1.0)
		c.draw_circle(Vector2(-60 + i * 30, -4 - u * 12), 10.0 + u * 8.0, Color(0.6, 0.05, 0.1, 0.16 * (1.0 - u)))
	# the forest of the impaled: stakes crowned with skulls and torn banners
	for i in 7:
		var x := -90.0 + i * 30.0
		var h := 130.0 + (i % 3) * 20.0
		var lean := (i - 3) * 1.6
		c.draw_line(Vector2(x, 0), Vector2(x + lean, -h), OUT, 5.0)
		c.draw_line(Vector2(x, 0), Vector2(x + lean, -h), Color("5a4030"), 3.0)
		BA._poly(c, [Vector2(x - 3 + lean, -h), Vector2(x + lean, -h - 14), Vector2(x + 3 + lean, -h)], Color("7a5a40"), f, 1.0)
		if i % 2 == 0:
			B2._skull(c, Vector2(x + lean, -h + 10.0), 4.6, Color("d8d0c0"))
		else:
			BA._poly(c, [Vector2(x + lean, -h + 6), Vector2(x + lean + 14 + sin(t * 2.0 + i) * 3.0, -h + 10), Vector2(x + lean, -h + 24)], Color(lining, 0.85), f, 0.8)
	# armoured greaves and long pointed sabatons
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		_limb(c, [Vector2(s * 10, -76), Vector2(s * 14, -44), Vector2(s * 13, -10 + lift)], [18.0, 14.0, 11.0], armor, Color("5a4a68"), f)
		c.draw_circle(Vector2(s * 14, -44), 8.0, OUT)
		c.draw_circle(Vector2(s * 14, -44), 6.6, BA._fl(Color("4a3e58"), f))
		BA._poly(c, [Vector2(s * 4, -10 + lift), Vector2(s * 22, -10 + lift), Vector2(s * 40, 0 + lift), Vector2(s * 20, 4 + lift), Vector2(s * 4, 4 + lift)], armor, f, 1.2)
		c.draw_line(Vector2(s * 8, -22 + lift * 0.5), Vector2(s * 18, -22 + lift * 0.5), gold, 1.4)
	# vast bat-wing cloak with ribbed membranes
	for s in [-1.0, 1.0]:
		var tip := Vector2(s * 104, -176 - rear)
		var wing := PackedVector2Array([Vector2(s * 16, -138 + br), Vector2(s * 56, -178 - rear), tip, Vector2(s * 92, -140 - rear * 0.5), Vector2(s * 98, -100), Vector2(s * 76, -108), Vector2(s * 78, -66), Vector2(s * 56, -84), Vector2(s * 50, -40), Vector2(s * 30, -76), Vector2(s * 22, -56)])
		BA._shape(c, wing, cloak, f, cloak_l)
		for k in 5:
			var e := Vector2(s * (92 - k * 12), -134 + k * 20)
			c.draw_line(Vector2(s * 20, -136 + br), e, Color(lining, 0.9), 1.6)
			c.draw_line(Vector2(s * 20, -136 + br), e, Color(OUT, 0.35), 0.6)
		c.draw_polyline(PackedVector2Array([Vector2(s * 56, -178 - rear), tip, Vector2(s * 92, -140 - rear * 0.5)]), gold, 1.8)
	# armoured, gaunt torso: breastplate with a chiselled crest
	var torso := BA._sm([Vector2(-24, -66), Vector2(24, -66), Vector2(30, -102), Vector2(28, -134 + br), Vector2(-28, -134 + br), Vector2(-30, -102)], true, 4)
	BA._shape(c, torso, armor, f, Color("5a4a68"))
	for k in 5:
		c.draw_arc(Vector2(0, -124 + k * 9 + br * 0.3), 15.0 - k, 0.15, PI - 0.15, 8, Color(0.8, 0.74, 0.8, 0.6), 1.3)
	c.draw_line(Vector2(0, -132), Vector2(0, -74), gold, 1.4)
	BA._poly(c, [Vector2(-10, -128 + br), Vector2(10, -128 + br), Vector2(6, -112 + br), Vector2(0, -104 + br), Vector2(-6, -112 + br)], Color("3a2c44"), f, 1.2)
	c.draw_circle(Vector2(-14, -96 + br), 7.0, Color(eye, 0.25 + 0.1 * sin(t * 4.0)))
	c.draw_circle(Vector2(-14, -96 + br), 3.2, OUT)
	c.draw_line(Vector2(-14, -104 + br), Vector2(-14, -88 + br), Color(eye, 0.9), 1.2)
	# Order of the Dragon medallion
	c.draw_circle(Vector2(12, -100 + br), 8.0, OUT)
	c.draw_circle(Vector2(12, -100 + br), 6.8, gold)
	c.draw_arc(Vector2(12, -100 + br), 4.4, 0.5, TAU - 0.5, 12, Color("5a3a18"), 1.4)
	c.draw_circle(Vector2(12, -100 + br), 1.4, Color("5a3a18"))
	# belt with hanging chains and a rosary of teeth
	c.draw_rect(Rect2(-26, -72, 52, 7), OUT)
	c.draw_rect(Rect2(-25, -71, 50, 5), Color("3a2a30"))
	for i in 6:
		c.draw_circle(Vector2(-20.0 + i * 8.0, -68.5), 1.3, gold)
	BA._chain(c, Vector2(-18, -66), Vector2(-6, -48), 7.0, 6, gold)
	BA._chain(c, Vector2(18, -66), Vector2(10, -46), 6.0, 5, gold)
	# spiked pauldrons and the high collar
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 20, -134 + br), Vector2(s * 44, -140 + br), Vector2(s * 50, -118), Vector2(s * 26, -114)], Color("3a2c44"), f, 1.4)
		BA._poly(c, [Vector2(s * 38, -138 + br), Vector2(s * 54, -158 + br - rear * 0.4), Vector2(s * 46, -128)], Color("8a8898"), f, 1.0)
		BA._poly(c, [Vector2(s * 8, -130 + br), Vector2(s * 30, -172 + br - rear * 0.4), Vector2(s * 24, -126 + br)], lining, f, 1.2)
		c.draw_line(Vector2(s * 12, -132 + br), Vector2(s * 29, -166 + br - rear * 0.4), cloak_l, 1.2)
	# arms ending in long talons
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 36, -126 + br)
		var el := Vector2(s * (56 + rear), -100 - rear * 1.5)
		var hand := Vector2(s * (50 + rear * 2.0), -70 - rear * 3.0 + sin(t * 2.0 + s) * 3.0)
		_limb(c, [sh, el, hand], [14.0, 12.0, 9.0], Color("2e2234"), Color("5a4a68"), f)
		c.draw_rect(Rect2(el.lerp(hand, 0.5) + Vector2(-6, -3), Vector2(12, 5)), gold)
		c.draw_circle(hand, 6.0, OUT)
		c.draw_circle(hand, 5.0, BA._fl(skin_d, f))
		for k in 4:
			var cl := hand + Vector2(s * (-4.0 + k * 4.0), 6.0)
			c.draw_line(cl, cl + Vector2(s * (1 + k * 0.8), 14.0 + k), OUT, 3.0)
			c.draw_line(cl, cl + Vector2(s * (1 + k * 0.8), 14.0 + k), Color("e8e0e8"), 1.4)
	# head: gaunt pale face, swept black hair, long fangs, iron crown of stakes
	var hy := -152.0 + br - rear * 0.5
	BA._poly(c, [Vector2(-16, hy - 4), Vector2(-24, hy + 32), Vector2(-10, hy + 44), Vector2(0, hy + 24), Vector2(10, hy + 44), Vector2(24, hy + 32), Vector2(16, hy - 4)], Color("0e0810"), f, 1.0)
	var face := BA._sm([Vector2(-12, hy - 8), Vector2(12, hy - 8), Vector2(13, hy + 8), Vector2(7, hy + 21), Vector2(-7, hy + 21), Vector2(-13, hy + 8)], true, 4)
	BA._shape(c, face, skin, f, Color(1, 1, 1))
	c.draw_line(Vector2(-10, hy + 6), Vector2(-5, hy + 16), skin_d, 1.2)
	c.draw_line(Vector2(10, hy + 6), Vector2(5, hy + 16), skin_d, 1.2)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 6.5, hy + 3), 6.0, Color(eye, 0.22))
		BA._poly(c, [Vector2(s * 2, hy), Vector2(s * 11, hy - 3), Vector2(s * 10, hy + 5), Vector2(s * 2, hy + 4)], OUT, f, 0.6)
		c.draw_circle(Vector2(s * 6.5, hy + 2.4), 2.2, eye)
		c.draw_line(Vector2(s * 2, hy - 2), Vector2(s * 12, hy - 5), OUT, 1.6)
	c.draw_line(Vector2(0, hy + 5), Vector2(1, hy + 11), skin_d, 1.0)
	c.draw_rect(Rect2(-6, hy + 14, 12, 3), Color("5a1020"))
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 4 - 1.2, hy + 14), Vector2(s * 4 + 1.2, hy + 14), Vector2(s * 4, hy + 24)], Color.WHITE, f, 0.6)
	c.draw_line(Vector2(0, hy + 17), Vector2(0, hy + 24 + sin(t * 4.0) * 1.0), Color(0.7, 0.05, 0.1, 0.9), 1.0)
	for k in 5:
		var cx := -12.0 + k * 6.0
		var ch := 14.0 + (3 - absf(k - 2)) * 5.0
		BA._poly(c, [Vector2(cx - 2.6, hy - 8), Vector2(cx, hy - 8 - ch), Vector2(cx + 2.6, hy - 8)], Color("7a7686"), f, 1.0)
		c.draw_circle(Vector2(cx, hy - 8 - ch), 1.2, Color(eye, 0.9))
	c.draw_line(Vector2(-14, hy - 8), Vector2(14, hy - 8), gold, 2.4)
	# bats wheeling about him
	for i in 5:
		var a := t * (1.1 + i * 0.12) + i * 1.7
		B2._bat(c, Vector2(cos(a) * (70.0 + i * 8.0), -110.0 + sin(a * 1.3) * 36.0 - i * 10.0), t + i, Color("1c0c14"), 1.2)
	if ph >= 3:
		for k in 5:
			var u := fmod(t * 0.8 + k * 0.2, 1.0)
			c.draw_rect(Rect2(-10 + k * 5, -90 + u * 80, 2, 3), Color(0.7, 0.05, 0.1, 0.8 * (1.0 - u)))


# ====================================================================== Ankou of the Ossuary

static func ankou(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var bone := Color("dcd6c4")
	var bone_d := Color("9a9482")
	var cloak := Color("2c3240")
	var cloak_l := Color("52607a")
	var gold := Color("b8a868")
	var eye := Color(0.4, 1.0, 0.9) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var br := sin(t * 1.4) * 1.5
	B2._shadow(c, 80.0)
	# the death-cart: wheel, planks and a heap of skulls
	var wc := Vector2(-62, -58)
	c.draw_circle(wc, 46.0, OUT)
	c.draw_circle(wc, 43.0, Color("5a4430"))
	c.draw_circle(wc, 35.0, Color("1a1218"))
	for k in 12:
		var a := TAU * k / 12.0 + t * 0.05
		c.draw_line(wc, wc + Vector2.from_angle(a) * 38.0, Color("7a5c40"), 2.6)
	c.draw_arc(wc, 43.0, 0, TAU, 32, Color("8a6c50"), 1.6)
	for k in 12:
		var a := TAU * k / 12.0
		c.draw_circle(wc + Vector2.from_angle(a) * 41.0, 1.6, gold)
	c.draw_circle(wc, 7.0, gold)
	c.draw_rect(Rect2(-130, -30, 70, 10), OUT)
	c.draw_rect(Rect2(-129, -29, 68, 8), Color("5a4430"))
	for i in 7:
		B2._skull(c, Vector2(-124.0 + i * 11.0, -36.0 - (i % 2) * 6), 5.2, Color("c8c2b0"))
	for i in 5:
		c.draw_line(Vector2(-110 + i * 14, -26), Vector2(-98 + i * 14, -44), bone, 2.2)
	# skeletal legs: femur, knee, tibia, foot bones
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		_limb(c, [Vector2(s * 10, -74), Vector2(s * 14, -38), Vector2(s * 11, -6 + lift)], [10.0, 8.0, 6.0], bone, Color.WHITE, f)
		c.draw_circle(Vector2(s * 14, -38), 6.0, OUT)
		c.draw_circle(Vector2(s * 14, -38), 5.0, BA._fl(bone, f))
		for k in 3:
			c.draw_line(Vector2(s * (4 + k * 5), -6 + lift), Vector2(s * (8 + k * 6), 2 + lift), bone, 2.2)
	# ragged shroud with a tattered hem
	var hem: Array = []
	for i in 9:
		hem.append(Vector2(-48.0 + i * 12.0, -8.0 + (i % 2) * 11.0 + sin(t * 2.0 + i) * 2.0))
	var body: Array = [Vector2(-24, -140 + br), Vector2(24, -140 + br), Vector2(38, -100), Vector2(52, -40)]
	hem.reverse()
	body.append_array(hem)
	body.append(Vector2(-52, -40))
	body.append(Vector2(-38, -100))
	var bp := PackedVector2Array(body)
	BA._shape(c, bp, cloak, f, cloak_l)
	for k in 6:
		c.draw_line(Vector2(-32 + k * 13, -100), Vector2(-42 + k * 17, -14), Color(0.06, 0.07, 0.1, 0.5), 1.4)
	for k in 4:
		c.draw_line(Vector2(-40 + k * 26, -60), Vector2(-34 + k * 26, -30), Color(cloak_l, 0.6), 1.0)
	# ribcage and spine glimpsed through a rent in the shroud
	c.draw_rect(Rect2(-14, -122 + br, 28, 40), Color(0.03, 0.04, 0.06))
	for k in 6:
		c.draw_arc(Vector2(0, -118 + k * 6.6 + br * 0.4), 12.5 - k * 0.7, 0.15, PI - 0.15, 8, bone, 1.6)
	for k in 7:
		c.draw_circle(Vector2(0, -120 + k * 5.6 + br * 0.4), 1.5, bone_d)
	c.draw_circle(Vector2(0, -96 + br), 5.0, Color(eye, 0.18 + 0.1 * sin(t * 3.0)))
	# soul-lantern and hourglass at the waist
	var lp := Vector2(30 + sin(t * 2.0) * 3.0, -62.0 + sin(t * 2.6) * 2.0)
	c.draw_line(Vector2(22, -82), lp + Vector2(0, -6), Color("4a3828"), 1.2)
	BA._poly(c, [lp + Vector2(-5, -5), lp + Vector2(5, -5), lp + Vector2(6, 6), lp + Vector2(-6, 6)], Color("2a2420"), f, 1.0)
	c.draw_circle(lp, 11.0, Color(eye, 0.22))
	BA._arch(c, lp.x, lp.y + 4, 3.2, 8.0, Color(eye, 0.95), Color("2a2420"))
	var hg := Vector2(-24, -74)
	BA._poly(c, [hg + Vector2(-5, -8), hg + Vector2(5, -8), hg + Vector2(0, 0)], Color("a8a090"), f, 1.0)
	BA._poly(c, [hg + Vector2(0, 0), hg + Vector2(5, 8), hg + Vector2(-5, 8)], Color("a8a090"), f, 1.0)
	c.draw_rect(Rect2(hg + Vector2(-1, 2), Vector2(2, 5)), Color(eye, 0.8))
	# tattered cape over bony shoulders
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 12, -140 + br), Vector2(s * 46, -132), Vector2(s * 50, -108), Vector2(s * 22, -118)], cloak_l, f, 1.2)
		for k in 3:
			BA._poly(c, [Vector2(s * (26 + k * 8), -112 + k * 2), Vector2(s * (30 + k * 8), -100 + k * 2), Vector2(s * (34 + k * 8), -112 + k * 2)], cloak_l, f, 0.8)
	var swing := 0.0
	if winding:
		swing = sin(t * 10.0) * 0.1
	# the scythe: ornate staff and a great out-turned blade
	var sa := Vector2(66, -34)
	var sb := Vector2(50, -184)
	c.draw_line(sa, sb, OUT, 7.0)
	c.draw_line(sa, sb, Color("5a4228"), 4.4)
	BA._rivets(c, sa.lerp(sb, 0.1), sa.lerp(sb, 0.9), 7, gold)
	var blade := PackedVector2Array()
	for i in 14:
		var u := i / 13.0
		blade.append(sb + Vector2(u * -88.0 * cos(swing), -sin(u * PI) * 24.0 + u * 16.0))
	for i in 14:
		var u := 1.0 - i / 13.0
		blade.append(sb + Vector2(u * -88.0 * cos(swing), -sin(u * PI) * 13.0 + u * 16.0 + 4.0))
	c.draw_colored_polygon(blade, BA._fl(Color("b4bec8"), f))
	c.draw_polyline(blade, OUT, 1.6)
	c.draw_line(sb + Vector2(-4, -2), sb + Vector2(-80, 14), Color(1, 1, 1, 0.75), 1.2)
	for k in 6:
		c.draw_circle(sb + Vector2(-12 - k * 12, 7 + k * 1.5), 1.0, Color(eye, 0.85))
	c.draw_circle(sb + Vector2(-86, 16), 6.0, Color(eye, 0.2))
	for k in 2:
		var hp := sa.lerp(sb, 0.3 + k * 0.28)
		c.draw_circle(hp, 5.2, OUT)
		c.draw_circle(hp, 4.0, bone)
		for j in 4:
			c.draw_line(hp + Vector2(-3, -3 + j * 2), hp + Vector2(-7, -4 + j * 2.6), bone, 1.2)
	_limb(c, [Vector2(32, -128 + br), Vector2(48, -96), sa.lerp(sb, 0.3)], [9.0, 7.0, 6.0], bone, Color.WHITE, f)
	# skull under a wide-brimmed hat and hood
	var hy := -154.0 + br
	BA._poly(c, [Vector2(-20, hy - 2), Vector2(-26, hy + 24), Vector2(26, hy + 24), Vector2(20, hy - 2)], Color("14161c"), f, 1.0)
	var sk := BA._sm([Vector2(-13, hy), Vector2(13, hy), Vector2(15, hy + 12), Vector2(9, hy + 23), Vector2(-9, hy + 23), Vector2(-15, hy + 12)], true, 4)
	BA._shape(c, sk, bone, f, Color.WHITE)
	c.draw_line(Vector2(-9, hy + 2), Vector2(-4, hy + 8), bone_d, 1.0)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 6.4, hy + 8), 8.0, Color(eye, 0.2))
		c.draw_circle(Vector2(s * 6.4, hy + 8), 5.0, OUT)
		c.draw_circle(Vector2(s * 6.4, hy + 8), 2.4, eye)
	BA._poly(c, [Vector2(0, hy + 12), Vector2(-2.4, hy + 17), Vector2(2.4, hy + 17)], OUT, f, 0.6)
	for k in 7:
		c.draw_line(Vector2(-7 + k * 2.3, hy + 19), Vector2(-7 + k * 2.3, hy + 23), OUT, 1.2)
	c.draw_line(Vector2(-9, hy + 19.4), Vector2(9, hy + 19.4), OUT, 1.0)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 2), 40.0, 7.5), OUT)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 3), 38.0, 6.0), Color("2a2630"))
	c.draw_arc(Vector2(0, hy - 4), 35.0, 0.2, 2.9, 12, Color("464058"), 1.2)
	BA._poly(c, [Vector2(-15, hy - 3), Vector2(-12, hy - 24), Vector2(12, hy - 24), Vector2(15, hy - 3)], Color("2a2630"), f, 1.2)
	c.draw_rect(Rect2(-15, hy - 9, 30, 3.4), gold)
	c.draw_circle(Vector2(0, hy - 7), 2.4, Color("d8d0a8"))
	# drifting soul wisps
	for i in 6:
		var u := fmod(t * 0.4 + i * 0.17, 1.0)
		c.draw_circle(Vector2(-70 + i * 30 + sin(t + i) * 6.0, -30 - u * 130.0), 2.6 - u, Color(eye, 0.7 * (1.0 - u)))
