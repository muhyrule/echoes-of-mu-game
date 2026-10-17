extends CharacterBody2D
## Arena bosses: the Nor' Loch Kelpie of Edinburgh (kelpie_giant) and the Golem of Prague (golem_giant).
## Both are huge multi-phase foes with telegraphed, theme-specific attack patterns.

const Art = preload("res://src/core/art.gd")
const BossArt = preload("res://src/entities/boss_art.gd")
const BossArt2 = preload("res://src/entities/boss_art2.gd")
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


const KINDS := {
	"kelpie_giant": {"title": "NOR' LOCH KELPIE", "hp": 70, "speed": 30.0, "scale": 3.0, "gold": "7fe8e0", "music": "boss",
		"pool": ["toll", "lash", "drop", "rush", "tide"], "p2": ["summon", "whirl"], "p3": ["toll", "drop", "tide"],
		"l2": "The Loch surges around the Kelpie!", "l3": "The Kelpie rears \u2014 the whole cistern is a flood!"},
	"golem_giant": {"title": "GOLEM OF PRAGUE", "hp": 90, "speed": 34.0, "scale": 2.4, "gold": "d8b078", "music": "boss2",
		"pool": ["cogs", "hands", "vents", "rush", "quake"], "p2": ["rift", "beam"], "p3": ["hands", "cogs", "beam"],
		"l2": "The Golem's clay hardens and its stride quickens!", "l3": "The Golem's brow blazes \u2014 it rages unchecked!"},
	"strigoi_giant": {"title": "STRIGOI OF POENARI", "hp": 85, "speed": 32.0, "scale": 2.6, "gold": "ff5a6a", "music": "boss",
		"pool": ["stakes", "bloodring", "mist", "rush"], "p2": ["bats", "drain"], "p3": ["stakes", "mist", "bloodring"],
		"l2": "Blood seeps from the walls \u2014 the Strigoi hungers!", "l3": "The Strigoi unfurls its wings \u2014 the keep fills with bats!"},
	"ankou_giant": {"title": "ANKOU, REAPER OF THE OSSUARY", "hp": 90, "speed": 32.0, "scale": 2.6, "gold": "80ffe8", "music": "crypt",
		"pool": ["scythe", "bonerain", "cart", "rush"], "p2": ["souls", "knell"], "p3": ["scythe", "cart", "souls"],
		"l2": "The Ankou's cart rattles \u2014 the dead stir!", "l3": "A chorus of skulls wails \u2014 the Reaper comes for you!"},
	"barghest_giant": {"title": "BARGHEST OF WHITBY", "hp": 90, "speed": 46.0, "scale": 2.6, "gold": "8ad8ff", "music": "boss2",
		"pool": ["howl", "pounce", "lightning", "rush"], "p2": ["hellfire", "pounce"], "p3": ["howl", "lightning", "hellfire"],
		"l2": "Thunder rolls \u2014 the Barghest's eyes ignite!", "l3": "The Black Dog howls \u2014 the storm breaks over the abbey!"},
	"plague_giant": {"title": "IL MEDICO DELLA PESTE", "hp": 95, "speed": 30.0, "scale": 2.6, "gold": "9aff60", "music": "crypt",
		"pool": ["miasma", "lancet", "censer", "rush"], "p2": ["rats", "knell"], "p3": ["miasma", "censer", "lancet"],
		"l2": "The Doctor's censer smokes \u2014 the air turns green!", "l3": "The plague deepens \u2014 the lazaretto bells toll for you!"},
	"cacus_giant": {"title": "CACUS OF THE AVENTINE", "hp": 105, "speed": 34.0, "scale": 2.8, "gold": "ff9a3a", "music": "boss",
		"pool": ["breath", "boulders", "stampede", "rush", "quake"], "p2": ["smoke", "beam"], "p3": ["breath", "stampede", "boulders"],
		"l2": "Smoke pours from the cave \u2014 Cacus bellows!", "l3": "Cacus's fury blazes \u2014 the Aventine itself shakes!"},
}


func setup(k: String, lvl: Node2D) -> void:
	kind = k
	level = lvl
	var d: Dictionary = KINDS[k]
	title = d.title
	hp = d.hp
	speed = d.speed
	scale = Vector2(d.scale, d.scale)
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
	return Color(KINDS[kind].gold)


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
				Audio.play_music(KINDS[kind].music)
				level.shake(6.0)
				level.boss_awake()
		"intro":
			if st > 1.6:
				state = "idle"
				st = 0.0
		"idle":
			facing = to.normalized()
			move = _stalk(to, dist, 1.9)
			if st > idle_wait:
				_begin_attack()
		"attack":
			facing = facing.lerp(to.normalized(), 0.04) if winding else facing
			move = _stalk(to, dist, 0.9 if winding else 1.4)
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


