extends CharacterBody2D
## Arena bosses: the Nor' Loch Kelpie of Edinburgh (kelpie_giant) and the Golem of Prague (golem_giant).
## Both are huge multi-phase foes with telegraphed, theme-specific attack patterns.

const Art = preload("res://src/core/art.gd")
const HazardScript = preload("res://src/entities/hazards.gd")
const E := 1.0 / 3.2  # extras are authored at 3.2x body size

var kind := "kelpie_giant"
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
	if k == "kelpie_giant":
		title = "NOR' LOCH KELPIE"
		hp = 70
		speed = 30.0
		scale = Vector2(3.0, 3.0)
	else:
		title = "GOLEM OF PRAGUE"
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
	return Color("7fe8e0") if kind == "kelpie_giant" else Color("d8b078")


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
				Audio.play_music("boss" if kind == "kelpie_giant" else "boss2")
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
	if kind == "kelpie_giant":
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


# ---------------------------------------------------------- Nor' Loch Kelpie (tide rings, mane lashes, geysers, drowned lights)

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
			fx.ring(global_position, 125.0 + 12.0 * phase, 11.0, gap, 0.55 - 0.05 * phase, 1, Color("78e8f0"), 420.0)
			Audio.sfx("bell"))
	after(1.0 + n * 0.6 + 1.6, func(): _finish(1.4))


func _a_lash() -> void:
	winding = true
	var n := 2 + phase
	for i in n:
		after(0.4 + i * 0.8, func():
			var d := _pp() - global_position
			fx.line(global_position, d, 420.0, 24.0, 0.85 - 0.1 * phase, 1, Color("5fd0c0"))
			if phase == 3:
				fx.line(global_position, d.rotated(0.5), 420.0, 20.0, 0.75, 1, Color("5fd0c0"))
				fx.line(global_position, d.rotated(-0.5), 420.0, 20.0, 0.75, 1, Color("5fd0c0")))
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
			fx.circle(p, 27.0, 1.0, 1, Color("60d8f0"), 0.3, "steam"))
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


# ---------------------------------------------------------- Golem of Prague (clay boulders, sweeping arms, stomps, mud)

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
				fx.shot(global_position + Vector2.from_angle(a) * 28.0, Vector2.from_angle(a) * (150.0 + 18.0 * phase), 9.0, 3.5, 1, Color("a07448"), "orb"))
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
			fx.line(global_position, Vector2.from_angle(a), 380.0, 22.0, 0.6, 1, Color("c89a60"))
			if phase == 3:
				fx.line(global_position, Vector2.from_angle(a + PI), 380.0, 22.0, 0.6, 1, Color("c89a60")))
	after(0.5 + steps * gap + 1.2, func():
		winding = false
		_finish(1.0))


