extends RefCounted
## Procedural pixel-style drawing helpers. All art is original and drawn from primitives.

const PAL_MU := {"coat": Color("4b3a6b"), "accent": Color("c0392b"), "skin": Color("e8c39e"), "hair": Color("15121c")}
const PAL_WRAITH := {"coat": Color("6fa8dc"), "accent": Color("d6f1ff"), "skin": Color("cfe8f7"), "hair": Color("2c4a6b")}
const PAL_ISOLDE := {"coat": Color("5d7a5a"), "accent": Color("8e5a2b"), "skin": Color("e2b790"), "hair": Color("a8472a")}
const PAL_ALDOUS := {"coat": Color("2c2c34"), "accent": Color("b79a4b"), "skin": Color("d9b896"), "hair": Color("d8d8e0")}


static func shadow(c: CanvasItem, r := 6.0) -> void:
	c.draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.45))
	c.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.4))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func person(c: CanvasItem, f: Vector2, t: float, pal: Dictionary, moving := false, alpha := 1.0) -> void:
	shadow(c)
	var step := 1 if (moving and int(t * 9.0) % 2 == 0) else 0
	var coat := Color(pal.coat, alpha)
	var acc := Color(pal.accent, alpha)
	var skin := Color(pal.skin, alpha)
	var hair := Color(pal.hair, alpha)
	c.draw_rect(Rect2(-3, 2, 2, 3 - step), coat.darkened(0.4))
	c.draw_rect(Rect2(1, 2, 2, 2 + step), coat.darkened(0.4))
	c.draw_rect(Rect2(-4, -5, 8, 8), coat)
	c.draw_rect(Rect2(-4, -6, 8, 2), acc)
	c.draw_rect(Rect2(-3, -12, 6, 6), skin)
	if f.y < -0.3:
		c.draw_rect(Rect2(-3, -13, 6, 7), hair)
	else:
		c.draw_rect(Rect2(-3, -13, 6, 3), hair)
		if abs(f.x) > 0.3:
			c.draw_rect(Rect2(-3 if f.x > 0 else 1, -12, 2, 5), hair)
			c.draw_rect(Rect2(1 if f.x > 0 else -2, -9, 1, 2), Color(0.1, 0.1, 0.15, alpha))
		else:
			c.draw_rect(Rect2(-2, -9, 1, 2), Color(0.1, 0.1, 0.15, alpha))
			c.draw_rect(Rect2(1, -9, 1, 2), Color(0.1, 0.1, 0.15, alpha))


static func rat(c: CanvasItem, f: Vector2, t: float, flash: float) -> void:
	shadow(c, 5.0)
	var col := Color("7a6552") if flash <= 0 else Color.WHITE
	var s := 1.0 if f.x >= 0 else -1.0
	c.draw_rect(Rect2(-5, -4, 10, 6), col)
	c.draw_rect(Rect2(3 * s - 2, -5, 5, 5), col.lightened(0.1))
	c.draw_rect(Rect2(4 * s, -4, 1, 1), Color("ff3b3b"))
	var wag := sin(t * 12.0) * 2.0
	c.draw_line(Vector2(-5 * s, -1), Vector2(-9 * s, -3 + wag), Color("c9a0a0"), 1.0)
	var leg := 1 if int(t * 10.0) % 2 == 0 else 0
	c.draw_rect(Rect2(-3, 2, 2, 1 + leg), col.darkened(0.3))
	c.draw_rect(Rect2(2, 2, 2, 2 - leg), col.darkened(0.3))


static func bat(c: CanvasItem, t: float, flash: float) -> void:
	var col := Color("3a2f4a") if flash <= 0 else Color.WHITE
	c.draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.4))
	c.draw_circle(Vector2.ZERO, 4, Color(0, 0, 0, 0.3))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var flap := sin(t * 18.0) * 5.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(-9, -6 - flap), Vector2(-6, 1)]), col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(9, -6 - flap), Vector2(6, 1)]), col)
	c.draw_rect(Rect2(-2, -4, 4, 5), col.lightened(0.15))
	c.draw_rect(Rect2(-2, -3, 1, 1), Color("ffd166"))
	c.draw_rect(Rect2(1, -3, 1, 1), Color("ffd166"))


static func warden(c: CanvasItem, f: Vector2, t: float, flash: float, winding: bool) -> void:
	shadow(c, 13.0)
	var steel := Color("6b7080") if flash <= 0 else Color.WHITE
	if winding and int(t * 20.0) % 2 == 0:
		steel = Color("c05050")
	c.draw_rect(Rect2(-9, 4, 6, 7), steel.darkened(0.4))
	c.draw_rect(Rect2(3, 4, 6, 7), steel.darkened(0.4))
	c.draw_rect(Rect2(-12, -14, 24, 20), steel)
	c.draw_rect(Rect2(-15, -16, 8, 8), steel.lightened(0.15))
	c.draw_rect(Rect2(7, -16, 8, 8), steel.lightened(0.15))
	c.draw_rect(Rect2(-7, -28, 14, 14), steel.lightened(0.05))
	c.draw_rect(Rect2(-5, -23, 10, 3), Color("0b0b12"))
	c.draw_rect(Rect2(-4, -22, 3, 1), Color("66e0ff"))
	c.draw_rect(Rect2(1, -22, 3, 1), Color("66e0ff"))
	c.draw_line(Vector2(0, -6), f * 16.0, Color("c9ccd6"), 3.0)
	c.draw_circle(Vector2(-12, 4), 3.0, Color("ffcf70") if int(t * 6.0) % 2 == 0 else Color("e09a3a"))


static func heart(c: CanvasItem, pos: Vector2, size: float, col: Color) -> void:
	c.draw_circle(pos + Vector2(-size * 0.5, 0), size * 0.55, col)
	c.draw_circle(pos + Vector2(size * 0.5, 0), size * 0.55, col)
	c.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-size * 1.0, size * 0.25), pos + Vector2(size * 1.0, size * 0.25), pos + Vector2(0, size * 1.35)]), col)


static func candle(c: CanvasItem, t: float, seed_v: float) -> void:
	c.draw_rect(Rect2(-2, -2, 4, 8), Color("d8cdb0"))
	c.draw_rect(Rect2(-3, 6, 6, 2), Color("5a4a2a"))
	var fl := 2.0 + sin(t * 9.0 + seed_v) * 0.8
	c.draw_circle(Vector2(0, -4), 3.0 + fl * 0.3, Color(1.0, 0.7, 0.2, 0.25))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-1.5, -2), Vector2(1.5, -2), Vector2(0, -6 - fl)]), Color("ffd166"))