# Bosses hunt the hero: close in fast, then circle at melee range instead of standing still.
func _stalk(to: Vector2, dist: float, mult: float) -> Vector2:
	var dir := to.normalized()
	if dist > 100.0:
		return dir * speed * mult
	return dir.orthogonal() * speed * 0.7 * (1.0 if int(t * 0.4) % 2 == 0 else -1.0)


func _pool() -> Array:
	var d: Dictionary = KINDS[kind]
	var pool: Array = d.pool.duplicate()
	if phase >= 2:
		pool.append_array(d.p2)
	if phase >= 3:
		pool.append_array(d.p3)
	return pool


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


func _a_tide() -> void:
	winding = true
	var sides := [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	var waves := phase
	for i in waves:
		after(0.5 + i * 1.9, func():
			var d: Vector2 = sides[randi() % 4]
			var c: Vector2 = _pp() - d * 380.0
			var o := d.orthogonal()
			var gap := randf_range(-110.0, 110.0)
			var gp: Vector2 = _pp()
			gap = clampf((gp - c).dot(o) + randf_range(-60.0, 60.0), -140.0, 140.0) if phase > 1 else (gp - c).dot(o)
			Audio.sfx("bell")
			fx.wave(c, d, 190.0, 260.0, 20.0, gap, 52.0, 1.1, 760.0, 1, Color("48c8e0")))
	after(0.5 + waves * 1.9 + 1.6, func():
		winding = false
		_finish(1.4))


func _a_whirl() -> void:
	winding = true
	after(0.6, func():
		winding = false
		Audio.sfx("roar")
		level.shake(5.0)
		var n := phase - 1
		for i in n:
			fx.whirl(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (60.0 + i * 40.0)), 100.0, 0.9, 5.0, Color("58d8e8")))
	after(2.6, func(): _finish(1.0))
	after(0.8, func():
		var a := (_pp() - global_position).angle()
		for i in 5:
			fx.shot(global_position, Vector2.from_angle(a - 0.6 + 0.3 * i) * 120.0, 8.0, 3.0, 1, Color("90f0d8"), "orb"))


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


func _a_quake() -> void:
	winding = true
	var n := 1 + phase
	after(0.8, func(): winding = false)
	for i in n:
		after(0.9 + i * 0.75, func():
			Audio.sfx("hit")
			level.shake(10.0)
			level.spark(global_position, Color("c8a878"), 16)
			var gap := (_pp() - global_position).angle() + randf_range(-0.4, 0.4)
			fx.ring(global_position, 140.0 + 15.0 * phase, 12.0, gap, 0.5, 1, Color("d8b078"), 440.0)
			for j in 3:
				fx.circle(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 120.0)), 22.0, 0.9, 1, Color("c8a878"), 0.3, "steam"))
	after(1.0 + n * 0.75 + 1.4, func(): _finish(1.3))


func _a_beam() -> void:
	winding = true
	var a0 := (_pp() - global_position).angle()
	var dir := 1.0 if randf() < 0.5 else -1.0
	var start := a0 - dir * 0.9
	after(0.6, func():
		Audio.sfx("roar")
		fx.sweep(global_position + Vector2(0, -50), start, dir * (0.8 + 0.12 * phase), 430.0, 20.0, 1.1, 2.0, 1, Color("ff8a3a")))
	after(0.6 + 1.1 + 2.0 + 0.8, func():
		winding = false
		_finish(1.4))


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


# ---------------------------------------------------------- later bosses

func _lanes(horizontal: bool, count: int, warn: float, col: Color, thick := 46.0) -> void:
	var pp := _pp()
	for i in count:
		var off := (-1.0 if i % 2 == 0 else 1.0) * (i / 2 + (0 if i == 0 else 1)) * 70.0
		var c: Vector2 = pp + (Vector2(0, off) if horizontal else Vector2(off, 0))
		var d := Vector2.RIGHT if horizontal else Vector2.DOWN
		fx.line(c - d * 340.0, d, 680.0, thick, warn, 1, col)


func _leap(dest: Vector2, wind: float, r: float, col: Color) -> void:
	fx.circle(dest, r, wind, 1, col, 0.3, "steam")
	after(wind - 0.1, func():
		global_position = _arena_pos(dest)
		Audio.sfx("hit")
		level.shake(9.0)
		level.spark(global_position, col, 18))


