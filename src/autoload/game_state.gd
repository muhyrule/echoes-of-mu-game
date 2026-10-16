extends Node
## Global game state: progress flags, player stats, party, save/load, input map.

const SAVE_PATH := "user://echoes_of_mu_save.json"
const LEVEL_SCENE := "res://src/scenes/world/Level.tscn"

var flags: Dictionary = {}
var max_hp := 6
var hp := 6
var keys := 0
var forms: Array = ["mu"]
var form := "mu"
var party: Array = []
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
		"reset_puzzle": [KEY_R],
		"pause": [KEY_ESCAPE],
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
	max_hp = 6
	hp = 6
	keys = 0
	forms = ["mu"]
	form = "mu"
	party = []
	current_map = "chapel"
	spawn = "start"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"flags": flags, "max_hp": max_hp, "hp": hp, "keys": keys,
		"forms": forms, "form": form, "party": party,
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
	max_hp = int(data.get("max_hp", 6))
	hp = max_hp
	keys = int(data.get("keys", 0))
	forms = data.get("forms", ["mu"])
	form = data.get("form", "mu")
	party = data.get("party", [])
	current_map = data.get("map", "chapel")
	spawn = data.get("spawn", "start")
	return true


func change_map(map_name: String, spawn_name := "start") -> void:
	current_map = map_name
	spawn = spawn_name
	save_game()
	get_tree().change_scene_to_file(LEVEL_SCENE)
