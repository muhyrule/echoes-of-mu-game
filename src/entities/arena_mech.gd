extends Node2D
## Boss-arena mechanics built around waygates. Linked gates teleport heroes across the room; a hero emerging
## beside the boss lands a portal strike. Every so often the boss channels an arena-wide cataclysm that only the
## glowing havens around the gates survive; weathering it leaves the boss exposed.

const CFG := {
	"loch": {"col": Color(0.4, 0.9, 1.0), "gates": 3, "name": "Whirlpool Gate", "cata": "The Loch floods", "line": "The Loch is rising \u2014 reach a whirlpool gate!"},
	"keep": {"col": Color(0.85, 0.1, 0.2), "gates": 2, "name": "Blood Mirror", "cata": "Blood Moon", "line": "A blood moon rises \u2014 step through a blood mirror!"},
	"ossuary": {"col": Color(0.55, 1.0, 0.9), "gates": 3, "name": "Lantern Door", "cata": "Judgement Toll", "line": "The Ankou tolls judgement \u2014 shelter at a lantern door!"},
	"cliff": {"col": Color(0.7, 0.85, 1.0), "gates": 2, "name": "Updraft", "cata": "Great Storm", "line": "The storm breaks \u2014 ride an updraft to the calm!", "gust": true, "bob": 3.5, "clouds": true},
	"lazaretto": {"col": Color(0.55, 0.9, 0.3), "gates": 2, "name": "Bell Door", "cata": "Pyre of the Plague", "line": "The pyres ignite \u2014 duck through a bell door!"},
	"cave": {"col": Color(1.0, 0.5, 0.15), "gates": 3, "name": "Fissure", "cata": "Eruption", "line": "The mountain erupts \u2014 leap into a fissure!"},
	"attic": {"col": Color(0.95, 0.75, 0.35), "gates": 2, "name": "Gear Gate", "cata": "Midnight Chime", "line": "The clock strikes \u2014 cross a gear gate!"},
}
const HAVEN := 58.0
const WARN := 4.2

var level: Node2D
var cfg: Dictionary = {}
var t := 0.0
var live := false
var boss: Node2D = null
var center := Vector2.ZERO
var half := Vector2(300, 200)
var pads: Array = []
var tp_cd := 0.0
var cata_t := -1.0
var cata_wait := 6.0
var cata_count := 0
var gust_t := 5.0
var gust_dir := Vector2.ZERO
var gust_phase := 0.0
var bursts: Array = []


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
	if cfg.is_empty():
		return
	var g: int = cfg.gates
	for i in g:
		var a := PI * 0.5 + TAU * i / g + (0.0 if g == 3 else PI * 0.5)
		var pos := center + Vector2(cos(a) * half.x * 0.6, sin(a) * half.y * 0.5 + half.y * 0.1)
		for k in 12:
			if not level._is_solid_char(Vector2i(int(pos.x / 16.0), int(pos.y / 16.0))):
				break
			pos = pos.lerp(center, 0.12)
		pads.append(pos)


func _find_boss() -> Node2D:
	for e in get_tree().get_nodes_in_group("enemies"):
		if str(e.get("kind")).ends_with("_giant"):
			return e
	return null


func _phase() -> int:
	return int(boss.get("phase")) if boss else 1


func _process(delta: float) -> void:
	if cfg.is_empty() or level == null or level.get("player") == null:
		return
	if Dialogue.blocking() or level.frozen:
		queue_redraw()
		return
	t += delta
	tp_cd = maxf(0.0, tp_cd - delta)
	boss = _find_boss()
	live = boss != null and boss.state not in ["dormant", "dying"] and not level.player.dead
	if cfg.has("bob") and level.cam:
		level.cam_bob = Vector2(sin(t * 0.9) * 1.5, sin(t * 1.3) * float(cfg.bob))
	for b in bursts.duplicate():
		b.t += delta
		if b.t > 0.6:
			bursts.erase(b)
	if live:
		_step(delta)
	elif cata_t >= 0.0:
		cata_t = -1.0
	queue_redraw()


func _step(delta: float) -> void:
	var P: Node2D = level.player
	var pp := P.global_position
	if tp_cd <= 0.0 and P.rolling <= 0.0:
		for i in pads.size():
			if pp.distance_to(pads[i]) < 15.0:
				_teleport(P, i)
				break
	_cataclysm(delta, P)
	if cfg.get("gust", false):
		gust_t -= delta
		if gust_t <= 0.0:
			gust_t = randf_range(6.0, 8.5) - _phase() * 0.8
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


func _teleport(P: Node2D, i: int) -> void:
	var dest: Vector2 = pads[(i + 1) % pads.size()]
	var out := (center - dest).normalized() * 26.0
	P.global_position = dest + out
	P.knock = Vector2.ZERO
	tp_cd = 1.0
	Audio.sfx("bell")
	level.spark(pads[i], cfg.col, 10)
	level.spark(dest, cfg.col, 14)
	bursts.append({"p": pads[i], "t": 0.0})
	bursts.append({"p": dest, "t": 0.0})
	var near := minf(boss.global_position.distance_to(dest), boss.global_position.distance_to(pads[i]))
	if near < 120.0 and boss.state in ["idle", "attack", "stun", "rush"]:
		boss.hurt(3, (boss.global_position - dest).normalized())
		level.shake(6.0)
		level.hud.show_notice("Portal strike!")


