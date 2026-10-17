extends Node2D
## Animated environment layer for themed boss arenas: rippling loch water, or dusty attic light shafts.

var level: Node2D
var t := 0.0
var drops: Array = []
var puddles: Array = []
var last_pos := {}


# Footstep character per arena: wet ripples on water/storm ground, otherwise a puff of that room's own dust.
const STEP := {
	"loch": [true, Color(0.8, 1, 1)],
	"cliff": [true, Color(0.7, 0.8, 0.9)],
	"keep": [false, Color(0.55, 0.1, 0.14)],
	"ossuary": [false, Color(0.88, 0.85, 0.74)],
	"lazaretto": [false, Color(0.55, 0.75, 0.4)],
	"cave": [false, Color(0.4, 0.32, 0.28)],
}


func _wet() -> bool:
	return STEP.get(level.arena, [false])[0]


func _dust_col() -> Color:
	return STEP[level.arena][1] if STEP.has(level.arena) else Color(0.78, 0.66, 0.5)


func splash(pos: Vector2, r: float) -> void:
	if _wet():
		var wc: Color = STEP[level.arena][1]
		puddles.append({"p": pos, "t": 0.0, "r": r, "life": 0.9, "k": "water", "c": wc})
		for i in int(clampf(r * 0.5, 3, 12)):
			var a := randf() * TAU
			drops.append({"p": pos, "v": Vector2.from_angle(a) * randf_range(20, 50) + Vector2(0, -randf_range(30, 60)), "z": 0.0, "t": 0.0, "g": 190.0, "col": Color(wc, 0.9)})
	else:
		var dc := _dust_col()
		puddles.append({"p": pos, "t": 0.0, "r": r, "life": 0.7, "k": "dust", "c": dc})
		for i in int(clampf(r * 0.5, 3, 10)):
			var a := randf() * TAU
			drops.append({"p": pos, "v": Vector2.from_angle(a) * randf_range(12, 34) + Vector2(0, -randf_range(6, 18)), "z": 0.0, "t": 0.0, "g": -10.0, "col": Color(dc, 0.8)})


func step_fx(pos: Vector2) -> void:
	if _wet():
		var wc: Color = STEP[level.arena][1]
		puddles.append({"p": pos + Vector2(0, 2), "t": 0.0, "r": 5.0, "life": 0.8, "k": "water", "c": wc})
		drops.append({"p": pos + Vector2(0, 2), "v": Vector2(randf_range(-22, 22), -randf_range(25, 45)), "z": 0.0, "t": 0.0, "g": 190.0, "col": Color(wc, 0.9)})
	else:
		var dc := _dust_col()
		puddles.append({"p": pos + Vector2(randf_range(-2, 2), 4), "t": 0.0, "r": 4.0, "life": 0.55, "k": "dust", "c": dc})
		drops.append({"p": pos + Vector2(randf_range(-3, 3), 3), "v": Vector2(randf_range(-10, 10), -randf_range(4, 10)), "z": 0.0, "t": 0.0, "g": -6.0, "col": Color(dc, 0.7)})


func _step_actors(delta: float) -> void:
	var actors: Array = [level.player] + level.followers.values()
	for a in actors:
		if not is_instance_valid(a):
			continue
		var pos: Vector2 = a.global_position
		var prev: Vector2 = last_pos.get(a, pos)
		var moved := pos.distance_to(prev)
		if moved > 0.4 and int(t * 11.0) != int((t - delta) * 11.0):
			step_fx(pos)
		last_pos[a] = pos
	var boss = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if str(e.get("kind")).ends_with("_giant"):
			boss = e
	if boss and int(t * 3.0) != int((t - delta) * 3.0) and boss.state in ["idle", "rush"]:
		splash(boss.global_position + Vector2(randf_range(-40, 40), randf_range(10, 30)), 18.0)
	for d in drops.duplicate():
		d.t += delta
		d.v.y += d.g * delta
		d.p += Vector2(d.v.x, 0) * delta
		d.z += d.v.y * delta
		if d.t > 0.45:
			drops.erase(d)
	for q in puddles.duplicate():
		q.t += delta
		if q.t > q.life:
			puddles.erase(q)
	if drops.size() > 300:
		drops = drops.slice(drops.size() - 300)
	if puddles.size() > 200:
		puddles = puddles.slice(puddles.size() - 200)


func _process(delta: float) -> void:
	t += delta
	if level and level.get("player") and level.get("followers") != null:
		_step_actors(delta)
	queue_redraw()


