extends Node2D
## Builds a location from data/maps/<name>.json and runs its rules, puzzles and events.

const Art = preload("res://src/core/art.gd")
const PlayerScript = preload("res://src/entities/player.gd")
const EnemyScript = preload("res://src/entities/enemy.gd")
const ArenaFxScript = preload("res://src/entities/arena_fx.gd")
const DungeonScript = preload("res://src/entities/dungeon.gd")
const SignsScript = preload("res://src/entities/signs.gd")
const PostScript = preload("res://src/core/post.gd")
const DecorScript = preload("res://src/entities/decor.gd")
const ArenaMechScript = preload("res://src/entities/arena_mech.gd")
const GiantScript = preload("res://src/entities/giant.gd")
const PropScript = preload("res://src/entities/prop.gd")
const FollowerScript = preload("res://src/entities/follower.gd")
const CritterScript = preload("res://src/entities/critter.gd")
const HudScript = preload("res://src/scenes/world/hud.gd")

const TILE := 16
const SOLID_CHARS := ["#", "o", "=", "H", "Z", "Y", "U", "T", "J", "F"]
const GEAR_SECRETS := {"e_chest": "iso_w_f", "p_chest": "cor_a_f", "ar_helm": "iso_a_f", "wp_crate": "wre_w_f", "pw_crate": "cor_w_f", "v_chest2": "wre_a_f"}
const BOSS_GEAR := {"vault_arena": "mu_w_f", "prague_arena": "mu_a_f"}
const FURNITURE := ["Z", "Y", "U", "T", "J", "F", "C", "R"]
const TOWN_THEMES := ["town_e", "town_p"]

var map_name := ""
var meta: Dictionary = {}
var arena := ""
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
var cam: Camera2D
var shake_amt := 0.0
var overlay: Node2D
var tint_node: CanvasModulate
var tint_base := Color.WHITE
var weather: Node2D
var fog: Array = []
var windows: Array = []
var gt := 0.0
var theme := "chapel"
var prefix := ""
var followers: Dictionary = {}
var arena_fx: Node2D
var cam_bob := Vector2.ZERO
var dungeon: Node2D = null
var cracked_props: Array = []
var hearths: Array = []
var entries: Array = []


func _ready() -> void:
	map_name = GameState.current_map
	var f := FileAccess.open("res://data/maps/%s.json" % map_name, FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	arena = str(meta.get("arena", ""))
	for row in meta.ascii:
		grid.append(row)
	h = grid.size()
	w = grid[0].length()
	triggers = meta.get("triggers", {})
	theme = meta.get("theme", "chapel")
	prefix = meta.get("prefix", map_name)

	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)

	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.level = self
	_build_world()
	_build_hero_puzzle()
	_place_player()
	entities.add_child(player)
	player.died.connect(_on_player_died)
	_setup_camera()
	_setup_hud()
	_setup_fx()
	_setup_atmosphere()
	_setup_weather()
	_setup_life()
	_spawn_followers()

	Audio.play_music(meta.get("music", "crypt"))
	Audio.preload_music(["road", "edin", "praha", "vaults", "ossuary"])
	GameState.refresh_stats()
	if map_name == "chapel":
		GameState.hp = GameState.max_hp
	hud.show_banner(meta.title, meta.subtitle)
	if arena != "":
		hud.banner_t = 2.5
		var afx := Node2D.new()
		afx.set_script(ArenaFxScript)
		afx.set("level", self)
		arena_fx = afx
		add_child(afx)
		move_child(afx, 0)
		var mech := Node2D.new()
		mech.set_script(ArenaMechScript)
		mech.set("level", self)
		add_child(mech)
	if not arena_fx:
		var dc := Node2D.new()
		dc.set_script(DecorScript)
		dc.set("level", self)
		add_child(dc)
		move_child(dc, 0)
	if meta.has("doors"):
		var sg := Node2D.new()
		sg.set_script(SignsScript)
		sg.set("level", self)
		add_child(sg)
	if meta.has("dungeon"):
		dungeon = Node2D.new()
		dungeon.set_script(DungeonScript)
		dungeon.set("level", self)
		add_child(dungeon)
	hud.fade = 1.0
	hud.fade_to(0.0, 0.6)
	if map_name == "chapel" and not GameState.flag("intro_done"):
		_run_events("intro")


func _broken_key(c: Vector2i) -> String:
	return "%s_broken_%d_%d" % [map_name, c.x, c.y]


func try_break(pos: Vector2) -> void:
	for p in cracked_props.duplicate():
		if is_instance_valid(p) and p.position.distance_to(pos) < 15.0:
			cracked_props.erase(p)
			GameState.set_flag(_broken_key(p.cell))
			Audio.sfx("hit")
			shake(5.0)
			for i in 3:
				spark(p.position + Vector2(randf_range(-6, 6), randf_range(-6, 6)), Color(0.7, 0.66, 0.78), 12)
			hud.show_notice("The wall crumbles!")
			p.unlock()


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


func frozen_for_dialogue() -> bool:
	return Dialogue.active


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


func _make_town_npc(c: Vector2i, d: Dictionary) -> void:
	if d.has("hide_if") and GameState.flag(d.hide_if):
		return
	var p := _make_prop("npc", c, d.id)
	p.def = d
	var pal := {"coat": Color("4a4a56"), "accent": Color("8a7436"), "skin": Color("c4a083"), "hair": Color("5a4a3a"), "boots": Color("1c1620"), "style": "short", "item": "none", "look": "villager"}
	for k in d.get("pal", {}):
		var v = d.pal[k]
		pal[k] = Color(v) if k in ["coat", "accent", "skin", "hair", "boots"] else v
	p.pal = pal


func _make_entry(c: Vector2i, d: Dictionary) -> void:
	var p := _make_prop("entry", c)
	p.def = d
	entries.append(p)


func _make_object(c: Vector2i, d: Dictionary) -> void:
	var p := _make_prop(d.kind, c)
	p.def = d


func spawn_enemy(kind: String, pos: Vector2) -> void:
	var e := CharacterBody2D.new()
	e.set_script(GiantScript if kind.ends_with("_giant") else EnemyScript)
	e.setup(kind, self)
	e.position = pos
	entities.add_child(e)


func _build_world() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	add_child(walls)
	var shape_res := RectangleShape2D.new()
	shape_res.size = Vector2(TILE, TILE)
	var gate_flag := GameState.flag(prefix + "_gate_open")
	flags_plate = gate_flag
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var ch: String = grid[y][x]
			if ch == "U":
				hearths.append(c)
				var hl := Art.make_light(Color("ff8a3a"), 1.6, 1.1)
				hl.position = _cell_center(c)
				add_child(hl)
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
			if meta.get("npcs", {}).has(ch):
				_make_town_npc(c, meta.npcs[ch])
				continue
			if meta.get("doors", {}).has(ch):
				_make_entry(c, meta.doors[ch])
				continue
			if meta.get("objects", {}).has(ch):
				_make_object(c, meta.objects[ch])
				continue
			match ch:
				"l":
					_make_prop("lamp", c)
				"@", "$", "&":
					marks[ch] = c
				"r":
					spawn_enemy("rat", _cell_center(c))
				"b":
					spawn_enemy("bat", _cell_center(c))
				"G":
					var bi: Dictionary = meta.get("boss", {})
					if not bi.is_empty() and not GameState.flag(bi.done_flag):
						spawn_enemy(bi.kind, _cell_center(c))
				"K":
					if not GameState.flag(prefix + "_key_taken"):
						_make_prop("key", c)
				"D":
					if not GameState.flag(prefix + "_door_open"):
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
					var bd: Dictionary = meta.get("boss", {})
					if not bd.is_empty() and GameState.flag(bd.done_flag):
						walkovers.append(_make_prop("final", c))
				"A":
					_make_prop("npc", c, "aldous")
				"I":
					if not GameState.flag("isolde_joined"):
						_make_prop("npc", c, "isolde")
				"M":
					_make_prop("table", c)
				"N":
					if not GameState.flag("wren_joined"):
						_make_prop("npc", c, "wren")
				"V":
					if not GameState.flag("corvin_joined"):
						_make_prop("npc", c, "corvin")
				"Q":
					_make_prop("gear", c)
				"x":
					if not GameState.flag(_broken_key(c)):
						cracked_props.append(_make_prop("cracked", c))
				"L":
					_make_prop("portal", c)
				"c":
					_make_prop("candle", c)
				"1", "2", "3", "4":
					trigger_cells[c] = triggers.get(ch, "")


func _place_player() -> void:
	var key: String = meta.spawns.get(GameState.spawn, "@")
	var c: Vector2i = marks.get(key, marks.get("@", Vector2i(2, 2)))
	if GameState.spawn.begins_with("door:"):
		var origin := GameState.spawn.substr(5)
		for e in entries:
			if e.def.get("map", "") == origin:
				for off in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
					if not _is_solid_char(e.cell + off):
						c = e.cell + off
						break
				break
	player.position = _cell_center(c)


func _setup_camera() -> void:
	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = w * TILE
	cam.limit_bottom = h * TILE
	var z := maxf(2.0 if meta.has("boss") else 2.6, maxf(1920.0 / (w * TILE), 1080.0 / (h * TILE)))
	cam.zoom = Vector2(z, z)
	if theme in TOWN_THEMES:
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 7.0
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
	var post := CanvasLayer.new()
	post.set_script(PostScript)
	add_child(post)


