extends CharacterBody2D
## Arena bosses: the Hollow Warden of the Bell (bell_giant) and the Clockwork Revenant (clock_giant).
## Both are huge multi-phase foes with telegraphed, theme-specific attack patterns.

const Art = preload("res://src/core/art.gd")
const HazardScript = preload("res://src/entities/hazards.gd")
const E := 1.0 / 3.2  # extras are authored at 3.2x body size

var kind := "bell_giant"
var title := "FOE"
var level: Node2D
var player: Node2D
var hp := 60
var max_hp := 60
var hit_radius := 52.0
var is_boss := true
var state := "dormant"
var st := 0.0
var t := randf() * 10.0
var flash := 0.0
var facing := Vector2.DOWN
var knock := Vector2.ZERO
var phase := 1
var exposed := 0.0
var winding := false
var charge_dir := Vector2.DOWN
var last_atk := ""
var queue: Array = []
var fx: Node2D
var speed := 30.0
var idle_wait := 1.5
var death_t := 0.0
var rushing := false


func setup(k: String, lvl: Node2D) -> void:
	kind = k
	level = lvl
	if k == "bell_giant":
		title = "HOLLOW WARDEN"
		hp = 70
		speed = 30.0
		scale = Vector2(3.0, 3.0)
	else:
		title = "CLOCKWORK REVENANT"
		hp = 90
		speed = 34.0
		scale = Vector2(2.4, 2.4)
	max_hp = hp


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 3
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 34.0 / scale.x
	shape.shape = c
	add_child(shape)
	player = level.player
	fx = Node2D.new()
	fx.set_script(HazardScript)
	fx.level = level
	fx.player = player
	level.add_child(fx)


func _exit_tree() -> void:
	if is_instance_valid(fx):
		fx.queue_free()


func after(sec: float, fn: Callable) -> void:
	queue.append([sec, fn])


func _gold() -> Color:
	return Color("f0c860") if kind == "bell_giant" else Color("ffb040")


func _physics_process(delta: float) -> void:
	if Dialogue.blocking() or level.frozen or player.dead:
		queue_redraw()
		return
	t += delta
	st += delta
	flash = maxf(0.0, flash - delta)
	exposed = maxf(0.0, exposed - delta)
	knock = knock.move_toward(Vector2.ZERO, 400.0 * delta)
	for q in queue.duplicate():
		q[0] -= delta
		if q[0] <= 0.0:
			queue.erase(q)
			q[1].call()
	var to := player.global_position - global_position
	var dist := to.length()
	var move := Vector2.ZERO
	match state:
		"dormant":
			if dist < 280.0:
				state = "intro"
				st = 0.0
				Audio.sfx("roar")
				Audio.play_music("boss" if kind == "bell_giant" else "boss2")
				level.shake(6.0)
				level.boss_awake()
		"intro":
			if st > 1.6:
				state = "idle"
				st = 0.0
		"idle":
			facing = to.normalized()
			move = to.normalized() * speed if dist > 90.0 else Vector2.ZERO
			if st > idle_wait:
				_begin_attack()
		"attack":
			facing = facing.lerp(to.normalized(), 0.04) if winding else facing
		"rush":
			move = charge_dir * 250.0
			if is_on_wall() and st > 0.15:
				_rush_crash()
			elif st > 1.1:
				_finish(0.4)
		"stun", "stagger":
			if st > (2.4 if state == "stun" else 1.7):
				_finish(0.0)
		"dying":
			death_t += delta
			if int(death_t * 10.0) != int((death_t - delta) * 10.0):
				level.spark(global_position + Vector2(randf_range(-40, 40), randf_range(-60, 20)), Color(1, 0.8, 0.4), 10)
				level.shake(3.0)
			if death_t > 2.4:
				level.enemy_died(self)
				queue_free()
				return
	velocity = move + knock
	move_and_slide()
	if state in ["idle", "attack", "rush", "stun"] and dist < 48.0:
		player.hurt(1, to.normalized() if dist > 0.1 else Vector2.DOWN)
	queue_redraw()


func _pool() -> Array:
	if kind == "bell_giant":
		return ["toll", "lash", "drop", "rush"] + (["summon"] if phase >= 2 else []) + (["toll", "drop"] if phase >= 3 else [])
	return ["cogs", "hands", "vents", "rush"] + (["rift"] if phase >= 2 else []) + (["hands", "cogs"] if phase >= 3 else [])


