extends RefCounted
## Ornate gothic bodies for the later bosses, drawn in world-pixel units (origin at the feet), using the shared helpers of boss_art.gd.
## Strigoi of Poenari (Wallachia), Ankou of the Ossuary (Brittany/Paris), Barghest of Whitby (Yorkshire),
## Il Medico della Peste (Venice, 1630 plague) and Cacus of the Aventine (Rome).

const BA = preload("res://src/entities/boss_art.gd")
const OUT := Color("0e0a14")


static func draw(kind: String, c: CanvasItem, t: float, ph: int, flash: float, winding: bool, exposed: float, moving: bool) -> void:
	match kind:
		"strigoi_giant":
			strigoi(c, t, ph, flash, winding, exposed, moving)
		"ankou_giant":
			ankou(c, t, ph, flash, winding, exposed, moving)
		"barghest_giant":
			barghest(c, t, ph, flash, winding, exposed, moving)
		"plague_giant":
			plague(c, t, ph, flash, winding, exposed, moving)
		"cacus_giant":
			cacus(c, t, ph, flash, winding, exposed, moving)


static func _shadow(c: CanvasItem, rx: float) -> void:
	for i in 3:
		c.draw_colored_polygon(BA._ellipse(Vector2(0, 3), rx - i * 8.0, 15.0 - i * 2.0), Color(0, 0, 0, 0.16))


static func _bat(c: CanvasItem, p: Vector2, t: float, col: Color, s := 1.0) -> void:
	var fl := sin(t * 14.0) * 3.0 * s
	for sg in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(sg * 6 * s, -3 * s - fl), p + Vector2(sg * 11 * s, 1 * s - fl), p + Vector2(sg * 8 * s, 2 * s), p + Vector2(sg * 5 * s, 4 * s)]), col)
	c.draw_circle(p, 1.8 * s, col.lightened(0.15))
	c.draw_circle(p + Vector2(-0.6, -0.4), 0.5, Color(1, 0.3, 0.3))


static func _skull(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	c.draw_circle(p, r + 1.0, OUT)
	c.draw_circle(p, r, col)
	c.draw_rect(Rect2(p + Vector2(-r * 0.5, r * 0.4), Vector2(r, r * 0.8)), col)
	c.draw_circle(p + Vector2(-r * 0.36, 0), r * 0.28, OUT)
	c.draw_circle(p + Vector2(r * 0.36, 0), r * 0.28, OUT)
	c.draw_line(p + Vector2(-r * 0.2, r * 0.9), p + Vector2(-r * 0.2, r * 1.3), OUT, 0.8)
	c.draw_line(p + Vector2(r * 0.2, r * 0.9), p + Vector2(r * 0.2, r * 1.3), OUT, 0.8)


static func _flame(c: CanvasItem, base: Vector2, h: float, t: float, col: Color, w := 4.0) -> void:
	var sway := sin(t * 9.0 + base.x) * w * 0.5
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.5 + sway * 0.4, -h * 0.55), base + Vector2(sway, -h), base + Vector2(w * 0.5 + sway * 0.4, -h * 0.5), base + Vector2(w, 0)]), Color(col, 0.75))
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(sway * 0.5, -h * 0.65), base + Vector2(w * 0.5, 0)]), col.lightened(0.5))


# ====================================================================== Strigoi of Poenari