func _setup_atmosphere() -> void:
	var tint := CanvasModulate.new()
	tint_node = tint
	tint.color = {"vault": Color(0.38, 0.4, 0.56), "prague": Color(0.46, 0.46, 0.52), "chapel": Color(0.55, 0.5, 0.62), "town_e": Color(0.5, 0.52, 0.68), "town_p": Color(0.62, 0.56, 0.58), "interior": Color(0.78, 0.68, 0.62)}[theme]
	tint.color *= Color(1.12, 1.12, 1.1, 1.0)
	tint_base = tint.color
	add_child(tint)
	var lamp := Art.make_light(Color("ffd9a0"), 2.0, 1.0)
	player.add_child(lamp)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.6, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.55)])
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


func shake(a: float) -> void:
	shake_amt = maxf(shake_amt, a)


func spark(pos: Vector2, col := Color(1, 0.9, 0.6), n := 8) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.35
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.damping_min = 120.0
	p.damping_max = 200.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.6
	p.color = col
	p.z_index = 20
	add_child(p)
	get_tree().create_timer(0.6).timeout.connect(p.queue_free)


func _chimney_smoke() -> void:
	for y in range(1, h - 1):
		for x in w:
			if grid[y][x] == "H" and grid[y - 1][x] != "H" and grid[y + 1][x] == "H" and x > 0 and grid[y][x - 1] == "H" and (x - _house_base(x, y)) == 1:
				var sm := CPUParticles2D.new()
				sm.position = Vector2(x * TILE + 7, y * TILE - 2)
				sm.amount = 14
				sm.lifetime = 3.5
				sm.preprocess = 3.5
				sm.direction = Vector2(0.4, -1)
				sm.spread = 12.0
				sm.gravity = Vector2(6, -2)
				sm.initial_velocity_min = 5.0
				sm.initial_velocity_max = 10.0
				sm.scale_amount_min = 1.2
				sm.scale_amount_max = 2.6
				sm.color = Color(0.7, 0.7, 0.78, 0.28)
				sm.z_index = 12
				add_child(sm)


func _setup_life() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_name)
	var kinds: Array = []
	if theme == "town_e":
		kinds = ["cat", "cat", "cat", "cat", "crow", "crow", "crow", "crow", "crow", "rat", "rat", "rat", "pigeon", "pigeon"]
	elif theme == "town_p":
		kinds = ["cat", "cat", "cat", "pigeon", "pigeon", "pigeon", "pigeon", "pigeon", "pigeon", "pigeon", "crow", "crow", "rat", "rat"]
	elif theme == "interior" and rng.randf() < 0.6:
		kinds = ["cat"]
	var tries := 0
	for k in kinds:
		while tries < 600:
			tries += 1
			var c := Vector2i(rng.randi_range(2, w - 3), rng.randi_range(3, h - 3))
			if grid[c.y][c.x] != ".":
				continue
			if marks.has("@") and Vector2(c).distance_to(Vector2(marks["@"])) < 6.0:
				continue
			var cr := Node2D.new()
			cr.set_script(CritterScript)
			cr.setup(k, self, _cell_center(c))
			entities.add_child(cr)
			break
	if theme in TOWN_THEMES:
		var lv := CPUParticles2D.new()
		lv.amount = 40
		lv.lifetime = 9.0
		lv.preprocess = 9.0
		lv.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		lv.emission_rect_extents = Vector2(330, 190)
		lv.direction = Vector2(1, 0.5)
		lv.spread = 40.0
		lv.gravity = Vector2(4, 6)
		lv.initial_velocity_min = 8.0
		lv.initial_velocity_max = 22.0
		lv.angular_velocity_min = -120.0
		lv.angular_velocity_max = 120.0
		lv.scale_amount_min = 0.9
		lv.scale_amount_max = 1.8
		lv.color = Color(0.55, 0.4, 0.22, 0.7) if theme == "town_e" else Color(0.95, 0.75, 0.8, 0.7)
		lv.local_coords = false
		lv.z_index = 15
		player.add_child(lv)


func set_weather_dark(d: float) -> void:
	if tint_node:
		tint_node.color = tint_base.lerp(tint_base * Color(0.7, 0.75, 0.9, 1.0), clampf(d * 3.0, 0.0, 1.0))


func _setup_weather() -> void:
	if theme not in TOWN_THEMES:
		return
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	weather = Node2D.new()
	weather.set_script(load("res://src/scenes/world/weather.gd"))
	weather.level = self
	layer.add_child(weather)


func _setup_fx() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(310, 180)
	dust.direction = Vector2(1, -0.3)
	dust.spread = 60.0
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 7.0
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 1.0
	dust.color = Color(1, 0.9, 0.75, 0.35)
	dust.local_coords = false
	dust.z_index = 15
	player.add_child(dust)
	var tex := Art.light_texture()
	for i in clampi(w * h / 150, 9, 28):
		var f := Sprite2D.new()
		f.texture = tex
		f.scale = Vector2(randf_range(1.4, 2.6), randf_range(0.5, 0.9))
		f.position = Vector2(randf() * w * TILE, randf() * h * TILE)
		f.modulate = {"vault": Color(0.55, 0.6, 0.85, 0.16), "prague": Color(0.85, 0.7, 0.45, 0.1), "chapel": Color(0.75, 0.6, 0.8, 0.12), "town_e": Color(0.7, 0.75, 0.95, 0.16), "town_p": Color(0.9, 0.78, 0.6, 0.1), "interior": Color(1.0, 0.8, 0.5, 0.05)}[theme]
		f.z_index = 14
		f.set_meta("spd", randf_range(2.0, 6.0))
		add_child(f)
		fog.append(f)
	if theme in TOWN_THEMES:
		_chimney_smoke()
	overlay = Node2D.new()
	overlay.z_index = 16
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	overlay.material = mat
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	var cols: Array = [Color("d0405a"), Color("4a7be0"), Color("e0b040"), Color("40b08a")]
	var n := 0
	for x in (range(3, w - 2, 5) if theme not in TOWN_THEMES else []):
		for y in range(0, h - 1):
			if grid[y][x] == "#" and not _is_solid_char(Vector2i(x, y + 1)):
				if theme == "chapel" or n % 2 == 1:
					windows.append([Vector2i(x, y), cols[(n + (2 if theme == "prague" else 0)) % 4] if theme != "vault" else Color("4a7be0")])
				if theme != "chapel" and n % 2 == 0:
					var tp := _make_prop("torch", Vector2i(x, y))
					tp.position.y += 2
				n += 1
				break


func _draw_overlay() -> void:
	for wd in windows:
		var c: Vector2i = wd[0]
		var col: Color = wd[1]
		var o := Vector2(c) * TILE
		var pulse := 0.8 + 0.2 * sin(gt * 0.7 + c.x)
		var top := o + Vector2(8, 14)
		for k in 3:
			var off := (k - 1) * 7.0
			var sway := sin(gt * 0.4 + c.x + k) * 3.0
			var shaft := PackedVector2Array([top + Vector2(off - 2.5, 0), top + Vector2(off + 2.5, 0), top + Vector2(off + 30.0 + sway + k * 6.0, 130), top + Vector2(off + 12.0 + sway + k * 6.0, 130)])
			var al := (0.2 if k == 1 else 0.1) * pulse
			overlay.draw_polygon(shaft, PackedColorArray([Color(col, al), Color(col, al), Color(col, 0.0), Color(col, 0.0)]))
		overlay.draw_circle(o + Vector2(8, 8), 16.0, Color(col, 0.05 * pulse))
		overlay.draw_set_transform(top + Vector2(24, 128), 0.0, Vector2(1.0, 0.45))
		overlay.draw_circle(Vector2.ZERO, 26.0, Color(col, 0.05 * pulse))
		overlay.draw_circle(Vector2.ZERO, 15.0, Color(col, 0.07 * pulse))
		overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for hc in hearths:
		var hp := _cell_center(hc)
		var hf := 0.8 + 0.2 * sin(gt * 11.0 + hc.x) + 0.08 * sin(gt * 23.0)
		overlay.draw_circle(hp, 30.0, Color(1.0, 0.5, 0.2, 0.05 * hf))
		overlay.draw_circle(hp, 16.0, Color(1.0, 0.6, 0.25, 0.08 * hf))
		for k in 3:
			var fx := (k - 1) * 3.2
			var fh := 5.0 + 2.0 * sin(gt * 13.0 + k * 2.0)
			overlay.draw_colored_polygon(PackedVector2Array([hp + Vector2(fx - 2, 5), hp + Vector2(fx + 2, 5), hp + Vector2(fx, 5 - fh)]), Color(1.0, 0.55, 0.15, 0.55))
	for e in entities.get_children():
		if not ("kind" in e):
			continue
		var bc := Color.TRANSPARENT
		var br := 0.0
		match e.kind:
			"torch":
				bc = Color(1.0, 0.55, 0.2)
				br = 22.0
			"candle":
				bc = Color(1.0, 0.8, 0.45)
				br = 11.0
			"lamp":
				bc = Color(1.0, 0.72, 0.38)
				br = 26.0
		if br > 0.0:
			var fl := 0.8 + 0.2 * sin(gt * 9.0 + e.position.x)
			overlay.draw_circle(e.position + Vector2(0, -6), br, Color(bc, 0.05 * fl))
			overlay.draw_circle(e.position + Vector2(0, -6), br * 0.55, Color(bc, 0.07 * fl))
			overlay.draw_circle(e.position + Vector2(0, -6), br * 0.2, Color(bc, 0.16 * fl))


