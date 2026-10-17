extends Control
## Party status, equipment, supplies and relics. Drawn in 640x360 logical units at 3x.

const Art = preload("res://src/core/art.gd")
const UI = preload("res://src/core/pixel_ui.gd")
const GOLD := Color("d9b45a")
const GOLD_D := Color("7a5a24")
const DIM := Color("987a7d")
const GOOD := Color("8adf8a")
const BAD := Color("e07a7a")
const SECTIONS := ["Equipment", "Supplies", "Relics"]

signal closed

var level: Node
var font: Font
var heroes: Array = []
var hero_i := 0
var section := 0
var sel := 0
var msg := ""
var warm := 3
var portrait: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	heroes = Gear.active_heroes()
	portrait = Node2D.new()
	portrait.set_script(load("res://src/scenes/world/portrait.gd"))
	portrait.position = Vector2(119, 153) * 3.0
	portrait.scale = Vector2(3, 3)
	add_child(portrait)
	_sync()
	Audio.sfx("door")


func _hero() -> String:
	return heroes[hero_i]


func _sync() -> void:
	portrait.hero = _hero()
	sel = 0


func _entries() -> Array:
	var out: Array = []
	match section:
		0:
			for slot in ["weapon", "armor"]:
				for id in Gear.owned_for(_hero(), slot):
					out.append({"kind": "gear", "id": id, "slot": slot})
		1:
			for id in Gear.SUPPLIES:
				out.append({"kind": "supply", "id": id})
		2:
			for it in GameState.items:
				out.append({"kind": "relic", "name": it})
	return out


func _process(_delta: float) -> void:
	if warm > 0:
		warm -= 1
		queue_redraw()
		return
	var es := _entries()
	var n := maxi(1, es.size())
	if Input.is_action_just_pressed("move_right"):
		hero_i = (hero_i + 1) % heroes.size()
		_sync()
		Audio.sfx("switch")
		msg = ""
	elif Input.is_action_just_pressed("move_left"):
		hero_i = (hero_i - 1 + heroes.size()) % heroes.size()
		_sync()
		Audio.sfx("switch")
		msg = ""
	if Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % n
		Audio.sfx("switch")
	elif Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + n) % n
		Audio.sfx("switch")
	if Input.is_action_just_pressed("form"):
		section = (section + 1) % SECTIONS.size()
		sel = 0
		msg = ""
		Audio.sfx("switch")
	if Input.is_action_just_pressed("interact") and not es.is_empty():
		_activate(es[clampi(sel, 0, es.size() - 1)])
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("status"):
		closed.emit()
		set_process(false)
	queue_redraw()


func _activate(e: Dictionary) -> void:
	if e.kind == "gear":
		var slot: String = e.slot
		if Gear.equipped(_hero(), slot) == e.id:
			msg = "Already equipped."
			return
		if not GameState.equip.has(_hero()):
			GameState.equip[_hero()] = {}
		GameState.equip[_hero()][slot] = e.id
		GameState.refresh_stats()
		msg = "Equipped %s." % Gear.ITEMS[e.id].name
		Audio.sfx("form")
	elif e.kind == "supply":
		var before := GameState.hp
		var had := int(GameState.supplies.get(e.id, 0))
		if had <= 0:
			msg = "You have none."
		elif e.id != "candle" and GameState.hp >= GameState.max_hp:
			msg = "Your health is already full."
		else:
			level.player.use_supply(e.id)
			msg = ("Ward lit for 8 seconds." if e.id == "candle" else "Restored %d hearts." % (GameState.hp - before))


func _txt(pos: Vector2, s: String, size: int, col: Color, right := false) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	size *= 3
	var p := pos * 3.0
	if right:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))


func _frame(r: Rect2, a := 0.95) -> void:
	UI.panel(self, r, a)