static func strigoi(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var cloak := Color("3a1420")
	var cloak_l := Color("5e2234")
	var lining := Color("8a1e2e")
	var skin := Color("c8c0cc")
	var gold := Color("c8a050")
	var eye := Color(1.0, 0.25, 0.25) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var br := sin(t * 1.6) * 1.5
	var rear := 8.0 if winding else 0.0
	_shadow(c, 70.0)
	# the forest of the impaled behind him: stakes crowned with skulls
	for i in 7:
		var x := -78.0 + i * 26.0
		var h := 120.0 + (i % 3) * 18.0
		c.draw_line(Vector2(x, 0), Vector2(x + (i - 3) * 1.5, -h), OUT, 5.0)
		c.draw_line(Vector2(x, 0), Vector2(x + (i - 3) * 1.5, -h), Color("5a4030"), 3.0)
		BA._poly(c, [Vector2(x - 3 + (i - 3) * 1.5, -h), Vector2(x + (i - 3) * 1.5, -h - 12), Vector2(x + 3 + (i - 3) * 1.5, -h)], Color("6a4a34"), f, 1.0)
		if i % 2 == 0:
			_skull(c, Vector2(x + (i - 3) * 1.5, -h + 10.0), 4.2, Color("d8d0c0"))
	# spindly legs and pointed boots
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		var leg := PackedVector2Array([Vector2(s * 5, -58), Vector2(s * 15, -58), Vector2(s * 14, -8 + lift), Vector2(s * 26, -2 + lift), Vector2(s * 24, 2 + lift), Vector2(s * 6, 2 + lift), Vector2(s * 6, -8 + lift)])
		BA._shape(c, leg, Color("1c1420"), f)
		c.draw_line(Vector2(s * 10, -50), Vector2(s * 10, -12 + lift), Color("3a2a40"), 1.0)
		c.draw_rect(Rect2(s * 8 - 3, -22 + lift * 0.5, 6, 2), gold)
	# great bat-wing cloak
	for s in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(s * 16, -138 + br), Vector2(s * 50, -168 - rear), Vector2(s * 84, -150 - rear * 0.5), Vector2(s * 76, -122), Vector2(s * 86, -86), Vector2(s * 64, -96), Vector2(s * 66, -60), Vector2(s * 44, -76), Vector2(s * 40, -40), Vector2(s * 22, -70)])
		BA._shape(c, wing, cloak, f, cloak_l)
		for k in 4:
			c.draw_line(Vector2(s * 20, -134), Vector2(s * (60 + k * 6), -140 + k * 20 - rear * 0.2), lining, 1.2)
		c.draw_polyline(PackedVector2Array([Vector2(s * 50, -168 - rear), Vector2(s * 84, -150 - rear * 0.5)]), gold, 1.4)
	# gaunt waistcoat torso with exposed ribs
	var torso := BA._sm([Vector2(-18, -62), Vector2(18, -62), Vector2(24, -100), Vector2(18, -134 + br), Vector2(-18, -134 + br), Vector2(-24, -100)], true, 4)
	BA._shape(c, torso, Color("24141c"), f, Color("4a2838"))
	for k in 5:
		c.draw_arc(Vector2(0, -122 + k * 9 + br * 0.3), 13.0 - k, 0.15, PI - 0.15, 8, Color(0.75, 0.7, 0.75, 0.55), 1.2)
	c.draw_line(Vector2(0, -130), Vector2(0, -78), Color(0.75, 0.7, 0.75, 0.5), 1.2)
	# wound where a stake once pierced: glowing
	c.draw_circle(Vector2(-6, -104 + br), 6.0, Color(eye, 0.25))
	c.draw_circle(Vector2(-6, -104 + br), 3.0, OUT)
	c.draw_line(Vector2(-6, -112 + br), Vector2(-6, -97 + br), Color(eye, 0.9), 1.0)
	# Order of the Dragon medallion
	c.draw_circle(Vector2(8, -104 + br), 6.5, OUT)
	c.draw_circle(Vector2(8, -104 + br), 5.5, gold)
	c.draw_arc(Vector2(8, -104 + br), 3.6, 0.5, TAU - 0.5, 12, Color("5a3a18"), 1.2)
	c.draw_circle(Vector2(8, -104 + br), 1.2, Color("5a3a18"))
	# belt, hanging chains and a rosary of teeth
	c.draw_rect(Rect2(-20, -66, 40, 5), OUT)
	c.draw_rect(Rect2(-19, -65, 38, 3), Color("3a2a30"))
	for i in 5:
		c.draw_circle(Vector2(-14.0 + i * 7.0, -63.5), 1.1, gold)
	BA._chain(c, Vector2(-16, -62), Vector2(-4, -50), 6.0, 5, gold)
	# high pointed collar
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 8, -128 + br), Vector2(s * 26, -164 + br - rear * 0.4), Vector2(s * 22, -126 + br)], lining, f, 1.2)
		c.draw_line(Vector2(s * 12, -130 + br), Vector2(s * 25, -160 + br - rear * 0.4), cloak_l, 1.0)
	# arms with long claws
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 20, -126 + br)
		var hand := Vector2(s * (40 + rear * 1.5), -80 - rear * 3.0 + sin(t * 2.0 + s) * 3.0)
		c.draw_line(sh, hand, OUT, 7.0)
		c.draw_line(sh, hand, Color("2a1a24"), 5.0)
		c.draw_line(sh + Vector2(s * 2, 0), hand + Vector2(s * 2, 0), cloak_l, 1.0)
		for k in 4:
			var cl := hand + Vector2(s * (2 + k * 2.0), 3.0 + k * 1.2)
			c.draw_line(hand, cl + Vector2(s * 3, 7), OUT, 2.6)
			c.draw_line(hand, cl + Vector2(s * 3, 7), skin, 1.2)
	# head: gaunt pale face, long black hair, fangs
	var hy := -150.0 + br - rear * 0.5
	BA._poly(c, [Vector2(-14, hy - 4), Vector2(-20, hy + 28), Vector2(-8, hy + 38), Vector2(0, hy + 20), Vector2(8, hy + 38), Vector2(20, hy + 28), Vector2(14, hy - 4)], Color("0e0810"), f, 1.0)
	var face := BA._sm([Vector2(-11, hy - 8), Vector2(11, hy - 8), Vector2(12, hy + 8), Vector2(6, hy + 20), Vector2(-6, hy + 20), Vector2(-12, hy + 8)], true, 4)
	BA._shape(c, face, skin, f, Color(1, 1, 1))
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 3, hy), Vector2(s * 10, hy - 2), Vector2(s * 9, hy + 5), Vector2(s * 3, hy + 3)], OUT, f, 0.6)
		c.draw_circle(Vector2(s * 6.5, hy + 2), 2.0, eye)
		c.draw_circle(Vector2(s * 6.5, hy + 2), 5.0, Color(eye, 0.2))
	c.draw_line(Vector2(0, hy + 4), Vector2(1, hy + 10), Color("8a7a88"), 1.0)
	c.draw_rect(Rect2(-5, hy + 13, 10, 2), Color("5a1020"))
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 3 - 1, hy + 14), Vector2(s * 3 + 1, hy + 14), Vector2(s * 3, hy + 20)], Color.WHITE, f, 0.6)
	# impaler's crown of iron stakes
	for k in 5:
		var cx := -12.0 + k * 6.0
		var ch := 12.0 + (3 - absf(k - 2)) * 4.0
		BA._poly(c, [Vector2(cx - 2.5, hy - 8), Vector2(cx, hy - 8 - ch), Vector2(cx + 2.5, hy - 8)], Color("6a6672"), f, 1.0)
		c.draw_circle(Vector2(cx, hy - 8 - ch), 1.0, Color(eye, 0.9))
	c.draw_line(Vector2(-13, hy - 8), Vector2(13, hy - 8), gold, 2.0)
	# bats wheeling about him
	for i in 4:
		var a := t * (1.1 + i * 0.12) + i * 1.7
		_bat(c, Vector2(cos(a) * (62.0 + i * 8.0), -110.0 + sin(a * 1.3) * 34.0 - i * 10.0), t + i, Color("1c0c14"))
	if ph >= 3:
		for k in 4:
			var u := fmod(t * 0.8 + k * 0.25, 1.0)
			c.draw_rect(Rect2(-8 + k * 6, -90 + u * 80, 2, 3), Color(0.7, 0.05, 0.1, 0.8 * (1.0 - u)))


# ====================================================================== Ankou of the Ossuary