const FOLLOW_PAL := {"mu": Art.PAL_MU, "isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}
const SEAL_FOR := {"bell": "seal_bell", "dagger": "seal_dagger", "bolt": "seal_bolt"}
var seals: Array = []
var seal_gates: Array = []


func _chain_ids() -> Array:
	var ids: Array = ["mu"]
	ids.append_array(GameState.party)
	ids.erase(GameState.lead)
	return ids


func _spawn_follower(id: String) -> void:
	if followers.has(id) and is_instance_valid(followers[id]):
		return
	var lead: Node2D = player
	for fid in _chain_ids():
		if fid == id:
			break
		if followers.has(fid) and is_instance_valid(followers[fid]):
			lead = followers[fid]
	var f := Node2D.new()
	f.set_script(FollowerScript)
	entities.add_child(f)
	f.hero = id
	f.level = self
	f.start(lead, FOLLOW_PAL[id])
	followers[id] = f


func _relink_followers() -> void:
	var lead: Node2D = player
	for fid in _chain_ids():
		if followers.has(fid) and is_instance_valid(followers[fid]):
			followers[fid].target = lead
			lead = followers[fid]


func _spawn_followers() -> void:
	if GameState.lead != "mu" and not GameState.lead in GameState.party:
		GameState.lead = "mu"
	player.set_lead(GameState.lead)
	if GameState.party.is_empty():
		return
	for id in _chain_ids():
		if FOLLOW_PAL.has(id):
			_spawn_follower(id)


func switch_hero(id: String) -> void:
	var old: String = GameState.lead
	if id == old or player.dead or frozen or _busy or Dialogue.blocking():
		return
	if not followers.has(id) or not is_instance_valid(followers[id]):
		return
	var f: Node2D = followers[id]
	var b: Node2D = player.brain
	var fa: float = f.atk_cd
	var fs: float = f.skill_cd
	f.atk_cd = b.atk_cd
	f.skill_cd = b.skill_cd
	b.atk_cd = fa
	b.skill_cd = fs
	f.hero = old
	f.pal = FOLLOW_PAL[old]
	followers.erase(id)
	followers[old] = f
	player.set_lead(id)
	player.invuln = maxf(player.invuln, 0.5)
	Audio.sfx("form")
	spark(player.global_position, Color(0.8, 0.7, 1.0), 12)
	spark(f.global_position, Color(0.8, 0.7, 1.0), 8)
	hud.show_notice("Now controlling %s" % id.capitalize())


func cycle_lead() -> void:
	var ids: Array = ["mu"]
	ids.append_array(GameState.party)
	if ids.size() < 2:
		return
	switch_hero(ids[(ids.find(GameState.lead) + 1) % ids.size()])


func _build_hero_puzzle() -> void:
	var hp: Dictionary = meta.get("hero_puzzle", {})
	if hp.is_empty():
		return
	var all_lit := true
	for k in SEAL_FOR.values():
		all_lit = all_lit and GameState.flag(prefix + "_" + k)
	for k in ["bell", "dagger", "bolt"]:
		var cc: Array = hp[k]
		var sp := _make_prop(SEAL_FOR[k], Vector2i(int(cc[0]), int(cc[1])))
		sp.lit = GameState.flag(prefix + "_" + SEAL_FOR[k])
		seals.append(sp)
	if not all_lit:
		for g in hp.gates:
			seal_gates.append(_make_prop("gate", Vector2i(int(g[0]), int(g[1]))))


func hero_hit(src: String, pos: Vector2, rad: float) -> bool:
	var hit := false
	if dungeon and dungeon.hit(src, pos, rad):
		hit = true
	for sp in seals:
		if not is_instance_valid(sp) or sp.lit or sp.kind != SEAL_FOR.get(src, ""):
			continue
		if sp.position.distance_to(pos) <= rad + 9.0:
			sp.lit = true
			hit = true
			GameState.set_flag(prefix + "_" + sp.kind)
			Audio.sfx("switch")
			shake(2.0)
			spark(sp.position, Color(1.0, 0.9, 0.6), 14)
			var left := 0
			for o in seals:
				if is_instance_valid(o) and not o.lit:
					left += 1
			if left == 0:
				for g in seal_gates:
					if is_instance_valid(g):
						g.unlock()
				hud.show_notice("All three seals answer. A gate grinds open...")
			else:
				hud.show_notice("A seal answers. %d to go." % left)
	return hit


func _has_window(c: Vector2i) -> bool:
	for wd in windows:
		if wd[0] == c:
			return true
	return false


func _banner(p: Vector2, vault: bool, prague: bool) -> void:
	var cl := Color("2c4a7a") if vault else (Color("6a5420") if prague else Color("6a1e30"))
	draw_rect(Rect2(p + Vector2(3, 1), Vector2(10, 1)), Color("c8a050"))
	draw_rect(Rect2(p + Vector2(4, 2), Vector2(8, 10)), cl.darkened(0.3))
	draw_polygon(PackedVector2Array([p + Vector2(4, 12), p + Vector2(12, 12), p + Vector2(8, 15)]), PackedColorArray([cl.darkened(0.3)]))
	draw_rect(Rect2(p + Vector2(5, 2), Vector2(2, 10)), cl)
	draw_rect(Rect2(p + Vector2(7.5, 5), Vector2(1, 4)), Color("d8b860"))
	draw_rect(Rect2(p + Vector2(6, 6.5), Vector2(4, 1)), Color("d8b860"))
	draw_rect(Rect2(p + Vector2(4, 2), Vector2(8, 1)), Color(0, 0, 0, 0.3))


func _draw() -> void:
	var vault := theme == "vault"
	var prague := theme == "prague" or theme == "town_p"
	var interior := theme == "interior"
	var floor_a := Color("2c2a33") if vault else (Color("34363f") if prague else Color("38323f"))
	var floor_b := Color("26242d") if vault else (Color("2a2c35") if prague else Color("322c38"))
	if theme == "town_e":
		floor_a = Color("3c3f4a")
		floor_b = Color("343742")
	elif theme == "town_p":
		floor_a = Color("4a4238")
		floor_b = Color("40382f")
	var wall_top := Color("15131b")
	var wall_face := Color("4a4558") if vault else (Color("565a66") if prague else Color("5a4f66"))
	var mortar := Color("2a2633")
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var ch: String = grid[y][x]
			if ch == "H":
				_draw_house(r, x, y)
				continue
			if arena != "" and not (ch in FURNITURE):
				_draw_arena_cell(r, x, y, ch)
				continue
			if ch in FURNITURE:
				_draw_floor_plank(r, x, y)
				_draw_furniture(r, ch, x, y)
				continue
			if ch == "#":
				if _is_solid_char(c + Vector2i(0, 1)):
					draw_rect(r, wall_top)
				else:
					draw_rect(r, wall_face)
					var hh := (x * 928371 + y * 364479) % 5
					var shade := Color(0, 0, 0, 0.12)
					draw_rect(Rect2(r.position.x, r.position.y + 5, TILE, 1), mortar)
					draw_rect(Rect2(r.position.x, r.position.y + 11, TILE, 1), mortar)
					var o1 := 3 + hh
					var o2 := 9 - hh
					draw_rect(Rect2(r.position.x + o1, r.position.y, 1, 5), mortar)
					draw_rect(Rect2(r.position.x + o2, r.position.y + 6, 1, 5), mortar)
					draw_rect(Rect2(r.position.x + o1 + 4, r.position.y + 12, 1, 4), mortar)
					draw_rect(Rect2(r.position.x, r.position.y, TILE, 1), wall_face.lightened(0.18))
					draw_rect(Rect2(r.position.x, r.position.y + 6, o2, 1), wall_face.lightened(0.1))
					draw_rect(Rect2(r.position.x + o2 + 1, r.position.y + 12, 8, 1), wall_face.lightened(0.1))
					for i in 8:
						var dx := (i * 2 + (i % 2)) + (hh % 2)
						draw_rect(Rect2(r.position.x + dx, r.position.y + 2 + (i % 4) * 3 + (i % 2), 1, 1), shade)
					draw_rect(Rect2(r.position.x, r.position.y + 13, TILE, 3), Color(0, 0, 0, 0.26))
					for i in 8:
						draw_rect(Rect2(r.position.x + i * 2 + (i + y) % 2, r.position.y + 13 + (i % 2), 1, 1), Color(0, 0, 0, 0.2))
					for wd in windows:
						if wd[0] == c:
							var wc: Color = wd[1]
							draw_rect(Rect2(r.position + Vector2(3, 0), Vector2(10, 14)), Color(Art.OUT))
							draw_colored_polygon(PackedVector2Array([r.position + Vector2(4, 13), r.position + Vector2(4, 5), r.position + Vector2(8, 1), r.position + Vector2(12, 5), r.position + Vector2(12, 13)]), wc.darkened(0.2))
							draw_rect(Rect2(r.position + Vector2(7.5, 1), Vector2(1, 12)), Color(Art.OUT))
							draw_rect(Rect2(r.position + Vector2(4, 8), Vector2(8, 1)), Color(Art.OUT))
							draw_rect(Rect2(r.position + Vector2(5, 9), Vector2(2, 3)), wc.lightened(0.4))
					draw_rect(Rect2(r.position.x + 8, r.position.y + 8, 1, 1), wall_face.lightened(0.08))
					if (x * 5 + y * 3) % 7 == 0 and not _has_window(c):
						_banner(r.position, vault, prague)
					if prague and (x + y) % 3 == 0:
						draw_rect(Rect2(r.position.x + 3, r.position.y + 5, 2, 2), Color("b58f4a"))
						draw_rect(Rect2(r.position.x + 3, r.position.y + 5, 2, 1), Color("e0c27a"))
					if (x * 31 + y * 17) % 9 == 0 and not prague and not interior:
						draw_rect(Rect2(r.position.x + 2, r.position.y + 9, 5, 4), Color(0.2, 0.4, 0.25, 0.55))
						draw_rect(Rect2(r.position.x + 3, r.position.y + 11, 2, 3), Color(0.25, 0.5, 0.3, 0.5))
				continue
			var hv := (x * 73856093 ^ y * 19349663) % 7
			if interior:
				_draw_floor_plank(r, x, y)
			else:
				var fa := floor_a
				var fb := floor_b
				if (theme == "town_e" or theme == "town_p") and ((x >= 50 and x <= 62) or (x >= 44 and x <= 68 and y >= 19 and y <= 25)):
					fa = floor_a.lightened(0.12)
					fb = floor_b.lightened(0.12)
				draw_rect(r, fa if (x + y) % 2 == 0 else fb)
				if theme in TOWN_THEMES:
					var ph := (x * 92821 + y * 68917) % 23
					if ph == 0:
						draw_set_transform(r.position + Vector2(8, 10), 0.0, Vector2(1.0, 0.45))
						draw_circle(Vector2.ZERO, 6.5, Color(0.1, 0.12, 0.2, 0.45))
						draw_circle(Vector2(-1, -1), 4.0, Color(0.45, 0.55, 0.8, 0.22))
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					elif ph == 1 and theme == "town_e":
						draw_rect(Rect2(r.position.x + 3, r.position.y + 9, 2, 3), Color(0.2, 0.4, 0.25, 0.7))
						draw_rect(Rect2(r.position.x + 5, r.position.y + 10, 1, 2), Color(0.3, 0.5, 0.3, 0.7))
						draw_rect(Rect2(r.position.x + 8, r.position.y + 8, 1, 4), Color(0.25, 0.45, 0.28, 0.7))
					elif ph == 2:
						draw_rect(Rect2(r.position.x + 4, r.position.y + 5, 7, 5), Color(0.28, 0.26, 0.32, 0.5))
						draw_rect(Rect2(r.position.x + 5, r.position.y + 5, 5, 1), Color(1, 1, 1, 0.08))
				draw_rect(Rect2(r.position.x, r.position.y, TILE, 1), Color(0, 0, 0, 0.22))
				draw_rect(Rect2(r.position.x, r.position.y, 1, TILE), Color(0, 0, 0, 0.22))
				draw_rect(Rect2(r.position.x + 1, r.position.y + 1, TILE - 1, 1), Color(1, 1, 1, 0.04))
				draw_rect(Rect2(r.position.x + 8, r.position.y + 8, 1, 8), Color(0, 0, 0, 0.12))
				draw_rect(Rect2(r.position.x, r.position.y + 8, 16, 1), Color(0, 0, 0, 0.1))
				for i in 6:
					var dp := (x * 7 + y * 13 + i * 5) % 16
					draw_rect(Rect2(r.position.x + dp, r.position.y + (dp * 3 + i * 5) % 16, 1, 1), Color(1, 1, 1, 0.05) if i % 2 == 0 else Color(0, 0, 0, 0.14))
			if y > 0 and grid[y - 1][x] in ["#", "H"]:
				draw_rect(Rect2(r.position.x, r.position.y, TILE, 5), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(r.position.x, r.position.y + 5, TILE, 3), Color(0, 0, 0, 0.15))
			if hv == 3 and vault:
				draw_rect(Rect2(r.position + Vector2(3, 8), Vector2(10, 5)), Color(0.15, 0.2, 0.35, 0.6))
				draw_rect(Rect2(r.position + Vector2(5, 9), Vector2(4, 1)), Color(0.6, 0.75, 1.0, 0.25))
			if hv == 4 and not interior:
				draw_rect(Rect2(r.position + Vector2(11, 11), Vector2(3, 2)), Color(0.22, 0.4, 0.26, 0.6))
			if hv == 0:
				draw_line(r.position + Vector2(3, 5), r.position + Vector2(9, 9), Color(0, 0, 0, 0.25), 1.0)
			if hv == 1:
				draw_rect(Rect2(r.position + Vector2(10, 3), Vector2(2, 2)), Color(1, 1, 1, 0.05))
			if prague and (x + y) % 2 == 0:
				draw_rect(r, Color(0.7, 0.55, 0.3, 0.07))
			if theme == "prague" and x % 6 == 0:
				draw_rect(Rect2(r.position.x, r.position.y, 1, TILE), Color(0.72, 0.56, 0.28, 0.5))
			if ch == ",":
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


func _draw_arena_cell(r: Rect2, x: int, y: int, ch: String) -> void:
	var o := r.position
	var hv := (x * 73856093 ^ y * 19349663) & 0xffff
	var loch := arena == "loch"
	if arena not in ["loch", "attic"]:
		_draw_themed_cell(r, x, y, ch, hv)
		return
	if ch == "#":
		if _is_solid_char(Vector2i(x, y + 1)):
			draw_rect(r, Color("0a1217") if loch else Color("120c08"))
			return
		var base := Color("2c4650") if loch else Color("3c2a1e")
		draw_rect(r, base)
		if loch:
			for i in 3:
				var yy := o.y + 3 + i * 5
				draw_rect(Rect2(o.x, yy, TILE, 1), Color("1a2c34"))
				draw_rect(Rect2(o.x + (hv >> (i * 3)) % 12, yy - 3, 1, 3), Color("1a2c34"))
			draw_rect(Rect2(o.x, o.y, TILE, 1), Color("5a8a96"))
			if hv % 3 == 0:
				draw_rect(Rect2(o.x + 2, o.y + 4, 4, 9), Color(0.2, 0.5, 0.35, 0.55))
				draw_rect(Rect2(o.x + 3, o.y + 12, 2, 3), Color(0.3, 0.65, 0.45, 0.6))
			if hv % 5 == 1:
				draw_rect(Rect2(o.x + 9, o.y + 3, 1, 10), Color(0.6, 0.85, 0.95, 0.3))
			draw_colored_polygon(PackedVector2Array([o + Vector2(2 + hv % 8, 13), o + Vector2(6 + hv % 8, 13), o + Vector2(4 + hv % 8, 16)]), Color("1a2c34"))
		else:
			for i in 4:
				draw_rect(Rect2(o.x + i * 4, o.y, 1, TILE), Color("1e140e"))
			draw_rect(Rect2(o.x, o.y, TILE, 1), Color("6a4a32"))
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 2, o.y + 3, 12, 8), Color("7a5a48"))
				draw_rect(Rect2(o.x + 2, o.y + 7, 12, 1), Color("4a3226"))
				draw_rect(Rect2(o.x + 8, o.y + 3, 1, 4), Color("4a3226"))
			if hv % 6 == 1:
				draw_line(o + Vector2(0, 0), o + Vector2(16, 16), Color("5a3e2a"), 2.0)
			if hv % 7 == 2:
				draw_line(o + Vector2(1, 1), o + Vector2(7, 5), Color(0.9, 0.9, 0.85, 0.4), 1.0)
				draw_line(o + Vector2(1, 1), o + Vector2(4, 8), Color(0.9, 0.9, 0.85, 0.4), 1.0)
		draw_rect(Rect2(o.x, o.y + 13, TILE, 3), Color(0, 0, 0, 0.3))
		return
	if loch:
		var deep := Color("12303a") if (x + y) % 2 == 0 else Color("0f2a34")
		draw_rect(r, deep)
		if hv % 4 == 0:
			draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color(0.22, 0.4, 0.46, 0.35))
			draw_rect(Rect2(o.x + 1, o.y + 1, 14, 1), Color(0.5, 0.75, 0.8, 0.22))
		if hv % 3 == 1:
			draw_rect(Rect2(o.x + 2 + hv % 6, o.y + 5 + hv % 7, 6, 1), Color(0.5, 0.85, 0.9, 0.2))
		if hv % 11 == 2:
			draw_circle(o + Vector2(8, 8), 4.0, Color("1e5a38"))
			draw_circle(o + Vector2(7, 7), 2.5, Color("2e8a52"))
			draw_line(o + Vector2(8, 8), o + Vector2(12, 4), Color("0f2a34"), 1.0)
		if hv % 17 == 5:
			for k in 3:
				draw_line(o + Vector2(4 + k * 4, 15), o + Vector2(3 + k * 4 + hv % 3, 6), Color("2e7a4a"), 1.0)
		if y > 0 and grid[y - 1][x] == "#":
			draw_rect(Rect2(o.x, o.y, TILE, 3), Color(0.8, 0.95, 1.0, 0.25))
			draw_rect(Rect2(o.x, o.y + 3, TILE, 2), Color(0.8, 0.95, 1.0, 0.1))
		if ch == "o":
			draw_set_transform(o + Vector2(8, 14), 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, 11.0, Color(0.8, 0.95, 1.0, 0.25))
			draw_circle(Vector2.ZERO, 8.0, Color(0.1, 0.25, 0.3, 0.8))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(o + Vector2(3, 0), Vector2(10, 15)), Color(Art.OUT))
			draw_rect(Rect2(o + Vector2(4, 1), Vector2(8, 13)), Color("6a8088"))
			draw_rect(Rect2(o + Vector2(4, 1), Vector2(3, 13)), Color("8aa2aa"))
			draw_rect(Rect2(o + Vector2(4, 8), Vector2(8, 6)), Color("2e7a4a"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(3, 1), o + Vector2(6, -2), o + Vector2(9, 0), o + Vector2(13, 1)]), Color("5a7078"))
		return
	draw_rect(r, Color("2a1e16") if (x + y) % 2 == 0 else Color("251a13"))
	_draw_floor_plank(r, x, y)
	draw_rect(r, Color(0.08, 0.06, 0.05, 0.3))
	if hv % 5 == 0:
		draw_colored_polygon(PackedVector2Array([o + Vector2(3, 10), o + Vector2(7, 6), o + Vector2(12, 9), o + Vector2(10, 13)]), Color("7a5a44"))
		draw_line(o + Vector2(4, 10), o + Vector2(11, 9), Color("4a3226"), 1.0)
	if hv % 7 == 1:
		for k in 4:
			draw_line(o + Vector2(2 + k * 3, 14), o + Vector2(6 + k * 3, 9 - k % 2), Color("c8a860"), 1.0)
	if hv % 9 == 3:
		draw_circle(o + Vector2(8, 8), 5.0, Color(0.7, 0.68, 0.64, 0.18))
	if y > 0 and grid[y - 1][x] == "#":
		draw_rect(Rect2(o.x, o.y, TILE, 4), Color(0, 0, 0, 0.35))
	if ch == "o":
		draw_rect(Rect2(o + Vector2(2, 14), Vector2(12, 2)), Color("4a4650"))
		draw_rect(Rect2(o + Vector2(4, 0), Vector2(8, 15)), Color(Art.OUT))
		draw_rect(Rect2(o + Vector2(5, 0), Vector2(6, 14)), Color("5a3e2a"))
		draw_rect(Rect2(o + Vector2(5, 0), Vector2(2, 14)), Color("7a5a3e"))
		for k in 2:
			draw_rect(Rect2(o + Vector2(4, 3 + k * 7), Vector2(8, 2)), Color("3a3640"))
			draw_rect(Rect2(o + Vector2(4, 3 + k * 7), Vector2(8, 1)), Color("6a6674"))


