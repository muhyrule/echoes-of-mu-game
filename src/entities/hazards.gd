extends Node2D
## Boss attack layer: telegraphed strikes, rings, projectiles and lingering zones (global coordinates).

var level: Node2D
var player: Node2D
var items: Array = []
var time := 0.0


func _ready() -> void:
	top_level = true
	z_index = 3


func add(h: Dictionary) -> Dictionary:
	h["t"] = 0.0
	h["hit"] = false
	h["fired"] = false
	if not h.has("warn"):
		h["warn"] = 0.0
	if not h.has("life"):
		h["life"] = 0.2
	items.append(h)
	return h


func clear() -> void:
	items.clear()


func count_kind(k: String) -> int:
	var n := 0
	for h in items:
		if h.kind == k:
			n += 1
	return n


func circle(pos: Vector2, r: float, warn: float, dmg: int, col: Color, life := 0.25, tag := "") -> void:
	add({"kind": "circle", "pos": pos, "r": r, "warn": warn, "dmg": dmg, "col": col, "life": life, "tag": tag})


func line(pos: Vector2, dir: Vector2, length: float, width: float, warn: float, dmg: int, col: Color, life := 0.22) -> void:
	add({"kind": "line", "pos": pos, "dir": dir.normalized(), "len": length, "width": width, "warn": warn, "dmg": dmg, "col": col, "life": life})


func cone(pos: Vector2, dir: Vector2, reach: float, half: float, warn: float, dmg: int, col: Color, life := 0.25) -> void:
	add({"kind": "cone", "pos": pos, "dir": dir.normalized(), "len": reach, "half": half, "warn": warn, "dmg": dmg, "col": col, "life": life})


func ring(pos: Vector2, speed: float, width: float, gap_dir: float, gap_half: float, dmg: int, col: Color, max_r := 340.0) -> void:
	add({"kind": "ring", "pos": pos, "speed": speed, "width": width, "gap": gap_dir, "gap_half": gap_half, "dmg": dmg, "col": col, "max": max_r, "life": max_r / speed})


func shot(pos: Vector2, vel: Vector2, r: float, life: float, dmg: int, col: Color, style := "cog") -> void:
	add({"kind": "shot", "pos": pos, "vel": vel, "r": r, "life": life, "dmg": dmg, "col": col, "style": style})


func zone(pos: Vector2, r: float, life: float, col: Color) -> void:
	add({"kind": "zone", "pos": pos, "r": r, "life": life, "col": col, "warn": 0.6})


func _physics_process(delta: float) -> void:
	if Dialogue.blocking() or level.frozen:
		queue_redraw()
		return
	time += delta
	var pp := player.global_position + Vector2(0, -3)
	for h in items.duplicate():
		h.t += delta
		var active: bool = h.t >= h.warn
		if h.get("dmg", 1) <= 0:
			if h.t > h.warn + h.life:
				items.erase(h)
			continue
		match h.kind:
			"circle":
				if active and not h.fired:
					h.fired = true
					level.shake(3.0)
					level.spark(h.pos, h.col, 10)
					if h.tag == "bell":
						Audio.sfx("bell")
					else:
						Audio.sfx("hit")
				if active and not h.hit and pp.distance_to(h.pos) < h.r + 4.0:
					h.hit = true
					player.hurt(h.dmg, (pp - h.pos).normalized())
			"line":
				if active and not h.fired:
					h.fired = true
					level.shake(2.5)
					Audio.sfx("hit")
				if active and not h.hit:
					var rel: Vector2 = pp - h.pos
					var along: float = rel.dot(h.dir)
					var perp: float = absf(rel.cross(h.dir))
					if along > -4.0 and along < h.len and perp < h.width * 0.5 + 4.0:
						h.hit = true
						player.hurt(h.dmg, (pp - (h.pos + h.dir * clampf(along, 0.0, h.len))).normalized())
			"cone":
				if active and not h.fired:
					h.fired = true
					level.shake(3.0)
					Audio.sfx("roar")
				if active and not h.hit:
					var rel2: Vector2 = pp - h.pos
					if rel2.length() < h.len and absf(angle_difference(rel2.angle(), h.dir.angle())) < h.half:
						h.hit = true
						player.hurt(h.dmg, rel2.normalized())
			"ring":
				var r: float = h.speed * h.t
				var rel3: Vector2 = pp - h.pos
				if absf(rel3.length() - r) < h.width * 0.5 + 3.0 and absf(angle_difference(rel3.angle(), h.gap)) > h.gap_half:
					player.hurt(h.dmg, rel3.normalized())
			"shot":
				h.pos += h.vel * delta
				if pp.distance_to(h.pos) < h.r + 4.0:
					player.hurt(h.dmg, h.vel.normalized())
					h.hit = true
					level.spark(h.pos, h.col, 6)
				elif level._is_solid_char(Vector2i(int(h.pos.x / 16.0), int(h.pos.y / 16.0))):
					h.hit = true
					level.spark(h.pos, h.col, 4)
			"zone":
				if active and pp.distance_to(h.pos) < h.r:
					player.slow = 0.35
		if h.hit and h.kind == "shot":
			items.erase(h)
		elif h.t > h.warn + h.life:
			items.erase(h)
	queue_redraw()


