extends RefCounted
## Ornate gothic bodies for the later bosses, drawn in world-pixel units (origin at the feet), using the shared helpers of boss_art.gd.
## Strigoi of Poenari (Wallachia), Ankou of the Ossuary (Brittany/Paris), Barghest of Whitby (Yorkshire),
## Il Medico della Peste (Venice, 1630 plague) and Cacus of the Aventine (Rome).

const BA = preload("res://src/entities/boss_art.gd")
const OUT := Color("0e0a14")
const B3 = preload("res://src/entities/boss_art3.gd")


static func draw(kind: String, c: CanvasItem, t: float, ph: int, flash: float, winding: bool, exposed: float, moving: bool) -> void:
	match kind:
		"strigoi_giant":
			strigoi(c, t, ph, flash, winding, exposed, moving)
		"ankou_giant":
			ankou(c, t, ph, flash, winding, exposed, moving)
		"barghest_giant":
			B3.barghest(c, t, ph, flash, winding, exposed, moving)
		"plague_giant":
			B3.plague(c, t, ph, flash, winding, exposed, moving)
		"cacus_giant":
			B3.cacus(c, t, ph, flash, winding, exposed, moving)


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