const ARENA_PAL := {
	"keep": {"wall": "4a1c26", "line": "2a0e16", "hi": "8a3a48", "deep": "14080c", "fa": "2e1418", "fb": "281016", "pil": "6a2a34"},
	"ossuary": {"wall": "6a6252", "line": "3a3428", "hi": "a89e84", "deep": "14120e", "fa": "26221c", "fb": "201c16", "pil": "8a826e"},
	"cliff": {"wall": "3a4250", "line": "1e242e", "hi": "6a7888", "deep": "0c1016", "fa": "262c34", "fb": "20262e", "pil": "586270"},
	"lazaretto": {"wall": "4a5a3e", "line": "26301e", "hi": "88a068", "deep": "0e140a", "fa": "2a3226", "fb": "242c20", "pil": "6a7a58"},
	"cave": {"wall": "3e2a24", "line": "1e1410", "hi": "7a5a48", "deep": "0e0806", "fa": "2a1c18", "fb": "241814", "pil": "5a4036"},
}


func _draw_themed_cell(r: Rect2, x: int, y: int, ch: String, hv: int) -> void:
	var o := r.position
	var P: Dictionary = ARENA_PAL[arena]
	if ch == "#":
		if _is_solid_char(Vector2i(x, y + 1)):
			draw_rect(r, Color(P.deep))
			return
		draw_rect(r, Color(P.wall))
		draw_rect(Rect2(o.x, o.y, TILE, 1), Color(P.hi))
		match arena:
			"ossuary":
				for i in 2:
					for k in 2:
						var sc := o + Vector2(4 + k * 8, 4 + i * 6)
						draw_circle(sc, 3.2, Color("d8d0bc"))
						draw_rect(Rect2(sc + Vector2(-1.6, 2), Vector2(3.2, 2)), Color("d8d0bc"))
						draw_circle(sc + Vector2(-1.2, 0), 0.9, Color(P.line))
						draw_circle(sc + Vector2(1.2, 0), 0.9, Color(P.line))
			"keep":
				for i in 3:
					draw_rect(Rect2(o.x, o.y + 3 + i * 5, TILE, 1), Color(P.line))
					draw_rect(Rect2(o.x + (hv >> (i * 2)) % 12, o.y + 3 + i * 5 - 4, 1, 5), Color(P.line))
				if hv % 4 == 0:
					draw_rect(Rect2(o.x + 6, o.y + 2, 2, 11), Color(0.55, 0.06, 0.1, 0.8))
					draw_rect(Rect2(o.x + 5, o.y + 11, 4, 3), Color(0.65, 0.08, 0.12, 0.8))
			"cliff":
				for i in 3:
					draw_rect(Rect2(o.x, o.y + 4 + i * 4, TILE, 1), Color(P.line))
				if hv % 3 == 0:
					draw_rect(Rect2(o.x + 3, o.y + 2, 5, 11), Color(0.2, 0.32, 0.18, 0.6))
				draw_line(o + Vector2(2 + hv % 8, 2), o + Vector2(6 + hv % 8, 13), Color(P.line), 1.0)
			"lazaretto":
				for i in 2:
					draw_rect(Rect2(o.x, o.y + 5 + i * 6, TILE, 1), Color(P.line))
				draw_rect(Rect2(o.x + hv % 10, o.y + 1, 5, 4), Color(0.7, 0.72, 0.6, 0.3))
				if hv % 3 == 1:
					draw_rect(Rect2(o.x + 3, o.y + 6, 3, 8), Color(0.45, 0.7, 0.25, 0.5))
			"cave":
				draw_colored_polygon(PackedVector2Array([o + Vector2(0, 4), o + Vector2(8, 2 + hv % 4), o + Vector2(16, 5), o + Vector2(16, 13), o + Vector2(0, 14)]), Color(P.wall).lightened(0.06))
				draw_line(o + Vector2(2, 3), o + Vector2(14, 12), Color(P.line), 1.0)
				if hv % 3 == 0:
					draw_line(o + Vector2(2, 14), o + Vector2(8, 10), Color(1.0, 0.45, 0.1, 0.8), 1.0)
		draw_rect(Rect2(o.x, o.y + 13, TILE, 3), Color(0, 0, 0, 0.3))
		return
	draw_rect(r, Color(P.fa) if (x + y) % 2 == 0 else Color(P.fb))
	match arena:
		"keep":
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 2, o.y + 2, 12, 12), Color(0.08, 0.03, 0.05, 0.4))
			if hv % 9 == 1:
				draw_circle(o + Vector2(8, 9), 5.0, Color(0.45, 0.04, 0.08, 0.7))
				draw_circle(o + Vector2(7, 8), 2.5, Color(0.7, 0.1, 0.14, 0.7))
			if hv % 13 == 2:
				draw_line(o + Vector2(2, 2), o + Vector2(14, 14), Color(0.05, 0.02, 0.03), 1.0)
		"ossuary":
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color(0.35, 0.32, 0.26, 0.25))
			if hv % 6 == 1:
				draw_line(o + Vector2(3, 12), o + Vector2(12, 8), Color("c8c0a8"), 2.0)
				draw_circle(o + Vector2(3, 12), 1.6, Color("d8d0b8"))
				draw_circle(o + Vector2(12, 8), 1.6, Color("d8d0b8"))
			if hv % 13 == 4:
				draw_circle(o + Vector2(8, 8), 3.4, Color("c8c0a8"))
				draw_circle(o + Vector2(7, 7.6), 0.9, Color(P.line))
				draw_circle(o + Vector2(9.2, 7.6), 0.9, Color(P.line))
		"cliff":
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color(0.3, 0.36, 0.42, 0.3))
				draw_rect(Rect2(o.x + 1, o.y + 1, 14, 1), Color(0.55, 0.65, 0.75, 0.2))
			if hv % 7 == 3:
				draw_rect(Rect2(o.x + 3, o.y + 6, 9, 5), Color(0.18, 0.26, 0.34, 0.7))
				draw_rect(Rect2(o.x + 4, o.y + 7, 5, 1), Color(0.6, 0.75, 0.9, 0.4))
			if hv % 11 == 5:
				draw_line(o + Vector2(4, 14), o + Vector2(4, 8), Color("3a5a2a"), 1.0)
				draw_line(o + Vector2(7, 14), o + Vector2(8, 7), Color("3a5a2a"), 1.0)
		"lazaretto":
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color(0.35, 0.45, 0.28, 0.2))
			if hv % 8 == 3:
				draw_circle(o + Vector2(8, 8), 5.0, Color(0.3, 0.5, 0.2, 0.45))
			if hv % 6 == 1:
				for k in 4:
					draw_line(o + Vector2(2 + k * 3, 14), o + Vector2(5 + k * 3, 9 - k % 2), Color("8aa860"), 1.0)
		"cave":
			if hv % 4 == 0:
				draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color(0.1, 0.06, 0.05, 0.35))
			if hv % 6 == 2:
				draw_line(o + Vector2(0, 8), o + Vector2(7, 6), Color(1.0, 0.4, 0.08, 0.85), 2.0)
				draw_line(o + Vector2(7, 6), o + Vector2(14, 10), Color(1.0, 0.6, 0.15, 0.85), 1.0)
			if hv % 9 == 4:
				draw_circle(o + Vector2(8, 8), 3.0, Color(0.5, 0.45, 0.4, 0.5))
	if y > 0 and grid[y - 1][x] == "#":
		draw_rect(Rect2(o.x, o.y, TILE, 4), Color(0, 0, 0, 0.35))
	if ch == "o":
		draw_rect(Rect2(o + Vector2(2, 14), Vector2(12, 2)), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(o + Vector2(4, 0), Vector2(8, 15)), Color(Art.OUT))
		draw_rect(Rect2(o + Vector2(5, 0), Vector2(6, 14)), Color(P.pil))
		draw_rect(Rect2(o + Vector2(5, 0), Vector2(2, 14)), Color(P.hi))
		for k in 2:
			draw_rect(Rect2(o + Vector2(4, 3 + k * 7), Vector2(8, 2)), Color(P.line))


