extends Node2D
## Seeded environmental detail scattered over open floor: ground clutter, wall-side growth, and slow ambient motion.

const T := 16.0

var level: Node2D
var items: Array = []
var t := 0.0
var theme := ""


func _ready() -> void:
	z_index = -1
	theme = level.theme
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level.map_name)
	var g: Array = level.grid
	for y in range(1, level.h - 1):
		for x in range(1, level.w - 1):
			if g[y][x] != ".":
				continue
			var near_wall: bool = g[y - 1][x] == "#" or g[y][x - 1] == "#" or g[y][x + 1] == "#"
			var roll := rng.randf()
			var p := Vector2(x * T + rng.randf_range(3, 13), y * T + rng.randf_range(3, 13))
			var kinds: Array = _kinds(near_wall, g[y - 1][x] == "#")
			if roll < (0.16 if near_wall else 0.07) and not kinds.is_empty():
				items.append({"k": kinds[rng.randi() % kinds.size()], "p": p, "s": rng.randf_range(0.7, 1.3), "r": rng.randf() * TAU})
	queue_redraw()


func _kinds(near_wall: bool, top_wall: bool) -> Array:
	match theme:
		"vault", "prague":
			if top_wall:
				return ["web", "chain", "chain", "moss"]
			if near_wall:
				return ["rubble", "bones", "moss", "web", "crack"]
			return ["crack", "bones", "puddle", "rubble", "blood", "puddle"]
		"chapel":
			return ["wax", "crack", "petals", "moss"] if near_wall else ["crack", "wax", "petals"]
		"town_e", "town_p":
			return ["weeds", "moss", "puddle", "litter"] if near_wall else ["puddle", "litter", "straw", "crack", "puddle", "weeds"]
	return []


func _process(delta: float) -> void:
	t += delta
	if theme == "vault" or theme == "prague" or theme == "town_e" or theme == "town_p":
		queue_redraw()


func _draw() -> void:
	for it in items:
		var p: Vector2 = it.p
		var s: float = it.s
		match it.k:
			"crack":
				var a: float = it.r
				var q := p
				for i in 4:
					var n := q + Vector2.from_angle(a + sin(i * 2.1 + p.x) * 0.7) * 4.0 * s
					draw_line(q, n, Color(0, 0, 0, 0.5), 1.0)
					q = n
			"bones":
				draw_line(p + Vector2(-3, -1) * s, p + Vector2(3, 1) * s, Color(0.78, 0.74, 0.62, 0.85), 1.4)
				draw_circle(p + Vector2(-3, -1) * s, 1.3, Color(0.78, 0.74, 0.62, 0.85))
				draw_circle(p + Vector2(3, 1) * s, 1.3, Color(0.78, 0.74, 0.62, 0.85))
				draw_circle(p + Vector2(1, 3) * s, 2.0, Color(0.82, 0.8, 0.7, 0.85))
				draw_circle(p + Vector2(0.5, 3) * s, 0.6, Color(0.1, 0.08, 0.08))
			"rubble":
				for i in 4:
					var o := Vector2(sin(i * 1.9 + p.y), cos(i * 2.3 + p.x)) * 3.0
					draw_rect(Rect2(p + o, Vector2(2.0, 1.6) * s), Color(0.28, 0.27, 0.32).lightened(0.05 * i))
			"moss":
				for i in 5:
					draw_circle(p + Vector2(sin(i * 2.4 + p.x), cos(i * 1.7)) * 3.0, 1.5, Color(0.2, 0.34, 0.2, 0.55))
			"web":
				var c := Color(0.8, 0.8, 0.9, 0.35)
				for i in 4:
					draw_line(p, p + Vector2(7 * s, 0).rotated(i * 0.4), c, 0.7)
				draw_arc(p, 4.0 * s, 0, 1.6, 6, c, 0.7)
				draw_arc(p, 7.0 * s, 0, 1.6, 8, c, 0.7)
			"chain":
				var sw := sin(t * 1.1 + p.x) * 1.5
				for i in 4:
					draw_rect(Rect2(p + Vector2(sw * i * 0.3 - 1, i * 3.5 - 3), Vector2(2, 2.6)), Color(0.38, 0.36, 0.42))
			"blood":
				draw_circle(p, 3.0 * s, Color(0.35, 0.03, 0.05, 0.5))
				draw_circle(p + Vector2(3, 1), 1.6 * s, Color(0.35, 0.03, 0.05, 0.5))
			"puddle":
				var col := Color(0.05, 0.08, 0.16, 0.6)
				draw_set_transform(p, 0, Vector2(1, 0.55))
				draw_circle(Vector2.ZERO, 5.5 * s, col)
				draw_circle(Vector2.ZERO, 5.5 * s, Color(0.5, 0.6, 0.8, 0.0))
				draw_arc(Vector2.ZERO, 5.5 * s, 0, TAU, 14, Color(0.5, 0.6, 0.85, 0.25), 1.0)
				var rp := fmod(t * 0.6 + p.x * 0.13, 1.0)
				draw_arc(Vector2.ZERO, rp * 4.5 * s, 0, TAU, 12, Color(0.7, 0.8, 1.0, 0.35 * (1.0 - rp)), 1.0)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			"wax":
				draw_circle(p, 2.2 * s, Color(0.85, 0.8, 0.65, 0.7))
				draw_circle(p + Vector2(2, 1), 1.2, Color(0.85, 0.8, 0.65, 0.6))
			"petals":
				for i in 3:
					draw_circle(p + Vector2(i * 2.5, sin(i * 3.0) * 2.0), 1.0, Color(0.5, 0.1, 0.18, 0.7))
			"weeds":
				for i in 3:
					draw_line(p + Vector2(i * 1.5, 0), p + Vector2(i * 1.5 + sin(t + i + p.x) * 0.8 - 1, -4.0 * s), Color(0.25, 0.4, 0.22), 1.0)
			"litter":
				draw_rect(Rect2(p, Vector2(3, 2) * s), Color(0.7, 0.66, 0.55, 0.6))
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(2, 2)), Color(0.55, 0.5, 0.42, 0.6))
			"straw":
				for i in 5:
					draw_line(p + Vector2(i, 0), p + Vector2(i + 2.5, 1.5 - i % 3), Color(0.72, 0.6, 0.3, 0.8), 1.0)
