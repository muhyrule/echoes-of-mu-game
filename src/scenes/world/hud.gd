extends Control
## HUD: hearts, keys, form, location banner, interaction hint, fades, pause, death.

const Art = preload("res://src/core/art.gd")
const UI = preload("res://src/core/pixel_ui.gd")
const DOCK_TOP := 306.0
const DOCK_HEIGHT := 46.0
const BOTTOM_SAFE := (360.0 - DOCK_TOP) * 3.0

var level: Node2D
var title_t := 3.0
var banner_title := ""
var banner_sub := ""
var banner_t := 0.0
var hint := ""
var notice := ""
var notice_t := 0.0
var fade := 0.0
var paused := false
var death_text := false
var font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func show_banner(title: String, sub: String) -> void:
	banner_title = title
	banner_sub = sub
	banner_t = 4.0


func show_notice(text: String) -> void:
	notice = text
	notice_t = 3.0


func fade_to(a: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "fade", a, secs)
	await tw.finished


func _process(delta: float) -> void:
	banner_t = maxf(0.0, banner_t - delta)
	title_t = maxf(0.0, title_t - delta)
	notice_t = maxf(0.0, notice_t - delta)
	if Input.is_action_just_pressed("pause") and not Dialogue.blocking() and not level.frozen:
		paused = not paused
		get_tree().paused = paused
	if paused and Input.is_action_just_pressed("form"):
		get_tree().paused = false
		GameState.save_game()
		get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
	queue_redraw()


func _txt(pos: Vector2, s: String, size: int, col: Color, center := false) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	size *= 3
	var p := pos * 3.0
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	draw_string(font, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))


const GOLD := Color("d9b45a")
const GOLD_D := Color("7a5a24")
const GOLD_L := Color("fff0b0")


func _frame(r: Rect2) -> void:
	UI.panel(self, r, 0.92)


