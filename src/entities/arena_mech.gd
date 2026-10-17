extends Node2D
## Live, per-arena mechanics that make each boss room an opponent of its own: drifting whirlpools, rotating
## blades, erupting geysers, sweeping carts, crosswinds and creeping miasma. Starts once the boss wakes.

const CFG := {
	"loch": {"col": Color(0.4, 0.9, 1.0), "whirls": 2, "geyser": [3.6, "water"]},
	"keep": {"col": Color(0.85, 0.1, 0.2), "sweep": 1, "geyser": [3.2, "stakes"]},
	"ossuary": {"col": Color(0.55, 1.0, 0.9), "lane": [6.5, "cart"], "geyser": [4.2, "bone"]},
	"cliff": {"col": Color(0.7, 0.85, 1.0), "gust": true, "geyser": [3.0, "bolt"], "bob": 3.5, "clouds": true},
	"lazaretto": {"col": Color(0.55, 0.9, 0.3), "miasma": 3, "geyser": [4.4, "pyre"]},
	"cave": {"col": Color(1.0, 0.5, 0.15), "lane": [7.0, "lava"], "geyser": [2.6, "lava"]},
	"attic": {"col": Color(0.95, 0.75, 0.35), "sweep": 2},
}

var level: Node2D
var cfg: Dictionary = {}
var t := 0.0
var live := false
var boss: Node2D = null
var center := Vector2.ZERO
var half := Vector2(300, 200)
var geysers: Array = []
var lanes: Array = []
var geyser_t := 2.0
var lane_t := 4.0
var gust_t := 5.0
var gust_dir := Vector2.ZERO
var gust_phase := 0.0
var miasma_acc := 0.0
var hits := {}


func _ready() -> void:
	z_index = 2
	cfg = CFG.get(level.arena, {})
	var sum := Vector2.ZERO
	var n := 0
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for y in level.h:
		for x in level.w:
			if level.grid[y][x] != "#":
				var p := Vector2(x * 16 + 8, y * 16 + 8)
				sum += p
				n += 1
				lo = lo.min(p)
				hi = hi.max(p)
	if n > 0:
		center = sum / n
		half = (hi - lo) * 0.5


func _find_boss() -> Node2D:
	for e in get_tree().get_nodes_in_group("enemies"):
		if str(e.get("kind")).ends_with("_giant"):
			return e
	return null


func _phase() -> int:
	return int(boss.get("phase")) if boss else 1


func _hurt(from: Vector2) -> void:
	var p: Node2D = level.player
	p.hurt(1, (p.global_position - from).normalized() if p.global_position != from else Vector2.DOWN)


func _process(delta: float) -> void:
	if cfg.is_empty() or level == null or level.get("player") == null:
		return
	if Dialogue.blocking() or level.frozen:
		queue_redraw()
		return
	t += delta
	boss = _find_boss()
	live = boss != null and boss.state not in ["dormant", "dying"] and not level.player.dead
	if cfg.has("bob") and level.cam:
		level.cam_bob = Vector2(sin(t * 0.9) * 1.5, sin(t * 1.3) * float(cfg.bob))
	if live:
		_step(delta)
	queue_redraw()


