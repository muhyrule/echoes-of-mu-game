extends Control
## HUD: hearts, keys, form, location banner, interaction hint, fades, pause, death.

const Art = preload("res://src/core/art.gd")

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
	draw_rect(r.grow(1.5), Color(Art.OUT))
	draw_rect(r, Color(0.05, 0.04, 0.09, 0.82))
	draw_rect(r.grow(-1.0), Color(0.12, 0.09, 0.2, 0.6), false, 1.0)
	draw_rect(r, GOLD_D, false, 1.4)
	draw_rect(r.grow(-1.5), GOLD, false, 0.7)
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var dx := -1.0 if corner.x > r.get_center().x else 1.0
		var dy := -1.0 if corner.y > r.get_center().y else 1.0
		draw_arc(corner + Vector2(dx * 4.0, dy * 4.0), 3.4, 0.0, TAU, 10, GOLD, 0.9)
		draw_circle(corner + Vector2(dx * 4.0, dy * 4.0), 1.1, GOLD_L)
		draw_line(corner + Vector2(dx * 7.5, dy * 4.0), corner + Vector2(dx * 16.0, dy * 4.0), GOLD, 0.7)


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
	_txt(Vector2(12, 46), "Key x%d" % GameState.keys, 12, Color("e6c15a"))
	var lead: String = GameState.lead
	var lead_cols := {"mu": Color("ffb7bd"), "isolde": Color("ffd890"), "wren": Color("e88d95"), "corvin": Color("e0b860")}
	if GameState.party.is_empty():
		var fname: String = {"wraith": "Wraith", "gargoyle": "Gargoyle"}.get(GameState.form, "Mu")
		var hint_q := "  [Q]" if GameState.forms.size() > 1 else ""
		_txt(Vector2(12, 62), "Form: %s%s" % [fname, hint_q], 12, {"wraith": Color("9fd0ff"), "gargoyle": Color("c2cad8")}.get(GameState.form, Color("ffb7bd")))
	else:
		var fm := ""
		if lead == "mu":
			fm = " (%s) [Q]" % str({"wraith": "Wraith", "gargoyle": "Gargoyle"}.get(GameState.form, "Mu")) if GameState.forms.size() > 1 else ""
		_txt(Vector2(12, 62), "Hero: %s%s  [C] swap" % [lead.capitalize(), fm], 12, lead_cols.get(lead, Color.WHITE))
	_txt(Vector2(12, 78), "Gold %d" % GameState.gold, 12, Color("f0d070"))
	var pl: Node2D = level.player
	var gname: String = pl.GUARD_NAME.get(lead, "Guard")
	_txt(Vector2(12, 108), "[Shift] Roll %s   [V] %s" % ["" if pl.roll_cd <= 0.0 else "%.1fs" % pl.roll_cd, gname], 9, Color("d0a2a7"))
	var sk_y := 128
	for fid in ["mu", "isolde", "wren", "corvin"]:
		var fo: Node2D = null
		if fid == lead:
			fo = level.player.brain if fid != "mu" else null
		elif level.followers.has(fid) and is_instance_valid(level.followers[fid]):
			fo = level.followers[fid]
		if fo != null:
			var kk: int = fo.KIT[fid].key
			var rdy: bool = fo.skill_cd <= 0.0
			var mark := "> " if fid == lead else "  "
			var lab := "%s%s [%s] %s %s" % [mark, fid.capitalize(), OS.get_keycode_string(kk), fo.KIT[fid].skill, "READY" if rdy else "%ds" % ceili(fo.skill_cd)]
			_txt(Vector2(12, sk_y), lab, 9, (Color("f0d070") if rdy else Color("8c6b6e")) if fid != lead else (Color("fff0a0") if rdy else Color("c88e93")))
			sk_y += 16
	if level.weather != null:
		_txt(Vector2(12, sk_y), "Weather: %s" % level.weather.label(), 9, Color("a8c0e0"))
	_txt(Vector2(12, 94), "[1] Tonic %d  [2] Elixir %d  [3] Candle %d" % [int(GameState.supplies.get("tonic", 0)), int(GameState.supplies.get("elixir", 0)), int(GameState.supplies.get("candle", 0))], 9, Color("b8b0c8"))
	if banner_t > 0.0:
		var a := minf(1.0, banner_t)
		_txt(Vector2(320, 120), banner_title, 22, Color(0.95, 0.88, 1.0, a), true)
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
