extends Node
## Global game state: progress flags, player stats, party, save/load, input map.

const SAVE_PATH := "user://echoes_of_mu_save.json"
const LEVEL_SCENE := "res://src/scenes/world/Level.tscn"

var flags: Dictionary = {}
var max_hp := 6
var base_hp := 6
var gold := 0
var weather := ""
var supplies: Dictionary = {}
var owned: Array = []
var equip: Dictionary = {}
var hp := 6
var keys := 0
var forms: Array = ["mu"]
var form := "mu"
var lead := "mu"
var party: Array = []
var items: Array = []
var current_map := "chapel"
var spawn := "start"


func _ready() -> void:
	_setup_input()


func _setup_input() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_SPACE, KEY_J],
		"interact": [KEY_E, KEY_ENTER],
		"form": [KEY_Q, KEY_K],
		"swap": [KEY_C, KEY_L],
		"reset_puzzle": [KEY_R],
		"pause": [KEY_ESCAPE],
		"status": [KEY_TAB, KEY_I],
		"use_tonic": [KEY_1],
		"use_elixir": [KEY_2],
		"use_candle": [KEY_3],
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in binds[action]:
			var ev := InputEventKey.new()
			ev.keycode = code
			InputMap.action_add_event(action, ev)


func flag(name: String) -> bool:
	return flags.get(name, false)


func set_flag(name: String, value := true) -> void:
	flags[name] = value


func new_game() -> void:
	flags = {}
	base_hp = 6
	gold = 40
	supplies = {"tonic": 1}
	owned = []
	equip = {}
	refresh_stats()
	hp = max_hp
	keys = 0
	forms = ["mu"]
	form = "mu"
	party = []
	lead = "mu"
	items = []
	current_map = "chapel"
	spawn = "start"


func refresh_stats() -> void:
	max_hp = base_hp + Gear.hp_bonus()
	hp = mini(hp, max_hp)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"flags": flags, "max_hp": max_hp, "base_hp": base_hp, "gold": gold,
		"supplies": supplies, "owned": owned, "equip": equip, "hp": hp, "keys": keys,
		"forms": forms, "form": form, "party": party, "items": items,
		"map": current_map, "spawn": spawn,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	flags = data.get("flags", {})
	base_hp = int(data.get("base_hp", data.get("max_hp", 6)))
	gold = int(data.get("gold", 0))
	supplies = data.get("supplies", {})
	owned = data.get("owned", [])
	equip = data.get("equip", {})
	keys = int(data.get("keys", 0))
	forms = data.get("forms", ["mu"])
	form = data.get("form", "mu")
	party = data.get("party", [])
	items = data.get("items", [])
	current_map = data.get("map", "chapel")
	spawn = data.get("spawn", "start")
	refresh_stats()
	hp = max_hp
	return true


func change_map(map_name: String, spawn_name := "start") -> void:
	current_map = map_name
	spawn = spawn_name
	save_game()
	get_tree().change_scene_to_file(LEVEL_SCENE)
