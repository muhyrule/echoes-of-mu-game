extends CharacterBody2D
## Mu: 8-direction movement, sword combat, form shifting.

const Art = preload("res://src/core/art.gd")

signal died

const FollowerScript = preload("res://src/entities/follower.gd")
const MOVE := {"mu": 88.0, "isolde": 80.0, "wren": 104.0, "corvin": 78.0}

const WORLD := 1
const BARS := 2

var level: Node2D
var facing := Vector2.DOWN
var attacking := 0.0
var attack_cd := 0.0
var invuln := 0.0
var ward := 0.0
var knock := Vector2.ZERO
var push_t := 0.0
var dead := false
var slow := 0.0
var t := 0.0
var moving := false
var _hit_set: Array = []
var brain: Node2D
var rolling := 0.0
var roll_cd := 0.0
var roll_dir := Vector2.DOWN
var roll_ang := 0.0
var guarding := false
var guard_t := 0.0
var guard_hits := 0
var guard_idle := 0.0
var guard_stun := 0.0
var parry_fx := 0.0
var trail: Array = []

# Dodge-roll tuning per hero: distance feel (speed), duration, cooldown.
const ROLL := {
	"mu": {"spd": 175.0, "dur": 0.40, "cd": 0.8},
	"isolde": {"spd": 150.0, "dur": 0.42, "cd": 1.0},
	"wren": {"spd": 215.0, "dur": 0.36, "cd": 0.6},
	"corvin": {"spd": 150.0, "dur": 0.44, "cd": 1.0},
}
const GUARD_NAME := {"mu": "Moonlit Parry", "isolde": "Bell Ward", "wren": "Shadow Slip", "corvin": "Aegis Plate"}
const PARRY_WINDOW := 0.22


func _ready() -> void:
	collision_layer = 8
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 8)
	shape.shape = r
	shape.position = Vector2(0, 2)
	add_child(shape)
	brain = Node2D.new()
	brain.set_script(FollowerScript)
	brain.set("puppet", true)
	brain.set("level", level)
	brain.set("target", self)
	add_child(brain)
	apply_form()
	add_to_group("player")


func is_mu() -> bool:
	return GameState.lead == "mu"


func set_lead(id: String) -> void:
	GameState.lead = id
	brain.set("hero", "" if id == "mu" else id)
	brain.set("pal", FollowerScript.PALS.get(id, Art.PAL_MU))
	apply_form()


func apply_form() -> void:
	# Wraith Mu slips through iron bars; Mu does not.
	collision_mask = WORLD if (is_mu() and GameState.form == "wraith") else (WORLD | BARS)


func _physics_process(delta: float) -> void:
	t += delta
	if brain.get("level") == null:
		brain.set("level", level)
	invuln = maxf(0.0, invuln - delta)
	ward = maxf(0.0, ward - delta)
	attack_cd = maxf(0.0, attack_cd - delta)
	attacking = maxf(0.0, attacking - delta)
	roll_cd = maxf(0.0, roll_cd - delta)
	parry_fx = maxf(0.0, parry_fx - delta)
	guard_stun = maxf(0.0, guard_stun - delta)
	guard_idle += delta
	if guard_idle > 2.5:
		guard_hits = 0
	if rolling > 0.0:
		rolling = maxf(0.0, rolling - delta)
		if rolling <= 0.0:
			roll_ang = 0.0
	if dead or Dialogue.blocking() or (level and level.frozen):
		rolling = 0.0
		roll_ang = 0.0
		guarding = false
		trail.clear()
	if dead or Dialogue.blocking() or (level and level.frozen):
		velocity = Vector2.ZERO
		moving = false
		queue_redraw()
		return
	for sid in ["tonic", "elixir", "candle"]:
		if Input.is_action_just_pressed("use_" + sid):
			use_supply(sid)

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if rolling > 0.0:
		_roll_step(delta)
		queue_redraw()
		return
	if Input.is_action_just_pressed("dodge") and roll_cd <= 0.0 and guard_stun <= 0.0 and attacking <= 0.0 and not (level and level.in_bars(global_position)):
		_start_roll(dir)
		queue_redraw()
		return
	var want_guard := Input.is_action_pressed("guard") and guard_stun <= 0.0 and attacking <= 0.0
	if want_guard and not guarding:
		guard_t = 0.0
		Audio.sfx("switch")
	guarding = want_guard
	if guarding:
		guard_t += delta
	moving = dir != Vector2.ZERO
	if moving and attacking <= 0.0:
		facing = dir.normalized()
	var spd: float = float(MOVE.get(GameState.lead, 88.0))
	if is_mu():
		spd = 118.0 if GameState.form == "wraith" else (70.0 if GameState.form == "gargoyle" else 88.0)
	if attacking > 0.0:
		spd *= 0.3
	if guarding:
		spd *= 0.45
	if slow > 0.0:
		slow -= delta
		spd *= 0.5
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	velocity = dir * spd + knock
	move_and_slide()
	_check_push(dir, delta)

	if guarding or guard_stun > 0.0:
		pass
	elif is_mu():
		if Input.is_action_just_pressed("attack") and attack_cd <= 0.0:
			_start_attack()
		if attacking > 0.0:
			_sword_hits()
		if Input.is_action_just_pressed("form"):
			cycle_form()
	else:
		if Input.is_action_pressed("attack"):
			brain.manual_attack()
		if Input.is_action_just_pressed("form") and level:
			level.hud.show_notice("Only Mu can shift forms")
	if Input.is_action_just_pressed("interact"):
		level.interact()
	queue_redraw()


