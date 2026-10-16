extends CharacterBody2D
## Enemies: crypt rat, gloam bat, Hollow Warden (boss).

const Art = preload("res://src/core/art.gd")

var kind := "rat"
var hp := 2
var speed := 40.0
var hit_radius := 6.0
var contact_dmg := 1
var level: Node2D
var player: Node2D
var state := "idle"
var st := 0.0
var t := randf() * 10.0
var knock := Vector2.ZERO
var flash := 0.0
var facing := Vector2.RIGHT
var wander := Vector2.ZERO
var charge_dir := Vector2.RIGHT
var summoned := false


func setup(k: String, lvl: Node2D) -> void:
	kind = k
	level = lvl
	match k:
		"rat":
			hp = 2
			speed = 42.0
		"bat":
			hp = 1
			speed = 60.0
		"warden":
			hp = 16
			speed = 34.0
			hit_radius = 14.0
			contact_dmg = 2
			state = "dormant"


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 if kind == "bat" else 3
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10.0 if kind == "warden" else 5.0
	shape.shape = c
	add_child(shape)
	if level:
		player = level.player


func _physics_process(delta: float) -> void:
	t += delta
	st += delta
	flash = maxf(0.0, flash - delta)
	if Dialogue.blocking() or level.frozen or player.dead:
		queue_redraw()
		return
	knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
	var to := player.global_position - global_position
	var dist := to.length()
	var move := Vector2.ZERO
	match kind:
		"rat":
			if dist < 100.0:
				move = to.normalized() * speed
			else:
				st = fmod(st, 2.0)
				if st < delta:
					wander = Vector2.from_angle(randf() * TAU) * 0.5 * speed if randf() < 0.6 else Vector2.ZERO
				move = wander
		"bat":
			var wob := Vector2(cos(t * 3.1), sin(t * 4.3)) * 40.0
			move = (to.normalized() * speed + wob) if dist < 140.0 else wob * 0.5
		"warden":
			move = _warden_ai(delta, to, dist)
	velocity = move + knock
	if move != Vector2.ZERO:
		facing = move.normalized()
	move_and_slide()
	if kind == "warden" and state == "charge" and is_on_wall():
		state = "stun"
		st = 0.0
		Audio.sfx("hit")
	level.spark(global_position + Vector2(0, -4), Color(1, 0.85, 0.5), 10)
	level.shake(2.0 if kind == "warden" else 1.0)
	if dist < hit_radius + 8.0 and state != "stun" and state != "dormant":
		player.hurt(contact_dmg, to.normalized() if dist > 0.1 else Vector2.DOWN)
	queue_redraw()


func _warden_ai(_delta: float, to: Vector2, dist: float) -> Vector2:
	match state:
		"dormant":
			if dist < 120.0:
				state = "chase"
				st = 0.0
				Audio.sfx("roar")
				Audio.play_music("boss")
				level.boss_awake()
			return Vector2.ZERO
		"chase":
			if st > 2.4:
				state = "windup"
				st = 0.0
				charge_dir = to.normalized()
			return to.normalized() * speed
		"windup":
			if st > 0.7:
				state = "charge"
				st = 0.0
				charge_dir = to.normalized()
			return Vector2.ZERO
		"charge":
			if st > 0.65:
				state = "chase"
				st = 0.0
			return charge_dir * 200.0
		"stun":
			if st > 1.2:
				state = "chase"
				st = 0.0
			return Vector2.ZERO
	return Vector2.ZERO


func hurt(dmg: int, dir: Vector2) -> void:
	if state == "dormant":
		return
	hp -= dmg * (2 if state == "stun" else 1)
	flash = 0.12
	knock = dir * (70.0 if kind == "warden" else 190.0)
	Audio.sfx("hit")
	if kind == "warden" and not summoned and hp <= 8:
		summoned = true
		level.spawn_enemy("bat", global_position + Vector2(-24, -10))
		level.spawn_enemy("bat", global_position + Vector2(24, -10))
		Audio.sfx("roar")
	if hp <= 0:
		level.enemy_died(self)
		queue_free()


func _draw() -> void:
	match kind:
		"rat":
			Art.rat(self, facing, t, flash)
		"bat":
			draw_set_transform(Vector2(0, sin(t * 6.0) * 2.0 - 6.0), 0.0, Vector2.ONE)
			Art.bat(self, t, flash)
		"warden":
			var dormant := state == "dormant"
			if dormant:
				draw_set_transform(Vector2(0, 4), 0.0, Vector2.ONE)
			Art.warden(self, facing, t, flash, state == "windup")