func _step(delta: float) -> void:
	var ph := _phase()
	var P: Node2D = level.player
	var pp := P.global_position
	if cfg.has("whirls"):
		for i in int(cfg.whirls):
			var wp := _whirl_pos(i)
			var d := wp - pp
			if d.length() < 95.0:
				P.knock += d.normalized() * 520.0 * delta
				P.knock = P.knock.limit_length(80.0)
			if d.length() < 20.0:
				_hurt(wp)
	if cfg.has("sweep"):
		for i in int(cfg.sweep):
			var seg := _sweep_end(i)
			var cp := Geometry2D.get_closest_point_to_segment(pp, center, seg)
			if cp.distance_to(pp) < 11.0 and pp.distance_to(center) > 26.0:
				_hurt(cp)
	if cfg.has("miasma"):
		for i in int(cfg.miasma):
			if _cloud_pos(i).distance_to(pp) < 48.0 + ph * 4.0:
				miasma_acc += delta
				if miasma_acc > 0.7:
					miasma_acc = 0.0
					_hurt(_cloud_pos(i))
	if cfg.has("geyser"):
		geyser_t -= delta
		if geyser_t <= 0.0:
			geyser_t = float(cfg.geyser[0]) - 0.5 * ph + randf_range(0.0, 0.8)
			var at: Vector2 = pp + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 70.0)
			at = at.clamp(center - half, center + half)
			if not level._is_solid_char(Vector2i(int(at.x / 16.0), int(at.y / 16.0))):
				geysers.append({"p": at, "t": 0.0, "hit": false})
		for g in geysers.duplicate():
			g.t += delta
			if g.t > 1.1 and g.t < 1.6 and not g.hit and g.p.distance_to(pp) < 30.0:
				g.hit = true
				_hurt(g.p)
				level.shake(3.0)
			if g.t > 1.1 and not g.get("fired", false):
				g.fired = true
				level.spark(g.p, cfg.col, 10)
			if g.t > 1.8:
				geysers.erase(g)
	if cfg.has("lane"):
		lane_t -= delta
		if lane_t <= 0.0:
			lane_t = float(cfg.lane[0]) - ph * 0.8
			var horizontal := randf() < 0.5
			var line := (pp.y if horizontal else pp.x) + randf_range(-30.0, 30.0)
			lanes.append({"h": horizontal, "line": line, "t": 0.0, "dir": 1.0 if randf() < 0.5 else -1.0})
		for l in lanes.duplicate():
			l.t += delta
			var lp := _lane_pos(l)
			if l.t > 1.2 and lp.distance_to(pp) < 26.0:
				_hurt(lp)
			if l.t > 1.2 + 2.6:
				lanes.erase(l)
	if cfg.get("gust", false):
		gust_t -= delta
		if gust_t <= 0.0:
			gust_t = randf_range(6.0, 8.5) - ph * 0.8
			gust_dir = Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
			gust_phase = 0.0
			Audio.sfx("roar")
		if gust_dir != Vector2.ZERO:
			gust_phase += delta
			if gust_phase > 3.6:
				gust_dir = Vector2.ZERO
			elif gust_phase > 1.0:
				P.knock += gust_dir * 900.0 * delta
				P.knock = P.knock.limit_length(95.0)


func _whirl_pos(i: int) -> Vector2:
	var a := t * 0.45 * (1.0 if i % 2 == 0 else -1.0) + i * PI
	return center + Vector2(cos(a) * half.x * 0.55, sin(a) * half.y * 0.5)


func _sweep_end(i: int) -> Vector2:
	var a := t * (0.55 + 0.12 * _phase()) * (1.0 if i % 2 == 0 else -1.0) + i * PI * 0.5
	return center + Vector2.from_angle(a) * minf(half.x, half.y) * 0.95


func _cloud_pos(i: int) -> Vector2:
	return center + Vector2(sin(t * 0.21 + i * 2.1) * half.x * 0.7, cos(t * 0.17 + i * 1.3) * half.y * 0.6)


func _lane_pos(l: Dictionary) -> Vector2:
	var travel: float = maxf(0.0, l.t - 1.2) * 280.0
	var span: float = (half.x if l.h else half.y) + 40.0
	var along: float = -span * l.dir + travel * l.dir
	if l.h:
		return Vector2(center.x + along, l.line)
	return Vector2(l.line, center.y + along)


func _draw() -> void:
	if cfg.is_empty() or level == null:
		return
	var col: Color = cfg.col
	if cfg.get("clouds", false):
		_draw_clouds(col)
	if cfg.has("whirls"):
		for i in int(cfg.whirls):
			_draw_whirl(_whirl_pos(i), col)
	if cfg.has("sweep"):
		for i in int(cfg.sweep):
			_draw_sweep(_sweep_end(i), col)
	if cfg.has("miasma"):
		for i in int(cfg.miasma):
			_draw_cloud(_cloud_pos(i), col)
	for g in geysers:
		_draw_geyser(g, col)
	for l in lanes:
		_draw_lane(l, col)
	if gust_dir != Vector2.ZERO:
		_draw_gust(col)


