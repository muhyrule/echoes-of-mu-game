extends Node2D
## Animated environment layer for themed boss arenas: rippling loch water, or dusty attic light shafts.

var level: Node2D
var t := 0.0
var drops: Array = []
var puddles: Array = []
var last_pos := {}


func splash(pos: Vector2, r: float) -> void:
	var loch: bool = level.arena == "loch"
	puddles.append({"p": pos, "t": 0.0, "r": r, "life": 0.9})
	for i in int(clampf(r * 0.5, 3, 12)):
		var a := randf() * TAU
		drops.append({"p": pos, "v": Vector2.from_angle(a) * randf_range(20, 50) + Vector2(0, -randf_range(30, 60)), "z": 0.0, "t": 0.0, "col": Color(0.8, 1, 1, 0.9) if loch else Color(0.8, 0.65, 0.45, 0.9)})


func _step_actors(delta: float) -> void:
	var actors: Array = [level.player] + level.followers.values()
	for a in actors:
		if not is_instance_valid(a):
			continue
		var pos: Vector2 = a.global_position
		var prev: Vector2 = last_pos.get(a, pos)
		var moved := pos.distance_to(prev)
		if moved > 0.4 and int(t * 11.0) != int((t - delta) * 11.0):
			var loch: bool = level.arena == "loch"
			puddles.append({"p": pos + Vector2(0, 2), "t": 0.0, "r": 5.0, "life": 0.8 if loch else 0.6})
			drops.append({"p": pos + Vector2(0, 2), "v": Vector2(randf_range(-22, 22), -randf_range(25, 45)), "z": 0.0, "t": 0.0, "col": Color(0.8, 1, 1, 0.9) if loch else Color(0.8, 0.65, 0.45, 0.8)})
		last_pos[a] = pos
	var boss = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("kind") in ["kelpie_giant", "golem_giant"]:
			boss = e
	if boss and int(t * 3.0) != int((t - delta) * 3.0) and boss.state in ["idle", "rush"]:
		splash(boss.global_position + Vector2(randf_range(-40, 40), randf_range(10, 30)), 18.0)
	for d in drops.duplicate():
		d.t += delta
		d.v.y += 190.0 * delta
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
	var loch: bool = level.arena == "loch"
	for q in puddles:
		var f: float = q.t / q.life
		var r: float = q.r * (0.5 + 1.6 * f)
		var col := Color(0.75, 1, 1, 0.55 * (1.0 - f)) if loch else Color(0.85, 0.7, 0.5, 0.35 * (1.0 - f))
		draw_set_transform(q.p, 0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, r, 0, TAU, 18, col, 1.0)
		if loch and f < 0.5:
			draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 14, Color(1, 1, 1, 0.5 * (1.0 - f * 2.0)), 1.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for d in drops:
		var pos: Vector2 = d.p + Vector2(0, d.z)
		var a: float = 1.0 - d.t / 0.45
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), Color(d.col, d.col.a * a))


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