func _cataclysm(delta: float, P: Node2D) -> void:
	if cata_t < 0.0:
		cata_wait -= delta
		if cata_wait <= 0.0 and boss.state == "idle":
			cata_t = 0.0
			cata_count += 1
			boss.state = "attack"
			boss.st = 0.0
			boss.winding = true
			boss.queue.clear()
			Audio.sfx("roar")
			level.shake(5.0)
			level.hud.show_notice(str(cfg.line) if cata_count == 1 else str(cfg.cata) + "!")
		return
	cata_t += delta
	if boss.state != "attack":
		cata_t = -1.0
		cata_wait = 6.0
		return
	if cata_t >= WARN:
		var safe := _in_haven(P.global_position)
		cata_t = -1.0
		cata_wait = 12.0 - 1.5 * _phase()
		boss.winding = false
		level.shake(12.0)
		Audio.sfx("hit")
		bursts.append({"p": center, "t": -1.0})
		if not safe:
			P.hurt(2, Vector2.DOWN)
			boss._finish(0.0)
		else:
			boss._finish(4.5)
			level.hud.show_notice("The %s is spent \u2014 strike now!" % boss.get("kind").replace("_giant", "").capitalize())


func _in_haven(p: Vector2) -> bool:
	for q in pads:
		if p.distance_to(q) < HAVEN:
			return true
	return false


func _draw() -> void:
	if cfg.is_empty() or level == null:
		return
	var col: Color = cfg.col
	if cfg.get("clouds", false):
		_draw_clouds(col)
	var warn := cata_t >= 0.0
	if warn:
		_draw_cataclysm(col)
	for q in pads:
		_draw_gate(q, col, warn)
	for b in bursts:
		if b.t >= 0.0:
			draw_arc(b.p, 10.0 + b.t * 80.0, 0, TAU, 24, Color(col, 0.8 * (1.0 - b.t / 0.6)), 2.0)
		else:
			draw_rect(Rect2(center - Vector2(900, 600), Vector2(1800, 1200)), Color(1, 1, 1, 0.5))
	if gust_dir != Vector2.ZERO:
		_draw_gust(col)


func _cam_center() -> Vector2:
	var cam: Camera2D = level.cam
	return cam.get_screen_center_position() if cam else center


func _draw_cataclysm(col: Color) -> void:
	var f := cata_t / WARN
	var c := _cam_center()
	var rect := Rect2(c - Vector2(620, 360), Vector2(1240, 720))
	draw_rect(rect, Color(col.darkened(0.5), 0.12 + 0.32 * f + 0.05 * sin(t * 12.0)))
	for i in 18:
		var x := rect.position.x + fmod(i * 71.0 + t * (40.0 + i * 3.0), rect.size.x)
		var y := rect.position.y + fmod(i * 131.0 + (t * (60.0 + i % 5 * 20.0) if level.arena != "cave" else -t * 60.0), rect.size.y)
		match level.arena:
			"loch":
				draw_line(Vector2(x, y), Vector2(x + 40, y), Color(col, 0.35 * f + 0.1), 2.0)
			"keep", "lazaretto":
				draw_line(Vector2(x, y), Vector2(x, y + 14), Color(col, 0.5), 2.0)
			"cliff":
				draw_line(Vector2(x, y), Vector2(x - 26, y + 18), Color(col, 0.5), 1.5)
			_:
				draw_circle(Vector2(x, y), 2.0 + 2.0 * f, Color(col.lightened(0.3), 0.6))
	for q in pads:
		draw_circle(q, HAVEN, Color(0.9, 1.0, 1.0, 0.10 + 0.08 * sin(t * 8.0)))
		draw_arc(q, HAVEN, 0, TAU, 36, Color(1, 1, 1, 0.9), 2.5)
		draw_arc(q, HAVEN * (1.0 - fmod(t * 1.2, 1.0)), 0, TAU, 24, Color(col, 0.6), 1.5)
	draw_arc(_boss_pos(), 30.0 + f * 260.0, 0, TAU, 40, Color(col, 0.4), 3.0)


func _boss_pos() -> Vector2:
	return boss.global_position if boss else center


func _draw_gate(p: Vector2, col: Color, warn: bool) -> void:
	var glow := 0.25 + 0.15 * sin(t * 3.0 + p.x)
	if warn:
		glow += 0.35
	draw_set_transform(p, 0, Vector2(1, 0.6))
	draw_circle(Vector2.ZERO, 20.0, Color(col, glow * 0.6))
	draw_circle(Vector2.ZERO, 14.0, Color(0.02, 0.03, 0.06, 0.85))
	for k in 4:
		draw_arc(Vector2.ZERO, 8.0 + k * 4.0, t * (2.0 + k) + k, t * (2.0 + k) + k + 3.0, 14, Color(col.lightened(0.3), 0.8 - k * 0.15), 2.0)
	draw_arc(Vector2.ZERO, 22.0, 0, TAU, 28, Color(col, 0.9), 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for k in 6:
		var u := fmod(t * 0.7 + k * 0.17, 1.0)
		draw_circle(p + Vector2(sin(k * 2.0 + t) * 10.0, -u * 36.0), 1.8, Color(col.lightened(0.4), 0.8 * (1.0 - u)))
	draw_line(p + Vector2(-9, -10), p + Vector2(9, -10), Color(col, 0.0), 1.0)


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