func _house_base(x: int, y: int) -> int:
	var bx := x
	while bx > 0 and grid[y][bx - 1] == "H":
		bx -= 1
	return bx


func _draw_house(r: Rect2, x: int, y: int) -> void:
	var bx := _house_base(x, y)
	var idx := (bx * 7 + 3) % 4
	var warm := theme == "town_p"
	var roofs: Array = [Color("7a3a2e"), Color("8a4a30"), Color("5a4a3a"), Color("6a3038")] if warm else [Color("3a3644"), Color("4a2f36"), Color("2f3a44"), Color("40362c")]
	var walls: Array = [Color("b09a72"), Color("a88a8a"), Color("8fa08a"), Color("c0a070")] if warm else [Color("6b6672"), Color("5f5a68"), Color("736a64"), Color("5a606c")]
	var below_h: bool = y + 1 < h and grid[y + 1][x] == "H"
	var above_h: bool = y > 0 and grid[y - 1][x] == "H"
	var left_h: bool = x > 0 and grid[y][x - 1] == "H"
	var right_h: bool = x + 1 < w and grid[y][x + 1] == "H"
	var o := r.position
	if below_h:
		var rc: Color = roofs[idx]
		draw_rect(r, rc)
		for ry in 4:
			var off := 0 if (ry + y) % 2 == 0 else 4
			draw_rect(Rect2(o.x, o.y + ry * 4 + 3, TILE, 1), rc.darkened(0.35))
			for k in 2:
				draw_rect(Rect2(o.x + off + k * 8, o.y + ry * 4, 1, 3), rc.darkened(0.3))
			draw_rect(Rect2(o.x, o.y + ry * 4, TILE, 1), rc.lightened(0.1))
		if not above_h:
			draw_rect(Rect2(o.x, o.y, TILE, 3), rc.lightened(0.22))
			draw_rect(Rect2(o.x, o.y, TILE, 1), rc.darkened(0.5))
		if not left_h:
			draw_rect(Rect2(o.x, o.y, 1, TILE), rc.darkened(0.55))
		if not right_h:
			draw_rect(Rect2(o.x + 15, o.y, 1, TILE), rc.darkened(0.55))
		if not above_h and (x - bx) == 1:
			draw_rect(Rect2(o.x + 3, o.y - 3, 8, 8), Color(Art.OUT))
			draw_rect(Rect2(o.x + 4, o.y - 2, 6, 7), Color("5a5260"))
			draw_rect(Rect2(o.x + 4, o.y - 2, 6, 1), Color("8a8296"))
	else:
		var wc: Color = walls[idx]
		draw_rect(r, wc)
		for ry in 3:
			draw_rect(Rect2(o.x, o.y + 3 + ry * 4, TILE, 1), wc.darkened(0.16))
		draw_rect(Rect2(o.x, o.y + 12, TILE, 4), wc.darkened(0.38))
		draw_rect(Rect2(o.x, o.y + 12, TILE, 1), wc.darkened(0.55))
		draw_rect(Rect2(o.x, o.y, TILE, 3), Color(0, 0, 0, 0.4))
		if not left_h:
			draw_rect(Rect2(o.x, o.y, 2, TILE), Color("2a2230"))
		if not right_h:
			draw_rect(Rect2(o.x + 14, o.y, 2, TILE), Color("2a2230"))
		if (x - bx) % 2 == 1 and left_h and right_h:
			var lit := (x * 7 + y) % 5 != 0
			draw_rect(Rect2(o.x + 3, o.y + 3, 10, 9), Color(Art.OUT))
			draw_rect(Rect2(o.x + 4, o.y + 4, 8, 7), Color("ffd98a") if lit else Color("2a2a3a"))
			draw_rect(Rect2(o.x + 4, o.y + 4, 8, 2), Color("ffeab0") if lit else Color("3a3a4c"))
			draw_rect(Rect2(o.x + 7.5, o.y + 4, 1, 7), Color(Art.OUT))
			draw_rect(Rect2(o.x + 4, o.y + 7.5, 8, 1), Color(Art.OUT))
			draw_rect(Rect2(o.x + 2, o.y + 12, 12, 2), Color("3a3040"))
			if theme == "town_p":
				var fc: Array = [Color("c0334f"), Color("e0b040"), Color("d0d0e0"), Color("a050c0")]
				draw_rect(Rect2(o.x + 2, o.y + 11, 12, 3), Color("4a3020"))
				for fx in 5:
					draw_circle(o + Vector2(3.5 + fx * 2.4, 11.0 + (fx % 2) * 0.6), 1.1, fc[(x + fx) % 4])
			else:
				draw_rect(Rect2(o.x + 1, o.y + 3, 2, 9), Color("3a2a22"))
				draw_rect(Rect2(o.x + 13, o.y + 3, 2, 9), Color("3a2a22"))
				draw_rect(Rect2(o.x + 1, o.y + 3, 1, 9), Color("5a4234"))
				draw_rect(Rect2(o.x + 13, o.y + 3, 1, 9), Color("5a4234"))
		elif (x - bx) % 3 == 0 and (x - bx) > 1 and left_h and right_h and (bx + x + y) % 2 == 0:
			var bcs: Array = [Color("7a1e2e"), Color("2c4a7a"), Color("8a6a20"), Color("3a5a3a")]
			var bcol: Color = bcs[(bx + x) % 4]
			draw_rect(Rect2(o.x + 5, o.y + 1, 6, 1.2), Color("3a2a22"))
			draw_colored_polygon(PackedVector2Array([Vector2(o.x + 5.5, o.y + 2.2), Vector2(o.x + 10.5, o.y + 2.2), Vector2(o.x + 10.5, o.y + 10.0), Vector2(o.x + 8, o.y + 8.0), Vector2(o.x + 5.5, o.y + 10.0)]), bcol)
			draw_rect(Rect2(o.x + 7.4, o.y + 3.5, 1.2, 2.5), bcol.lightened(0.35))


