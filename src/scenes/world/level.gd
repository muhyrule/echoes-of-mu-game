extends Node2D
## Builds a location from data/maps/<name>.json and runs its rules, puzzles and events.

const Art = preload("res://src/core/art.gd")
const PlayerScript = preload("res://src/entities/player.gd")
const EnemyScript = preload("res://src/entities/enemy.gd")
const PropScript = preload("res://src/entities/prop.gd")
const FollowerScript = preload("res://src/entities/follower.gd")
const HudScript = preload("res://src/scenes/world/hud.gd")

const TILE := 16
const SOLID_CHARS := ["#", "o", "="]

var map_name := ""
var meta: Dictionary = {}
var grid: Array = []
var w := 0
var h := 0
var occupied: Dictionary = {}
var marks: Dictionary = {}
var triggers: Dictionary = {}
var trigger_cells: Dictionary = {}
var plate_cell := Vector2i(-1, -1)
var flags_plate := false
var frozen := false
var player: Node2D
var entities: Node2D
var hud: Control
var gates: Array = []
var bars_props: Array = []
var blocks: Array = []
var interactables: Array = []
var pickups: Array = []
var walkovers: Array = []
var _busy := false
var _nearest: Node2D


func _ready() -> void:
	map_name = GameState.current_map
	var f := FileAccess.open("res://data/maps/%s.json" % map_name, FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	for row in meta.ascii:
		grid.append(row)
	h = grid.size()
	w = grid[0].length()
	triggers = meta.get("triggers", {})

	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)

	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.level = self
	_build_world()
	_place_player()
	entities.add_child(player)
	player.died.connect(_on_player_died)
	_setup_camera()
	_setup_hud()
	_setup_atmosphere()
	_spawn_follower()

	Audio.play_music(meta.get("music", "crypt"))
	if map_name == "chapel":
		GameState.hp = GameState.max_hp
	hud.show_banner(meta.title, meta.subtitle)
	hud.fade = 1.0
	hud.fade_to(0.0, 0.6)
	if map_name == "chapel" and not GameState.flag("intro_done"):
		_run_events("intro")


func _is_solid_char(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return true
	return grid[c.y][c.x] in SOLID_CHARS


func cell_free(c: Vector2i) -> bool:
	if _is_solid_char(c):
		return false
	if occupied.has(c):
		return false
	return true


func in_bars(pos: Vector2) -> bool:
	for b in bars_props:
		if absf(b.position.x - pos.x) < 14.0 and absf(b.position.y - pos.y) < 14.0:
			return true
	return false


func _cell_center(c: Vector2i) -> Vector2:
	return Vector2(c) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


func _make_prop(kind: String, c: Vector2i, npc_id := "") -> Node2D:
	var p := Node2D.new()
	p.set_script(PropScript)
	p.setup(kind, c, self, npc_id)
	entities.add_child(p)
	if p.is_interactable():
		interactables.append(p)
	if p.is_pickup():
		pickups.append(p)
	return p


func spawn_enemy(kind: String, pos: Vector2) -> void:
	var e := CharacterBody2D.new()
	e.set_script(EnemyScript)
	e.setup(kind, self)
	e.position = pos
	entities.add_child(e)


func _build_world() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	add_child(walls)
	var shape_res := RectangleShape2D.new()
	shape_res.size = Vector2(TILE, TILE)
	var gate_flag := GameState.flag("vault_gate_open")
	flags_plate = gate_flag
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var ch: String = grid[y][x]
			if ch in SOLID_CHARS:
				var near_open := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if not _is_solid_char(c + Vector2i(dx, dy)):
							near_open = true
				if near_open:
					var cs := CollisionShape2D.new()
					cs.shape = shape_res
					cs.position = _cell_center(c)
					walls.add_child(cs)
				continue
			match ch:
				"@", "$":
					marks[ch] = c
				"r":
					spawn_enemy("rat", _cell_center(c))
				"b":
					spawn_enemy("bat", _cell_center(c))
				"G":
					if not GameState.flag("edinburgh_done"):
						spawn_enemy("warden", _cell_center(c))
				"K":
					if not GameState.flag("vault_key_taken"):
						_make_prop("key", c)
				"D":
					if not GameState.flag("vault_door_open"):
						_make_prop("door", c)
				"B":
					bars_props.append(_make_prop("bars", c))
				"g":
					if not gate_flag:
						gates.append(_make_prop("gate", c))
				"S":
					plate_cell = c
					_make_prop("plate", c)
				"P":
					if not gate_flag:
						blocks.append(_make_prop("block", c))
				"W":
					_make_prop("shrine", c)
				"E":
					walkovers.append(_make_prop("exit", c))
				"X":
					marks["X"] = c
					if GameState.flag("edinburgh_done"):
						walkovers.append(_make_prop("final", c))
				"A":
					_make_prop("npc", c, "aldous")
				"I":
					if not GameState.flag("isolde_joined"):
						_make_prop("npc", c, "isolde")
				"M":
					_make_prop("table", c)
				"L":
					_make_prop("portal", c)
				"c":
					_make_prop("candle", c)
				"1", "2", "3", "4":
					trigger_cells[c] = triggers.get(ch, "")


func _place_player() -> void:
	var key: String = meta.spawns.get(GameState.spawn, "@")
	var c: Vector2i = marks.get(key, marks.get("@", Vector2i(2, 2)))
	player.position = _cell_center(c)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = w * TILE
	cam.limit_bottom = h * TILE
	cam.zoom = Vector2(3, 3)
	player.add_child(cam)
	cam.make_current()


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.set_script(HudScript)
	hud.level = self
	layer.add_child(hud)


func _setup_atmosphere() -> void:
	var tint := CanvasModulate.new()
	tint.color = Color(0.38, 0.4, 0.56) if map_name == "vaults" else Color(0.55, 0.5, 0.62)
	add_child(tint)
	var lamp := Art.make_light(Color("ffd9a0"), 1.6, 0.9)
	player.add_child(lamp)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.45, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.7)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var vignette := TextureRect.new()
	vignette.texture = tex
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.size = Vector2(1920, 1080)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.get_parent().add_child(vignette)
	hud.get_parent().move_child(vignette, 0)