func _draw_motion() -> void:
	for q in puddles:
		var f: float = q.t / q.life
		if q.k == "water":
			var r: float = q.r * (0.5 + 1.6 * f)
			draw_set_transform(q.p, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, r, 0, TAU, 18, Color(q.c, 0.55 * (1.0 - f)), 1.0)
			if f < 0.5:
				draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 14, Color(q.c.lightened(0.5), 0.5 * (1.0 - f * 2.0)), 1.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			var a: float = 0.4 * (1.0 - f)
			var rise: float = f * 7.0
			var sz: float = q.r * (0.5 + f)
			draw_rect(Rect2(q.p + Vector2(-sz, -rise - sz * 0.5), Vector2(sz, sz * 0.8)), Color(q.c, a))
			draw_rect(Rect2(q.p + Vector2(sz * 0.2, -rise * 1.4 - sz * 0.8), Vector2(sz * 0.8, sz * 0.7)), Color(q.c.lightened(0.2), a * 0.8))
	for d in drops:
		var pos: Vector2 = d.p + Vector2(0, d.z)
		var a2: float = 1.0 - d.t / 0.45
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), Color(d.col, d.col.a * a2))


func _draw() -> void:
	if level == null:
		return
	var T: int = 16
	var loch: bool = level.arena == "loch"
	var cam: Camera2D = level.cam
	var c := cam.get_screen_center_position() if cam else Vector2(level.w * T / 2.0, level.h * T / 2.0)
	var x0 := clampi(int((c.x - 520) / T), 0, level.w - 1)
	var x1 := clampi(int((c.x + 520) / T), 0, level.w - 1)
	var y0 := clampi(int((c.y - 300) / T), 0, level.h - 1)
	var y1 := clampi(int((c.y + 300) / T), 0, level.h - 1)
	if loch:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if level.grid[y][x] == "#":
					continue
				var p := Vector2(x * T, y * T)
				var ph := t * 1.6 + x * 0.9 + y * 0.55
				var a := 0.12 + 0.1 * sin(ph)
				var xo := 3.0 + 4.0 * (0.5 + 0.5 * sin(ph * 0.7))
				draw_rect(Rect2(p.x + xo, p.y + 6 + 3 * sin(ph * 0.5), 7, 1), Color(0.6, 0.95, 1.0, a))
				if (x * 7 + y * 3) % 5 == 0:
					var r := 3.0 + fmod(t * 3.0 + x + y, 5.0)
					draw_arc(p + Vector2(8, 9), r, 0, TAU, 14, Color(0.7, 0.95, 1.0, 0.22 * (1.0 - r / 8.0)), 1.0)
		for i in 14:
			var fx: float = fmod(i * 97.0 + t * (4.0 + i % 3), level.w * T)
			var fy: float = float(i * 53 % (level.h * T)) + 6.0 * sin(t * 0.6 + i)
			draw_circle(Vector2(fx, fy), 2.0, Color(0.5, 0.95, 0.8, 0.12 + 0.08 * sin(t * 2 + i)))
		for i in 6:
			var wy: float = fmod(i * 61.0 + t * 7.0, level.h * T)
			var wx: float = level.w * T * (0.5 + 0.5 * sin(t * 0.4 + i * 1.7))
			draw_line(Vector2(wx - 40, wy), Vector2(wx + 40, wy + 2 * sin(t + i)), Color(0.8, 1, 1, 0.10), 1.0)
	elif level.arena != "attic" and level.arena != "":
		_draw_ambient(T)
	else:
		for i in 22:
			var ex: float = fmod(i * 173.0 + 20.0 * sin(t * 0.7 + i), level.w * T)
			var ey: float = level.h * T - fmod(t * (14.0 + i % 5 * 3.0) + i * 41.0, level.h * T)
			draw_rect(Rect2(ex, ey, 2, 2), Color(1.0, 0.55 + 0.2 * sin(t * 6 + i), 0.2, 0.55))
		for i in 5:
			var sx := 120.0 + i * 210.0
			var sway := 10.0 * sin(t * 0.3 + i)
			var shaft := PackedVector2Array([
				Vector2(sx + sway, 0), Vector2(sx + 60 + sway, 0),
				Vector2(sx + 260 + sway, level.h * T * 0.9), Vector2(sx + 140 + sway, level.h * T * 0.9)])
			draw_colored_polygon(shaft, Color(1.0, 0.85, 0.5, 0.055 + 0.02 * sin(t * 0.8 + i)))
		for i in 40:
			var mx: float = fmod(i * 131.0 + t * 5.0, level.w * T)
			var my: float = fmod(i * 77.0 + t * (3.0 + i % 4), level.h * T)
			draw_circle(Vector2(mx, my), 1.0, Color(1.0, 0.9, 0.6, 0.3))
	_draw_motion()