func _begin_attack() -> void:
	var pool := _pool()
	var pick: String = pool[randi() % pool.size()]
	if pick == last_atk:
		pick = pool[(pool.find(pick) + 1) % pool.size()]
	last_atk = pick
	state = "attack"
	st = 0.0
	queue.clear()
	call("_a_" + pick)


func _finish(expose := 0.0) -> void:
	state = "idle"
	st = 0.0
	winding = false
	rushing = false
	exposed = maxf(exposed, expose)
	idle_wait = [1.5, 1.1, 0.7][phase - 1]


func _pp() -> Vector2:
	return player.global_position


func _arena_pos(p: Vector2) -> Vector2:
	if level._is_solid_char(Vector2i(int(p.x / 16.0), int(p.y / 16.0))):
		return _pp()
	return p


# ---------------------------------------------------------- Hollow Warden

func _a_toll() -> void:
	winding = true
	var n := 1 + phase
	after(0.9, func():
		winding = false
		Audio.sfx("bell")
		level.shake(7.0)
		level.spark(global_position, _gold(), 18))
	for i in n:
		after(0.95 + i * 0.6, func():
			var gap := (_pp() - global_position).angle() + randf_range(-0.35, 0.35) * (phase - 1)
			fx.ring(global_position, 125.0 + 12.0 * phase, 11.0, gap, 0.55 - 0.05 * phase, 1, Color("ffd878"), 420.0)
			Audio.sfx("bell"))
	after(1.0 + n * 0.6 + 1.6, func(): _finish(1.4))


func _a_lash() -> void:
	winding = true
	var n := 2 + phase
	for i in n:
		after(0.4 + i * 0.8, func():
			var d := _pp() - global_position
			fx.line(global_position, d, 420.0, 24.0, 0.85 - 0.1 * phase, 1, Color("b8a0ff"))
			if phase == 3:
				fx.line(global_position, d.rotated(0.5), 420.0, 20.0, 0.75, 1, Color("b8a0ff"))
				fx.line(global_position, d.rotated(-0.5), 420.0, 20.0, 0.75, 1, Color("b8a0ff")))
	after(0.4 + n * 0.8 + 0.8, func(): _finish(0.6))


func _a_drop() -> void:
	winding = true
	var n := 3 + phase * 2
	after(0.5, func(): winding = false)
	for i in n:
		after(0.4 + i * 0.28, func():
			var p := _pp()
			if i > 0:
				p = _arena_pos(p + Vector2.from_angle(randf() * TAU) * randf_range(25.0, 110.0))
			fx.circle(p, 27.0, 1.0, 1, Color("ffd060"), 0.3, "bell"))
	after(0.4 + n * 0.28 + 1.5, func(): _finish(1.2))


func _a_summon() -> void:
	winding = true
	after(0.9, func():
		winding = false
		Audio.sfx("roar")
		level.shake(5.0)
		var bats := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.kind == "bat":
				bats += 1
		for i in maxi(0, mini(2 + phase - 2, 5 - bats)):
			level.spawn_enemy("bat", global_position + Vector2.from_angle(randf() * TAU) * 60.0))
	after(2.6, func(): _finish(1.6))


# ---------------------------------------------------------- Clockwork Revenant

func _a_cogs() -> void:
	winding = true
	var volleys := phase
	var n := 1 + phase * 2
	for v in volleys:
		after(0.8 + v * 0.95, func():
			winding = false
			Audio.sfx("switch")
			var base := (_pp() - global_position).angle() + (0.18 if v % 2 == 1 else 0.0)
			for i in n:
				var a := base - 0.55 + 1.1 * float(i) / float(maxi(n - 1, 1))
				fx.shot(global_position + Vector2.from_angle(a) * 28.0, Vector2.from_angle(a) * (150.0 + 18.0 * phase), 7.0, 3.5, 1, Color("e0a040")))
	after(0.8 + volleys * 0.95 + 1.0, func():
		level.spark(global_position, Color(0.9, 0.9, 0.9), 14)
		_finish(1.6))


func _a_hands() -> void:
	winding = true
	var steps := 7 + phase
	var dir := 1.0 if randf() < 0.5 else -1.0
	var base := (_pp() - global_position).angle() - dir * 0.5
	var gap := 0.44 - 0.04 * phase
	for i in steps:
		after(0.5 + i * gap, func():
			Audio.sfx("switch")
			var a := base + dir * i * 0.5236
			fx.line(global_position, Vector2.from_angle(a), 380.0, 15.0, 0.6, 1, Color("ffc040"))
			if phase == 3:
				fx.line(global_position, Vector2.from_angle(a + PI), 380.0, 15.0, 0.6, 1, Color("60d8e0")))
	after(0.5 + steps * gap + 1.2, func():
		winding = false
		_finish(1.0))


