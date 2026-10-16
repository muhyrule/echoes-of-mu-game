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

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir != Vector2.ZERO
	if moving and attacking <= 0.0:
		facing = dir.normalized()
	var spd := 118.0 if GameState.form == "wraith" else 88.0
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
	attack_cd = 0.42 if GameState.form == "wraith" else 0.32
	_hit_set.clear()
	Audio.sfx("slash")


func _sword_hits() -> void:
	var dmg := 1 if GameState.form == "wraith" else 2
	var reach := 24.0 if GameState.form == "wraith" else 30.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in _hit_set:
			continue
		var to: Vector2 = e.global_position - global_position
		var near: bool = to.length() < e.hit_radius + 8.0
		if near or (to.length() < reach + e.hit_radius and to.normalized().dot(facing) > 0.25):
			_hit_set.append(e)
			e.hurt(dmg, to.normalized() if to.length() > 0.1 else facing)


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
	GameState.hp -= dmg
	invuln = 1.0
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
	var pal := Art.PAL_WRAITH if wraith else Art.PAL_MU
	var yoff := sin(t * 3.0) * 1.5 if wraith else 0.0
	draw_set_transform(Vector2(0, yoff), 0.0, Vector2.ONE)
	Art.person(self, facing, t, pal, moving, 0.75 if wraith else 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if attacking > 0.0:
		var a := facing.angle()
		var k := 1.0 - attacking / 0.2
		var col := Color(0.7, 0.85, 1.0, 0.8) if wraith else Color(0.95, 0.96, 1.0)
		for i in 4:
			var f := float(i) / 4.0
			var c2 := Color(col.r, col.g, col.b, (1.0 - f) * 0.7 * (1.0 - k * 0.6))
			draw_arc(Vector2(0, -3), 19.0 - f * 3.0, a - 1.1 + k * 0.8 - f * 0.5, a + 1.1 + k * 0.8, 14, c2, 3.5 - f * 2.0)
		draw_line(Vector2(0, -3) + facing * 6.0, Vector2(0, -3) + facing * 22.0, col, 2.0)
	elif not wraith:
		draw_line(Vector2(4 * signf(facing.x + 0.01), -2), Vector2(4 * signf(facing.x + 0.01), -9), Color("c9ccd6"), 1.0)
