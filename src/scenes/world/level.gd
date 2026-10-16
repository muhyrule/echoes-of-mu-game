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
var cam: Camera2D
var shake_amt := 0.0
var overlay: Node2D
var fog: Array = []
var windows: Array = []
var gt := 0.0
var theme := "chapel"
var prefix := ""
var followers: Dictionary = {}
var cracked_props: Array = []


func _ready() -> void:
	map_name = GameState.current_map
	var f := FileAccess.open("res://data/maps/%s.json" % map_name, FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
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
	_place_player()
	entities.add_child(player)
	player.died.connect(_on_player_died)
	_setup_camera()
	_setup_hud()
	_setup_fx()
	_setup_atmosphere()
	_spawn_followers()

	Audio.play_music(meta.get("music", "crypt"))
	if map_name == "chapel":
		GameState.hp = GameState.max_hp
	hud.show_banner(meta.title, meta.subtitle)
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
	var gate_flag := GameState.flag(prefix + "_gate_open")
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
	player.position = _cell_center(c)


func _setup_camera() -> void:
	cam = Camera2D.new()
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
	tint.color = {"vault": Color(0.38, 0.4, 0.56), "prague": Color(0.46, 0.46, 0.52), "chapel": Color(0.55, 0.5, 0.62)}[theme]
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


func _setup_fx() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(230, 130)
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
		f.modulate = {"vault": Color(0.55, 0.6, 0.85, 0.16), "prague": Color(0.85, 0.7, 0.45, 0.1), "chapel": Color(0.75, 0.6, 0.8, 0.12)}[theme]
		f.z_index = 14
		f.set_meta("spd", randf_range(2.0, 6.0))
		add_child(f)
		fog.append(f)
	overlay = Node2D.new()
	overlay.z_index = 16
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	overlay.material = mat
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	var cols := [Color("d0405a"), Color("4a7be0"), Color("e0b040"), Color("40b08a")]
	var n := 0
	for x in range(3, w - 2, 5):
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
		if br > 0.0:
			var fl := 0.8 + 0.2 * sin(gt * 9.0 + e.position.x)
			overlay.draw_circle(e.position + Vector2(0, -6), br, Color(bc, 0.05 * fl))
			overlay.draw_circle(e.position + Vector2(0, -6), br * 0.55, Color(bc, 0.07 * fl))
			overlay.draw_circle(e.position + Vector2(0, -6), br * 0.2, Color(bc, 0.16 * fl))


const FOLLOW_PAL := {"isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}


func _spawn_follower(id: String) -> void:
	if followers.has(id) and is_instance_valid(followers[id]):
		return
	var lead: Node2D = player
	for fid in GameState.party:
		if fid == id:
			break
		if followers.has(fid) and is_instance_valid(followers[fid]):
			lead = followers[fid]
	var f := Node2D.new()
	f.set_script(FollowerScript)
	entities.add_child(f)
	f.start(lead, FOLLOW_PAL[id])
	followers[id] = f


func _relink_followers() -> void:
	var lead: Node2D = player
	for fid in GameState.party:
		if followers.has(fid) and is_instance_valid(followers[fid]):
			followers[fid].target = lead
			lead = followers[fid]


func _spawn_followers() -> void:
	for id in GameState.party:
		if FOLLOW_PAL.has(id):
			_spawn_follower(id)


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
	var prague := theme == "prague"
	var floor_a := Color("2c2a33") if vault else (Color("34363f") if prague else Color("38323f"))
	var floor_b := Color("26242d") if vault else (Color("2a2c35") if prague else Color("322c38"))
	var wall_top := Color("15131b")
	var wall_face := Color("4a4558") if vault else (Color("565a66") if prague else Color("5a4f66"))
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
					if (x * 31 + y * 17) % 9 == 0 and not prague:
						draw_rect(Rect2(r.position.x + 2, r.position.y + 9, 5, 4), Color(0.2, 0.4, 0.25, 0.55))
						draw_rect(Rect2(r.position.x + 3, r.position.y + 11, 2, 3), Color(0.25, 0.5, 0.3, 0.5))
				continue
			var hv := (x * 73856093 ^ y * 19349663) % 7
			draw_rect(r, floor_a if (x + y) % 2 == 0 else floor_b)
			draw_rect(Rect2(r.position.x, r.position.y, TILE, 1), Color(0, 0, 0, 0.22))
			draw_rect(Rect2(r.position.x, r.position.y, 1, TILE), Color(0, 0, 0, 0.22))
			draw_rect(Rect2(r.position.x + 1, r.position.y + 1, TILE - 1, 1), Color(1, 1, 1, 0.04))
			draw_rect(Rect2(r.position.x + 8, r.position.y + 8, 1, 8), Color(0, 0, 0, 0.12))
			draw_rect(Rect2(r.position.x, r.position.y + 8, 16, 1), Color(0, 0, 0, 0.1))
			for i in 6:
				var dp := (x * 7 + y * 13 + i * 5) % 16
				draw_rect(Rect2(r.position.x + dp, r.position.y + (dp * 3 + i * 5) % 16, 1, 1), Color(1, 1, 1, 0.05) if i % 2 == 0 else Color(0, 0, 0, 0.14))
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
			if prague and (x + y) % 2 == 0:
				draw_rect(r, Color(0.7, 0.55, 0.3, 0.07))
			if prague and x % 6 == 0:
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
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
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
	hud.hint = text
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
				_leave("prague", "start")
				return
			else:
				_busy = false
				_leave("vaults", "start")
				return
	_busy = false


func _talk(p: Node2D) -> void:
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
	_run_events(meta.get("boss", {}).get("intro", "warden_intro"))


func enemy_died(e: Node2D) -> void:
	if e.is_boss:
		_boss_defeated(e.position)
	elif randf() < 0.3:
		var c := Vector2i(int(e.position.x / TILE), int(e.position.y / TILE))
		_make_prop("heart", c)
		var hp_prop: Node2D = pickups.back()
		hp_prop.position = e.position


func _boss_defeated(pos: Vector2) -> void:
	for en in get_tree().get_nodes_in_group("enemies"):
		if en != null and not en.is_boss:
			en.queue_free()
	Audio.sfx("bell")
	_busy = true
	await get_tree().create_timer(0.8).timeout
	Audio.play_music(meta.get("music", "crypt"))
	var bi: Dictionary = meta.get("boss", {})
	await Dialogue.play(bi.get("defeated", "warden_defeated"))
	if bi.has("leave") and bi.leave in GameState.party:
		GameState.party.erase(bi.leave)
		GameState.set_flag(bi.leave + "_left")
		if followers.has(bi.leave) and is_instance_valid(followers[bi.leave]):
			followers[bi.leave].queue_free()
		followers.erase(bi.leave)
		_relink_followers()
		hud.show_notice("%s leaves the party" % bi.leave.capitalize())
	var final_cell: Vector2i = marks.get("X", Vector2i(int(pos.x / TILE), int(pos.y / TILE)))
	walkovers.append(_make_prop("final", final_cell))
	GameState.hp = GameState.max_hp
	GameState.save_game()
	hud.show_notice("Step into the light to return to the chapel")
	_busy = false


func _leave_via(p: Node2D) -> void:
	if p.kind == "final" or p.kind == "exit":
		var ex: Dictionary = meta.get("exit", {"map": "chapel", "spawn": "start"})
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