func _draw_ambient(T: int) -> void:
	var W: float = level.w * T
	var H: float = level.h * T
	var a: String = level.arena
	var col := _dust_col()
	match a:
		"keep":
			for i in 5:
				var wy := fmod(i * 83.0 + t * 6.0, H)
				draw_line(Vector2(W * (0.5 + 0.5 * sin(t * 0.3 + i)) - 60, wy), Vector2(W * (0.5 + 0.5 * sin(t * 0.3 + i)) + 60, wy), Color(0.6, 0.1, 0.14, 0.07), 3.0)
			for i in 26:
				var dx: float = fmod(i * 149.0, W)
				var dy: float = fmod(t * (20.0 + i % 4 * 6.0) + i * 57.0, H)
				draw_rect(Rect2(dx, dy, 2, 4), Color(0.7, 0.08, 0.12, 0.35))
			for i in 4:
				var bx: float = fmod(t * (30.0 + i * 9.0) + i * 300.0, W + 200.0) - 100.0
				var by: float = H * 0.2 + i * 90.0 + 20.0 * sin(t * 2.0 + i)
				draw_line(Vector2(bx, by), Vector2(bx + 8, by - 3 - 2 * sin(t * 14.0)), Color(0.1, 0.04, 0.08, 0.7), 2.0)
				draw_line(Vector2(bx, by), Vector2(bx - 8, by - 3 - 2 * sin(t * 14.0)), Color(0.1, 0.04, 0.08, 0.7), 2.0)
		"ossuary":
			for i in 18:
				var wx: float = fmod(i * 131.0 + 16.0 * sin(t * 0.5 + i), W)
				var wy: float = H - fmod(t * (8.0 + i % 4 * 3.0) + i * 47.0, H)
				draw_circle(Vector2(wx, wy), 2.2, Color(0.5, 1.0, 0.9, 0.22 + 0.1 * sin(t * 2.0 + i)))
				draw_circle(Vector2(wx, wy), 5.0, Color(0.5, 1.0, 0.9, 0.06))
			for i in 4:
				var gx: float = fmod(i * 270.0 + t * 8.0, W)
				draw_rect(Rect2(gx, 0, 28, H), Color(0.5, 0.9, 0.8, 0.03))
		"lazaretto":
			for i in 10:
				var sx: float = fmod(i * 163.0 + t * (6.0 + i % 3 * 3.0), W)
				var sy: float = fmod(i * 71.0 + 30.0 * sin(t * 0.4 + i), H)
				draw_circle(Vector2(sx, sy), 26.0 + 6.0 * sin(t + i), Color(0.45, 0.7, 0.3, 0.05))
			for i in 16:
				var px: float = fmod(i * 119.0, W)
				var py: float = H - fmod(t * (10.0 + i % 3 * 4.0) + i * 39.0, H)
				draw_circle(Vector2(px + 6.0 * sin(t + i), py), 1.6, Color(0.7, 1.0, 0.5, 0.3))
		"cliff":
			for i in 70:
				var rx: float = fmod(i * 97.0 + t * 90.0, W + 200.0) - 100.0
				var ry: float = fmod(i * 61.0 + t * 380.0, H)
				draw_line(Vector2(rx, ry), Vector2(rx - 7, ry + 14), Color(0.7, 0.8, 0.95, 0.3), 1.0)
			var storm := fmod(t, 7.0)
			if storm < 0.12 or (storm > 0.25 and storm < 0.32):
				draw_rect(Rect2(0, 0, W, H), Color(0.85, 0.92, 1.0, 0.12))
			for i in 4:
				var wy: float = fmod(i * 77.0 + t * 12.0, H)
				draw_line(Vector2(0, wy), Vector2(W, wy + 8), Color(0.6, 0.7, 0.85, 0.05), 6.0)
		"cave":
			for i in 30:
				var ex: float = fmod(i * 151.0 + 20.0 * sin(t * 0.7 + i), W)
				var ey: float = H - fmod(t * (16.0 + i % 5 * 4.0) + i * 43.0, H)
				draw_rect(Rect2(ex, ey, 2, 2), Color(1.0, 0.5 + 0.2 * sin(t * 6 + i), 0.15, 0.6))
			for i in 8:
				var sx: float = fmod(i * 211.0 + t * 5.0, W)
				draw_circle(Vector2(sx, H * 0.1 + 10.0 * sin(t * 0.5 + i)), 40.0, Color(0.2, 0.17, 0.17, 0.06))
		_:
			draw_circle(Vector2(W * 0.5, H * 0.5), 1.0, col)
