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
			B3.strigoi(c, t, ph, flash, winding, exposed, moving)
		"ankou_giant":
			B3.ankou(c, t, ph, flash, winding, exposed, moving)
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
