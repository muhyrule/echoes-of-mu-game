extends CharacterBody2D
## Mu: 8-direction movement, sword combat, form shifting.

const Art = preload("res://src/core/art.gd")

signal died

const WORLD := 1
const BARS := 2

var level: Node2D
var facing := Vector2.DOWN
var attacking := 0.0
var attack_cd := 0.0
var invuln := 0.0
var knock := Vector2.ZERO
var push_t := 0.0
var dead := false
var t := 0.0
var moving := false
var _hit_set: Array = []


func _ready() -> void:
	collision_layer = 8
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 8)
	shape.shape = r
	shape.position = Vector2(0, 2)
	add_child(shape)
	apply_form()
	add_to_group("player")


func apply_form() -> void:
	# Wraith Mu slips through iron bars; Mu does not.
	collision_mask = WORLD if GameState.form == "wraith" else (WORLD | BARS)


func _physics_process(delta: float) -> void:
	t += delta
	invuln = maxf(0.0, invuln - delta)
	attack_cd = maxf(0.0, attack_cd - delta)
	attacking = maxf(0.0, attacking - delta)
	if dead or Dialogue.blocking() or (level and level.frozen):
		velocity = Vector2.ZERO
		moving = false
		queue_redraw()
		return
	for sid in ["tonic", "elixir", "candle"]:
		if Input.is_action_just_pressed("use_" + sid):
			use_supply(sid)

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir != Vector2.ZERO
	if moving and attacking <= 0.0:
		facing = dir.normalized()
	var spd := 118.0 if GameState.form == "wraith" else (70.0 if GameState.form == "gargoyle" else 88.0)
	if attacking > 0.0:
		spd *= 0.3
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	velocity = dir * spd + knock
	move_and_slide()
	_check_push(dir, delta)

	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0:
		_start_attack()
	if attacking > 0.0:
		_sword_hits()
	if Input.is_action_just_pressed("form"):
		cycle_form()
	if Input.is_action_just_pressed("interact"):
		level.interact()
	queue_redraw()


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
			invuln = maxf(invuln, 8.0)
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
	if invuln > 0.0 or dead:
		return
	if GameState.form == "gargoyle":
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
	if invuln > 0.0 and int(t * 20.0) % 2 == 0:
		return
	var wraith := GameState.form == "wraith"
	var garg := GameState.form == "gargoyle"
	var pal := Art.PAL_WRAITH if wraith else (Art.PAL_GARGOYLE if garg else Art.PAL_MU)
	var yoff := sin(t * 3.0) * 1.5 if wraith else 0.0
	draw_set_transform(Vector2(0, yoff), 0.0, Vector2.ONE)
	if garg:
		_draw_wings()
	Art.person(self, facing, t, pal, moving, 0.75 if wraith else 1.0, attacking, yoff)
	if garg:
		_draw_horns()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