static func ankou(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var bone := Color("d8d2c0")
	var cloak := Color("2c3038")
	var cloak_l := Color("485060")
	var gold := Color("a89860")
	var eye := Color(0.4, 1.0, 0.9) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var br := sin(t * 1.4) * 1.5
	_shadow(c, 74.0)
	# the death-cart wheel, a pile of skulls and bones behind
	var wc := Vector2(-52, -52)
	c.draw_circle(wc, 40.0, OUT)
	c.draw_circle(wc, 37.0, Color("4a3828"))
	c.draw_circle(wc, 30.0, Color("1a1218"))
	for k in 10:
		var a := TAU * k / 10.0 + t * 0.05
		c.draw_line(wc, wc + Vector2.from_angle(a) * 33.0, Color("6a5038"), 2.4)
	c.draw_circle(wc, 6.0, gold)
	c.draw_arc(wc, 37.0, 0, TAU, 28, Color("7a6048"), 1.4)
	for i in 5:
		_skull(c, Vector2(-92.0 + i * 11.0, -14.0 - (i % 2) * 5.0), 5.0, Color("c8c2b0"))
	for i in 4:
		c.draw_line(Vector2(-84 + i * 14, -6), Vector2(-74 + i * 14, -12), bone, 2.0)
	# legs of bone
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		c.draw_line(Vector2(s * 9, -66), Vector2(s * 12, -34), OUT, 7.0)
		c.draw_line(Vector2(s * 9, -66), Vector2(s * 12, -34), bone, 4.0)
		c.draw_line(Vector2(s * 12, -34), Vector2(s * 10, -4 + lift), OUT, 6.0)
		c.draw_line(Vector2(s * 12, -34), Vector2(s * 10, -4 + lift), bone, 3.0)
		c.draw_circle(Vector2(s * 12, -34), 4.0, OUT)
		c.draw_circle(Vector2(s * 12, -34), 3.0, bone)
		BA._poly(c, [Vector2(s * 6, -4 + lift), Vector2(s * 20, -4 + lift), Vector2(s * 22, 2 + lift), Vector2(s * 4, 2 + lift)], bone, f, 1.0)
	# ragged cloak with tattered hem
	var hem: Array = []
	for i in 9:
		hem.append(Vector2(-44.0 + i * 11.0, -8.0 + (i % 2) * 9.0 + sin(t * 2.0 + i) * 2.0))
	var body: Array = [Vector2(-22, -138 + br), Vector2(22, -138 + br), Vector2(34, -100), Vector2(48, -40)]
	body.append_array(hem.duplicate())
	hem.reverse()
	body.append(Vector2(-48, -40))
	body.append(Vector2(-34, -100))
	var bp := PackedVector2Array(body)
	BA._shape(c, bp, cloak, f, cloak_l)
	for k in 5:
		c.draw_line(Vector2(-30 + k * 15, -100), Vector2(-38 + k * 19, -14), Color(0.06, 0.07, 0.1, 0.5), 1.4)
	# ribcage glimpsed through a rent in the cloak
	c.draw_rect(Rect2(-12, -118 + br, 24, 36), Color(0.03, 0.04, 0.06))
	for k in 5:
		c.draw_arc(Vector2(0, -114 + k * 7 + br * 0.4), 11.0 - k * 0.6, 0.2, PI - 0.2, 8, bone, 1.4)
	c.draw_line(Vector2(0, -118 + br), Vector2(0, -84 + br), bone, 1.6)
	# hanging soul-lantern at the waist and an hourglass
	var lp := Vector2(26 + sin(t * 2.0) * 3.0, -62.0 + sin(t * 2.6) * 2.0)
	c.draw_line(Vector2(20, -80), lp + Vector2(0, -6), Color("4a3828"), 1.2)
	BA._poly(c, [lp + Vector2(-5, -5), lp + Vector2(5, -5), lp + Vector2(6, 6), lp + Vector2(-6, 6)], Color("2a2420"), f, 1.0)
	c.draw_circle(lp, 9.0, Color(eye, 0.2))
	BA._arch(c, lp.x, lp.y + 4, 3.2, 8.0, Color(eye, 0.95), Color("2a2420"))
	var hg := Vector2(-22, -72)
	BA._poly(c, [hg + Vector2(-5, -8), hg + Vector2(5, -8), hg + Vector2(0, 0), hg + Vector2(5, 8), hg + Vector2(-5, 8), hg + Vector2(0, 0)], Color("a8a090"), f, 1.0)
	c.draw_rect(Rect2(hg + Vector2(-1, 2), Vector2(2, 5)), Color(eye, 0.8))
	# shoulder cape and arms
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 12, -138 + br), Vector2(s * 40, -130), Vector2(s * 44, -112), Vector2(s * 20, -118)], cloak_l, f, 1.2)
	var swing := 0.0
	if winding:
		swing = sin(t * 10.0) * 0.1
	# the scythe: staff and out-turned blade, held across the body
	var sa := Vector2(60, -34)
	var sb := Vector2(46, -176)
	c.draw_line(sa, sb, OUT, 6.0)
	c.draw_line(sa, sb, Color("5a4228"), 3.6)
	BA._rivets(c, sa.lerp(sb, 0.1), sa.lerp(sb, 0.9), 5, gold)
	var blade := PackedVector2Array()
	for i in 14:
		var u := i / 13.0
		blade.append(sb + Vector2(u * -76.0 * cos(swing), -sin(u * PI) * 20.0 + u * 14.0))
	for i in 14:
		var u := 1.0 - i / 13.0
		blade.append(sb + Vector2(u * -76.0 * cos(swing), -sin(u * PI) * 12.0 + u * 14.0 + 3.0))
	c.draw_colored_polygon(blade, BA._fl(Color("aab4be"), f))
	c.draw_polyline(blade, OUT, 1.4)
	c.draw_line(sb + Vector2(-4, -2), sb + Vector2(-70, 12), Color(1, 1, 1, 0.7), 1.0)
	for k in 5:
		c.draw_circle(sb + Vector2(-12 - k * 12, 6 + k * 1.4), 0.9, Color(eye, 0.8))
	# skeletal hands on the staff
	for k in 2:
		var hp := sa.lerp(sb, 0.3 + k * 0.3)
		c.draw_circle(hp, 4.5, OUT)
		c.draw_circle(hp, 3.4, bone)
		for j in 3:
			c.draw_line(hp + Vector2(-3, -2 + j * 2), hp + Vector2(-6, -3 + j * 2.4), bone, 1.0)
	c.draw_line(Vector2(30, -126 + br), sa.lerp(sb, 0.3), OUT, 6.0)
	c.draw_line(Vector2(30, -126 + br), sa.lerp(sb, 0.3), cloak_l, 4.0)
	# skull under a wide-brimmed hat and hood
	var hy := -152.0 + br
	BA._poly(c, [Vector2(-18, hy - 2), Vector2(-22, hy + 22), Vector2(22, hy + 22), Vector2(18, hy - 2)], Color("14161c"), f, 1.0)
	var sk := BA._sm([Vector2(-12, hy), Vector2(12, hy), Vector2(14, hy + 12), Vector2(8, hy + 22), Vector2(-8, hy + 22), Vector2(-14, hy + 12)], true, 4)
	BA._shape(c, sk, bone, f, Color.WHITE)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 6, hy + 8), 4.4, OUT)
		c.draw_circle(Vector2(s * 6, hy + 8), 2.2, eye)
		c.draw_circle(Vector2(s * 6, hy + 8), 7.0, Color(eye, 0.18))
	BA._poly(c, [Vector2(0, hy + 12), Vector2(-2, hy + 16), Vector2(2, hy + 16)], OUT, f, 0.6)
	for k in 6:
		c.draw_line(Vector2(-6 + k * 2.4, hy + 18), Vector2(-6 + k * 2.4, hy + 22), OUT, 1.0)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 2), 36.0, 7.0), OUT)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 3), 34.0, 5.6), Color("2a2630"))
	BA._poly(c, [Vector2(-14, hy - 3), Vector2(-12, hy - 22), Vector2(12, hy - 22), Vector2(14, hy - 3)], Color("2a2630"), f, 1.2)
	c.draw_rect(Rect2(-14, hy - 8, 28, 3), gold)
	c.draw_circle(Vector2(0, hy - 6.5), 2.0, Color("c8c0a0"))
	# drifting soul wisps
	for i in 5:
		var u := fmod(t * 0.4 + i * 0.2, 1.0)
		c.draw_circle(Vector2(-60 + i * 30 + sin(t + i) * 6.0, -30 - u * 120.0), 2.2 - u, Color(eye, 0.7 * (1.0 - u)))