func _start_roll(dir: Vector2) -> void:
	roll_dir = dir.normalized() if dir != Vector2.ZERO else facing
	facing = roll_dir
	var k: Dictionary = ROLL[GameState.lead] if ROLL.has(GameState.lead) else ROLL.mu
	rolling = float(k.dur)
	roll_cd = float(k.cd)
	guarding = false
	trail.clear()
	Audio.sfx("slash")
	_roll_dust()


func _roll_step(delta: float) -> void:
	var k: Dictionary = ROLL[GameState.lead] if ROLL.has(GameState.lead) else ROLL.mu
	var u: float = 1.0 - rolling / float(k.dur)
	roll_ang = u * TAU * 1.0 * (1.0 if roll_dir.x >= 0.0 else -1.0)
	if absf(roll_dir.x) < 0.3:
		roll_ang = u * TAU * (1.0 if roll_dir.y >= 0.0 else -1.0)
	var ease_f: float = 1.35 - u * 0.9
	velocity = roll_dir * float(k.spd) * ease_f
	moving = true
	move_and_slide()
	if int(t * 30.0) != int((t - delta) * 30.0):
		trail.append({"p": global_position, "a": roll_ang, "t": 0.0})
		if trail.size() > 6:
			trail.pop_front()
		if int(t * 15.0) != int((t - delta) * 15.0):
			_roll_dust()
	for tr in trail:
		tr.t += delta


func _roll_dust() -> void:
	if level == null:
		return
	var afx = level.get("arena_fx")
	if afx != null:
		afx.splash(global_position + Vector2(0, 3), 9.0)
	else:
		level.spark(global_position + Vector2(0, 4), Color(0.8, 0.75, 0.65), 5)


# Called from hurt(); returns true when the guard swallowed the hit.
func _guard_absorb(dmg: int, from_dir: Vector2) -> bool:
	guard_idle = 0.0
	if guard_t <= PARRY_WINDOW:
		_parry(from_dir)
		return true
	guard_hits += 1
	Audio.sfx("hit")
	parry_fx = 0.2
	knock = from_dir * 70.0
	invuln = 0.35
	if level:
		level.spark(global_position + facing * 8.0, Color(0.8, 0.85, 1.0), 6)
	if guard_hits >= 3:
		guard_hits = 0
		guarding = false
		guard_stun = 0.9
		invuln = 0.4
		if level:
			level.hud.show_notice("Guard broken!")
	return true