func _orb(pos: Vector2, filled: bool, col: Color) -> void:
	draw_circle(pos, 5.0, Color(Art.OUT))
	draw_circle(pos, 4.2, col if filled else Color("262a34"))
	if filled:
		draw_circle(pos + Vector2(0.6, 0.8), 3.0, col.darkened(0.25))
		draw_circle(pos + Vector2(-0.4, -0.4), 2.4, col.lightened(0.1))
		draw_circle(pos + Vector2(-1.3, -1.5), 1.0, Color(1, 1, 1, 0.8))
	else:
		draw_arc(pos, 3.4, 0.0, TAU, 10, Color("404758"), 0.6)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	var pw := maxf(60.0, GameState.max_hp * 12.0 + 22.0)
	_frame(Rect2(8, 8, pw, 24))
	_txt(Vector2(20, 17), "VITALITY", 6, GOLD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
	for i in GameState.max_hp:
		_orb(Vector2(19 + i * 12, 25), i < GameState.hp, Color("c0334f"))
	var boss: Node = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_boss and e.state != "dormant":
			boss = e
	if boss == null:
		title_t = 3.0
	if boss != null:
		var bx := 640.0 - 128.0
		_frame(Rect2(bx, 8, 120, 24))
		if title_t > 0.0:
			_txt(Vector2(bx + 12, 17), str(boss.get("title") if boss.get("title") != null else "FOE"), 6, GOLD)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(3, 3))
		var segs := 16
		var fill := int(ceil(float(boss.hp) / float(boss.max_hp) * segs))
		for i in segs:
			var r := Rect2(bx + 8 + i * 6.6, 20, 5.6, 8)
			draw_rect(r.grow(0.8), Color(Art.OUT))
			draw_rect(r, Color("a8283c") if i < fill else Color("262a34"))
			if i < fill:
				draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color("e0687a"))
	_frame(Rect2(pw + 16, 8, 138, 24))
	_txt(Vector2(pw + 25, 24), "KEYS %d" % GameState.keys, 9, UI.PAPER)
	_txt(Vector2(pw + 81, 24), "%d G" % GameState.gold, 9, GOLD)
	_frame(Rect2(8, DOCK_TOP, 624, DOCK_HEIGHT))
	var lead: String = GameState.lead
	var lead_cols := {"mu": Color("cb6264"), "isolde": Color("aabd7e"), "wren": Color("74b3b4"), "corvin": Color("d2b274")}
	UI.crest(self, Vector2(27, 327), lead, lead_cols.get(lead, GOLD))
	if GameState.party.is_empty():
		var fname: String = {"wraith": "Wraith", "gargoyle": "Gargoyle"}.get(GameState.form, "Mu")
		var hint_q := "  [Q]" if GameState.forms.size() > 1 else ""
		_txt(Vector2(44, 325), "%s%s" % [fname, hint_q], 11, UI.PAPER)
	else:
		var fm := ""
		if lead == "mu":
			fm = " (%s) [Q]" % str({"wraith": "Wraith", "gargoyle": "Gargoyle"}.get(GameState.form, "Mu")) if GameState.forms.size() > 1 else ""
		_txt(Vector2(44, 325), "%s%s" % [lead.capitalize(), fm], 10, UI.PAPER)
	_txt(Vector2(44, 340), "[C] Hero   [Tab] Inventory", 7, GOLD)
	var pl: Node2D = level.player
	var gname: String = pl.GUARD_NAME.get(lead, "Guard")
	_txt(Vector2(183, 340), "[Shift] Roll %s   [V] %s" % ["" if pl.roll_cd <= 0.0 else "%.1fs" % pl.roll_cd, gname], 8, UI.PAPER)
	var sk_i := 0
	for fid in ["mu", "isolde", "wren", "corvin"]:
		var fo: Node2D = null
		if fid == lead:
			fo = level.player.brain if fid != "mu" else null
		elif level.followers.has(fid) and is_instance_valid(level.followers[fid]):
			fo = level.followers[fid]
		if fo != null:
			var kk: int = fo.KIT[fid].key
			var rdy: bool = fo.skill_cd <= 0.0
			var pos := Vector2(418 + (sk_i % 2) * 108, 318 + (sk_i / 2) * 18)
			_txt(pos, "%s [%s] %s" % [fid.capitalize(), OS.get_keycode_string(kk), "READY" if rdy else "%ds" % ceili(fo.skill_cd)], 7, lead_cols[fid] if rdy else Color("858b92"))
			_txt(pos + Vector2(0, 8), fo.KIT[fid].skill, 6, UI.PAPER)
			sk_i += 1
	if level.weather != null:
		_txt(Vector2(320, 22), level.weather.label(), 8, Color("a8c0d0"), true)
	_txt(Vector2(183, 324), "[1] Tonic %d  [2] Elixir %d  [3] Candle %d" % [int(GameState.supplies.get("tonic", 0)), int(GameState.supplies.get("elixir", 0)), int(GameState.supplies.get("candle", 0))], 8, UI.PAPER)
	if banner_t > 0.0:
		var a := minf(1.0, banner_t)
		_txt(Vector2(320, 120), banner_title, 22, Color(UI.PAPER, a), true)
		_txt(Vector2(320, 144), banner_sub, 13, Color(0.85, 0.64, 0.66, a), true)
	if hint != "" and not Dialogue.blocking():
		_txt(Vector2(320, 238), hint, 13, Color(1, 0.95, 0.7), true)
	if notice_t > 0.0:
		_txt(Vector2(320, 90), notice, 14, Color(0.7, 1.0, 0.85, minf(1.0, notice_t)), true)
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size / 3.0), Color(0, 0, 0, fade))
		if death_text:
			_txt(Vector2(320, 180), "The echoes fade...", 22, Color(0.90, 0.64, 0.66, fade), true)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, size / 3.0), Color(0, 0, 0, 0.6))
		_txt(Vector2(320, 150), "PAUSED", 24, Color.WHITE, true)
		_txt(Vector2(320, 185), "Esc — resume     Q — save & quit to menu", 13, Color(0.8, 0.8, 0.9), true)
		_txt(Vector2(320, 215), "WASD/Arrows move · Space attack · E interact · Q form · R reset puzzle · Tab party/inventory", 11, Color(0.65, 0.65, 0.8), true)