# ====================================================================== Barghest of Whitby

static func barghest(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var fur := Color("16141c")
	var fur_l := Color("2e2a3c")
	var ghost := Color(0.55, 0.85, 1.0)
	var eye := Color(1.0, 0.45, 0.2) if exposed <= 0.0 else Color(1.0, 0.95, 0.5)
	var br := sin(t * 1.9) * 1.5
	var rear := 14.0 if winding else 0.0
	_shadow(c, 84.0)
	# four powerful legs with ember paws
	var legs := [[-52.0, 0.0], [-34.0, 1.6], [28.0, 3.1], [48.0, 4.6]]
	for k in 4:
		var lx: float = legs[k][0]
		var lift: float = maxf(0.0, sin(t * 4.0 + float(legs[k][1]))) * 5.0 if moving else 0.0
		var knee := Vector2(lx + 4, -34)
		BA._poly(c, [Vector2(lx - 9, -64), Vector2(lx + 9, -64), Vector2(lx + 8, -30), Vector2(lx + 6, -6 - lift), Vector2(lx + 14, 0 - lift), Vector2(lx - 8, 0 - lift), Vector2(lx - 6, -6 - lift), Vector2(lx - 8, -30)], fur if k % 2 == 0 else fur.lightened(0.06), f, 1.2)
		for j in 3:
			c.draw_line(Vector2(lx - 6 + j * 5, -64 + j), Vector2(lx - 7 + j * 5, -34 + j), fur_l, 1.0)
		c.draw_circle(Vector2(lx + 3, -2 - lift), 3.0, Color(ghost, 0.35))
		for j in 3:
			c.draw_line(Vector2(lx + 6 + j * 2, -1 - lift), Vector2(lx + 9 + j * 2, 3 - lift), Color("c8c8d0"), 1.2)
		if k == 0:
			knee.x += 0.0
	# lashing tail wreathed in ghost fire
	var tp: Array = []
	for j in 6:
		tp.append(Vector2(-72 - j * 8, -78 - j * 5 + sin(t * 3.0 + j * 0.6) * 5.0 + rear * j * 0.4))
	c.draw_polyline(BA._sm(tp, false, 4), OUT, 8.0)
	c.draw_polyline(BA._sm(tp, false, 4), fur, 5.0)
	for j in 4:
		_flame(c, tp[j + 2], 12.0, t + j, ghost, 3.0)
	# body: deep chest, tucked waist and haunch
	var body := BA._sm([Vector2(-78, -84 + br), Vector2(-52, -104 + br), Vector2(-6, -98 + br - rear * 0.3), Vector2(34, -108 + br - rear * 0.6), Vector2(62, -92 - rear * 0.6), Vector2(58, -64), Vector2(20, -58), Vector2(-24, -62), Vector2(-62, -60), Vector2(-80, -70)], true, 5)
	BA._shape(c, body, fur, f, fur_l)
	# shaggy fur tufts along the spine and belly
	for i in 14:
		var x := -70.0 + i * 9.5
		var y := -100.0 + br - (rear * 0.4 if x > 0 else 0.0) - (6.0 if i % 2 == 0 else 0.0)
		BA._poly(c, [Vector2(x - 3, y + 6), Vector2(x + sin(t * 3.0 + i) * 1.5, y - 8), Vector2(x + 4, y + 6)], fur_l, f, 0.8)
	for i in 9:
		var x := -64.0 + i * 12.0
		BA._poly(c, [Vector2(x - 3, -62), Vector2(x, -52 + (i % 3) * 2), Vector2(x + 3, -62)], fur, f, 0.8)
	# ghost-fire licking along the spine
	for i in 6:
		_flame(c, Vector2(-56.0 + i * 20.0, -102.0 + br - (rear * 0.5 if i > 3 else 0.0)), 14.0 + (i % 2) * 6.0 + (ph - 1) * 4.0, t + i * 0.7, ghost, 3.5)
	# dangling broken shackle chains
	BA._chain(c, Vector2(-30, -70), Vector2(-14, -34), 8.0, 6, Color("8a8a98"))
	BA._chain(c, Vector2(8, -66), Vector2(22, -26), 7.0, 6, Color("8a8a98"))
	c.draw_circle(Vector2(-14, -34), 4.0, OUT)
	c.draw_arc(Vector2(-14, -34), 3.4, 0, TAU, 10, Color("a0a0b0"), 1.4)
	# spiked ruff collar and great neck
	var neck := BA._sm([Vector2(40, -108 + br - rear * 0.6), Vector2(66, -126 - rear), Vector2(88, -122 - rear), Vector2(84, -84 - rear * 0.2), Vector2(58, -66)], true, 4)
	BA._shape(c, neck, fur, f, fur_l)
	for i in 7:
		var a := -2.4 + i * 0.4
		var p0 := Vector2(66, -100 - rear * 0.5)
		BA._poly(c, [p0 + Vector2.from_angle(a - 0.12) * 20.0, p0 + Vector2.from_angle(a) * 38.0, p0 + Vector2.from_angle(a + 0.12) * 20.0], Color("3a3448"), f, 1.0)
	var hx := 92.0
	var hy := -118.0 - rear
	# head: long muzzle, open jaw, fangs
	var skull := BA._sm([Vector2(hx - 22, hy - 4), Vector2(hx - 8, hy - 20), Vector2(hx + 14, hy - 16), Vector2(hx + 48, hy + 2), Vector2(hx + 52, hy + 12), Vector2(hx + 14, hy + 14), Vector2(hx - 14, hy + 16)], true, 5)
	BA._shape(c, skull, fur, f, fur_l)
	var jaw_open := 6.0 + (10.0 if winding else 0.0) + sin(t * 3.0) * 1.5
	var jaw := PackedVector2Array([Vector2(hx - 8, hy + 14), Vector2(hx + 50, hy + 14 + jaw_open * 0.5), Vector2(hx + 40, hy + 22 + jaw_open), Vector2(hx - 2, hy + 24 + jaw_open * 0.6)])
	BA._shape(c, jaw, Color("0c0a12"), f)
	c.draw_colored_polygon(PackedVector2Array([Vector2(hx + 2, hy + 14), Vector2(hx + 48, hy + 14 + jaw_open * 0.4), Vector2(hx + 38, hy + 18 + jaw_open * 0.8), Vector2(hx + 4, hy + 18 + jaw_open * 0.5)]), Color("5a0a14"))
	for k in 5:
		BA._poly(c, [Vector2(hx + 16 + k * 7, hy + 13 + jaw_open * 0.1 * k * 0.3), Vector2(hx + 19 + k * 7, hy + 22 + jaw_open * 0.4), Vector2(hx + 21 + k * 7, hy + 13)], Color("e8e8f0"), f, 0.8)
		BA._poly(c, [Vector2(hx + 16 + k * 7, hy + 20 + jaw_open * 0.9), Vector2(hx + 18 + k * 7, hy + 14 + jaw_open * 0.5), Vector2(hx + 21 + k * 7, hy + 20 + jaw_open * 0.9)], Color("d8d8e0"), f, 0.8)
	# ears, burning eyes, scarred snout
	BA._poly(c, [Vector2(hx - 16, hy - 12), Vector2(hx - 12, hy - 38), Vector2(hx - 2, hy - 16)], fur, f, 1.2)
	BA._poly(c, [Vector2(hx - 4, hy - 16), Vector2(hx + 4, hy - 36), Vector2(hx + 10, hy - 14)], fur_l, f, 1.2)
	c.draw_circle(Vector2(hx + 14, hy - 2), 12.0, Color(eye, 0.22))
	c.draw_circle(Vector2(hx + 14, hy - 2), 5.0, OUT)
	c.draw_circle(Vector2(hx + 14, hy - 2), 3.6, eye)
	_flame(c, Vector2(hx + 14, hy - 6), 12.0, t, eye, 3.0)
	c.draw_line(Vector2(hx + 6, hy - 6), Vector2(hx + 22, hy - 8), Color(OUT, 0.9), 1.6)
	c.draw_circle(Vector2(hx + 48, hy + 4), 2.4, OUT)
	for k in 3:
		c.draw_line(Vector2(hx + 26 + k * 5, hy - 8 + k), Vector2(hx + 30 + k * 5, hy - 3 + k), Color(0.4, 0.4, 0.5), 1.0)
	for k in 3:
		var u := fmod(t * 0.9 + k * 0.33, 1.0)
		c.draw_circle(Vector2(hx + 54 + u * 22, hy + 6 - u * 6), 2.0 + u * 3.0, Color(ghost, 0.35 * (1.0 - u)))
	# whiskers of mist and drifting spirits
	for i in 5:
		var u := fmod(t * 0.35 + i * 0.2, 1.0)
		c.draw_circle(Vector2(-40 + i * 30, -20 - u * 60), 3.0 - u * 2.0, Color(ghost, 0.3 * (1.0 - u)))


# ====================================================================== Il Medico della Peste

static func plague(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var coat := Color("2a2430")
	var coat_l := Color("4a4056")
	var wax := Color("5a4a3a")
	var gold := Color("c8a858")
	var bone := Color("e8e0cc")
	var eye := Color(0.5, 1.0, 0.45) if exposed <= 0.0 else Color(1.0, 0.9, 0.4)
	var miasma := Color(0.5, 0.85, 0.35)
	var br := sin(t * 1.5) * 1.3
	var lift_arm := 14.0 if winding else 0.0
	_shadow(c, 66.0)
	# plague rats at his feet
	for i in 3:
		var rx := -60.0 + i * 56.0 + sin(t * 2.0 + i) * 6.0
		c.draw_colored_polygon(BA._ellipse(Vector2(rx, -4), 8.0, 4.5), OUT)
		c.draw_colored_polygon(BA._ellipse(Vector2(rx, -4.5), 6.8, 3.6), Color("4a4038"))
		c.draw_circle(Vector2(rx + 7, -5), 2.4, Color("4a4038"))
		c.draw_circle(Vector2(rx + 8.4, -5.6), 0.7, Color(1, 0.3, 0.3))
		c.draw_line(Vector2(rx - 7, -4), Vector2(rx - 15, -2 + sin(t * 3.0 + i) * 2.0), Color("8a6a6a"), 1.0)
	# boots and legs
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 3.0 + s) * 3.0 if moving else 0.0
		BA._poly(c, [Vector2(s * 6, -50), Vector2(s * 18, -50), Vector2(s * 17, -10 + lift), Vector2(s * 24, 0 + lift), Vector2(s * 5, 0 + lift)], Color("1a1418"), f, 1.2)
		c.draw_line(Vector2(s * 8, -30 + lift * 0.4), Vector2(s * 16, -30 + lift * 0.4), gold, 1.0)
	# long waxed-leather coat with flared skirts
	var sway := sin(t * 2.0) * 3.0
	var coatp := BA._sm([Vector2(-22, -134 + br), Vector2(22, -134 + br), Vector2(32, -96), Vector2(52 + sway, -14), Vector2(24, -8), Vector2(0, -22), Vector2(-24, -8), Vector2(-52 - sway, -14), Vector2(-32, -96)], true, 4)
	BA._shape(c, coatp, coat, f, coat_l)
	for k in 6:
		c.draw_line(Vector2(-20 + k * 8, -110), Vector2(-36 + k * 14 + (sway if k > 2 else -sway), -18), Color(0.05, 0.04, 0.08, 0.55), 1.2)
	c.draw_line(Vector2(0, -132 + br), Vector2(0, -22), gold, 1.2)
	for k in 6:
		c.draw_circle(Vector2(0, -122 + k * 16), 1.8, gold)
	# the winged lion of St Mark embroidered on the breast
	var lp := Vector2(-11, -112 + br)
	c.draw_circle(lp, 8.0, OUT)
	c.draw_circle(lp, 7.0, Color("1a3a6a"))
	for s in [-1.0, 1.0]:
		BA._poly(c, [lp + Vector2(s * 1, -1), lp + Vector2(s * 8, -7), lp + Vector2(s * 6, 0), lp + Vector2(s * 7, 4)], gold, f, 0.6)
	c.draw_circle(lp + Vector2(0, 1), 2.4, gold)
	# bandolier of vials and a belt of herb bundles
	c.draw_line(Vector2(-20, -128 + br), Vector2(20, -74), OUT, 4.0)
	c.draw_line(Vector2(-20, -128 + br), Vector2(20, -74), wax, 2.4)
	for k in 5:
		var vp := Vector2(-16.0 + k * 8.0, -122.0 + k * 10.8 + br)
		c.draw_rect(Rect2(vp + Vector2(-1.6, 0), Vector2(3.2, 7)), OUT)
		c.draw_rect(Rect2(vp + Vector2(-0.9, 1), Vector2(1.8, 5)), Color(0.4 + 0.1 * k, 0.9 - 0.1 * k, 0.4 + 0.1 * (k % 2), 0.85))
	c.draw_rect(Rect2(-24, -72, 48, 6), OUT)
	c.draw_rect(Rect2(-23, -71, 46, 4), wax)
	for k in 5:
		var hp := Vector2(-18.0 + k * 9.0, -66)
		c.draw_line(hp, hp + Vector2(0, 10), Color("5a7a3a"), 2.0)
		c.draw_circle(hp + Vector2(0, 11), 1.6, Color("8a5aa0"))
	# cape of black over the shoulders with a gold-trimmed collar
	BA._poly(c, [Vector2(-26, -130 + br), Vector2(26, -130 + br), Vector2(36, -112), Vector2(0, -102), Vector2(-36, -112)], Color("1a1620"), f, 1.2)
	c.draw_line(Vector2(-34, -112), Vector2(0, -102), gold, 1.4)
	c.draw_line(Vector2(0, -102), Vector2(34, -112), gold, 1.4)
	# left arm with the long cane
	var cane_a := Vector2(-48, -2)
	var cane_b := Vector2(-52, -156)
	c.draw_line(cane_a, cane_b, OUT, 5.0)
	c.draw_line(cane_a, cane_b, Color("3a2a20"), 3.0)
	BA._rivets(c, cane_a + Vector2(0, -10), cane_b + Vector2(0, 10), 7, gold)
	c.draw_circle(cane_b, 5.0, OUT)
	c.draw_circle(cane_b, 4.0, gold)
	c.draw_line(Vector2(-20, -122 + br), Vector2(-48, -100), OUT, 7.0)
	c.draw_line(Vector2(-20, -122 + br), Vector2(-48, -100), coat_l, 5.0)
	c.draw_circle(Vector2(-48, -100), 4.5, Color("2a1a14"))
	# right arm lifting a swinging censer of green fumes
	var ha := Vector2(44, -92 - lift_arm)
	c.draw_line(Vector2(20, -122 + br), ha, OUT, 7.0)
	c.draw_line(Vector2(20, -122 + br), ha, coat_l, 5.0)
	c.draw_circle(ha, 4.5, Color("2a1a14"))
	var cp := ha + Vector2(sin(t * 2.6) * 10.0 + 8.0, 28.0 + cos(t * 2.6) * 2.0)
	c.draw_line(ha, cp + Vector2(0, -7), Color("8a8070"), 1.2)
	BA._poly(c, [cp + Vector2(-7, -6), cp + Vector2(7, -6), cp + Vector2(6, 4), cp + Vector2(0, 8), cp + Vector2(-6, 4)], gold, f, 1.2)
	for k in 4:
		c.draw_line(cp + Vector2(-5 + k * 3.4, -5), cp + Vector2(-5 + k * 3.4, 3), Color("5a3a18"), 1.0)
	for k in 5:
		var u := fmod(t * 0.7 + k * 0.2, 1.0)
		c.draw_circle(cp + Vector2(sin(t * 2.0 + k * 2.0) * 7.0 * u, -8.0 - u * 50.0), 3.0 + u * 5.0, Color(miasma, 0.4 * (1.0 - u)))
	# the beaked mask, wide hat, tinted lenses
	var hy := -150.0 + br
	BA._poly(c, [Vector2(-14, hy + 8), Vector2(-18, hy + 30), Vector2(18, hy + 30), Vector2(14, hy + 8)], Color("14101a"), f, 1.0)
	var mask := BA._sm([Vector2(-12, hy - 6), Vector2(12, hy - 6), Vector2(14, hy + 10), Vector2(8, hy + 20), Vector2(-8, hy + 20), Vector2(-14, hy + 10)], true, 4)
	BA._shape(c, mask, bone, f, Color.WHITE)
	var beak := PackedVector2Array([Vector2(0, hy + 4), Vector2(26, hy + 14), Vector2(40, hy + 36), Vector2(26, hy + 32), Vector2(8, hy + 22), Vector2(-2, hy + 14)])
	BA._shape(c, beak, bone, f, Color.WHITE, 1.6)
	c.draw_line(Vector2(6, hy + 12), Vector2(34, hy + 32), Color(0.6, 0.55, 0.45), 1.0)
	for k in 3:
		c.draw_circle(Vector2(14 + k * 6, hy + 18 + k * 6), 0.9, Color(0.4, 0.35, 0.3))
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 6.5, OUT)
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 5.2, gold)
		c.draw_circle(Vector2(s * 6 + 2, hy + 6), 3.8, Color(eye.r * 0.5, eye.g * 0.5, eye.b * 0.4).lerp(eye, 0.6 + 0.2 * sin(t * 3.0)))
		c.draw_circle(Vector2(s * 6 + 1, hy + 5), 1.0, Color(1, 1, 1, 0.8))
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 6), 38.0, 8.0), OUT)
	c.draw_colored_polygon(BA._ellipse(Vector2(0, hy - 7), 36.0, 6.6), Color("1c1824"))
	BA._poly(c, [Vector2(-16, hy - 7), Vector2(-13, hy - 26), Vector2(13, hy - 26), Vector2(16, hy - 7)], Color("1c1824"), f, 1.2)
	c.draw_rect(Rect2(-16, hy - 12, 32, 3.5), gold)
	for k in 3:
		c.draw_line(Vector2(-10 + k * 10, hy - 26), Vector2(-14 + k * 14, hy - 38), Color("e8e0cc"), 1.6)
	# perched raven on the shoulder
	var rv := Vector2(-30, -134 + br)
	c.draw_colored_polygon(BA._ellipse(rv, 9.0, 6.0), OUT)
	c.draw_colored_polygon(BA._ellipse(rv, 7.6, 4.8), Color("2a2438"))
	c.draw_circle(rv + Vector2(-7, -5), 3.4, Color("2a2438"))
	BA._poly(c, [rv + Vector2(-9, -6), rv + Vector2(-15, -4), rv + Vector2(-9, -3)], gold, f, 0.6)
	c.draw_circle(rv + Vector2(-8, -6), 0.7, Color(1, 0.9, 0.4))
	for i in 3:
		var u := fmod(t * 0.5 + i * 0.33, 1.0)
		c.draw_circle(Vector2(-40 + i * 40, -20 - u * 130), 4.0 + u * 6.0, Color(miasma, 0.12 * (1.0 - u)))