func _stat(y: float, label: String, val: String, col := Color.WHITE) -> void:
	_txt(Vector2(52, y), label, 9, DIM)
	_txt(Vector2(186, y), val, 9, col, true)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.6))
	_frame(Rect2(30, 14, 580, 332))
	_txt(Vector2(46, 34), "Party & Inventory", 13, GOLD)
	_txt(Vector2(594, 34), "Gold %d    Keys %d" % [GameState.gold, GameState.keys], 11, Color("f0d070"), true)
	var hero := _hero()
	for i in heroes.size():
		var r := Rect2(46 + i * 70, 42, 66, 14)
		draw_rect(r, Color("34424b") if i == hero_i else Color("172129"))
		draw_rect(r, GOLD if i == hero_i else GOLD_D, false, 0.8)
		_txt(Vector2(52 + i * 70, 52), Gear.HERO_NAMES[heroes[i]], 9, Color.WHITE if i == hero_i else DIM)
	_frame(Rect2(44, 62, 150, 238), 0.8)
	_txt(Vector2(119, 78), Gear.HERO_NAMES[hero], 11, Color("fff0b0"), false)
	var wi: Dictionary = Gear.ITEMS[Gear.equipped(hero, "weapon")]
	var ai: Dictionary = Gear.ITEMS[Gear.equipped(hero, "armor")]
	_stat(168, "Vitality", "%d / %d" % [GameState.hp, GameState.max_hp] if hero == "mu" else "+%d" % int(ai.hp + wi.hp), Color("e07a8a"))
	_stat(180, "Attack", "+%d" % int(wi.atk + ai.atk))
	_stat(192, "Defence", "+%d" % int(wi.def + ai.def))
	_txt(Vector2(52, 208), "Weapon", 8, DIM)
	_txt(Vector2(52, 218), String(wi.name), 9, Color("c8d0e0"))
	_txt(Vector2(52, 232), "Armour", 8, DIM)
	_txt(Vector2(52, 242), String(ai.name), 9, Color("c8d0e0"))
	_txt(Vector2(52, 258), "Role", 8, DIM)
	_txt(Vector2(52, 268), _role(hero), 8, Color("ffb7bd"))
	_txt(Vector2(52, 282), "Form: %s" % GameState.form.capitalize(), 8, DIM)
	for i in SECTIONS.size():
		var r2 := Rect2(204 + i * 84, 62, 80, 14)
		draw_rect(r2, Color("34424b") if i == section else Color("172129"))
		draw_rect(r2, GOLD if i == section else GOLD_D, false, 0.8)
		_txt(Vector2(210 + i * 84, 72), SECTIONS[i], 9, Color.WHITE if i == section else DIM)
	_frame(Rect2(204, 82, 396, 150), 0.8)
	var es := _entries()
	if es.is_empty():
		_txt(Vector2(216, 108), "Nothing here yet.", 10, DIM)
	var sel_c := clampi(sel, 0, maxi(0, es.size() - 1))
	var first := clampi(sel_c - 5, 0, maxi(0, es.size() - 7))
	for i in range(first, mini(es.size(), first + 7)):
		var e: Dictionary = es[i]
		var y := 88.0 + (i - first) * 20.0
		if i == sel_c:
			draw_rect(Rect2(208, y, 388, 18), Color("2a3248"))
			draw_rect(Rect2(208, y, 388, 18), GOLD, false, 0.8)
		var label := ""
		var tag := ""
		var col := Color.WHITE
		match e.kind:
			"gear":
				var it: Dictionary = Gear.ITEMS[e.id]
				label = ("Weapon  " if e.slot == "weapon" else "Armour  ") + it.name
				if Gear.equipped(hero, e.slot) == e.id:
					tag = "Equipped"
					col = GOOD
				elif it.tier == 9:
					tag = "Treasure"
			"supply":
				label = Gear.SUPPLIES[e.id].name
				tag = "x%d  [%s]" % [int(GameState.supplies.get(e.id, 0)), Gear.SUPPLIES[e.id].key]
			"relic":
				label = e.name
		_txt(Vector2(214, y + 13), label, 9, col)
		_txt(Vector2(590, y + 13), tag, 9, GOLD, true)
	if es.size() > 7:
		_txt(Vector2(590, 228), "%d / %d" % [sel_c + 1, es.size()], 7, DIM, true)
	_frame(Rect2(204, 238, 396, 62), 0.8)
	if not es.is_empty():
		var e2: Dictionary = es[sel_c]
		match e2.kind:
			"gear":
				var it2: Dictionary = Gear.ITEMS[e2.id]
				var cur: Dictionary = Gear.ITEMS[Gear.equipped(hero, e2.slot)]
				_txt(Vector2(212, 252), String(it2.desc), 8, DIM)
				var x := 212.0
				for k in [["atk", "ATK"], ["def", "DEF"], ["hp", "HP"]]:
					var dv: int = int(it2[k[0]]) - int(cur[k[0]])
					_txt(Vector2(x, 270), "%s %d%s" % [k[1], int(it2[k[0]]), (" (%+d)" % dv) if dv != 0 else ""], 9, GOOD if dv > 0 else (BAD if dv < 0 else Color.WHITE))
					x += 80.0
				_txt(Vector2(212, 286), "E equip", 8, DIM)
			"supply":
				_txt(Vector2(212, 252), String(Gear.SUPPLIES[e2.id].desc), 9, DIM)
				_txt(Vector2(212, 272), "E use now, or press the number key in the field.", 8, DIM)
			"relic":
				_txt(Vector2(212, 252), "A keepsake gathered on the road.", 9, DIM)
	_txt(Vector2(52, 316), msg, 10, Color("ffd9a0"))
	_txt(Vector2(46, 334), "Party: Melee +%d   Guard %d   Max HP %d" % [Gear.atk_bonus(), Gear.def_total(), GameState.max_hp], 9, Color("b8b0c8"))
	_txt(Vector2(594, 334), "A/D hero   W/S choose   Q section   E select   Tab/Esc close", 8, DIM, true)


func _role(hero: String) -> String:
	match hero:
		"mu":
			return "Lead. Gear counts in full."
		"isolde":
			return "Shield and might."
		"wren":
			return "Speed and +25% gold."
		_:
			return "Vitality aid."
