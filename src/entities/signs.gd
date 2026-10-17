extends Node2D
## Pictorial hanging signs above every door/gate on a map, so players can read a building by its emblem.

const T := 16.0
const ICONS := {
	"marsh_cottage": "reeds", "mason_yard": "chisel", "drowned_candle": "mug", "archive": "book",
	"chandlery": "candle", "apothecary": "flask", "armoury": "shield", "weaponsmith": "sword",
	"lantern_inn": "lantern", "vaults": "skull", "raven_tavern": "raven", "orloj_lodge": "clock",
	"alchemist": "flask", "cartographer": "compass", "bakery": "loaf", "silver_retort": "retort",
	"guild_armoury": "shield", "bohemian_steel": "anvil", "rose_inn": "rose", "prague": "skull",
	"keep_arena": "tower", "ossuary_arena": "skull", "cliff_arena": "anchor", "lazaretto_arena": "mask",
	"cave_arena": "flame",
}
const TINT := {
	"reeds": Color("6a9a5a"), "chisel": Color("b0b0bc"), "mug": Color("d8a040"), "book": Color("a05a3a"),
	"candle": Color("f0d890"), "flask": Color("7ac8a0"), "shield": Color("8aa0d0"), "sword": Color("d0d4e0"),
	"lantern": Color("f0b050"), "skull": Color("e8e4d0"), "raven": Color("9a8ad0"), "clock": Color("e0c060"),
	"compass": Color("d0b070"), "loaf": Color("d89a50"), "retort": Color("c070d0"), "anvil": Color("a8a8b8"),
	"rose": Color("e05070"), "tower": Color("c0b090"), "anchor": Color("70a0d0"), "mask": Color("e0e0f0"),
	"flame": Color("f08040"),
}

var level: Node2D
var t := 0.0
var signs: Array = []


func _ready() -> void:
	z_index = 3
	var doors: Dictionary = level.meta.get("doors", {})
	var rows: Array = level.meta.get("ascii", [])
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row.substr(x, 1)
			if doors.has(ch) and ICONS.has(str(doors[ch].get("map", ""))):
				if y > 0 and (signs.is_empty() or not _near(x, y)):
					signs.append({"p": Vector2(x * T + 8.0, y * T - 11.0), "i": ICONS[doors[ch].map], "x": x, "y": y})