func _spawn_follower() -> void:
	if GameState.flag("isolde_joined"):
		var f := Node2D.new()
		f.set_script(FollowerScript)
		entities.add_child(f)
		f.start(player)


func _draw() -> void:
	var vault := map_name == "vaults"
	var floor_a := Color("2c2a33") if vault else Color("38323f")
	var floor_b := Color("26242d") if vault else Color("322c38")
	var wall_top := Color("15131b")
	var wall_face := Color("4a4558") if vault else Color("5a4f66")
	var mortar := Color("2a2633")
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var ch: String = grid[y][x]
			if ch == "#":
				if _is_solid_char(c + Vector2i(0, 1)):
					draw_rect(r, wall_top)
				else:
					draw_rect(r, wall_face)
					draw_rect(Rect2(r.position.x, r.position.y + 7, TILE, 1), mortar)
					draw_rect(Rect2(r.position.x + (4 if (x + y) % 2 == 0 else 11), r.position.y, 1, 7), mortar)
					draw_rect(Rect2(r.position.x + (11 if (x + y) % 2 == 0 else 4), r.position.y + 8, 1, 8), mortar)
					draw_rect(Rect2(r.position.x, r.position.y, TILE, 2), wall_face.lightened(0.12))
					draw_rect(Rect2(r.position.x, r.position.y + 12, TILE, 4), Color(0, 0, 0, 0.28))
					draw_rect(Rect2(r.position.x + 8, r.position.y + 8, 1, 1), wall_face.lightened(0.08))
					if (x * 31 + y * 17) % 9 == 0:
						draw_rect(Rect2(r.position.x + 2, r.position.y + 9, 5, 4), Color(0.2, 0.4, 0.25, 0.55))
						draw_rect(Rect2(r.position.x + 3, r.position.y + 11, 2, 3), Color(0.25, 0.5, 0.3, 0.5))
				continue
			var hv := (x * 73856093 ^ y * 19349663) % 7
			draw_rect(r, floor_a if (x + y) % 2 == 0 else floor_b)
			draw_rect(Rect2(r.position.x, r.position.y, TILE, 1), Color(0, 0, 0, 0.22))
			draw_rect(Rect2(r.position.x, r.position.y, 1, TILE), Color(0, 0, 0, 0.22))
			draw_rect(Rect2(r.position.x + 1, r.position.y + 1, TILE - 1, 1), Color(1, 1, 1, 0.04))
			if y > 0 and grid[y - 1][x] == "#":
				draw_rect(Rect2(r.position.x, r.position.y, TILE, 5), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(r.position.x, r.position.y + 5, TILE, 3), Color(0, 0, 0, 0.15))
			if hv == 3 and vault:
				draw_rect(Rect2(r.position + Vector2(3, 8), Vector2(10, 5)), Color(0.15, 0.2, 0.35, 0.6))
				draw_rect(Rect2(r.position + Vector2(5, 9), Vector2(4, 1)), Color(0.6, 0.75, 1.0, 0.25))
			if hv == 4:
				draw_rect(Rect2(r.position + Vector2(11, 11), Vector2(3, 2)), Color(0.22, 0.4, 0.26, 0.6))
			if hv == 0:
				draw_line(r.position + Vector2(3, 5), r.position + Vector2(9, 9), Color(0, 0, 0, 0.25), 1.0)
			if hv == 1:
				draw_rect(Rect2(r.position + Vector2(10, 3), Vector2(2, 2)), Color(1, 1, 1, 0.05))
			if map_name == "chapel" and x >= 18 and x <= 21:
				draw_rect(r, Color("5a2030"))
				draw_rect(Rect2(r.position.x, r.position.y, 1, TILE), Color("8a6a3a"))
				draw_rect(Rect2(r.position.x + 15, r.position.y, 1, TILE), Color("8a6a3a"))
			if ch == "o":
				draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(12, 14)), Color("6a6478"))
				draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(12, 3)), Color("8a849a"))
				draw_rect(Rect2(r.position + Vector2(4, 5), Vector2(3, 10)), Color("827c92"))
			elif ch == "=":
				draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(16, 11)), Color("4d3624"))
				draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(16, 3)), Color("6a4a30"))
				draw_rect(Rect2(r.position + Vector2(0, 13), Vector2(16, 1)), Color("2a1c12"))