func _char_at(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return grid[y][x]


func _draw_floor_plank(r: Rect2, x: int, y: int) -> void:
	var o := r.position
	var base := Color("5a4228") if y % 2 == 0 else Color("523a24")
	draw_rect(r, base)
	draw_rect(Rect2(o.x, o.y, TILE, 1), Color(0, 0, 0, 0.32))
	draw_rect(Rect2(o.x, o.y + 8, TILE, 1), Color(0, 0, 0, 0.32))
	draw_rect(Rect2(o.x + (x * 5 + y * 3) % 12 + 2, o.y, 1, 8), Color(0, 0, 0, 0.26))
	draw_rect(Rect2(o.x + (x * 7 + y * 11) % 12 + 2, o.y + 8, 1, 8), Color(0, 0, 0, 0.26))
	draw_rect(Rect2(o.x + 1, o.y + 1, TILE - 2, 1), Color(1, 0.9, 0.7, 0.06))
	draw_rect(Rect2(o.x + 3, o.y + 4, 6, 1), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(o.x + 8, o.y + 12, 6, 1), Color(0, 0, 0, 0.1))


func _draw_furniture(r: Rect2, ch: String, x: int, y: int) -> void:
	var o := r.position
	var O := Color(Art.OUT)
	if ch == "Z":
		draw_rect(Rect2(o.x, o.y, TILE, TILE), O)
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color("4a3220"))
		var cols: Array = [Color("6a1e30"), Color("2c4a7a"), Color("4a5a2e"), Color("6a5420"), Color("5a3a6a"), Color("8a6a40")]
		for row in 2:
			var by := o.y + 2 + row * 7
			draw_rect(Rect2(o.x + 1, by + 5, 14, 1), Color("2a1c12"))
			var bxp := o.x + 2
			var k := 0
			while bxp < o.x + 14:
				var bw := 2 + (x * 3 + y * 5 + k * 2 + row) % 2
				var bh := 4 - (k + row) % 2
				draw_rect(Rect2(bxp, by + 5 - bh, bw, bh), cols[(x + y + k * 2 + row) % 6])
				draw_rect(Rect2(bxp, by + 5 - bh, bw, 1), Color(1, 1, 1, 0.18))
				bxp += bw + 0.5
				k += 1
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 1), Color("6a4a30"))
	elif ch == "T":
		draw_rect(Rect2(o.x + 1, o.y + 12, 14, 3), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(o.x + 1, o.y + 3, 14, 11), O)
		draw_rect(Rect2(o.x + 2, o.y + 4, 12, 8), Color("7a5430"))
		draw_rect(Rect2(o.x + 2, o.y + 4, 12, 2), Color("9a7040"))
		draw_rect(Rect2(o.x + 2, o.y + 12, 12, 2), Color("4a3220"))
		draw_rect(Rect2(o.x + 2, o.y + 7, 12, 1), Color(0, 0, 0, 0.18))
		var k := (x * 7 + y * 3) % 4
		if k == 0:
			draw_rect(Rect2(o.x + 6, o.y + 5, 3, 4), O)
			draw_rect(Rect2(o.x + 6.6, o.y + 5.6, 1.8, 2.8), Color("c8a050"))
		elif k == 1:
			draw_circle(o + Vector2(8, 7.5), 3.0, O)
			draw_circle(o + Vector2(8, 7.5), 2.2, Color("c8c0b0"))
			draw_circle(o + Vector2(8, 7.5), 1.2, Color("7a3a24"))
		elif k == 2:
			draw_rect(Rect2(o.x + 4, o.y + 5, 4, 3), Color("e8e0c8"))
			draw_rect(Rect2(o.x + 9, o.y + 6, 3, 3), O)
			draw_rect(Rect2(o.x + 9.6, o.y + 6.6, 1.8, 1.8), Color("c8a050"))
		else:
			draw_rect(Rect2(o.x + 5, o.y + 5, 6, 3), Color("d8c8a0"))
			draw_rect(Rect2(o.x + 7, o.y + 4, 1, 5), Color("c0334f"))
	elif ch == "J":
		draw_rect(Rect2(o.x, o.y + 2, TILE, 14), O)
		draw_rect(Rect2(o.x, o.y + 3, TILE, 4), Color("a07a48"))
		draw_rect(Rect2(o.x, o.y + 3, TILE, 1), Color("c8a068"))
		draw_rect(Rect2(o.x, o.y + 7, TILE, 8), Color("5a3a22"))
		draw_rect(Rect2(o.x + 1, o.y + 9, 6, 5), Color("6a4a2a"))
		draw_rect(Rect2(o.x + 9, o.y + 9, 6, 5), Color("6a4a2a"))
		draw_rect(Rect2(o.x + 1, o.y + 9, 6, 5), Color("3a2414"), false, 0.7)
		draw_rect(Rect2(o.x + 9, o.y + 9, 6, 5), Color("3a2414"), false, 0.7)
		if (x + y) % 3 == 0:
			draw_rect(Rect2(o.x + 4, o.y + 1, 2, 2), Color("e0c060"))
			draw_rect(Rect2(o.x + 7, o.y + 1.5, 2, 1.5), Color("c8a040"))
	elif ch == "F":
		draw_rect(Rect2(o.x, o.y, TILE, TILE), O)
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color("3a2a1c"))
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 2), Color("5a4430"))
		var kk := (x * 5 + y * 11) % 3
		for i in 3:
			var px := o.x + 3.5 + i * 4.2
			if kk == 0:
				draw_rect(Rect2(px, o.y + 3, 1.2, 10), Color("c4c8d4"))
				draw_rect(Rect2(px - 1, o.y + 10, 3.2, 1.2), Color("c8a050"))
			elif kk == 1:
				draw_circle(Vector2(px + 0.6, o.y + 8), 2.8, Color("8a8d98"))
				draw_circle(Vector2(px + 0.2, o.y + 7.4), 1.2, Color("c4c8d4"))
			else:
				draw_rect(Rect2(px, o.y + 4, 3, 8), Color("4a4d58"))
				draw_rect(Rect2(px, o.y + 4, 3, 1.4), Color("8a8d98"))
				draw_rect(Rect2(px + 1.2, o.y + 6, 0.8, 4), Color("c8a050"))
		draw_rect(Rect2(o.x + 1, o.y + 13, 14, 1.4), Color("2a1c12"))
	elif ch == "C":
		draw_rect(Rect2(o.x + 3, o.y + 12, 10, 3), Color(0, 0, 0, 0.28))
		draw_rect(Rect2(o.x + 3, o.y + 2, 10, 5), O)
		draw_rect(Rect2(o.x + 4, o.y + 3, 8, 3), Color("6a4a2a"))
		draw_rect(Rect2(o.x + 3, o.y + 7, 10, 6), O)
		draw_rect(Rect2(o.x + 4, o.y + 8, 8, 4), Color("8a5a30"))
		draw_rect(Rect2(o.x + 4, o.y + 8, 8, 1), Color("a87a48"))
	elif ch == "R":
		draw_rect(Rect2(o.x, o.y, TILE, TILE), Color("6a1e30"))
		draw_rect(Rect2(o.x, o.y, TILE, TILE), Color(0, 0, 0, 0.0))
		var up := _char_at(x, y - 1) != "R"
		var dn := _char_at(x, y + 1) != "R"
		var lf := _char_at(x - 1, y) != "R"
		var rt := _char_at(x + 1, y) != "R"
		var gc := Color("c8a050")
		if up:
			draw_rect(Rect2(o.x, o.y, TILE, 2), gc)
		if dn:
			draw_rect(Rect2(o.x, o.y + 14, TILE, 2), gc)
		if lf:
			draw_rect(Rect2(o.x, o.y, 2, TILE), gc)
		if rt:
			draw_rect(Rect2(o.x + 14, o.y, 2, TILE), gc)
		draw_rect(Rect2(o.x + 6, o.y + 6, 4, 4), Color("3a1020"))
		draw_rect(Rect2(o.x + 7, o.y + 7, 2, 2), gc)
	elif ch == "Y":
		var bc: Color = [Color("6a1e30"), Color("2c4a7a"), Color("4a5a2e"), Color("5a3a6a")][(x * 3 + y) % 4]
		draw_rect(Rect2(o.x, o.y + 1, TILE, 15), O)
		draw_rect(Rect2(o.x + 1, o.y + 2, 14, 13), Color("4a3220"))
		draw_rect(Rect2(o.x + 2, o.y + 3, 12, 4), Color("d8d0c0"))
		draw_rect(Rect2(o.x + 2, o.y + 3, 12, 1), Color("f0ead8"))
		draw_rect(Rect2(o.x + 2, o.y + 7, 12, 8), bc)
		draw_rect(Rect2(o.x + 2, o.y + 7, 12, 2), bc.lightened(0.2))
		draw_rect(Rect2(o.x + 2, o.y + 13, 12, 2), bc.darkened(0.3))
	else:
		draw_rect(Rect2(o.x, o.y, TILE, TILE), O)
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 14), Color("5a5668"))
		for ry in 3:
			draw_rect(Rect2(o.x + 1, o.y + 4 + ry * 4, 14, 1), Color("3a3646"))
		draw_rect(Rect2(o.x + 1, o.y + 1, 14, 2), Color("8a869a"))
		draw_rect(Rect2(o.x + 3, o.y + 5, 10, 10), O)
		draw_rect(Rect2(o.x + 4, o.y + 7, 8, 8), Color("1a0c08"))
		draw_rect(Rect2(o.x + 5, o.y + 11, 6, 3), Color("d05a1a"))
		draw_rect(Rect2(o.x + 6, o.y + 12, 4, 2), Color("ffb040"))


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
	gt += _delta
	if cam:
		shake_amt = maxf(0.0, shake_amt - _delta * 14.0)
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt + cam_bob
	for f in fog:
		f.position.x += f.get_meta("spd") * _delta
		if f.position.x > w * TILE + 100:
			f.position.x = -100
	if overlay:
		overlay.queue_redraw()
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
			"entry":
				text = "[E] " + str(_nearest.def.get("label", "Enter"))
			"grave", "statue", "seal_bell", "seal_dagger", "seal_bolt":
				text = "[E] Examine"
			"barrel", "chest", "crate", "urn", "tomes":
				text = "[E] Search"
	hud.hint = text
	if Input.is_action_just_pressed("swap") and not frozen and not hud.paused:
		cycle_lead()
	if Input.is_action_just_pressed("status") and not frozen and not _busy and not Dialogue.blocking() and not hud.paused and not player.dead:
		open_status()
	if Input.is_action_just_pressed("reset_puzzle") and not frozen:
		_reset_puzzle()