# Strigoi: impaling stakes, blood rings, mist-step, bats, draining whirl
func _a_stakes() -> void:
	winding = true
	var n := 4 + phase * 2
	for i in n:
		after(0.5 + i * 0.3, func():
			winding = false
			Audio.sfx("slash")
			var p := _pp() if i % 2 == 0 else _arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 120.0))
			fx.circle(p, 20.0, 0.8, 1, Color("c02838"), 0.3, "steam"))
	after(0.5 + n * 0.3 + 1.2, func(): _finish(1.3))


func _a_bloodring() -> void:
	winding = true
	var n := 1 + phase
	for i in n:
		after(0.8 + i * 0.7, func():
			winding = false
			Audio.sfx("bell")
			level.shake(6.0)
			var gap := (_pp() - global_position).angle() + randf_range(-0.4, 0.4)
			fx.ring(global_position, 135.0, 11.0, gap, 0.5, 1, Color("c01830"), 440.0))
	after(1.0 + n * 0.7 + 1.4, func(): _finish(1.3))


func _a_mist() -> void:
	winding = true
	var n := phase
	for i in n:
		after(0.4 + i * 1.5, func():
			_leap(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * 40.0), 0.9, 62.0, Color("c02838")))
		after(1.7 + i * 1.5, func():
			for j in 6:
				fx.shot(global_position, Vector2.from_angle(TAU * j / 6.0 + randf()) * 150.0, 8.0, 3.0, 1, Color("d83a4a"), "orb"))
	after(0.4 + n * 1.5 + 1.0, func():
		winding = false
		_finish(1.5))


func _a_bats() -> void:
	winding = true
	after(0.8, func():
		winding = false
		Audio.sfx("roar")
		var a := (_pp() - global_position).angle()
		for i in 7:
			fx.shot(global_position, Vector2.from_angle(a - 0.9 + 0.3 * i) * (130.0 + 10.0 * phase), 7.0, 3.2, 1, Color("3a1428"), "orb")
		var bats := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.kind == "bat":
				bats += 1
		for i in maxi(0, mini(phase, 4 - bats)):
			level.spawn_enemy("bat", global_position + Vector2.from_angle(randf() * TAU) * 60.0))
	after(2.6, func(): _finish(1.4))


func _a_drain() -> void:
	winding = true
	after(0.6, func():
		winding = false
		Audio.sfx("roar")
		for i in phase:
			fx.whirl(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (50.0 + i * 50.0)), 100.0, 0.9, 4.5, Color("b01830")))
	after(2.8, func(): _finish(1.2))


# Ankou: scythe sweeps, falling bone, death-cart lanes, souls, knell
func _a_scythe() -> void:
	winding = true
	var a0 := (_pp() - global_position).angle()
	var dir := 1.0 if randf() < 0.5 else -1.0
	after(0.5, func():
		Audio.sfx("slash")
		fx.sweep(global_position + Vector2(0, -40), a0 - dir * 1.0, dir * (1.2 + 0.2 * phase), 300.0, 24.0, 0.9, 1.6, 1, Color("a8f0e0")))
	if phase >= 3:
		after(2.6, func():
			fx.sweep(global_position + Vector2(0, -40), a0 + dir * 1.0, -dir * 1.6, 300.0, 24.0, 0.7, 1.4, 1, Color("a8f0e0")))
	after(3.8 if phase >= 3 else 3.0, func():
		winding = false
		_finish(1.4))


func _a_bonerain() -> void:
	winding = true
	var n := 6 + phase * 3
	for i in n:
		after(0.4 + i * 0.22, func():
			winding = false
			var p := _pp() if i % 3 == 0 else _arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 140.0))
			fx.circle(p, 22.0, 0.9, 1, Color("d8d2c0"), 0.3, "steam"))
	after(0.4 + n * 0.22 + 1.4, func(): _finish(1.2))


func _a_cart() -> void:
	winding = true
	var n := 2 + phase
	var horiz := randf() < 0.5
	_lanes(horiz, n, 1.0, Color("90e8d8"))
	after(0.9, func():
		Audio.sfx("hit")
		level.shake(6.0))
	if phase >= 2:
		after(1.8, func(): _lanes(not horiz, n, 0.9, Color("90e8d8")))
	after(3.2, func():
		winding = false
		_finish(1.3))


