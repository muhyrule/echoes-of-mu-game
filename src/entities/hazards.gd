extends Node2D
## Boss attack layer: telegraphed strikes, rings, projectiles and lingering zones (global coordinates).

var level: Node2D
var player: Node2D
var items: Array = []
var time := 0.0


func _ready() -> void:
	top_level = true
	add_to_group("hazards")
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


func cancel_near(pos: Vector2, r: float) -> void:
	for h in items.duplicate():
		if h.kind == "shot" and h.pos.distance_to(pos) < r:
			level.spark(h.pos, h.col, 6)
			items.erase(h)
		elif h.kind == "ring" and absf(pos.distance_to(h.pos) - h.speed * h.t) < r * 0.6:
			h.hit = true
			h.speed = 0.0
			h.life = 0.0
			h.warn = 0.0
			h.t = 99.0


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


func wave(pos: Vector2, dir: Vector2, speed: float, span: float, thick: float, gap: float, gap_half: float, warn: float, length: float, dmg: int, col: Color) -> void:
	add({"kind": "wave", "pos": pos, "dir": dir.normalized(), "speed": speed, "span": span, "thick": thick, "gap": gap, "gap_half": gap_half, "warn": warn, "dmg": dmg, "col": col, "life": length / speed})


func whirl(pos: Vector2, r: float, warn: float, life: float, col: Color) -> void:
	add({"kind": "whirl", "pos": pos, "r": r, "warn": warn, "life": life, "col": col, "dmg": 1, "cool": 0.0})


func sweep(pos: Vector2, a0: float, rot: float, length: float, width: float, warn: float, life: float, dmg: int, col: Color) -> void:
	add({"kind": "sweep", "pos": pos, "a0": a0, "rot": rot, "len": length, "width": width, "warn": warn, "life": life, "dmg": dmg, "col": col})


func _splash(pos: Vector2, r: float) -> void:
	var afx = level.get("arena_fx")
	if afx != null:
		afx.splash(pos, r)


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
					_splash(h.pos, h.r)
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
			"wave":
				if active:
					var rel4: Vector2 = pp - h.pos
					var front: float = h.speed * (h.t - h.warn)
					var perp: float = rel4.dot(h.dir.orthogonal())
					if not h.fired:
						h.fired = true
						Audio.sfx("roar")
						level.shake(5.0)
					if absf(rel4.dot(h.dir) - front) < h.thick * 0.5 + 3.0 and absf(perp) < h.span and absf(perp - h.gap) > h.gap_half:
						player.hurt(h.dmg, h.dir)
					if int(h.t * 30.0) % 3 == 0:
						_splash(h.pos + h.dir * front + h.dir.orthogonal() * randf_range(-h.span, h.span), 10.0)
			"whirl":
				h.cool -= delta
				if active:
					var rel5: Vector2 = h.pos - pp
					var d5 := rel5.length()
					if d5 < h.r and d5 > 4.0:
						var np: Vector2 = player.global_position + rel5.normalized() * (28.0 + 40.0 * (1.0 - d5 / h.r)) * delta
						if not level._is_solid_char(Vector2i(int(np.x / 16.0), int(np.y / 16.0))):
							player.global_position = np
					if d5 < h.r * 0.22 and h.cool <= 0.0:
						h.cool = 0.9
						player.hurt(h.dmg, -rel5.normalized())
					if int(h.t * 20.0) % 4 == 0:
						_splash(h.pos + Vector2.from_angle(randf() * TAU) * h.r * randf_range(0.3, 1.0), 6.0)
			"sweep":
				if active:
					var ang: float = h.a0 + h.rot * (h.t - h.warn)
					var rel6: Vector2 = pp - h.pos
					var dv := Vector2.from_angle(ang)
					var al: float = rel6.dot(dv)
					if al > 10.0 and al < h.len and absf(rel6.cross(dv)) < h.width * 0.5 + 3.0:
						player.hurt(h.dmg, rel6.normalized())
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
					if h.tag == "steam":
						var rise: float = (1.0 - f)
						for j in 5:
							var jx: float = (j - 2) * h.r * 0.32
							draw_rect(Rect2(h.pos + Vector2(jx - 2, -rise * (60.0 + j % 2 * 20.0)), Vector2(4, rise * (60.0 + j % 2 * 20.0))), Color(0.85, 1.0, 1.0, 0.7 * f))
						for j in 8:
							var da: float = j * TAU / 8.0
							draw_rect(Rect2(h.pos + Vector2(cos(da) * h.r * (0.4 + rise), -sin(rise * PI) * 40.0 - rise * 20.0 + sin(da) * 4.0), Vector2(2, 2)), Color(1, 1, 1, 0.8 * f))
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
			"wave":
				_draw_wave(h)
			"whirl":
				_draw_whirl(h)
			"sweep":
				_draw_sweep(h)
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