# ====================================================================== Cacus of the Aventine

static func cacus(c: CanvasItem, t: float, ph: int, f: float, winding: bool, exposed: float, moving: bool) -> void:
	var skin := Color("6a4a3c")
	var skin_l := Color("8a6450")
	var skin_d := Color("3e2a22")
	var gold := Color("b89048")
	var fire := Color(1.0, 0.55, 0.15) if ph < 3 else Color(1.0, 0.3 + 0.2 * sin(t * 10.0), 0.1)
	var eye := Color(1.0, 0.7, 0.2) if exposed <= 0.0 else Color(1.0, 1.0, 0.7)
	var bone := Color("d8ceb8")
	var br := sin(t * 1.7) * 1.8
	var raise := 22.0 if winding else 0.0
	_shadow(c, 84.0)
	# smoke curling up from the cave behind
	for i in 6:
		var u := fmod(t * 0.35 + i * 0.17, 1.0)
		c.draw_circle(Vector2(-60 + i * 24 + sin(t + i) * 8.0, -60 - u * 120.0), 10.0 + u * 14.0, Color(0.2, 0.18, 0.2, 0.22 * (1.0 - u)))
	# thick legs with cloven, hoof-like feet
	for s in [-1.0, 1.0]:
		var lift: float = sin(t * 2.6 + s) * 3.0 if moving else 0.0
		var leg := PackedVector2Array([Vector2(s * 6, -58), Vector2(s * 34, -58), Vector2(s * 36, -26 + lift), Vector2(s * 40, -4 + lift), Vector2(s * 44, 2 + lift), Vector2(s * 12, 2 + lift), Vector2(s * 8, -26 + lift)])
		BA._shape(c, leg, skin, f, skin_l)
		for k in 3:
			c.draw_line(Vector2(s * (14 + k * 6), -54), Vector2(s * (14 + k * 6), -30 + lift * 0.5), skin_d, 1.2)
		BA._poly(c, [Vector2(s * 12, 2 + lift), Vector2(s * 44, 2 + lift), Vector2(s * 40, 8 + lift), Vector2(s * 14, 8 + lift)], Color("2a1c18"), f, 1.2)
		for k in 3:
			c.draw_line(Vector2(s * (14 + k * 11), 4 + lift), Vector2(s * (14 + k * 11), 8 + lift), Color("e8e0d0"), 1.2)
	# cattle-hide kilt with fur trim and a belt of skulls
	var kilt := PackedVector2Array([Vector2(-44, -62), Vector2(44, -62), Vector2(48, -34), Vector2(30, -26), Vector2(14, -34), Vector2(0, -24), Vector2(-14, -34), Vector2(-30, -26), Vector2(-48, -34)])
	BA._shape(c, kilt, Color("4a3228"), f, Color("7a5a42"))
	for k in 6:
		c.draw_line(Vector2(-36 + k * 14, -60), Vector2(-40 + k * 16, -30), Color(0.1, 0.06, 0.04, 0.5), 2.0)
		c.draw_circle(Vector2(-30 + k * 12, -48 + (k % 2) * 6), 3.0, Color("e8e0d0", 0.6))
	c.draw_rect(Rect2(-46, -68, 92, 8), OUT)
	c.draw_rect(Rect2(-45, -67, 90, 6), Color("2a1c18"))
	for k in 6:
		_skull(c, Vector2(-36.0 + k * 14.4, -64), 4.4, bone)
	# barrel chest, scorched and cracked with embers
	var torso := BA._sm([Vector2(-46, -68), Vector2(46, -68), Vector2(64, -112 + br), Vector2(50, -148 + br), Vector2(-50, -148 + br), Vector2(-64, -112 + br)], true, 5)
	BA._shape(c, torso, skin, f, skin_l)
	for s in [-1.0, 1.0]:
		BA._poly(c, [Vector2(s * 4, -120 + br), Vector2(s * 40, -126 + br), Vector2(s * 44, -102 + br), Vector2(s * 4, -96 + br)], skin_l, f, 1.4)
		c.draw_line(Vector2(s * 8, -112 + br), Vector2(s * 36, -116 + br), skin_d, 1.4)
		for k in 3:
			c.draw_line(Vector2(s * (8 + k * 12), -92 + br), Vector2(s * (14 + k * 12), -74), skin_d, 1.6)
	c.draw_line(Vector2(0, -140 + br), Vector2(0, -70), skin_d, 2.0)
	var cr := [[Vector2(-30, -140), Vector2(-24, -126), Vector2(-32, -112), Vector2(-22, -96)], [Vector2(26, -136), Vector2(32, -120), Vector2(24, -106), Vector2(30, -86)], [Vector2(2, -92), Vector2(-4, -82), Vector2(4, -74)]]
	for pts in cr:
		c.draw_polyline(PackedVector2Array(pts), Color(fire, 0.4 + 0.3 * sin(t * 4.0)), 3.0)
		c.draw_polyline(PackedVector2Array(pts), Color(1.0, 0.9, 0.5, 0.9), 1.0)
	# necklace of skulls from the cave-mouth doorposts
	for k in 7:
		var u := k / 6.0
		var np := Vector2(-34 + u * 68, -146 + br + sin(u * PI) * 20.0)
		_skull(c, np, 3.6, bone)
	# bull-horn pauldrons: trophies of the stolen cattle
	for s in [-1.0, 1.0]:
		var pc := Vector2(s * 58, -136 + br)
		BA._poly(c, [pc + Vector2(-s * 4, -8), pc + Vector2(s * 16, -12), pc + Vector2(s * 20, 10), pc + Vector2(-s * 2, 12)], Color("3a2a22"), f, 1.4)
		var horn := PackedVector2Array([pc + Vector2(s * 12, -8), pc + Vector2(s * 26, -20), pc + Vector2(s * 34, -40), pc + Vector2(s * 28, -26), pc + Vector2(s * 16, -4)])
		c.draw_colored_polygon(horn, Color("e0d4b8"))
		c.draw_polyline(horn, OUT, 1.4)
		c.draw_line(pc + Vector2(s * 14, -8), pc + Vector2(s * 30, -34), Color("a89870"), 1.0)
		c.draw_rect(Rect2(pc + Vector2(-2, -2), Vector2(4, 4)), gold)
	# arms: hanging, or hoisting a boulder overhead when winding
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 58, -126 + br)
		var hand := Vector2(s * (66 - raise * 0.7), -66 - raise * 4.6 + sin(t * 2.0 + s) * 2.0)
		var elbow := Vector2(s * (86 - raise * 0.5), -98 - raise * 2.0)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), OUT, 16.0)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), skin, 12.0)
		c.draw_polyline(PackedVector2Array([sh, elbow, hand]), skin_l, 3.0)
		c.draw_circle(hand, 8.0, OUT)
		c.draw_circle(hand, 6.8, skin_d)
		c.draw_rect(Rect2(elbow + Vector2(-5, -3), Vector2(10, 5)), gold)
	if winding:
		var bp := Vector2(0, -66 - raise * 4.6 - 18.0)
		var rock := BA._sm([bp + Vector2(-26, 6), bp + Vector2(-20, -14), bp + Vector2(-2, -22), bp + Vector2(20, -14), bp + Vector2(28, 4), bp + Vector2(10, 14), bp + Vector2(-12, 14)], true, 3)
		BA._shape(c, rock, Color("6a625e"), f, Color("a8a098"))
		c.draw_line(bp + Vector2(-8, -12), bp + Vector2(2, 0), Color("2a2624"), 1.4)
		c.draw_line(bp + Vector2(2, 0), bp + Vector2(-4, 10), Color("2a2624"), 1.4)
		c.draw_circle(bp + Vector2(12, -6), 2.0, Color(fire, 0.7))
	# the face: low brow, three burning eyes, a furnace of a mouth
	var hy := -168.0 + br
	var head := BA._sm([Vector2(-26, hy + 4), Vector2(-20, hy - 20), Vector2(0, hy - 28), Vector2(20, hy - 20), Vector2(26, hy + 4), Vector2(22, hy + 30), Vector2(0, hy + 40), Vector2(-22, hy + 30)], true, 5)
	BA._shape(c, head, skin, f, skin_l)
	BA._poly(c, [Vector2(-28, hy - 2), Vector2(0, hy - 8), Vector2(28, hy - 2), Vector2(24, hy + 6), Vector2(0, hy), Vector2(-24, hy + 6)], skin_d, f, 1.4)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(s * 12, hy + 7), 6.0, Color(eye, 0.25))
		c.draw_circle(Vector2(s * 12, hy + 7), 3.4, OUT)
		c.draw_circle(Vector2(s * 12, hy + 7), 2.4, eye)
	c.draw_circle(Vector2(0, hy - 8), 5.0, Color(eye, 0.3))
	c.draw_circle(Vector2(0, hy - 8), 2.6, eye)
	c.draw_line(Vector2(-4, hy - 8), Vector2(4, hy - 8), OUT, 0.8)
	var mouth_o := 8.0 + (8.0 if winding else 0.0)
	BA._poly(c, [Vector2(-14, hy + 20), Vector2(14, hy + 20), Vector2(10, hy + 22 + mouth_o), Vector2(-10, hy + 22 + mouth_o)], Color("2a0a08"), f, 1.2)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, hy + 22), Vector2(10, hy + 22), Vector2(6, hy + 22 + mouth_o * 0.8), Vector2(-6, hy + 22 + mouth_o * 0.8)]), Color(fire, 0.85))
	for k in 5:
		BA._poly(c, [Vector2(-12 + k * 6, hy + 20), Vector2(-9 + k * 6, hy + 26), Vector2(-6 + k * 6, hy + 20)], bone, f, 0.6)
	for k in 3:
		_flame(c, Vector2(-6 + k * 6, hy + 24 + mouth_o * 0.5), 10.0 + mouth_o * 0.6, t + k, fire, 3.0)
	# matted beard with ember sparks and charred hair
	for k in 9:
		var bx := -16.0 + k * 4.0
		BA._poly(c, [Vector2(bx - 2.5, hy + 32), Vector2(bx + sin(t * 2.0 + k) * 1.5, hy + 52 + (k % 3) * 5), Vector2(bx + 2.5, hy + 32)], Color("2a1c18"), f, 0.8)
	for k in 7:
		var u := fmod(t * 0.9 + k * 0.14, 1.0)
		c.draw_rect(Rect2(-18 + k * 6, hy + 38 - u * 50, 2, 2), Color(fire, 1.0 - u))
	for k in 5:
		c.draw_line(Vector2(-18 + k * 9, hy - 22 + abs(k - 2)), Vector2(-24 + k * 12, hy - 40 - (k % 2) * 6), Color("1c1210"), 3.0)
	# lava cracks and embers around the feet
	for i in 5:
		var u := fmod(t * 0.5 + i * 0.2, 1.0)
		c.draw_rect(Rect2(-50 + i * 24, -u * 140, 2, 2), Color(fire, 0.9 * (1.0 - u)))