func _a_souls() -> void:
	winding = true
	after(0.7, func():
		winding = false
		Audio.sfx("bell")
		var n := 8 + phase * 2
		for i in n:
			fx.shot(global_position, Vector2.from_angle(TAU * i / n) * (110.0 + 12.0 * phase), 8.0, 4.0, 1, Color("80ffe8"), "orb"))
	if phase >= 2:
		after(2.0, func():
			for i in 10:
				fx.shot(global_position, Vector2.from_angle(TAU * i / 10.0 + 0.3) * 125.0, 8.0, 4.0, 1, Color("80ffe8"), "orb"))
	after(3.2, func(): _finish(1.4))


func _a_knell() -> void:
	winding = true
	var n := 2 + phase
	for i in n:
		after(0.8 + i * 0.7, func():
			Audio.sfx("bell")
			level.shake(6.0)
			winding = false
			var gap := (_pp() - global_position).angle() + randf_range(-0.5, 0.5)
			fx.ring(global_position, 125.0, 11.0, gap, 0.5, 1, Color("a8f0c8"), 420.0))
	after(1.0 + n * 0.7 + 1.4, func(): _finish(1.3))


# Barghest: howl cone, pounce, lightning, hellfire
func _a_howl() -> void:
	winding = true
	var n := 1 + phase
	for i in n:
		after(0.6 + i * 1.1, func():
			Audio.sfx("roar")
			level.shake(5.0)
			var d := _pp() - global_position
			fx.cone(global_position, d, 360.0, 0.5, 0.8, 1, Color("8ad8ff"))
			fx.cone(global_position, d.rotated(0.9), 300.0, 0.28, 0.8, 1, Color("8ad8ff")))
	after(0.6 + n * 1.1 + 1.0, func():
		winding = false
		_finish(1.2))


func _a_pounce() -> void:
	winding = true
	var n := phase
	for i in n:
		after(0.3 + i * 1.4, func():
			_leap(_pp(), 0.8, 58.0, Color("ff9a60")))
	after(0.3 + n * 1.4 + 0.4, func():
		winding = false
		_finish(1.5))


func _a_lightning() -> void:
	winding = true
	var n := 6 + phase * 3
	for i in n:
		after(0.4 + i * 0.25, func():
			winding = false
			Audio.sfx("switch")
			var p := _pp() if i % 2 == 0 else _arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 150.0))
			fx.circle(p, 24.0, 0.7, 1, Color("c8e8ff"), 0.25, "steam"))
	after(0.4 + n * 0.25 + 1.2, func(): _finish(1.2))


func _a_hellfire() -> void:
	winding = true
	var rays := 6 + phase * 2
	var off := randf() * TAU
	after(0.6, func():
		Audio.sfx("roar")
		for i in rays:
			fx.line(global_position, Vector2.from_angle(off + TAU * i / rays), 440.0, 22.0, 0.9, 1, Color("6ac8ff")))
	after(1.9, func():
		for i in rays:
			fx.line(global_position, Vector2.from_angle(off + TAU * (i + 0.5) / rays), 440.0, 22.0, 0.8, 1, Color("6ac8ff")))
	after(3.2, func():
		winding = false
		_finish(1.3))


# Plague Doctor: miasma, lancets, censer sweep, rats
func _a_miasma() -> void:
	winding = true
	after(0.5, func():
		winding = false
		Audio.sfx("roar")
		for i in 2 + phase:
			var p := _arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (0.0 if i == 0 else randf_range(50.0, 130.0)))
			fx.circle(p, 34.0, 1.0, 1, Color("78c840"), 0.3, "steam")
			if fx.count_kind("zone") < 4:
				fx.zone(p, 40.0, 6.0, Color("486a2a")))
	after(2.8, func(): _finish(1.4))


func _a_lancet() -> void:
	winding = true
	var n := 2 + phase
	for i in n:
		after(0.5 + i * 0.9, func():
			winding = false
			Audio.sfx("slash")
			var a := (_pp() - global_position).angle()
			for j in 5:
				fx.line(global_position, Vector2.from_angle(a + (j - 2) * 0.28), 420.0, 18.0, 0.7, 1, Color("c8f0a0")))
	after(0.5 + n * 0.9 + 1.0, func(): _finish(1.2))


func _a_censer() -> void:
	winding = true
	var a0 := (_pp() - global_position).angle()
	var dir := 1.0 if randf() < 0.5 else -1.0
	after(0.6, func():
		Audio.sfx("roar")
		fx.sweep(global_position + Vector2(0, -40), a0 - dir * 0.9, dir * (0.9 + 0.15 * phase), 360.0, 26.0, 1.0, 2.2, 1, Color("90d848")))
	after(4.0, func():
		winding = false
		_finish(1.4))


