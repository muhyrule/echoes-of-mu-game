extends Control
## Shop, inn and pub screen. Drawn in 640x360 logical units at 3x scale.

const Art = preload("res://src/core/art.gd")

signal closed

const GOLD := Color("d9b45a")
const GOLD_D := Color("7a5a24")
const DIM := Color("987a7d")
const GOOD := Color("8adf8a")
const BAD := Color("e07a7a")

var kind := "items"
var tier := 2
var level: Node
var font: Font
var sel := 0
var tab := 0
var heroes: Array = []
var entries: Array = []
var msg := ""
var warm := 3
var t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	heroes = Gear.active_heroes()
	_rebuild()
	Audio.sfx("door")


func _title() -> String:
	return {"items": "Apothecary Wares", "weapons": "Weaponsmith", "armor": "Armoury", "inn": "The Inn", "pub": "The Taproom"}.get(kind, "Shop")


func _rebuild() -> void:
	entries = []
	match kind:
		"items":
			for id in Gear.SUPPLIES:
				var d: Dictionary = Gear.SUPPLIES[id]
				entries.append({"id": id, "name": d.name, "price": d.price, "desc": d.desc + "  [" + d.key + "]", "have": int(GameState.supplies.get(id, 0))})
		"weapons", "armor":
			var slot := "weapon" if kind == "weapons" else "armor"
			for id in Gear.stock(heroes[tab], slot, tier):
				entries.append({"id": id, "name": Gear.ITEMS[id].name, "price": Gear.ITEMS[id].price, "desc": Gear.ITEMS[id].desc})
		"inn":
			for d in Gear.INN_MENU:
				entries.append(d)
		"pub":
			for d in Gear.PUB_MENU:
				entries.append(d)
	sel = clampi(sel, 0, maxi(0, entries.size() - 1))


func _process(delta: float) -> void:
	t += delta
	if warm > 0:
		warm -= 1
		queue_redraw()
		return
	var moved := false
	if Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % maxi(1, entries.size())
		moved = true
	elif Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + entries.size()) % maxi(1, entries.size())
		moved = true
	if kind in ["weapons", "armor"]:
		if Input.is_action_just_pressed("move_right"):
			tab = (tab + 1) % heroes.size()
			sel = 0
			moved = true
			_rebuild()
		elif Input.is_action_just_pressed("move_left"):
			tab = (tab - 1 + heroes.size()) % heroes.size()
			sel = 0
			moved = true
			_rebuild()
	if moved:
		Audio.sfx("switch")
		msg = ""
	if Input.is_action_just_pressed("interact") and not entries.is_empty():
		_buy(entries[sel])
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("form"):
		closed.emit()
		set_process(false)
	queue_redraw()


func _buy(e: Dictionary) -> void:
	match kind:
		"items":
			if GameState.gold < e.price:
				msg = "Not enough gold."
				return
			GameState.gold -= e.price
			GameState.supplies[e.id] = int(GameState.supplies.get(e.id, 0)) + 1
			msg = "Bought %s." % e.name
			Audio.sfx("switch")
		"weapons", "armor":
			var hero: String = heroes[tab]
			var slot: String = Gear.ITEMS[e.id].slot
			if Gear.equipped(hero, slot) == e.id:
				msg = "Already equipped."
				return
			if e.id not in GameState.owned:
				if GameState.gold < e.price:
					msg = "Not enough gold."
					return
				GameState.gold -= e.price
				GameState.owned.append(e.id)
				msg = "Bought and equipped %s." % e.name
			else:
				msg = "Equipped %s." % e.name
			if not GameState.equip.has(hero):
				GameState.equip[hero] = {}
			GameState.equip[hero][slot] = e.id
			GameState.refresh_stats()
			Audio.sfx("form")
		"inn", "pub":
			if GameState.gold < e.price:
				msg = "Not enough gold."
				return
			if GameState.hp >= GameState.max_hp:
				msg = "You are in good health already."
				return
			GameState.gold -= e.price
			GameState.hp = mini(GameState.max_hp, GameState.hp + e.heal)
			if e.id == "rest":
				GameState.hp = GameState.max_hp
				GameState.save_game()
				msg = "You sleep soundly. Progress saved."
			else:
				msg = "You feel better."
			Audio.sfx("heal")


func _txt(pos: Vector2, s: String, size: int, col: Color, right := false) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	size *= 3
	var p := pos * 3.0
	if right:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))


func _frame(r: Rect2) -> void:
	draw_rect(r.grow(1.5), Color(Art.OUT))
	draw_rect(r, Color(0.05, 0.04, 0.09, 0.94))
	draw_rect(r.grow(-1.0), Color(0.12, 0.09, 0.2, 0.6), false, 1.0)
	draw_rect(r, GOLD_D, false, 1.4)
	draw_rect(r.grow(-1.5), GOLD, false, 0.7)