func _near(x: int, y: int) -> bool:
	for s in signs:
		if absi(s.x - x) <= 1 and absi(s.y - y) <= 1:
			return true
	return false


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	for s in signs:
		var sway := sin(t * 1.3 + s.p.x) * 0.04
		draw_set_transform(s.p + Vector2(0, -6), sway, Vector2.ONE)
		_plaque(s.i)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _plaque(icon: String) -> void:
	var c: Color = TINT.get(icon, Color.WHITE)
	draw_line(Vector2(-9, -2), Vector2(9, -2), Color("2a2018"), 2.0)
	draw_line(Vector2(-7, -2), Vector2(-7, 2), Color("2a2018"), 1.0)
	draw_line(Vector2(7, -2), Vector2(7, 2), Color("2a2018"), 1.0)
	draw_rect(Rect2(-10, 2, 20, 18), Color("120d0a"))
	draw_rect(Rect2(-9, 3, 18, 16), Color("4a3524"))
	draw_rect(Rect2(-8, 4, 16, 14), Color("1c1410"))
	draw_rect(Rect2(-9, 3, 18, 16), Color("8a6a3a"), false, 1.0)
	var o := Vector2(0, 11)
	match icon:
		"reeds":
			for k in 3:
				draw_line(o + Vector2(-4 + k * 4, 6), o + Vector2(-5 + k * 5, -5), c, 1.2)
				draw_circle(o + Vector2(-5 + k * 5, -5), 1.4, Color("8a5a30"))
		"chisel":
			draw_rect(Rect2(o + Vector2(-5, 0), Vector2(8, 6)), Color("807a88"))
			draw_line(o + Vector2(2, -2), o + Vector2(6, -6), c, 1.6)
			draw_line(o + Vector2(0, 0), o + Vector2(3, -3), Color("c08040"), 2.0)
		"mug":
			draw_rect(Rect2(o + Vector2(-4, -3), Vector2(7, 8)), c)
			draw_arc(o + Vector2(4, 1), 2.5, -1.6, 1.6, 6, c, 1.2)
			draw_rect(Rect2(o + Vector2(-4, -5), Vector2(7, 2)), Color("f8f0e0"))
		"book":
			draw_rect(Rect2(o + Vector2(-5, -4), Vector2(10, 9)), c)
			draw_line(o + Vector2(0, -4), o + Vector2(0, 5), Color("f0d8a0"), 1.0)
			draw_rect(Rect2(o + Vector2(-4, -3), Vector2(3, 1)), Color("f0d8a0"))
		"candle":
			draw_rect(Rect2(o + Vector2(-2, -1), Vector2(4, 7)), c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(-2, -2), o + Vector2(2, -2), o + Vector2(0, -7)]), Color("ff9a30"))
		"flask":
			draw_rect(Rect2(o + Vector2(-1.5, -6), Vector2(3, 4)), Color("c0c8d0"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(-1.5, -2), o + Vector2(1.5, -2), o + Vector2(5, 5), o + Vector2(-5, 5)]), c)
			draw_circle(o + Vector2(0, 2), 1.0, Color("e8fff0"))
		"shield":
			draw_colored_polygon(PackedVector2Array([o + Vector2(-5, -5), o + Vector2(5, -5), o + Vector2(5, 1), o + Vector2(0, 7), o + Vector2(-5, 1)]), c)
			draw_line(o + Vector2(0, -5), o + Vector2(0, 6), Color("2a3a6a"), 1.4)
			draw_line(o + Vector2(-5, -1), o + Vector2(5, -1), Color("2a3a6a"), 1.4)
		"sword":
			draw_line(o + Vector2(0, 7), o + Vector2(0, -6), c, 2.0)
			draw_line(o + Vector2(-4, 2), o + Vector2(4, 2), Color("c0a050"), 1.6)
			draw_circle(o + Vector2(0, 7), 1.2, Color("c0a050"))
		"lantern":
			draw_arc(o + Vector2(0, -4), 3.0, PI, TAU, 6, c, 1.0)
			draw_rect(Rect2(o + Vector2(-4, -3), Vector2(8, 9)), Color("6a4a20"))
			draw_rect(Rect2(o + Vector2(-3, -2), Vector2(6, 7)), c)
		"skull":
			draw_circle(o + Vector2(0, -1), 5.0, c)
			draw_rect(Rect2(o + Vector2(-3, 2), Vector2(6, 4)), c)
			draw_circle(o + Vector2(-2, -1), 1.4, Color("120d0a"))
			draw_circle(o + Vector2(2, -1), 1.4, Color("120d0a"))
		"raven":
			draw_circle(o + Vector2(0, 0), 4.0, c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(3, -2), o + Vector2(7, 0), o + Vector2(3, 1)]), Color("e0b040"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(-3, 0), o + Vector2(-8, 4), o + Vector2(-2, 3)]), c.darkened(0.3))
			draw_circle(o + Vector2(1.5, -1), 0.8, Color.WHITE)
		"clock":
			draw_circle(o, 6.0, c)
			draw_circle(o, 4.6, Color("1c1410"))
			draw_line(o, o + Vector2(0, -3.5), c, 1.0)
			draw_line(o, o + Vector2(2.5, 1), c, 1.0)
		"compass":
			draw_arc(o, 6.0, 0, TAU, 14, c, 1.0)
			draw_colored_polygon(PackedVector2Array([o + Vector2(-2, 0), o + Vector2(0, -6), o + Vector2(2, 0)]), Color("d05050"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(-2, 0), o + Vector2(0, 6), o + Vector2(2, 0)]), c)
		"loaf":
			draw_circle(o + Vector2(-2, 0), 4.0, c)
			draw_circle(o + Vector2(2, 0), 4.0, c)
			draw_rect(Rect2(o + Vector2(-2, -4), Vector2(4, 8)), c)
			for k in 3:
				draw_line(o + Vector2(-3 + k * 3, -3), o + Vector2(-2 + k * 3, 1), Color("a06a30"), 1.0)
		"retort":
			draw_circle(o + Vector2(-1, 2), 4.0, c)
			draw_line(o + Vector2(1, -1), o + Vector2(6, -5), c, 1.6)
			draw_circle(o + Vector2(-1, 2), 2.0, Color("e8d0f8"))
		"anvil":
			draw_rect(Rect2(o + Vector2(-6, -3), Vector2(12, 3)), c)
			draw_rect(Rect2(o + Vector2(-2, 0), Vector2(4, 4)), c.darkened(0.2))
			draw_rect(Rect2(o + Vector2(-5, 4), Vector2(10, 2)), c.darkened(0.3))
		"rose":
			for k in 5:
				draw_circle(o + Vector2(0, -2) + Vector2.from_angle(k * 1.257) * 3.0, 2.2, c)
			draw_circle(o + Vector2(0, -2), 1.6, c.darkened(0.4))
			draw_line(o + Vector2(0, 2), o + Vector2(0, 7), Color("4a8a4a"), 1.2)
		"tower":
			draw_rect(Rect2(o + Vector2(-4, -3), Vector2(8, 10)), c)
			for k in 3:
				draw_rect(Rect2(o + Vector2(-4 + k * 3.5, -6), Vector2(2, 3)), c)
			draw_rect(Rect2(o + Vector2(-1.5, 2), Vector2(3, 5)), Color("1c1410"))
		"anchor":
			draw_line(o + Vector2(0, -5), o + Vector2(0, 6), c, 1.4)
			draw_line(o + Vector2(-3, -2), o + Vector2(3, -2), c, 1.2)
			draw_arc(o + Vector2(0, 2), 5.0, 0.2, PI - 0.2, 8, c, 1.4)
			draw_circle(o + Vector2(0, -6), 1.3, c)
		"mask":
			draw_circle(o + Vector2(0, 0), 5.0, c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0, 0), o + Vector2(3, 3), o + Vector2(0, 8)]), c)
			draw_circle(o + Vector2(-2, -1), 1.3, Color("120d0a"))
			draw_circle(o + Vector2(2, -1), 1.3, Color("120d0a"))
		"flame":
			draw_colored_polygon(PackedVector2Array([o + Vector2(-4, 5), o + Vector2(4, 5), o + Vector2(5, -1), o + Vector2(0, -7), o + Vector2(-5, -1)]), c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(-2, 5), o + Vector2(2, 5), o + Vector2(0, -1)]), Color("ffe080"))