func _a_vents() -> void:
	winding = true
	var rings := [[6, 100.0], [10, 190.0], [14, 280.0]]
	var col := Color("7fe0e0")
	for r in mini(phase + 1, 3):
		var n: int = rings[r][0]
		var rad: float = rings[r][1]
		var off := randf() * TAU
		for i in n:
			after(0.5 + r * 1.1 + i * 0.1, func():
				var a := off + TAU * float(i) / float(n)
				fx.circle(_arena_pos(global_position + Vector2.from_angle(a) * rad), 25.0, 0.9, 1, col, 0.35, "steam"))
	after(0.5 + mini(phase + 1, 3) * 1.1 + 1.8, func():
		winding = false
		_finish(1.0))


func _a_rift() -> void:
	winding = true
	after(0.7, func():
		winding = false
		Audio.sfx("switch")
		for i in 3:
			if fx.count_kind("zone") < 4:
				fx.zone(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (0.0 if i == 0 else 70.0)), 46.0, 7.0, Color("80c8ff"))
		var a := (_pp() - global_position).angle()
		for i in 3:
			fx.shot(global_position + Vector2.from_angle(a) * 28.0, Vector2.from_angle(a - 0.3 + 0.3 * i) * 130.0, 7.0, 3.0, 1, Color("e0a040")))
	after(3.0, func(): _finish(0.8))


# ---------------------------------------------------------- shared

func _a_rush() -> void:
	winding = true
	charge_dir = (_pp() - global_position).normalized()
	fx.line(global_position, charge_dir, 520.0, 70.0, 0.95, 0, Color("ff7060"), 0.01)
	after(0.95, func():
		winding = false
		state = "rush"
		st = 0.0
		rushing = true
		Audio.sfx("roar"))


func _rush_crash() -> void:
	state = "stun"
	st = 0.0
	rushing = false
	exposed = 2.4
	Audio.sfx("hit")
	level.shake(9.0)
	level.spark(global_position + charge_dir * 28.0, Color(1, 0.8, 0.5), 20)
	if kind == "bell_giant":
		for i in 4:
			fx.circle(_arena_pos(global_position + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 130.0)), 27.0, 1.1 + i * 0.2, 1, Color("ffd060"), 0.3, "bell")
	else:
		for i in 6:
			fx.shot(global_position, Vector2.from_angle(TAU * float(i) / 6.0 + 0.3) * 150.0, 7.0, 3.0, 1, Color("e0a040"))


func hurt(dmg: int, dir: Vector2) -> void:
	if state in ["dormant", "intro", "dying"]:
		return
	hp -= dmg * (2 if exposed > 0.0 else 1)
	flash = 0.12
	knock = dir * 25.0
	Audio.sfx("hit")
	level.spark(global_position + Vector2(0, -10), Color(1, 0.85, 0.5), 8)
	level.shake(2.0)
	if hp <= 0:
		state = "dying"
		queue.clear()
		fx.clear()
		winding = false
		death_t = 0.0
		Audio.sfx("roar")
		return
	if phase == 1 and hp <= max_hp * 0.66:
		_phase_up(2)
	elif phase == 2 and hp <= max_hp * 0.33:
		_phase_up(3)


func _phase_up(p: int) -> void:
	phase = p
	state = "stagger"
	st = 0.0
	exposed = 1.7
	queue.clear()
	fx.clear()
	winding = false
	speed += 8.0
	Audio.sfx("roar")
	level.shake(10.0)
	level.spark(global_position, _gold(), 24)
	level.hud.show_notice(_phase_line())


func _phase_line() -> String:
	if kind == "bell_giant":
		return "The Warden tolls the second bell!" if phase == 2 else "The last bell cracks \u2014 the Warden rages!"
	return "The Revenant's gears scream faster!" if phase == 2 else "Time itself stutters around the Revenant!"


# ---------------------------------------------------------- drawing