func _reset_puzzle() -> void:
	if GameState.flag(prefix + "_gate_open"):
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
		GameState.set_flag(prefix + "_key_taken")
		Audio.sfx("pickup")
		p.queue_free()
		_run_events(prefix + "_key")
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
			GameState.set_flag(prefix + "_gate_open")
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
				GameState.set_flag(prefix + "_door_open")
				Audio.sfx("door")
				p.unlock()
			else:
				await Dialogue.play(prefix + "_locked")
		"npc":
			await _talk(p)
		"entry":
			await _enter(p)
			return
		"barrel", "chest", "crate", "urn", "tomes", "grave", "statue":
			await _search(p)
		"seal_bell", "seal_dagger", "seal_bolt":
			var hints := {"seal_bell": "A bell of blue glass set in the floor, cracked across the lip. It hums when anything loud is near. A struck bell would answer it, rung by someone who learned to ring.",
				"seal_dagger": "A painted roundel of the old Ringers' guild, scored with tiny knife-nicks. It wants a thrown blade, and someone who throws well.",
				"seal_bolt": "A brass socket with a stopped wheel inside. It wants a spark of clockwork, loosed from some distance by someone who builds such things."}
			var lit_txt: String = "The seal glows softly. It has been answered." if p.lit else hints[p.kind]
			await Dialogue.play_lines([{"who": "", "text": lit_txt}])
		"shrine":
			await _shrine()
		"table":
			await Dialogue.play("worldmap")
		"portal":
			if not GameState.flag("isolde_joined"):
				await Dialogue.play("portal_alone")
			elif GameState.flag("prague_done"):
				await Dialogue.play("portal_done2")
			elif GameState.flag("edinburgh_done"):
				_busy = false
				_leave("prague_town", "from_chapel")
				return
			else:
				_busy = false
				_leave("edinburgh", "from_chapel")
				return
	_busy = false