func _draw_whirl(p: Vector2, col: Color) -> void:
	draw_set_transform(p, 0, Vector2(1, 0.6))
	for k in 5:
		var r := 16.0 + k * 14.0
		draw_arc(Vector2.ZERO, r, t * 2.2 + k, t * 2.2 + k + 4.2, 20, Color(col, 0.55 - k * 0.08), 2.0)
	draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.1, 0.16, 0.8))
	draw_arc(Vector2.ZERO, 96.0, 0, TAU, 40, Color(col, 0.08), 1.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_sweep(e: Vector2, col: Color) -> void:
	var d := (e - center)
	var nrm := d.orthogonal().normalized()
	var arm := PackedVector2Array([center + nrm * 6.0, e + nrm * 3.0, e - nrm * 3.0, center - nrm * 6.0])
	draw_colored_polygon(arm, Color(col, 0.22))
	draw_line(center, e, Color(0.1, 0.05, 0.05, 0.9), 5.0)
	draw_line(center, e, Color(col, 0.95), 2.0)
	for k in 6:
		var b := center + d * (0.35 + k * 0.11)
		draw_colored_polygon(PackedVector2Array([b + nrm * 5.0, b + d.normalized() * 8.0, b - nrm * 5.0]), Color(col.lightened(0.3), 0.95))
	draw_circle(center, 16.0, Color(0.08, 0.05, 0.06, 0.9))
	draw_arc(center, 16.0, 0, TAU, 20, col, 2.0)
	draw_circle(center, 6.0, col)


func _draw_cloud(p: Vector2, col: Color) -> void:
	for k in 9:
		var a := t * 0.6 + k * 0.7
		var q := p + Vector2(cos(a) * 26.0, sin(a * 1.3) * 16.0)
		draw_circle(q, 22.0 + 4.0 * sin(t + k), Color(col, 0.1))
	draw_circle(p, 38.0, Color(col, 0.12))
	for k in 6:
		var u := fmod(t * 0.5 + k * 0.17, 1.0)
		draw_circle(p + Vector2(sin(k * 3.1 + t) * 26.0, 18.0 - u * 40.0), 2.0, Color(col.lightened(0.4), 0.7 * (1.0 - u)))


func _draw_geyser(g: Dictionary, col: Color) -> void:
	var style: String = cfg.geyser[1]
	var p: Vector2 = g.p
	if g.t < 1.1:
		var f: float = g.t / 1.1
		draw_set_transform(p, 0, Vector2(1, 0.6))
		draw_arc(Vector2.ZERO, 28.0, 0, TAU, 24, Color(col, 0.35 + 0.4 * f), 2.0)
		draw_arc(Vector2.ZERO, 28.0 * f, 0, TAU, 20, Color(col, 0.5), 1.5)
		draw_circle(Vector2.ZERO, 28.0, Color(col, 0.08 + 0.12 * f))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	var u: float = clampf((g.t - 1.1) / 0.7, 0.0, 1.0)
	var h: float = sin(u * PI) * 70.0
	draw_set_transform(p, 0, Vector2(1, 0.6))
	draw_circle(Vector2.ZERO, 28.0 * (1.0 - u * 0.4), Color(col, 0.5 * (1.0 - u)))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	match style:
		"stakes", "bone":
			for k in 5:
				var x := (k - 2) * 11.0
				var hh := h * (0.7 + 0.3 * (k % 2))
				var tip: Color = Color("c8c2b0") if style == "bone" else Color("2a1218")
				draw_colored_polygon(PackedVector2Array([p + Vector2(x - 4, 0), p + Vector2(x + 4, 0), p + Vector2(x, -hh)]), tip)
				draw_polyline(PackedVector2Array([p + Vector2(x - 4, 0), p + Vector2(x, -hh), p + Vector2(x + 4, 0)]), col, 1.5)
		"bolt":
			var pts := PackedVector2Array()
			for k in 8:
				pts.append(p + Vector2(sin(k * 7.0 + g.t * 40.0) * 5.0, -k * 16.0))
			draw_polyline(pts, Color(1, 1, 1, 1.0 - u), 4.0)
			draw_polyline(pts, Color(col, 1.0 - u), 2.0)
		_:
			for k in 7:
				var a := -PI * 0.5 + (k - 3) * 0.18
				var q := p + Vector2.from_angle(a) * h
				draw_line(p, q, Color(col, 0.7), 5.0 - absf(k - 3) * 0.8)
				draw_circle(q, 3.0, Color(col.lightened(0.5), 0.9))


func _draw_lane(l: Dictionary, col: Color) -> void:
	var span: float = (half.x if l.h else half.y) + 60.0
	var a := Vector2(center.x - span, l.line) if l.h else Vector2(l.line, center.y - span)
	var b := Vector2(center.x + span, l.line) if l.h else Vector2(l.line, center.y + span)
	if l.t < 1.2:
		var blink := 0.15 + 0.2 * absf(sin(l.t * 9.0))
		draw_line(a, b, Color(col, blink), 40.0)
		draw_line(a, b, Color(col, 0.6), 1.5)
		return
	var p := _lane_pos(l)
	var d := Vector2(l.dir if l.h else 0.0, 0.0 if l.h else l.dir)
	draw_line(p - d * 60.0, p, Color(col, 0.3), 30.0)
	if cfg.lane[1] == "cart":
		draw_rect(Rect2(p - Vector2(24, 14), Vector2(48, 20)), Color("5a4430"))
		draw_rect(Rect2(p - Vector2(24, 14), Vector2(48, 20)), Color("2a1c10"), false, 2.0)
		for k in 4:
			draw_circle(p + Vector2(-16 + k * 11, -16), 5.0, Color("dcd6c4"))
		draw_circle(p + Vector2(-14, 8), 9.0, Color("3a2c20"))
		draw_circle(p + Vector2(14, 8), 9.0, Color("3a2c20"))
		draw_circle(p + Vector2(0, -2), 28.0, Color(col, 0.12))
	else:
		draw_circle(p, 26.0, Color(col, 0.45))
		draw_circle(p, 16.0, Color(1.0, 0.85, 0.4, 0.9))
		for k in 6:
			draw_circle(p - d * (k * 12.0) + Vector2(sin(k + t * 8.0) * 4.0, -k * 1.5), 12.0 - k, Color(col, 0.35))


func _draw_gust(col: Color) -> void:
	var cam: Camera2D = level.cam
	var c := cam.get_screen_center_position() if cam else center
	var power := 1.0 if gust_phase > 1.0 else gust_phase
	for i in 22:
		var y := c.y - 300.0 + fmod(i * 61.0, 600.0)
		var x := c.x - 520.0 + fmod(i * 173.0 + t * 700.0 * gust_dir.x, 1040.0)
		if x < c.x - 520.0:
			x += 1040.0
		draw_line(Vector2(x, y), Vector2(x - gust_dir.x * 46.0, y + 2.0), Color(col, 0.45 * power), 1.5)


func _draw_clouds(col: Color) -> void:
	var cam: Camera2D = level.cam
	var c := cam.get_screen_center_position() if cam else center
	for i in 26:
		var sp := 90.0 + (i % 5) * 40.0
		var x := c.x - 560.0 + fmod(i * 211.0, 1120.0)
		var y := c.y + 340.0 - fmod(t * sp + i * 137.0, 700.0)
		var s := 0.6 + (i % 4) * 0.25
		var a := 0.07 + 0.03 * (i % 3)
		for k in 4:
			draw_circle(Vector2(x + k * 14.0 * s, y + sin(k + i) * 4.0), (16.0 - absf(k - 1.5) * 3.0) * s, Color(col.lightened(0.3), a))
		draw_line(Vector2(x + 20, y + 10), Vector2(x + 20, y + 40 + sp * 0.3), Color(1, 1, 1, 0.08), 1.0)
