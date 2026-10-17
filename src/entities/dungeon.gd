extends Node2D
## Living dungeon layer driven by the map's "dungeon" block: rune-lit floors, dripping water, timed spike
## grates, sweeping saw-blades, waygate shortcuts, and braziers that only a specific hero's ability can light
## to disarm a trap group (Corvin's bolt, Wren's dagger, Isolde's bell). Also spawns the extra monsters.

const T := 16.0
const CYCLE := 3.2

var level: Node2D
var d: Dictionary = {}
var t := 0.0
var spikes: Array = []
var blades: Array = []
var gates: Array = []
var braziers: Array = []
var glyphs: Array = []
var disarmed := {}
var tp_cd := 0.0
var drips: Array = []
var bursts: Array = []


func _ready() -> void:
	z_index = 1
	d = level.meta.get("dungeon", {})
	for s in d.get("spikes", []):
		spikes.append({"c": Vector2(float(s[0]), float(s[1])), "g": str(s[2]), "o": float(s[3])})
	for b in d.get("blades", []):
		blades.append({"a": _p(b[0], b[1]), "b": _p(b[2], b[3]), "g": str(b[4]), "o": float(b[5])})
	for g in d.get("gates", []):
		gates.append([_p(g[0][0], g[0][1]), _p(g[1][0], g[1][1])])
	for b in d.get("braziers", []):
		braziers.append({"p": _p(b[0], b[1]), "src": str(b[2]), "g": str(b[3]), "lit": level.get("prefix") != null and GameState.flag("%s_brz_%s" % [level.prefix, b[3]])})
		if braziers.back().lit:
			disarmed[str(b[3])] = true
	for g in d.get("glyphs", []):
		glyphs.append({"p": _p(g[0], g[1]), "r": float(g[2]) * T})
	for e in d.get("enemies", []):
		level.spawn_enemy(str(e[0]), _p(e[1], e[2]))


func _p(x, y) -> Vector2:
	return Vector2(float(x) * T + 8.0, float(y) * T + 8.0)


func hit(src: String, pos: Vector2, rad: float) -> bool:
	var did := false
	for b in braziers:
		if b.lit or b.src != src or b.p.distance_to(pos) > rad + 9.0:
			continue
		b.lit = true
		did = true
		disarmed[b.g] = true
		GameState.set_flag("%s_brz_%s" % [level.prefix, b.g])
		Audio.sfx("switch")
		level.shake(2.0)
		level.spark(b.p, Color(1.0, 0.75, 0.35), 16)
		level.hud.show_notice("The brazier flares \u2014 the traps beyond fall still.")
	return did


func _spike_state(s: Dictionary) -> float:
	# 0 = safe, 0..1 telegraph, 2 = raised
	var u := fmod(t + s.o, CYCLE)
	if u < 1.6:
		return 0.0
	if u < 2.4:
		return (u - 1.6) / 0.8
	if u < 2.9:
		return 2.0
	return 0.0


func _blade_pos(b: Dictionary) -> Vector2:
	return b.a.lerp(b.b, 0.5 + 0.5 * sin(t * 1.5 + b.o))


func _process(delta: float) -> void:
	if d.is_empty() or level == null or level.get("player") == null:
		return
	if Dialogue.blocking() or level.frozen:
		queue_redraw()
		return
	t += delta
	tp_cd = maxf(0.0, tp_cd - delta)
	var P: Node2D = level.player
	if P.dead:
		queue_redraw()
		return
	var pp := P.global_position
	for s in spikes:
		if disarmed.has(s.g):
			continue
		if _spike_state(s) >= 2.0:
			var c: Vector2 = s.c * T + Vector2(8, 8)
			if absf(pp.x - c.x) < 9.0 and absf(pp.y - c.y) < 9.0:
				P.hurt(1, Vector2.UP)
	for b in blades:
		if disarmed.has(b.g):
			continue
		if _blade_pos(b).distance_to(pp) < 11.0:
			P.hurt(1, (pp - _blade_pos(b)).normalized())
	if tp_cd <= 0.0 and P.rolling <= 0.0:
		for g in gates:
			for i in 2:
				if pp.distance_to(g[i]) < 12.0:
					var dest: Vector2 = g[1 - i]
					P.global_position = dest + Vector2(0, 20)
					tp_cd = 1.2
					Audio.sfx("bell")
					level.spark(g[i], Color(0.6, 0.85, 1.0), 12)
					level.spark(dest, Color(0.6, 0.85, 1.0), 12)
					bursts.append({"p": g[i], "t": 0.0})
					bursts.append({"p": dest, "t": 0.0})
	for b in bursts.duplicate():
		b.t += delta
		if b.t > 0.6:
			bursts.erase(b)
	if randf() < delta * 1.5 and drips.size() < 12:
		var c: Vector2 = level.cam.get_screen_center_position() if level.cam else pp
		var at: Vector2 = c + Vector2(randf_range(-480, 480), randf_range(-260, 260))
		var cx := int(at.x / T)
		var cy := int(at.y / T)
		if cx > 0 and cy > 0 and cx < level.w and cy < level.h and level.grid[cy][cx] != "#":
			drips.append({"p": at, "t": 0.0})
	for q in drips.duplicate():
		q.t += delta
		if q.t > 1.4:
			drips.erase(q)
	queue_redraw()