func _parry(from_dir: Vector2) -> void:
	parry_fx = 0.45
	invuln = 0.5
	guard_hits = 0
	Audio.sfx("bell")
	var hero: String = GameState.lead
	var col: Color = {"mu": Color(0.8, 0.9, 1.0), "isolde": Color(1.0, 0.85, 0.4), "wren": Color(0.95, 0.35, 0.41), "corvin": Color(0.9, 0.75, 0.35)}.get(hero, Color.WHITE)
	var rad: float = {"mu": 62.0, "isolde": 90.0, "wren": 50.0, "corvin": 80.0}.get(hero, 60.0)
	if level:
		level.shake(4.0)
		level.spark(global_position, col, 16)
	for hz in get_tree().get_nodes_in_group("hazards"):
		hz.cancel_near(global_position, rad + 20.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		var to: Vector2 = e.global_position - global_position
		if to.length() > rad + e.hit_radius:
			continue
		var n: Vector2 = to.normalized() if to.length() > 0.1 else facing
		match hero:
			"mu":
				e.hurt(2 + Gear.atk_bonus(), n)
			"isolde":
				e.hurt(1, n)
				if e.get("knock") != null:
					e.knock = n * 160.0
			"wren":
				e.hurt(1, n)
			"corvin":
				e.hurt(2, n)
	match hero:
		"wren":
			var dst := global_position + from_dir * 34.0
			if level and not level._is_solid_char(Vector2i(int(dst.x / 16.0), int(dst.y / 16.0))):
				level.spark(global_position, col, 10)
				global_position = dst
			invuln = 0.9
		"corvin":
			ward = maxf(ward, 1.6)
		"isolde":
			if level:
				level.shake(6.0)


func draw_guard(c: CanvasItem) -> void:
	if rolling > 0.0:
		for tr in trail:
			var a: float = clampf(0.35 - tr.t * 1.2, 0.0, 0.35)
			c.draw_circle(to_local(tr.p) + Vector2(0, -5), 5.0, Color(1, 1, 1, a))
	var hero: String = GameState.lead
	var col: Color = {"mu": Color(0.8, 0.9, 1.0), "isolde": Color(1.0, 0.85, 0.4), "wren": Color(0.95, 0.35, 0.41), "corvin": Color(0.9, 0.75, 0.35)}.get(hero, Color.WHITE)
	if guard_stun > 0.0:
		c.draw_arc(Vector2(0, -6), 10.0, t * 10.0, t * 10.0 + 4.0, 10, Color(1, 0.5, 0.4, 0.8), 1.5)
	if guarding:
		var f := facing.angle()
		var win: bool = guard_t <= PARRY_WINDOW
		var a2 := 0.9 if win else 0.55
		var cc := Color(1, 1, 1, a2) if win else Color(col, a2)
		match hero:
			"mu":
				c.draw_arc(Vector2(0, -6), 14.0, f - 1.0, f + 1.0, 14, cc, 2.5)
				c.draw_arc(Vector2(0, -6), 11.0, f - 0.8, f + 0.8, 12, Color(col, 0.4), 1.0)
			"isolde":
				c.draw_arc(Vector2(0, -6), 14.0, 0, TAU, 24, Color(cc, a2 * 0.7), 1.5)
				for i in 4:
					var b := t * 1.5 + i * TAU / 4.0
					c.draw_circle(Vector2(0, -6) + Vector2.from_angle(b) * 14.0, 1.6, cc)
			"wren":
				for i in 3:
					c.draw_circle(Vector2(0, -6) + Vector2.from_angle(f + 0.5 * (i - 1)) * (11.0 + i), 2.0 - i * 0.3, Color(col, a2 * (1.0 - i * 0.25)))
				c.draw_arc(Vector2(0, -6), 12.0, f - 0.7, f + 0.7, 10, Color(col, 0.5), 1.0)
			"corvin":
				var pts := PackedVector2Array()
				for i in 6:
					pts.append(Vector2(0, -6) + facing * 11.0 + Vector2.from_angle(f + PI / 2.0).rotated(0) * (i - 2.5) * 3.0 + facing * (absf(i - 2.5) * -1.0))
				c.draw_polyline(pts, cc, 2.5)
				c.draw_circle(Vector2(0, -6) + facing * 11.0, 2.0, Color(col, a2))
	if parry_fx > 0.0:
		var u := 1.0 - parry_fx / 0.45
		c.draw_arc(Vector2(0, -6), 8.0 + u * 44.0, 0, TAU, 28, Color(col, 0.9 * (1.0 - u)), 2.5)
		if hero == "mu":
			c.draw_arc(Vector2(0, -6), 8.0 + u * 52.0, facing.angle() - 1.2, facing.angle() + 1.2, 14, Color(1, 1, 1, 0.9 * (1.0 - u)), 3.0)
		elif hero == "wren":
			for i in 6:
				c.draw_rect(Rect2(Vector2(0, -6) + Vector2.from_angle(i * 1.05) * (6.0 + u * 20.0) - Vector2(1, 1), Vector2(2, 2)), Color(col, 1.0 - u))
		elif hero == "corvin":
			for i in 8:
				c.draw_circle(Vector2(0, -6) + Vector2.from_angle(t * 6.0 + i * TAU / 8.0) * (8.0 + u * 22.0), 1.4, Color(col, 1.0 - u))


func _check_push(dir: Vector2, delta: float) -> void:
	var pushed := false
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider()
		if body == null or body.get_parent() == null:
			continue
		var prop = body.get_parent()
		if prop.has_method("push"):
			var n := -col.get_normal()
			if absf(n.x) > 0.9 or absf(n.y) > 0.9:
				var d := Vector2(roundf(n.x), roundf(n.y))
				if dir.dot(d) > 0.5:
					pushed = true
					push_t += delta
					if push_t > 0.3:
						prop.push(d)
						push_t = 0.0
	if not pushed:
		push_t = 0.0


func _start_attack() -> void:
	attacking = 0.2
	attack_cd = {"wraith": 0.42, "gargoyle": 0.6}.get(GameState.form, 0.32) * Gear.cooldown_mult()
	_hit_set.clear()
	Audio.sfx("slash")


func _sword_hits() -> void:
	var dmg: int = {"wraith": 1, "gargoyle": 3}.get(GameState.form, 2) + Gear.atk_bonus()
	var reach: float = {"wraith": 24.0, "gargoyle": 26.0}.get(GameState.form, 30.0)
	if GameState.form == "gargoyle" and level:
		level.try_break(global_position + facing * 12.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in _hit_set:
			continue
		var to: Vector2 = e.global_position - global_position
		var near: bool = to.length() < e.hit_radius + 8.0
		if near or (to.length() < reach + e.hit_radius and to.normalized().dot(facing) > 0.25):
			_hit_set.append(e)
			e.hurt(dmg, to.normalized() if to.length() > 0.1 else facing)


func use_supply(sid: String) -> void:
	if int(GameState.supplies.get(sid, 0)) <= 0:
		return
	if sid != "candle" and GameState.hp >= GameState.max_hp:
		return
	GameState.supplies[sid] -= 1
	match sid:
		"tonic":
			GameState.hp = mini(GameState.max_hp, GameState.hp + 3)
		"elixir":
			GameState.hp = GameState.max_hp
		"candle":
			ward = 8.0
	Audio.sfx("switch")
	if level:
		level.spark(global_position, Color(1.0, 0.8, 0.4), 10)
		level.hud.show_notice("Used %s" % Gear.SUPPLIES[sid].name)


func cycle_form() -> void:
	if GameState.forms.size() < 2:
		return
	if level and level.in_bars(global_position):
		return
	var i := GameState.forms.find(GameState.form)
	GameState.form = GameState.forms[(i + 1) % GameState.forms.size()]
	apply_form()
	Audio.sfx("form")


func hurt(dmg: int, from_dir: Vector2) -> void:
	if invuln > 0.0 or ward > 0.0 or dead or rolling > 0.0:
		return
	if guarding and _guard_absorb(dmg, from_dir):
		return
	if GameState.form == "gargoyle" and is_mu():
		dmg = maxi(1, dmg - 1)
	var armor := Gear.def_total()
	dmg = maxi(1, dmg - armor / 3)
	GameState.hp -= dmg
	invuln = 1.0 + 0.06 * armor
	knock = from_dir * 170.0
	Audio.sfx("hurt")
	if level:
		level.shake(4.0)
		level.spark(global_position, Color(0.9, 0.3, 0.4), 12)
	if GameState.hp <= 0:
		dead = true
		died.emit()


func _draw() -> void:
	if not is_mu():
		if ward > 0.0:
			var wa2 := 0.35 + 0.15 * sin(t * 8.0) if ward > 1.5 else 0.35 * (ward / 1.5)
			draw_circle(Vector2(0, -6), 15.0, Color(1.0, 0.8, 0.4, wa2 * 0.5))
			draw_arc(Vector2(0, -6), 15.0, 0, TAU, 28, Color(1.0, 0.9, 0.6, wa2 + 0.2), 1.2)
		return
	if invuln > 0.0 and parry_fx <= 0.0 and int(t * 20.0) % 2 == 0:
		return
	var wraith := GameState.form == "wraith"
	var garg := GameState.form == "gargoyle"
	var pal := Art.PAL_WRAITH if wraith else (Art.PAL_GARGOYLE if garg else Art.PAL_MU)
	var yoff := sin(t * 3.0) * 1.5 if wraith else 0.0
	draw_set_transform(Vector2(0, yoff), 0.0, Vector2.ONE)
	if garg:
		_draw_wings()
	if not wraith and not garg:
		pal = Gear.styled("mu", pal)
	if ward > 0.0:
		var wa := 0.35 + 0.15 * sin(t * 8.0) if ward > 1.5 else 0.35 * (ward / 1.5)
		draw_circle(Vector2(0, -6), 15.0, Color(1.0, 0.8, 0.4, wa * 0.5))
		draw_arc(Vector2(0, -6), 15.0, 0, TAU, 28, Color(1.0, 0.9, 0.6, wa + 0.2), 1.2)
	Art.person(self, facing, t, pal, moving, 0.75 if wraith else 1.0, attacking, yoff, roll_ang)
	if garg:
		_draw_horns()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_guard(self)
	if attacking > 0.0:
		var a := facing.angle()
		var k := 1.0 - attacking / 0.2
		var col := Color(0.7, 0.85, 1.0, 0.8) if wraith else (Color(0.85, 0.9, 1.0) if garg else Color(0.95, 0.96, 1.0))
		for i in 4:
			var f := float(i) / 4.0
			var c2 := Color(col.r, col.g, col.b, (1.0 - f) * 0.7 * (1.0 - k * 0.6))
			draw_arc(Vector2(0, -3), 19.0 - f * 3.0, a - 1.1 + k * 0.8 - f * 0.5, a + 1.1 + k * 0.8, 14, c2, 3.5 - f * 2.0)
		draw_line(Vector2(0, -3) + facing * 6.0, Vector2(0, -3) + facing * 22.0, col, 2.0)
	elif not wraith and not garg:
		draw_line(Vector2(4 * signf(facing.x + 0.01), -2), Vector2(4 * signf(facing.x + 0.01), -9), Color("c9ccd6"), 1.0)


func _draw_wings() -> void:
	draw_set_transform(Vector2(0, 5), 0.0, Vector2.ONE)
	var flap := sin(t * (9.0 if moving else 2.5)) * (2.5 if moving else 1.0)
	for sgn in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(sgn * 3, -12), Vector2(sgn * 13, -22 + flap), Vector2(sgn * 21, -17 + flap),
			Vector2(sgn * 17, -10), Vector2(sgn * 19, -4 + flap * 0.5), Vector2(sgn * 11, -5), Vector2(sgn * 4, -3)])
		draw_colored_polygon(wing, Color(Art.OUT))
		var inner := PackedVector2Array([
			Vector2(sgn * 4, -11), Vector2(sgn * 12.5, -20.5 + flap), Vector2(sgn * 19, -16.5 + flap),
			Vector2(sgn * 15.5, -10), Vector2(sgn * 17, -5.5 + flap * 0.5), Vector2(sgn * 10.5, -6.5), Vector2(sgn * 5, -5)])
		draw_colored_polygon(inner, Color("5a6372"))
		draw_line(Vector2(sgn * 4, -11), Vector2(sgn * 18, -16 + flap), Color("8d97a8"), 0.7)
		draw_line(Vector2(sgn * 5, -9), Vector2(sgn * 16, -8 + flap * 0.5), Color("8d97a8"), 0.5)


func _draw_horns() -> void:
	draw_set_transform(Vector2(0, -1.5), 0.0, Vector2.ONE)
	for sgn in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(sgn * 3.2, -17.5), Vector2(sgn * 5.5, -23.5), Vector2(sgn * 1.5, -19.5)]), Color(Art.OUT))
		draw_colored_polygon(PackedVector2Array([Vector2(sgn * 3.0, -18), Vector2(sgn * 4.8, -22.2), Vector2(sgn * 2.0, -19)]), Color("a9b2c2"))