func _draw() -> void:
	for h in items:
		var warning: bool = h.t < h.warn
		var p: float = clampf(h.t / maxf(h.warn, 0.001), 0.0, 1.0)
		var col: Color = h.col
		match h.kind:
			"circle":
				if warning:
					draw_circle(h.pos, h.r, Color(col, 0.10 + 0.14 * p))
					draw_circle(h.pos, h.r * p, Color(col, 0.25))
					draw_arc(h.pos, h.r, 0, TAU, 40, Color(col, 0.55 + 0.3 * sin(h.t * 20.0)), 1.6)
				else:
					var f: float = 1.0 - (h.t - h.warn) / h.life
					draw_circle(h.pos, h.r, Color(1, 1, 1, 0.5 * f))
					draw_circle(h.pos, h.r * (1.0 + (1.0 - f) * 0.3), Color(col, 0.55 * f))
			"line":
				var n: Vector2 = h.dir.orthogonal() * h.width * 0.5
				var a: Vector2 = h.pos
				var b: Vector2 = h.pos + h.dir * h.len
				if warning:
					var thin: Vector2 = n * (0.25 + 0.2 * p)
					draw_colored_polygon(PackedVector2Array([a - thin, b - thin, b + thin, a + thin]), Color(col, 0.20 + 0.15 * p))
					draw_line(a - n, b - n, Color(col, 0.5), 1.0)
					draw_line(a + n, b + n, Color(col, 0.5), 1.0)
					var fill: Vector2 = a + h.dir * h.len * p
					draw_colored_polygon(PackedVector2Array([a - n, fill - n, fill + n, a + n]), Color(col, 0.18))
				else:
					var f2: float = 1.0 - (h.t - h.warn) / h.life
					draw_colored_polygon(PackedVector2Array([a - n, b - n, b + n, a + n]), Color(col, 0.7 * f2))
					var core: Vector2 = n * 0.35
					draw_colored_polygon(PackedVector2Array([a - core, b - core, b + core, a + core]), Color(1, 1, 1, 0.85 * f2))
			"cone":
				var pts := PackedVector2Array([h.pos])
				var base: float = h.dir.angle()
				for i in 13:
					pts.append(h.pos + Vector2.from_angle(base - h.half + h.half * 2.0 * float(i) / 12.0) * h.len)
				if warning:
					draw_colored_polygon(pts, Color(col, 0.10 + 0.14 * p))
					draw_polyline(pts, Color(col, 0.6), 1.2)
				else:
					var f3: float = 1.0 - (h.t - h.warn) / h.life
					draw_colored_polygon(pts, Color(col, 0.65 * f3))
			"ring":
				var r: float = h.speed * h.t
				var g0: float = h.gap + h.gap_half
				var g1: float = h.gap + TAU - h.gap_half
				var fade: float = clampf(1.0 - r / h.max * 0.5, 0.4, 1.0)
				draw_arc(h.pos, r, g0, g1, 72, Color(col, 0.25 * fade), h.width * 2.0)
				draw_arc(h.pos, r, g0, g1, 72, Color(col, 0.9 * fade), h.width)
				draw_arc(h.pos, r, g0, g1, 72, Color(1, 1, 1, 0.8 * fade), maxf(1.0, h.width * 0.25))
			"shot":
				_draw_shot(h)
			"zone":
				var a2: float = minf(1.0, h.t / 0.6) * clampf((h.warn + h.life - h.t) / 0.8, 0.0, 1.0)
				draw_circle(h.pos, h.r, Color(col, 0.10 * a2))
				draw_arc(h.pos, h.r, 0, TAU, 40, Color(col, 0.55 * a2), 1.4)
				draw_arc(h.pos, h.r * 0.6, h.t * -1.4, h.t * -1.4 + TAU * 0.8, 24, Color(col, 0.35 * a2), 1.0)
				for i in 12:
					var ang := TAU * float(i) / 12.0
					draw_line(h.pos + Vector2.from_angle(ang) * h.r * 0.9, h.pos + Vector2.from_angle(ang) * h.r, Color(col, 0.6 * a2), 1.0)
				var hand: Vector2 = Vector2.from_angle(h.t * 2.4) * h.r * 0.7
				draw_line(h.pos, h.pos + hand, Color(col, 0.7 * a2), 1.4)


func _draw_shot(h: Dictionary) -> void:
	var pos: Vector2 = h.pos
	var r: float = h.r
	var col: Color = h.col
	draw_circle(pos, r * 2.2, Color(col, 0.12))
	if h.style == "cog":
		var spin: float = h.t * 9.0
		var pts := PackedVector2Array()
		for i in 16:
			var rr := r * (1.25 if i % 2 == 0 else 0.9)
			pts.append(pos + Vector2.from_angle(spin + TAU * float(i) / 16.0) * rr)
		draw_colored_polygon(pts, Color("1c1520"))
		draw_circle(pos, r * 0.95, col)
		draw_circle(pos, r * 0.45, Color("2a2018"))
		draw_arc(pos, r * 0.95, spin, spin + 2.0, 10, Color(1, 1, 0.8, 0.8), 1.0)
	else:
		draw_circle(pos, r, Color("1c1520"))
		draw_circle(pos, r * 0.75, col)
		draw_circle(pos + Vector2(-r * 0.2, -r * 0.25), r * 0.3, Color(1, 1, 1, 0.7))