func _pick_dialogue(d: Dictionary) -> String:
	var id: String = d.id
	for v in d.get("variants", []):
		if (not v.has("if") or GameState.flag(v["if"])) and (not v.has("not") or not GameState.flag(v["not"])):
			return v.id
	if GameState.flag("talked_" + id) and Dialogue.data.has(id + "_again"):
		return id + "_again"
	return id


func _enter(p: Node2D) -> void:
	var d: Dictionary = p.def
	if d.has("requires") and not GameState.flag(d.requires):
		await Dialogue.play(d.get("locked", ""))
		_busy = false
		return
	if d.has("once"):
		if not GameState.flag(d.once):
			GameState.set_flag(d.once)
			await Dialogue.play(d.once)
	_busy = false
	Audio.sfx("door")
	_leave(d.map, "door:" + map_name)


func _search(p: Node2D) -> void:
	var d: Dictionary = p.def
	var fid := "found_" + str(d.get("id", ""))
	if not d.has("id") or GameState.flag(fid):
		await Dialogue.play_lines([{"who": "", "text": d.get("empty", "Nothing more of interest here.")}])
		return
	GameState.set_flag(fid)
	var reward: String = d.get("reward", "")
	var found_gear: String = GEAR_SECRETS.get(d.id, "")
	if found_gear != "":
		_grant_gear(found_gear)
	if d.has("item"):
		GameState.items.append(d.item)
	match reward:
		"maxhp":
			GameState.base_hp += 1
			GameState.refresh_stats()
			GameState.hp = GameState.max_hp
			Audio.sfx("form")
		"heal":
			GameState.hp = GameState.max_hp
			Audio.sfx("switch")
		"relic", "lore":
			Audio.sfx("pickup")
		_:
			Audio.sfx("switch")
	if d.has("item"):
		var coin := int(18 * Gear.gold_mult())
		GameState.gold += coin
		hud.show_notice(("Found: %s  (+%d gold)" % [d.item, coin]) + (("  +  " + Gear.ITEMS[found_gear].name) if found_gear != "" else ""))
	elif reward == "maxhp" or reward == "heal":
		hud.show_notice("Vitality restored" if reward == "heal" else "Your vitality grows")
	GameState.save_game()
	await Dialogue.play_lines([{"who": "", "text": d.get("text", "")}])
	p.queue_redraw()


func open_status() -> void:
	var sc := Control.new()
	sc.set_script(load("res://src/scenes/world/status.gd"))
	sc.level = self
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(sc)
	add_child(layer)
	frozen = true
	await sc.closed
	layer.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	frozen = false


func open_shop(kind: String, tier: int) -> void:
	var sh := Control.new()
	sh.set_script(load("res://src/scenes/world/shop.gd"))
	sh.kind = kind
	sh.tier = tier
	sh.level = self
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(sh)
	add_child(layer)
	frozen = true
	await sh.closed
	layer.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	frozen = false


func _talk(p: Node2D) -> void:
	if not p.def.is_empty():
		var did := _pick_dialogue(p.def)
		await Dialogue.play(did)
		GameState.set_flag("talked_" + p.def.id)
		if p.def.has("shop"):
			await open_shop(p.def.shop, p.def.get("tier", 2))
		return
	if p.id == "aldous":
		if not GameState.flag("isolde_joined"):
			await Dialogue.play("aldous_pre")
		elif GameState.flag("prague_done"):
			await Dialogue.play("aldous_prague")
		elif GameState.flag("edinburgh_done"):
			await Dialogue.play("aldous_after")
		else:
			await Dialogue.play("aldous_ready")
	elif p.id == "isolde":
		await Dialogue.play("isolde_meet")
		GameState.set_flag("isolde_joined")
		_join_party(p, "isolde", "Isolde")
	elif p.id == "wren":
		await Dialogue.play("wren_meet")
		GameState.set_flag("wren_joined")
		_join_party(p, "wren", "Wren")
	elif p.id == "corvin":
		await Dialogue.play("corvin_meet")
		GameState.set_flag("corvin_joined")
		_join_party(p, "corvin", "Corvin")


func _join_party(p: Node2D, id: String, display: String) -> void:
	GameState.party.append(id)
	interactables.erase(p)
	p.unlock()
	_spawn_follower(id)
	hud.show_notice("%s joins the party" % display)
	Audio.sfx("pickup")
	GameState.save_game()


func _shrine() -> void:
	var sh: Dictionary = meta.get("shrine", {})
	if sh.is_empty():
		return
	var form: String = sh.form
	if not GameState.flag(form + "_unlocked"):
		await Dialogue.play(sh.dialogue)
		if not form in GameState.forms:
			GameState.forms.append(form)
		GameState.set_flag(form + "_unlocked")
		GameState.hp = GameState.max_hp
		Audio.sfx("form")
		hud.show_notice(sh.notice)
		GameState.save_game()
	else:
		GameState.hp = GameState.max_hp
		Audio.sfx("switch")
		await Dialogue.play(sh.after)


func _run_events(id: String) -> void:
	_busy = true
	await Dialogue.play(id)
	_busy = false


func boss_awake() -> void:
	_run_events(meta.get("boss", {}).get("intro", "kelpie_intro"))


func enemy_died(e: Node2D) -> void:
	if e.is_boss:
		_boss_defeated(e.position)
	else:
		var coin := int(randi_range(2, 5) * Gear.gold_mult())
		GameState.gold += coin
	if not e.is_boss and randf() < 0.3:
		var c := Vector2i(int(e.position.x / TILE), int(e.position.y / TILE))
		_make_prop("heart", c)
		var hp_prop: Node2D = pickups.back()
		hp_prop.position = e.position


func _grant_gear(id: String) -> void:
	if id in GameState.owned:
		return
	GameState.owned.append(id)
	hud.show_notice("Gear found: %s  (Tab to equip)" % Gear.ITEMS[id].name)


func _boss_defeated(pos: Vector2) -> void:
	for en in get_tree().get_nodes_in_group("enemies"):
		if en != null and not en.is_boss:
			en.queue_free()
	Audio.sfx("bell")
	_busy = true
	await get_tree().create_timer(0.8).timeout
	Audio.play_music(meta.get("music", "crypt"))
	var bi: Dictionary = meta.get("boss", {})
	await Dialogue.play(bi.get("defeated", "kelpie_defeated"))
	if bi.has("leave") and bi.leave in GameState.party:
		if GameState.lead == bi.leave:
			switch_hero("mu")
		GameState.party.erase(bi.leave)
		GameState.set_flag(bi.leave + "_left")
		if followers.has(bi.leave) and is_instance_valid(followers[bi.leave]):
			followers[bi.leave].queue_free()
		followers.erase(bi.leave)
		_relink_followers()
		GameState.refresh_stats()
		hud.show_notice("%s leaves the party" % bi.leave.capitalize())
	GameState.gold += int(80 * Gear.gold_mult())
	if BOSS_GEAR.has(map_name):
		_grant_gear(BOSS_GEAR[map_name])
	var final_cell: Vector2i = marks.get("X", Vector2i(int(pos.x / TILE), int(pos.y / TILE)))
	walkovers.append(_make_prop("final", final_cell))
	GameState.hp = GameState.max_hp
	GameState.save_game()
	hud.show_notice("Step into the light to return to the chapel")
	_busy = false


func _leave_via(p: Node2D) -> void:
	if p.kind == "final" or p.kind == "exit":
		var ex: Dictionary = meta.get("exit", {"map": "chapel", "spawn": "start"})
		if p.kind == "final" and meta.has("final_exit"):
			ex = meta.final_exit
		_leave(ex.map, ex.spawn)


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