func _a_vents() -> void:
	winding = true
	var rings := [[6, 100.0], [10, 190.0], [14, 280.0]]
	var col := Color("c8a878")
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
				fx.zone(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (0.0 if i == 0 else 70.0)), 46.0, 7.0, Color("6a5038"))
		var a := (_pp() - global_position).angle()
		for i in 3:
			fx.shot(global_position + Vector2.from_angle(a) * 28.0, Vector2.from_angle(a - 0.3 + 0.3 * i) * 130.0, 9.0, 3.0, 1, Color("a07448"), "orb"))
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
	if kind == "kelpie_giant":
		for i in 4:
			fx.circle(_arena_pos(global_position + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 130.0)), 27.0, 1.1 + i * 0.2, 1, Color("60d8f0"), 0.3, "steam")
	else:
		for i in 6:
			fx.shot(global_position, Vector2.from_angle(TAU * float(i) / 6.0 + 0.3) * 150.0, 9.0, 3.0, 1, Color("a07448"), "orb")


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
	if kind == "kelpie_giant":
		return "The Loch surges around the Kelpie!" if phase == 2 else "The Kelpie rears \u2014 the whole cistern is a flood!"
	return "The Golem's clay hardens and its stride quickens!" if phase == 2 else "The Golem's brow blazes \u2014 it rages unchecked!"


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
	if kind == "golem_giant":
		tint = Color(tint.r * 1.1, tint.g * 0.82, tint.b * 0.62, tint.a)
	if dormant:
		tint = Color(0.55, 0.55, 0.65)
	self_modulate = Color(tint, 0.45 + 0.55 * rise) if state == "intro" else tint
	var bob := sin(t * 1.8) * 1.2 if not dormant else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind == "kelpie_giant":
		_draw_kelpie(bob)
	else:
		Art.colossus(self, facing, t, flash, winding)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
		_draw_emet(bob)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
	if exposed > 0.0 and state != "dying":
		for i in 4:
			var a := t * 4.0 + TAU * i / 4.0
			draw_circle(Vector2(cos(a) * 26.0, -78.0 + sin(a * 2.0) * 4.0), 2.2, Color(1, 0.95, 0.5, 0.9))
	if winding:
		draw_arc(Vector2(0, -20), 52.0 + sin(t * 16.0) * 3.0, 0, TAU, 40, Color(_gold(), 0.45), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_kelpie(off: float) -> void:
	var o := Color(Art.OUT)
	var hit := flash > 0.0
	var body := Color("1f4a55") if not hit else Color.WHITE
	var lite := Color("3a8a94") if not hit else Color.WHITE
	for i in 3:
		var r := 22.0 + i * 6.0 + fmod(t * 8.0, 6.0)
		draw_arc(Vector2(0, 8), r, 0.2, PI - 0.2, 20, Color(0.5, 0.9, 0.95, 0.35 - i * 0.1), 1.0)
		draw_arc(Vector2(0, 8), r, PI + 0.2, TAU - 0.2, 20, Color(0.5, 0.9, 0.95, 0.35 - i * 0.1), 1.0)
	draw_circle(Vector2(0, 6), 20.0, Color(0.1, 0.3, 0.35, 0.8))
	var sw := sin(t * 1.6) * 2.0 + (4.0 if winding else 0.0)
	var neck := PackedVector2Array([Vector2(-14, 8), Vector2(-8, -24 + off), Vector2(-2 + sw, -40 + off), Vector2(10 + sw, -38 + off), Vector2(12, -26 + off), Vector2(14, 8)])
	draw_colored_polygon(neck, o)
	var neck_in := PackedVector2Array([Vector2(-12, 6), Vector2(-6, -23 + off), Vector2(-1 + sw, -38 + off), Vector2(9 + sw, -36 + off), Vector2(10, -26 + off), Vector2(12, 6)])
	draw_colored_polygon(neck_in, body)
	var hd := PackedVector2Array([Vector2(-6 + sw, -44 + off), Vector2(8 + sw, -46 + off), Vector2(22 + sw, -36 + off), Vector2(20 + sw, -31 + off), Vector2(6 + sw, -33 + off), Vector2(-4 + sw, -36 + off)])
	draw_colored_polygon(hd, o)
	var hd_in := PackedVector2Array([Vector2(-4 + sw, -43 + off), Vector2(8 + sw, -44.5 + off), Vector2(20 + sw, -36 + off), Vector2(19 + sw, -33 + off), Vector2(6 + sw, -34.5 + off), Vector2(-3 + sw, -37 + off)])
	draw_colored_polygon(hd_in, lite)
	draw_colored_polygon(PackedVector2Array([Vector2(-2 + sw, -44 + off), Vector2(0 + sw, -52 + off), Vector2(4 + sw, -44 + off)]), body)
	var eye := Color(0.6, 1.0, 0.95) if exposed <= 0.0 else Color(1, 0.9, 0.4)
	draw_circle(Vector2(8 + sw, -39 + off), 2.0, eye)
	draw_circle(Vector2(8 + sw, -39 + off), 4.0, Color(eye, 0.25))
	for i in 7:
		var y := -42.0 + i * 7.0
		var wv := sin(t * 2.2 + i) * 3.0
		draw_line(Vector2(-4 + sw * (1.0 - i / 7.0), y + off), Vector2(-14 + wv, y + 8.0 + off), Color("2e7a4a"), 2.2)
		draw_line(Vector2(-14 + wv, y + 8.0 + off), Vector2(-17 + wv * 1.4, y + 14.0 + off), Color("56b070"), 1.4)
	for i in 5:
		var dp := fmod(t * 14.0 + i * 9.0, 30.0)
		draw_circle(Vector2(14.0 + i * 2.0 + sw, -30.0 + dp + off), 1.1, Color(0.7, 0.95, 1.0, 0.7))
	var lp := Vector2(-6 + sw, -26 + off + sin(t * 2.0) * 1.5)
	draw_circle(lp, 6.0, Color(1.0, 0.8, 0.3, 0.18))
	draw_circle(lp, 2.2, Color("ffd060"))


func _draw_emet(off: float) -> void:
	var c := Vector2(0, -48 + off) * 1.0
	var col := Color(1.0, 0.75, 0.3, 0.95) if phase < 3 else Color(1.0, 0.35 + 0.2 * sin(t * 10.0), 0.2, 1.0)
	draw_circle(c, 17.0, Color(col, 0.12))
	var glyphs := 3 if phase < 3 else 2
	var start := -9.0 if phase < 3 else -3.0
	for g in glyphs:
		var gx := c.x + start + g * 9.0
		var gy := c.y
		match g + (0 if phase < 3 else 1):
			0:
				draw_line(Vector2(gx - 4, gy - 5), Vector2(gx + 3, gy - 5), col, 1.8)
				draw_line(Vector2(gx + 3, gy - 5), Vector2(gx - 3, gy + 5), col, 1.8)
				draw_line(Vector2(gx - 4, gy + 5), Vector2(gx + 4, gy + 5), col, 1.8)
			1:
				draw_line(Vector2(gx - 4, gy - 5), Vector2(gx + 4, gy - 5), col, 1.8)
				draw_line(Vector2(gx + 4, gy - 5), Vector2(gx + 4, gy + 5), col, 1.8)
				draw_line(Vector2(gx - 4, gy + 5), Vector2(gx - 4, gy + 1), col, 1.8)
			_:
				draw_line(Vector2(gx - 5, gy - 5), Vector2(gx + 5, gy - 5), col, 1.8)
				draw_line(Vector2(gx, gy - 5), Vector2(gx, gy + 5), col, 1.8)
				draw_line(Vector2(gx - 5, gy + 5), Vector2(gx + 5, gy + 5), col, 1.8)