func _gear(pos: Vector2, r: float, teeth: int, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in teeth * 2:
		var rr := r if i % 2 == 0 else r * 0.82
		for k in 2:
			pts.append(pos + Vector2.from_angle(rot + TAU * (float(i) + k * 0.5) / float(teeth * 2)) * rr)
	draw_colored_polygon(pts, Color(Art.OUT))
	draw_circle(pos, r * 0.78, col)
	draw_circle(pos, r * 0.3, Color("1c1520"))
	for i in 4:
		var a := rot + PI * 0.5 * i
		draw_line(pos + Vector2.from_angle(a) * r * 0.3, pos + Vector2.from_angle(a) * r * 0.74, Color(Art.OUT), 1.6)


func _draw() -> void:
	var dormant := state == "dormant"
	var rise := clampf(st / 1.6, 0.0, 1.0) if state == "intro" else (0.0 if dormant else 1.0)
	var tint := Color.WHITE
	if phase == 2:
		tint = Color(1.0, 0.9, 0.9)
	elif phase == 3:
		tint = Color(1.0, 0.72 + 0.1 * sin(t * 8.0), 0.72)
	if exposed > 0.0 and int(t * 12.0) % 2 == 0:
		tint = Color(1.5, 1.4, 0.9)
	if dormant:
		tint = Color(0.55, 0.55, 0.65)
	self_modulate = Color(tint, 0.45 + 0.55 * rise) if state == "intro" else tint
	var bob := sin(t * 1.8) * 1.2 if not dormant else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
	if kind == "clock_giant":
		_gear(Vector2(0, -80), 70.0, 14, t * 0.35, Color("6e5326"))
		_gear(Vector2(-34, -10), 14.0, 10, -t * 0.9, Color("8a6a30"))
		_gear(Vector2(34, -10), 14.0, 10, -t * 0.9 + 0.3, Color("8a6a30"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind == "bell_giant":
		Art.warden(self, facing, t, flash, winding)
	else:
		Art.colossus(self, facing, t, flash, winding)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
	if kind == "bell_giant":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(E * 1.7, E * 1.7))
		_draw_bell(bob)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
	else:
		_draw_clock_face(bob)
	if exposed > 0.0 and state != "dying":
		for i in 4:
			var a := t * 4.0 + TAU * i / 4.0
			draw_circle(Vector2(cos(a) * 26.0, -78.0 + sin(a * 2.0) * 4.0), 2.2, Color(1, 0.95, 0.5, 0.9))
	if winding:
		draw_arc(Vector2(0, -20), 52.0 + sin(t * 16.0) * 3.0, 0, TAU, 40, Color(_gold(), 0.45), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bell(off: float) -> void:
	var sway := sin(t * 1.7) * 0.08 + (0.35 if winding else 0.0)
	var anchor := Vector2(-48, -52 + off)
	var pos := anchor + Vector2(sin(sway) * 40.0, cos(sway) * 40.0 + 4.0)
	draw_line(anchor, pos + Vector2(0, -16), Color("3a3440"), 3.0)
	for i in 5:
		draw_circle(anchor.lerp(pos + Vector2(0, -16), i / 4.0), 2.2, Color("6a6474"))
	var body := PackedVector2Array([pos + Vector2(-5, -14), pos + Vector2(5, -14), pos + Vector2(14, 8), pos + Vector2(18, 16), pos + Vector2(-18, 16), pos + Vector2(-14, 8)])
	draw_colored_polygon(body, Color(Art.OUT))
	var inner := PackedVector2Array([pos + Vector2(-3.5, -12.5), pos + Vector2(3.5, -12.5), pos + Vector2(12, 8), pos + Vector2(15, 14), pos + Vector2(-15, 14), pos + Vector2(-12, 8)])
	draw_colored_polygon(inner, Color("a8782c") if flash <= 0.0 else Color.WHITE)
	draw_line(pos + Vector2(-8, -8), pos + Vector2(-11, 8), Color("e0b45a"), 2.0)
	draw_circle(pos + Vector2(0, 16), 3.0, Color("3a3440"))


func _draw_clock_face(off: float) -> void:
	var c := Vector2(0, -48 + off)
	draw_circle(c, 17.0, Color(Art.OUT))
	draw_circle(c, 15.0, Color("e8dcc0") if flash <= 0.0 else Color.WHITE)
	for i in 12:
		var a := TAU * i / 12.0
		draw_line(c + Vector2.from_angle(a) * 12.0, c + Vector2.from_angle(a) * 14.0, Color("2a2018"), 1.0)
	var m := t * (1.6 if phase < 3 else 5.0)
	draw_line(c, c + Vector2.from_angle(m) * 12.0, Color("2a2018"), 1.4)
	draw_line(c, c + Vector2.from_angle(m / 12.0) * 8.0, Color("7a2a2a"), 1.8)
	draw_circle(c, 1.5, Color("2a2018"))