func _physics_process(_delta: float) -> void:
	if frozen or player.dead:
		return
	var pp := player.global_position
	for p in pickups.duplicate():
		if is_instance_valid(p) and p.position.distance_to(pp) < 10.0:
			_pickup(p)
	for p in walkovers:
		if is_instance_valid(p) and p.position.distance_to(pp) < 9.0:
			_leave_via(p)
			return
	var pc := Vector2i(int(pp.x / TILE), int(pp.y / TILE))
	if trigger_cells.has(pc) and not _busy:
		var id: String = trigger_cells[pc]
		if id != "" and not GameState.flag("seen_" + id):
			GameState.set_flag("seen_" + id)
			_run_events(id)


func _process(_delta: float) -> void:
	_nearest = null
	var best := 24.0
	for p in interactables:
		if not is_instance_valid(p) or p.open:
			continue
		var d: float = p.position.distance_to(player.global_position)
		if d < best:
			best = d
			_nearest = p
	var text := ""
	if _nearest and not frozen:
		match _nearest.kind:
			"npc":
				text = "[E] Talk"
			"door":
				text = "[E] Unlock" if GameState.keys > 0 else "[E] Inspect"
			"shrine":
				text = "[E] Touch the shrine"
			"table":
				text = "[E] Read the map"
			"portal":
				text = "[E] Step through"
	hud.hint = text
	if Input.is_action_just_pressed("reset_puzzle") and not frozen:
		_reset_puzzle()


func _reset_puzzle() -> void:
	if GameState.flag("vault_gate_open"):
		return
	for b in blocks:
		if not is_instance_valid(b) or b.moving:
			continue
		occupied.erase(b.cell)
		b.cell = b.home_cell
		occupied[b.cell] = b
		b.position = _cell_center(b.cell)
	Audio.sfx("push")


func _pickup(p: Node2D) -> void:
	pickups.erase(p)
	if p.kind == "key":
		GameState.keys += 1
		GameState.set_flag("vault_key_taken")
		Audio.sfx("pickup")
		p.queue_free()
		_run_events("vault_key")
	elif p.kind == "heart":
		GameState.hp = mini(GameState.max_hp, GameState.hp + 1)
		Audio.sfx("pickup")
		p.queue_free()


