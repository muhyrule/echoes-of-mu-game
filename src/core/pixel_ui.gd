extends RefCounted
## Shared stepped metalwork and parchment for the high-resolution interface.

const INK := Color("10151d")
const GOLD := Color("b79a62")
const LIGHT := Color("ead5a0")
const PAPER := Color("d8cfb7")


static func panel(c: CanvasItem, r: Rect2, opacity := 0.96) -> void:
	c.draw_rect(r.grow(3), Color(0, 0, 0, opacity * 0.6))
	c.draw_rect(r.grow(1), Color(INK, opacity))
	c.draw_rect(r, Color(0.07, 0.09, 0.12, opacity))
	c.draw_rect(r.grow(-1), GOLD.darkened(0.5), false, 1)
	c.draw_line(r.position, Vector2(r.end.x, r.position.y), GOLD, 1)
	c.draw_line(r.position, Vector2(r.position.x, r.end.y), GOLD, 1)
	c.draw_line(Vector2(r.position.x, r.end.y), r.end, GOLD.darkened(0.6), 1)
	c.draw_line(Vector2(r.end.x, r.position.y), r.end, GOLD.darkened(0.6), 1)
	for i in int(r.size.x / 12):
		c.draw_rect(Rect2(r.position + Vector2(8 + i * 12, 3), Vector2(3, 0.5)), Color(GOLD, 0.22))
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var dx := 1.0 if corner.x < r.get_center().x else -1.0
		var dy := 1.0 if corner.y < r.get_center().y else -1.0
		var p: Vector2 = corner + Vector2(dx * 3, dy * 3)
		c.draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), LIGHT)
		c.draw_line(p + Vector2(dx * 3, 0), p + Vector2(dx * 11, 0), GOLD, 1)
		c.draw_line(p + Vector2(0, dy * 3), p + Vector2(0, dy * 8), GOLD, 1)


static func crest(c: CanvasItem, p: Vector2, hero: String, accent: Color) -> void:
	c.draw_rect(Rect2(p - Vector2(9, 10), Vector2(18, 20)), INK)
	c.draw_rect(Rect2(p - Vector2(8, 9), Vector2(16, 18)), accent.darkened(0.65))
	c.draw_rect(Rect2(p - Vector2(8, 9), Vector2(16, 18)), GOLD.darkened(0.3), false, 1)
	match hero:
		"mu":
			c.draw_rect(Rect2(p + Vector2(-1, -7), Vector2(2, 13)), PAPER)
			c.draw_rect(Rect2(p + Vector2(-5, -2), Vector2(10, 2)), GOLD)
			c.draw_rect(Rect2(p + Vector2(-2, 7), Vector2(4, 2)), GOLD)
		"isolde":
			c.draw_rect(Rect2(p + Vector2(-1, -4), Vector2(2, 12)), GOLD)
			c.draw_rect(Rect2(p + Vector2(-5, -7), Vector2(10, 5)), PAPER)
		"wren":
			for side in [-1, 1]:
				c.draw_line(p + Vector2(side * 6, -6), p + Vector2(-side * 4, 5), PAPER, 2)
				c.draw_rect(Rect2(p + Vector2(side * 3 - 1, 3), Vector2(2, 5)), GOLD)
		"corvin":
			c.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), GOLD)
			c.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), INK)
			c.draw_line(p, p + Vector2(0, -3), PAPER, 1)
			c.draw_line(p, p + Vector2(3, 0), PAPER, 1)