func _a_rats() -> void:
	winding = true
	after(0.8, func():
		winding = false
		Audio.sfx("roar")
		var rats := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.kind == "rat":
				rats += 1
		for i in maxi(0, mini(2 + phase, 6 - rats)):
			level.spawn_enemy("rat", global_position + Vector2.from_angle(randf() * TAU) * 70.0)
		var a := (_pp() - global_position).angle()
		for i in 5:
			fx.shot(global_position, Vector2.from_angle(a - 0.6 + 0.3 * i) * 120.0, 8.0, 3.0, 1, Color("78c840"), "orb"))
	after(2.6, func(): _finish(1.5))


# Cacus: fire breath, boulders, cattle stampede, smoke
func _a_breath() -> void:
	winding = true
	var n := 1 + phase
	for i in n:
		after(0.7 + i * 1.2, func():
			Audio.sfx("roar")
			level.shake(6.0)
			var d := _pp() - global_position
			fx.cone(global_position, d, 400.0, 0.45, 0.9, 1, Color("ff7a2a"))
			if phase >= 3:
				fx.cone(global_position, d.rotated(0.8), 340.0, 0.3, 0.9, 1, Color("ff7a2a"))
				fx.cone(global_position, d.rotated(-0.8), 340.0, 0.3, 0.9, 1, Color("ff7a2a")))
	after(0.7 + n * 1.2 + 1.2, func():
		winding = false
		_finish(1.4))


func _a_boulders() -> void:
	winding = true
	var n := 4 + phase * 2
	after(0.9, func():
		winding = false
		Audio.sfx("hit")
		var a := (_pp() - global_position).angle()
		for i in 3 + phase:
			fx.shot(global_position, Vector2.from_angle(a - 0.5 + 1.0 * i / float(2 + phase)) * 140.0, 14.0, 3.5, 1, Color("8a7a6a"), "orb"))
	for i in n:
		after(0.8 + i * 0.28, func():
			var p := _arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 120.0))
			fx.circle(p, 26.0, 0.9, 1, Color("a89078"), 0.3, "steam"))
	after(0.8 + n * 0.28 + 1.4, func(): _finish(1.3))


func _a_stampede() -> void:
	winding = true
	var horiz := randf() < 0.5
	var n := 2 + phase
	_lanes(horiz, n, 1.1, Color("e87838"), 52.0)
	after(1.0, func():
		Audio.sfx("hit")
		level.shake(8.0))
	if phase >= 2:
		after(1.9, func(): _lanes(not horiz, n, 1.0, Color("e87838"), 52.0))
	after(3.4, func():
		winding = false
		_finish(1.4))


func _a_smoke() -> void:
	winding = true
	after(0.6, func():
		winding = false
		Audio.sfx("roar")
		for i in 3:
			if fx.count_kind("zone") < 5:
				fx.zone(_arena_pos(_pp() + Vector2.from_angle(randf() * TAU) * (0.0 if i == 0 else 80.0)), 48.0, 7.0, Color("4a3a36"))
		for i in 8:
			fx.shot(global_position, Vector2.from_angle(TAU * i / 8.0) * 120.0, 8.0, 3.0, 1, Color("ff8a3a"), "orb"))
	after(2.8, func(): _finish(1.2))


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
	return KINDS[kind]["l2" if phase == 2 else "l3"]


# ---------------------------------------------------------- drawing

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
	var k := 1.0 / scale.x
	draw_set_transform(Vector2(0, 14.0 * k), 0.0, Vector2(k, k))
	if kind == "kelpie_giant":
		BossArt.kelpie(self, t, phase, flash, winding, exposed)
	elif kind != "golem_giant":
		BossArt2.draw(kind, self, t, phase, flash, winding, exposed, state == "idle" and velocity.length() > 4.0)
	else:
		BossArt.golem(self, t, phase, flash, winding, exposed, state == "idle" and velocity.length() > 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(E, E))
	if exposed > 0.0 and state != "dying":
		for i in 4:
			var a := t * 4.0 + TAU * i / 4.0
			draw_circle(Vector2(cos(a) * 46.0, -120.0 + sin(a * 2.0) * 6.0), 3.0, Color(1, 0.95, 0.5, 0.9))
	if winding:
		draw_arc(Vector2(0, -70), 95.0 + sin(t * 16.0) * 4.0, 0, TAU, 40, Color(_gold(), 0.45), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