func check_plate() -> void:
	if flags_plate:
		return
	for b in blocks:
		if is_instance_valid(b) and b.cell == plate_cell and not b.moving:
			flags_plate = true
			GameState.set_flag("vault_gate_open")
			Audio.sfx("switch")
			for g in gates:
				if is_instance_valid(g):
					g.unlock()
			hud.show_notice("Somewhere, an old gate grinds open...")
			return


func interact() -> void:
	if _nearest == null or _busy or frozen:
		return
	_interact(_nearest)


func _interact(p: Node2D) -> void:
	_busy = true
	match p.kind:
		"door":
			if GameState.keys > 0:
				GameState.keys -= 1
				GameState.set_flag("vault_door_open")
				Audio.sfx("door")
				p.unlock()
			else:
				await Dialogue.play("vault_locked")
		"npc":
			await _talk(p)
		"shrine":
			await _shrine()
		"table":
			await Dialogue.play("worldmap")
		"portal":
			if not GameState.flag("isolde_joined"):
				await Dialogue.play("portal_alone")
			elif GameState.flag("edinburgh_done"):
				await Dialogue.play("portal_done")
			else:
				_busy = false
				_leave("vaults", "start")
				return
	_busy = false


func _talk(p: Node2D) -> void:
	if p.id == "aldous":
		if not GameState.flag("isolde_joined"):
			await Dialogue.play("aldous_pre")
		elif GameState.flag("edinburgh_done"):
			await Dialogue.play("aldous_after")
		else:
			await Dialogue.play("aldous_ready")
	elif p.id == "isolde":
		await Dialogue.play("isolde_meet")
		GameState.set_flag("isolde_joined")
		GameState.party.append("isolde")
		interactables.erase(p)
		p.unlock()
		_spawn_follower()
		hud.show_notice("Isolde joins the party")
		Audio.sfx("pickup")
		GameState.save_game()


func _shrine() -> void:
	if not GameState.flag("wraith_unlocked"):
		await Dialogue.play("shrine")
		if not "wraith" in GameState.forms:
			GameState.forms.append("wraith")
		GameState.hp = GameState.max_hp
		Audio.sfx("form")
		hud.show_notice("Wraith Form unlocked — press Q")
		GameState.save_game()
	else:
		GameState.hp = GameState.max_hp
		Audio.sfx("switch")
		await Dialogue.play("shrine_after")


func _run_events(id: String) -> void:
	_busy = true
	await Dialogue.play(id)
	_busy = false


func boss_awake() -> void:
	_run_events("warden_intro")


func enemy_died(e: Node2D) -> void:
	if e.kind == "warden":
		_boss_defeated(e.position)
	elif randf() < 0.3:
		var c := Vector2i(int(e.position.x / TILE), int(e.position.y / TILE))
		_make_prop("heart", c)
		var hp_prop: Node2D = pickups.back()
		hp_prop.position = e.position


func _boss_defeated(pos: Vector2) -> void:
	for en in get_tree().get_nodes_in_group("enemies"):
		if en != null and en.kind != "warden":
			en.queue_free()
	Audio.sfx("bell")
	_busy = true
	await get_tree().create_timer(0.8).timeout
	Audio.play_music("crypt")
	await Dialogue.play("warden_defeated")
	var final_cell: Vector2i = marks.get("X", Vector2i(int(pos.x / TILE), int(pos.y / TILE)))
	walkovers.append(_make_prop("final", final_cell))
	GameState.hp = GameState.max_hp
	GameState.save_game()
	hud.show_notice("Step into the light to return to the chapel")
	_busy = false


func _leave_via(p: Node2D) -> void:
	if p.kind == "final" or p.kind == "exit":
		_leave("chapel", "from_vaults")


func _leave(map: String, spawn: String) -> void:
	if frozen:
		return
	frozen = true
	await hud.fade_to(1.0, 0.4)
	GameState.change_map(map, spawn)


func _on_player_died() -> void:
	frozen = true
	hud.death_text = true
	Audio.stop_music()
	await hud.fade_to(1.0, 1.2)
	await get_tree().create_timer(0.6).timeout
	GameState.hp = GameState.max_hp
	get_tree().reload_current_scene()