func _delta_txt(label: String, v: int) -> String:
	return "%s %s%d" % [label, "+" if v > 0 else "", v]


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
	_frame(Rect2(40, 24, 560, 312))
	_txt(Vector2(60, 46), _title(), 14, GOLD)
	_txt(Vector2(580, 46), "Gold %d" % GameState.gold, 12, Color("f0d070"), true)
	var top := 62.0
	if kind in ["weapons", "armor"]:
		for i in heroes.size():
			var r := Rect2(60 + i * 96, 54, 90, 16)
			draw_rect(r, Color("323b52") if i == tab else Color("1a1426"))
			draw_rect(r, GOLD if i == tab else GOLD_D, false, 0.8)
			var cls: String = Gear.WEAPON_CLASS[heroes[i]] if kind == "weapons" else Gear.ARMOR_CLASS[heroes[i]]
			_txt(Vector2(66 + i * 96, 66), "%s: %s" % [Gear.HERO_NAMES[heroes[i]], cls], 8, Color.WHITE if i == tab else DIM)
		top = 80.0
	var shown := mini(entries.size(), 9)
	for i in shown:
		var e: Dictionary = entries[i]
		var y := top + i * 24.0
		var r2 := Rect2(60, y, 270, 21)
		if i == sel:
			draw_rect(r2, Color("2a3248"))
			draw_rect(r2, GOLD, false, 0.8)
			_txt(Vector2(64, y + 14), ">", 10, GOLD)
		var col := Color.WHITE
		var tag := "%dg" % int(e.price)
		if kind in ["weapons", "armor"]:
			var hero: String = heroes[tab]
			var slot: String = Gear.ITEMS[e.id].slot
			if Gear.equipped(hero, slot) == e.id:
				tag = "Equipped"
				col = GOOD
			elif e.id in GameState.owned:
				tag = "Owned"
				col = Color("b8c8ff")
		elif kind == "items":
			tag = "%dg   (have %d)" % [int(e.price), int(e.have if e.has("have") else 0)]
		if kind in ["items"]:
			e.have = int(GameState.supplies.get(e.id, 0))
		_txt(Vector2(74, y + 14), String(e.name), 10, col)
		_txt(Vector2(322, y + 14), tag, 9, GOLD, true)
	if entries.is_empty():
		_txt(Vector2(70, top + 20), "Nothing in stock for you today.", 10, DIM)
	_frame(Rect2(344, top, 236, 150))
	if not entries.is_empty():
		var e2: Dictionary = entries[sel]
		_txt(Vector2(354, top + 16), String(e2.name), 10, Color("fff0b0"))
		_wrap(String(e2.desc), Vector2(354, top + 32), 34, 9, DIM)
		if kind in ["weapons", "armor"]:
			var it: Dictionary = Gear.ITEMS[e2.id]
			var cur: Dictionary = Gear.ITEMS[Gear.equipped(heroes[tab], it.slot)]
			var y2 := top + 70.0
			for k in [["atk", "Attack"], ["def", "Defence"], ["hp", "Vitality"]]:
				var dv: int = int(it[k[0]]) - int(cur[k[0]])
				var c: Color = GOOD if dv > 0 else (BAD if dv < 0 else DIM)
				_txt(Vector2(354, y2), "%s  %d" % [k[1], int(it[k[0]])], 10, Color.WHITE)
				_txt(Vector2(570, y2), ("(%+d)" % dv) if dv != 0 else "(=)", 10, c, true)
				y2 += 16.0
			_txt(Vector2(354, y2 + 4), "Aids the party: " + _aid(heroes[tab], it.slot), 8, DIM)
	_txt(Vector2(60, 316), msg, 10, Color("ffd9a0"))
	var hint := "Up/Down choose   E buy" + ("   Left/Right hero" if kind in ["weapons", "armor"] else "") + "   Esc leave"
	_txt(Vector2(580, 328), hint, 8, DIM, true)


func _aid(hero: String, slot: String) -> String:
	match hero:
		"mu":
			return "full effect"
		"isolde":
			return "shield and mightier blows" if slot == "weapon" else "extra defence"
		"wren":
			return "faster strikes, +25% gold" if slot == "weapon" else "quicker recovery"
		_:
			return "ticking power" if slot == "weapon" else "extra vitality"


func _wrap(s: String, pos: Vector2, width: int, size: int, col: Color) -> void:
	var line := ""
	var y := pos.y
	for word in s.split(" "):
		if line.length() + word.length() + 1 > width:
			_txt(Vector2(pos.x, y), line, size, col)
			y += 12.0
			line = ""
		line += ("" if line == "" else " ") + word
	if line != "":
		_txt(Vector2(pos.x, y), line, size, col)