func _draw_wave(h: Dictionary) -> void:
	var col: Color = h.col
	var d: Vector2 = h.dir
	var o: Vector2 = d.orthogonal()
	var warning: bool = h.t < h.warn
	var front: float = h.speed * maxf(0.0, h.t - h.warn)
	var step := 6.0
	if warning:
		var p: float = h.t / maxf(h.warn, 0.001)
		for u in range(-int(h.span), int(h.span), 10):
			if absf(float(u) - h.gap) < h.gap_half:
				continue
			var a: Vector2 = h.pos + o * float(u)
			draw_line(a, a + d * h.speed * 0.9 * p, Color(col, 0.18), 1.0)
			draw_rect(Rect2(a - Vector2(1, 1), Vector2(2, 2)), Color(col, 0.5 + 0.3 * sin(h.t * 20.0 + u)))
		var g: Vector2 = h.pos + o * h.gap
		draw_line(g, g + d * 200.0, Color(0.6, 1.0, 0.7, 0.35 + 0.2 * sin(h.t * 12.0)), 2.0)
		return
	var crest := PackedVector2Array()
	var u2: float = -h.span
	while u2 <= h.span:
		if absf(u2 - h.gap) >= h.gap_half:
			var base: Vector2 = h.pos + d * front + o * u2
			var bump: float = sin(u2 * 0.12 + h.t * 9.0) * 3.0
			draw_line(base - d * h.thick * 0.5, base + d * (bump + 4.0), Color(col, 0.55), step)
			draw_line(base - d * h.thick * 0.2, base + d * (bump + 6.0), Color(col.lightened(0.4), 0.9), step * 0.6)
			if int(u2 / step) % 3 == 0:
				draw_rect(Rect2(base + d * (bump + 7.0 + fmod(h.t * 40.0 + u2, 8.0)) - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, 0.9))
				draw_rect(Rect2(base - d * (h.thick * 0.5 + 4.0 + fmod(h.t * 30.0 + u2, 14.0)) - Vector2(1, 1), Vector2(2, 2)), Color(col, 0.5))
		u2 += step


func _draw_whirl(h: Dictionary) -> void:
	var col: Color = h.col
	var a: float = minf(1.0, h.t / maxf(h.warn, 0.001)) * clampf((h.warn + h.life - h.t) / 0.6, 0.0, 1.0)
	draw_circle(h.pos, h.r, Color(col.darkened(0.5), 0.35 * a))
	for k in 4:
		var rr: float = h.r * (0.3 + k * 0.23)
		var s0: float = h.t * (3.0 + k * 0.8) * (1.0 if k % 2 == 0 else -1.0)
		draw_arc(h.pos, rr, s0, s0 + TAU * 0.7, 28, Color(col, 0.6 * a), 2.0)
		draw_arc(h.pos, rr * 0.96, s0 + 0.2, s0 + TAU * 0.5, 20, Color(1, 1, 1, 0.5 * a), 1.0)
	draw_circle(h.pos, h.r * 0.2, Color(0.02, 0.06, 0.1, 0.8 * a))
	draw_arc(h.pos, h.r, 0, TAU, 40, Color(col, 0.7 * a), 1.6)


func _draw_sweep(h: Dictionary) -> void:
	var col: Color = h.col
	if h.t < h.warn:
		var p: float = h.t / maxf(h.warn, 0.001)
		var dv := Vector2.from_angle(h.a0)
		draw_line(h.pos, h.pos + dv * h.len, Color(col, 0.2 + 0.4 * p), 1.0 + 2.0 * p)
		draw_arc(h.pos, h.len * 0.5, h.a0, h.a0 + h.rot * h.life, 24, Color(col, 0.25), 1.0)
		return
	var ang: float = h.a0 + h.rot * (h.t - h.warn)
	for k in 6:
		var a2: float = ang - h.rot * 0.03 * k
		var dv2 := Vector2.from_angle(a2)
		var f: float = 1.0 - k / 6.0
		var n: Vector2 = dv2.orthogonal() * h.width * 0.5 * f
		draw_colored_polygon(PackedVector2Array([h.pos - n, h.pos + dv2 * h.len - n, h.pos + dv2 * h.len + n, h.pos + n]), Color(col, 0.45 * f))
	var dv3 := Vector2.from_angle(ang)
	draw_line(h.pos, h.pos + dv3 * h.len, Color(1, 1, 0.85, 0.95), 3.0)
	for j in 10:
		var sp: Vector2 = h.pos + dv3 * (30.0 + fmod(h.t * 300.0 + j * 40.0, h.len - 30.0))
		draw_rect(Rect2(sp + dv3.orthogonal() * sin(h.t * 30.0 + j) * 6.0 - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.9, 0.5, 0.9))


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
