extends Node2D
## Party member that trails the player and fights beside them: an auto attack plus a signature skill (keys 4/5/6).

const Art = preload("res://src/core/art.gd")
const ShotScript = preload("res://src/entities/party_shot.gd")

# Isolde: heavy maul arc and Bell Toll. Wren: twin stabs and Shadow Fan. Corvin: clockwork bolts and Gearstorm.
const KIT := {
	"mu": {"reach": 28.0, "speed": 108.0, "atk_cd": 0.5, "dmg": 2, "skill_cd": 10.0, "key": KEY_7, "skill": "Moon Cleave"},
	"isolde": {"reach": 24.0, "speed": 96.0, "atk_cd": 0.85, "dmg": 2, "skill_cd": 9.0, "key": KEY_4, "skill": "Bell Toll"},
	"wren": {"reach": 16.0, "speed": 130.0, "atk_cd": 0.42, "dmg": 1, "skill_cd": 7.0, "key": KEY_5, "skill": "Shadow Fan"},
	"corvin": {"reach": 84.0, "speed": 90.0, "atk_cd": 1.1, "dmg": 1, "skill_cd": 14.0, "key": KEY_6, "skill": "Gearstorm"},
}
const PALS := {"mu": Art.PAL_MU, "isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}
const DELAY := 16
const ENGAGE := 90.0

var target: Node2D
var trail: Array = []
var pal: Dictionary = Art.PAL_ISOLDE
var facing := Vector2.DOWN
var t := 0.0
var hero := ""
var moving := false
var level: Node2D
var home := Vector2.ZERO
var atk_cd := 0.0
var skill_cd := 4.0
var atk_anim := 0.0
var fx_t := 0.0
var fx_kind := ""
var puppet := false


func start(p: Node2D, palette: Dictionary = Art.PAL_ISOLDE) -> void:
	target = p
	pal = palette
	global_position = p.global_position + Vector2(-12, 4)
	home = global_position
	for i in DELAY:
		trail.append(global_position)


func skill_name() -> String:
	return str(KIT.get(hero, {}).get("skill", ""))


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and KIT.has(hero) and ev.keycode == KIT[hero].key:
		if skill_cd <= 0.0 and not _locked():
			_skill()


func manual_attack() -> void:
	if atk_cd > 0.0 or _locked() or not KIT.has(hero):
		return
	atk_cd = float(KIT[hero].atk_cd) * Gear.cooldown_mult()
	_swing()


func try_skill() -> void:
	if skill_cd <= 0.0 and not _locked() and KIT.has(hero):
		_skill()


func _locked() -> bool:
	return Dialogue.blocking() or (level != null and level.frozen) or (target != null and target.get("dead") == true)


func _nearest_foe(from: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var bd := radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or str(e.get("state")) in ["dormant", "intro", "dying"]:
			continue
		var d: float = from.distance_to(e.global_position) - float(e.get("hit_radius"))
		if d < bd:
			bd = d
			best = e
	return best


func _free_at(pos: Vector2) -> bool:
	if level == null:
		return true
	return not level._is_solid_char(Vector2i(int(floor(pos.x / 16.0)), int(floor(pos.y / 16.0))))


func _process(delta: float) -> void:
	t += delta
	atk_cd = maxf(0.0, atk_cd - delta)
	skill_cd = maxf(0.0, skill_cd - delta)
	atk_anim = maxf(0.0, atk_anim - delta)
	fx_t = maxf(0.0, fx_t - delta)
	if target == null:
		return
	if puppet:
		facing = target.get("facing")
		moving = target.get("moving")
		var tg := target.get("invuln") as float
		modulate.a = 0.4 if tg > 0.0 and int(t * 20.0) % 2 == 0 else 1.0
		visible = hero != ""
		queue_redraw()
		return
	if trail.is_empty() or trail.back().distance_to(target.global_position) > 3.0:
		trail.append(target.global_position)
	while trail.size() > DELAY:
		home = trail.pop_front()
	var foe: Node2D = null
	if KIT.has(hero) and not _locked():
		foe = _nearest_foe(target.global_position, ENGAGE)
	if foe != null:
		_fight(foe, delta)
	else:
		var d := home - global_position
		if d.length() > 10.0:
			facing = d.normalized()
			moving = true
			global_position += facing * minf(150.0 * delta, d.length())
		else:
			moving = d.length() > 0.5
			if moving:
				facing = d.normalized()
			global_position = home
	queue_redraw()


func _fight(foe: Node2D, delta: float) -> void:
	var kit: Dictionary = KIT[hero]
	var to: Vector2 = foe.global_position - global_position
	var dist := to.length()
	var hr: float = float(foe.get("hit_radius"))
	if dist > 0.1:
		facing = to.normalized()
	var want: float = float(kit.reach) * 0.7 + hr * (0.5 if hero != "corvin" else 0.0)
	moving = false
	if dist > want + 2.0 or (hero == "corvin" and dist < 36.0):
		var dir := facing if dist > want else -facing
		var step: Vector2 = dir * float(kit.speed) * delta
		if _free_at(global_position + step):
			global_position += step
			moving = true
	if atk_cd <= 0.0 and dist - hr <= float(kit.reach):
		_auto_attack(foe)
	if skill_cd <= 0.0 and _skill_wanted(foe):
		_skill()


func _skill_wanted(foe: Node2D) -> bool:
	if hero == "corvin":
		return true
	return foe.global_position.distance_to(global_position) - float(foe.get("hit_radius")) < 70.0


func _dmg(base: int) -> int:
	return base + int(Gear.item(Gear.equipped(hero, "weapon")).atk) / 3


func _auto_attack(_foe: Node2D) -> void:
	atk_cd = float(KIT[hero].atk_cd)
	_swing()


func _melee(reach: float, dmg: int, arc: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or str(e.get("state")) in ["dormant", "intro", "dying"]:
			continue
		var d: Vector2 = e.global_position - global_position
		if d.length() - float(e.get("hit_radius")) <= reach and (d.length() < float(e.get("hit_radius")) + 6.0 or d.normalized().dot(facing) > arc):
			e.hurt(dmg, d.normalized() if d.length() > 0.1 else facing)


func _swing() -> void:
	var kit: Dictionary = KIT[hero]
	atk_anim = 0.22
	Audio.sfx("slash")
	match hero:
		"mu", "isolde":
			_melee(float(kit.reach), _dmg(int(kit.dmg)), 0.0)
		"wren":
			_melee(float(kit.reach), _dmg(1), 0.2)
			get_tree().create_timer(0.1).timeout.connect(func() -> void:
				if is_instance_valid(self):
					_melee(float(kit.reach), _dmg(1), 0.2))
		"corvin":
			_shoot(facing, "bolt", _dmg(1), 190.0)


func _shoot(dir: Vector2, kind: String, dmg: int, spd: float) -> void:
	var s := Node2D.new()
	s.set_script(ShotScript)
	s.set("level", level)
	s.set("vel", dir.normalized() * spd)
	s.set("dmg", dmg)
	s.set("kind", kind)
	get_parent().add_child(s)
	s.global_position = global_position + Vector2(0, -6) + dir.normalized() * 6.0


func _skill() -> void:
	skill_cd = float(KIT[hero].skill_cd)
	fx_t = 0.5
	fx_kind = hero
	atk_anim = 0.3
	match hero:
		"mu":
			Audio.sfx("slash")
			if level:
				level.shake(2.0)
				level.spark(global_position, Color(0.85, 0.92, 1.0), 10)
			_melee(46.0, _dmg(3), -2.0)
		"isolde":
			Audio.sfx("bell")
			if level:
				level.hero_hit("bell", global_position, 52.0)
			if level:
				level.shake(3.0)
				level.spark(global_position, Color(1.0, 0.85, 0.4), 14)
			if target != null:
				target.set("ward", 1.0)
			if level and puppet:
				level.spark(global_position, Color(1.0, 0.85, 0.4), 6)
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or str(e.get("state")) in ["dormant", "intro", "dying"]:
					continue
				var d: Vector2 = e.global_position - global_position
				if d.length() - float(e.get("hit_radius")) < 52.0:
					e.hurt(_dmg(2), d.normalized() if d.length() > 0.1 else facing)
		"wren":
			Audio.sfx("slash")
			var foe := _nearest_foe(global_position, 160.0)
			var base := facing if foe == null else (foe.global_position - global_position).normalized()
			for i in 5:
				_shoot(base.rotated((i - 2) * 0.22), "dagger", _dmg(1), 240.0)
		"corvin":
			Audio.sfx("hit")
			for i in 8:
				_shoot(Vector2.from_angle(i * TAU / 8.0), "bolt", _dmg(1), 170.0)
			if GameState.hp < GameState.max_hp:
				GameState.hp += 1
				if level:
					level.spark(target.global_position, Color(0.5, 1.0, 0.7), 8)


func _draw() -> void:
	if hero == "":
		return
	var st: Dictionary = Gear.styled(hero, pal)
	var rp: float = target.get("roll_ang") if puppet and target != null else 0.0
	Art.person(self, facing, t, st, moving, 1.0, atk_anim, 0.0, rp)
	if puppet and target != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		target.draw_guard(self)
	if atk_anim > 0.0 and hero in ["isolde", "mu"]:
		var a := facing.angle()
		var k := 1.0 - atk_anim / 0.22
		draw_arc(Vector2(0, -5), 22.0, a - 1.0 + k * 1.2, a - 0.2 + k * 1.2, 8, Color(1.0, 0.95, 0.8, 0.7), 3.0)
	elif atk_anim > 0.0 and hero == "wren":
		for i in 2:
			var o := facing * (8.0 + i * 4.0) + Vector2(0, -5 + i * 2)
			draw_line(o, o + facing.rotated(0.5 - i) * 7.0, Color(0.9, 0.95, 1.0, 0.8), 1.6)
	elif atk_anim > 0.0 and hero == "corvin":
		draw_circle(facing * 7.0 + Vector2(0, -6), 3.0, Color(0.7, 0.95, 1.0, 0.6))
	if fx_t > 0.0:
		var u := 1.0 - fx_t / 0.5
		match fx_kind:
			"mu":
				draw_arc(Vector2(0, -4), 6.0 + u * 38.0, 0, TAU, 28, Color(0.85, 0.92, 1.0, 0.85 * (1.0 - u)), 3.0)
			"isolde":
				draw_arc(Vector2(0, -4), 8.0 + u * 44.0, 0, TAU, 28, Color(1.0, 0.85, 0.4, 0.8 * (1.0 - u)), 3.0)
				draw_arc(Vector2(0, -4), 4.0 + u * 30.0, 0, TAU, 24, Color(1.0, 1.0, 0.8, 0.5 * (1.0 - u)), 1.5)
			"wren":
				draw_arc(Vector2(0, -4), 6.0 + u * 16.0, 0, TAU, 16, Color(0.80, 0.32, 0.36, 0.7 * (1.0 - u)), 2.0)
			"corvin":
				for i in 8:
					var ang := t * 6.0 + i * TAU / 8.0
					draw_circle(Vector2.from_angle(ang) * (6.0 + u * 12.0) + Vector2(0, -6), 1.6, Color(0.9, 0.75, 0.35, 1.0 - u))