func _draw() -> void:
	if d.is_empty() or level == null:
		return
	for g in glyphs:
		_draw_glyph(g)
	for q in drips:
		var f: float = q.t / 1.4
		if f < 0.25:
			draw_line(q.p + Vector2(0, -30 + f * 120.0), q.p + Vector2(0, -26 + f * 120.0), Color(0.6, 0.8, 1.0, 0.6), 1.0)
		else:
			var r: float = (f - 0.25) * 22.0
			draw_set_transform(q.p, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, r, 0, TAU, 14, Color(0.6, 0.8, 1.0, 0.5 * (1.0 - f)), 1.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for s in spikes:
		_draw_spike(s)
	for b in blades:
		_draw_blade(b)
	for g in gates:
		_draw_gate(g[0])
		_draw_gate(g[1])
		draw_line(g[0], g[1], Color(0.6, 0.85, 1.0, 0.0), 1.0)
	for b in braziers:
		_draw_brazier(b)
	for b in bursts:
		draw_arc(b.p, 10.0 + b.t * 80.0, 0, TAU, 24, Color(0.6, 0.85, 1.0, 0.8 * (1.0 - b.t / 0.6)), 2.0)


func _draw_glyph(g: Dictionary) -> void:
	var p: Vector2 = g.p
	var r: float = g.r
	var pulse := 0.5 + 0.5 * sin(t * 1.2 + p.x)
	draw_set_transform(p, 0, Vector2(1, 0.62))
	draw_circle(Vector2.ZERO, r, Color(0.25, 0.4, 0.8, 0.04 + 0.03 * pulse))
	draw_arc(Vector2.ZERO, r, 0, TAU, 56, Color(0.5, 0.7, 1.0, 0.28 + 0.1 * pulse), 1.5)
	draw_arc(Vector2.ZERO, r * 0.82, 0, TAU, 48, Color(0.5, 0.7, 1.0, 0.16), 1.0)
	for k in 7:
		var a := TAU * k / 7.0 + t * 0.08
		var q := Vector2.from_angle(a) * r * 0.9
		draw_circle(q, 2.2, Color(0.7, 0.85, 1.0, 0.45 + 0.3 * sin(t * 2.0 + k)))
		draw_line(Vector2.from_angle(a) * r * 0.5, Vector2.from_angle(a + 2.5) * r * 0.5, Color(0.5, 0.7, 1.0, 0.18), 1.0)
	for k in 7:
		draw_line(Vector2.from_angle(TAU * k / 7.0 + t * 0.08) * r * 0.82, Vector2.from_angle(TAU * (k + 3) / 7.0 + t * 0.08) * r * 0.82, Color(0.5, 0.7, 1.0, 0.14), 1.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_spike(s: Dictionary) -> void:
	var c: Vector2 = s.c * T
	var off := disarmed.has(s.g)
	draw_rect(Rect2(c + Vector2(1, 1), Vector2(14, 14)), Color(0.07, 0.07, 0.1, 0.85))
	draw_rect(Rect2(c + Vector2(1, 1), Vector2(14, 14)), Color(0.4, 0.4, 0.5, 0.6), false, 1.0)
	for k in 4:
		for j in 4:
			draw_circle(c + Vector2(3.5 + k * 3.0, 3.5 + j * 3.0), 0.8, Color(0.02, 0.02, 0.04))
	if off:
		return
	var st := _spike_state(s)
	if st > 0.0 and st < 2.0:
		draw_rect(Rect2(c + Vector2(1, 1), Vector2(14, 14)), Color(1.0, 0.3, 0.2, 0.15 + 0.3 * st))
	elif st >= 2.0:
		for k in 4:
			for j in 4:
				var b := c + Vector2(3.5 + k * 3.0, 3.5 + j * 3.0)
				draw_colored_polygon(PackedVector2Array([b + Vector2(-1.3, 1.5), b + Vector2(1.3, 1.5), b + Vector2(0, -5.0)]), Color(0.82, 0.85, 0.92))
				draw_line(b + Vector2(0, -5.0), b + Vector2(0.8, 1.5), Color(1, 1, 1, 0.5), 0.6)


func _draw_blade(b: Dictionary) -> void:
	var off := disarmed.has(b.g)
	draw_line(b.a, b.b, Color(0.05, 0.05, 0.08), 4.0)
	draw_line(b.a, b.b, Color(0.4, 0.38, 0.45), 1.2)
	draw_circle(b.a, 3.5, Color(0.3, 0.28, 0.34))
	draw_circle(b.b, 3.5, Color(0.3, 0.28, 0.34))
	var p := _blade_pos(b)
	if off:
		draw_circle(p, 9.0, Color(0.25, 0.25, 0.3))
		return
	draw_circle(p, 12.0, Color(0.8, 0.3, 0.3, 0.12))
	draw_circle(p, 9.5, Color(0.08, 0.06, 0.08))
	for k in 10:
		var a := TAU * k / 10.0 + t * 12.0
		draw_colored_polygon(PackedVector2Array([p + Vector2.from_angle(a - 0.18) * 7.5, p + Vector2.from_angle(a) * 11.5, p + Vector2.from_angle(a + 0.18) * 7.5]), Color(0.85, 0.87, 0.95))
	draw_circle(p, 6.5, Color(0.55, 0.55, 0.62))
	draw_circle(p, 2.0, Color(0.9, 0.8, 0.4))


func _draw_gate(p: Vector2) -> void:
	var col := Color(0.55, 0.8, 1.0)
	draw_set_transform(p, 0, Vector2(1, 0.62))
	draw_circle(Vector2.ZERO, 13.0, Color(col, 0.2 + 0.08 * sin(t * 3.0)))
	draw_circle(Vector2.ZERO, 8.0, Color(0.02, 0.03, 0.08, 0.9))
	for k in 3:
		draw_arc(Vector2.ZERO, 4.0 + k * 3.0, t * (2.0 + k) + k, t * (2.0 + k) + k + 3.0, 12, Color(col.lightened(0.3), 0.85 - k * 0.2), 1.5)
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 24, Color(col, 0.9), 1.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for k in 4:
		var u := fmod(t * 0.7 + k * 0.25, 1.0)
		draw_circle(p + Vector2(sin(k * 2.0 + t) * 6.0, -u * 24.0), 1.2, Color(col.lightened(0.4), 0.8 * (1.0 - u)))


func _draw_brazier(b: Dictionary) -> void:
	var p: Vector2 = b.p
	var tint: Color = {"bolt": Color(0.9, 0.75, 0.35), "dagger": Color(0.65, 0.5, 0.95), "bell": Color(1.0, 0.85, 0.4)}.get(b.src, Color.WHITE)
	draw_rect(Rect2(p + Vector2(-5, 2), Vector2(10, 5)), Color(0.05, 0.04, 0.06))
	draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 3)), Color(0.35, 0.3, 0.28))
	draw_arc(p + Vector2(0, -1), 5.0, 0, PI, 10, tint, 1.2)
	if b.lit:
		var fl := 1.0 + 0.2 * sin(t * 12.0 + p.x)
		draw_circle(p + Vector2(0, -4), 14.0, Color(1.0, 0.6, 0.2, 0.14))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(2, -6 * fl), p + Vector2(0, -10 * fl), p + Vector2(-2, -6 * fl)]), Color(1.0, 0.55, 0.15))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(0, -6 * fl)]), Color(1.0, 0.9, 0.5))
	else:
		draw_circle(p + Vector2(0, -3), 3.0, Color(tint, 0.18 + 0.15 * sin(t * 3.0)))
		draw_arc(p + Vector2(0, -3), 7.0 + 2.0 * sin(t * 3.0), 0, TAU, 14, Color(tint, 0.5), 1.0)
