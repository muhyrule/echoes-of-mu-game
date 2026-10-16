extends Node2D
## A map object: door, gate, bars, block, plate, key, heart, shrine, npc, portal, torch, etc.

const Art = preload("res://src/core/art.gd")

var kind := ""
var cell := Vector2i.ZERO
var id := ""
var solid := false
var body: StaticBody2D
var level: Node2D
var moving := false
var open := false
var t := randf() * 10.0
var home_cell := Vector2i.ZERO
var wait := 2.0
var light: PointLight2D
var base_energy := 1.0
var pal: Dictionary = {}
var def: Dictionary = {}
var lit := false

const SEALS := ["seal_bell", "seal_dagger", "seal_bolt"]
const OBJECT_KINDS := ["barrel", "chest", "crate", "urn", "tomes", "grave", "statue"]


func setup(k: String, c: Vector2i, lvl: Node2D, npc_id := "") -> void:
	kind = k
	cell = c
	home_cell = c
	level = lvl
	id = npc_id
	position = Vector2(c) * 16.0 + Vector2(8, 8)
	solid = kind in ["door", "gate", "bars", "block", "npc", "shrine", "table", "cracked"] or kind in OBJECT_KINDS or kind in SEALS
	if solid:
		body = StaticBody2D.new()
		body.collision_layer = 2 if kind == "bars" else 1
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, 16) if kind != "npc" else Vector2(10, 10)
		s.shape = r
		body.add_child(s)
		add_child(body)
		level.occupied[cell] = self
	_add_light()


func _add_light() -> void:
	match kind:
		"candle":
			light = Art.make_light(Color("ffb050"), 0.55, 0.9)
			light.position = Vector2(0, -4)
		"torch":
			light = Art.make_light(Color("ff9438"), 1.1, 1.05)
			light.position = Vector2(0, -6)
		"shrine":
			light = Art.make_light(Color("6fc8ff"), 0.9, 0.9)
		"portal", "final":
			light = Art.make_light(Color("b894ff"), 1.0, 1.0)
		"key":
			light = Art.make_light(Color("ffe08a"), 0.35, 0.8)
		"plate":
			light = Art.make_light(Color("66e0ff"), 0.45, 0.0)
		"gear":
			light = null
		"lamp":
			light = Art.make_light(Color("ffb35a"), 1.3, 1.0)
			light.position = Vector2(0, -8)
		"table":
			light = Art.make_light(Color("ffcf80"), 0.5, 0.5)
	if light:
		base_energy = light.energy
		add_child(light)


func is_interactable() -> bool:
	if kind == "door":
		return not open
	return kind in ["npc", "shrine", "table", "portal", "entry"] or kind in OBJECT_KINDS or kind in SEALS


func is_pickup() -> bool:
	return kind in ["key", "heart"]


func push(dir: Vector2) -> void:
	if kind != "block" or moving:
		return
	var target := cell + Vector2i(dir)
	if not level.cell_free(target):
		return
	moving = true
	level.occupied.erase(cell)
	cell = target
	level.occupied[cell] = self
	Audio.sfx("push")
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(cell) * 16.0 + Vector2(8, 8), 0.18)
	tw.tween_callback(func():
		moving = false
		level.check_plate())


func unlock() -> void:
	open = true
	if body:
		body.collision_layer = 0
		level.occupied.erase(cell)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _wander(delta: float) -> void:
	if level._busy or level.frozen_for_dialogue():
		return
	wait -= delta
	if wait > 0.0 or moving:
		return
	wait = randf_range(1.5, 4.5)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var d: Vector2i = dirs[randi() % 4]
	var tc := cell + d
	var r: int = def.get("wander", 3)
	if absi(tc.x - home_cell.x) > r or absi(tc.y - home_cell.y) > r or not level.cell_free(tc):
		return
	if level.player.position.distance_to(level._cell_center(tc)) < 14.0:
		return
	level.occupied.erase(cell)
	cell = tc
	level.occupied[cell] = self
	moving = true
	def["face"] = [d.x, d.y]
	var tw := create_tween()
	tw.tween_property(self, "position", level._cell_center(tc), 0.55)
	tw.tween_callback(func(): moving = false)


func _process(delta: float) -> void:
	t += delta
	if kind == "npc" and def.has("wander"):
		_wander(delta)
	if light:
		match kind:
			"candle", "torch", "lamp":
				light.energy = base_energy * (0.85 + 0.15 * sin(t * 13.0 + position.x) + 0.05 * sin(t * 31.0))
			"plate":
				light.energy = 0.8 if level.flags_plate else 0.0
			_:
				light.energy = base_energy * (0.85 + 0.15 * sin(t * 3.0))
	queue_redraw()


func _draw() -> void:
	match kind:
		"door":
			draw_rect(Rect2(-8, -8, 16, 16), Color(Art.OUT))
			draw_rect(Rect2(-7.2, -7.2, 14.4, 14.4), Color("5a3a24"))
			for x in [-4.8, -1.6, 1.6, 4.8]:
				draw_line(Vector2(x, -7.2), Vector2(x, 7.2), Color("3a2415"), 0.5)
			draw_rect(Rect2(-7.2, -7.2, 14.4, 1.2), Color("7a5236"))
			for y in [-4.5, 4.0]:
				draw_rect(Rect2(-7.2, y - 1.1, 14.4, 2.2), Color("4a4d58"))
				draw_rect(Rect2(-7.2, y - 1.1, 14.4, 0.7), Color("7a7f8e"))
				for x in [-5.5, 5.5]:
					draw_circle(Vector2(x, y), 0.55, Color("c0c4d0"))
			draw_circle(Vector2(0, 0), 2.4, Color(Art.OUT))
			draw_circle(Vector2(0, 0), 1.8, Color("d6b25a"))
			draw_rect(Rect2(-0.35, -0.2, 0.7, 1.6), Color(Art.OUT))
		"gate", "bars":
			draw_rect(Rect2(-8, -8, 16, 16), Color("0c0a12"))
			var bc := Color("9aa0ae") if kind == "bars" else Color("8a8f9c")
			for x in [-6.0, -2.0, 2.0, 6.0]:
				draw_rect(Rect2(x - 1.0, -8, 2.0, 16), Color(Art.OUT))
				draw_rect(Rect2(x - 0.6, -8, 1.2, 16), bc)
				draw_rect(Rect2(x - 0.6, -8, 0.5, 16), Color(1, 1, 1, 0.25))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 0.9, -7.5), Vector2(x + 0.9, -7.5), Vector2(x, -9.0)]), bc)
			for y in [-4.0, 4.0]:
				draw_rect(Rect2(-8, y - 0.9, 16, 1.8), Color(Art.OUT))
				draw_rect(Rect2(-8, y - 0.5, 16, 1.0), Color("5f6370"))
		"block":
			var wob: float = 0.0
			draw_rect(Rect2(-7.6, -7.0, 15.2, 15.0), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(-7.4, -7.4 + wob, 14.8, 14.8), Color(Art.OUT))
			draw_rect(Rect2(-6.6, -6.6, 13.2, 13.2), Color("767287"))
			draw_rect(Rect2(-6.6, -6.6, 13.2, 2.0), Color("a29db6"))
			draw_rect(Rect2(-6.6, -6.6, 2.0, 13.2), Color("918ca6"))
			draw_rect(Rect2(-6.6, 4.6, 13.2, 2.0), Color("4a4659"))
			draw_rect(Rect2(4.6, -6.6, 2.0, 13.2), Color("55516a"))
			draw_rect(Rect2(-4.4, -4.4, 8.8, 8.8), Color("625e75"))
			var rune := Color(0.5, 0.85, 1.0, 0.55 + 0.25 * sin(t * 2.5))
			draw_line(Vector2(-2, 2), Vector2(0, -2.5), rune, 0.7)
			draw_line(Vector2(0, -2.5), Vector2(2, 2), rune, 0.7)
			draw_line(Vector2(-1.2, 0.2), Vector2(1.2, 0.2), rune, 0.7)
		"plate":
			draw_rect(Rect2(-7, -7, 14, 14), Color(Art.OUT))
			draw_rect(Rect2(-6.3, -6.3, 12.6, 12.6), Color("423d52"))
			draw_rect(Rect2(-4.8, -4.8, 9.6, 9.6), Color("2a2636"))
			var lit: bool = level.flags_plate
			var col := Color("66e0ff") if lit else Color("8a5aa0")
			draw_arc(Vector2.ZERO, 3.2, 0.0, TAU, 20, col, 0.9)
			draw_circle(Vector2.ZERO, 1.2, col)
		"key":
			var bob := sin(t * 4.0) * 1.5
			draw_circle(Vector2(0, 5), 4.0, Color(0, 0, 0, 0.2))
			draw_circle(Vector2(-3.4, bob), 3.8, Color(Art.OUT))
			draw_circle(Vector2(-3.4, bob), 3.0, Color("f0cc66"))
			draw_circle(Vector2(-3.4, bob), 1.3, Color(Art.OUT))
			draw_rect(Rect2(-1, bob - 1.4, 9.2, 2.8), Color(Art.OUT))
			draw_rect(Rect2(-0.4, bob - 0.8, 8.0, 1.6), Color("f0cc66"))
			draw_rect(Rect2(5.0, bob, 2.4, 4.4), Color(Art.OUT))
			draw_rect(Rect2(5.5, bob + 0.5, 1.4, 3.4), Color("f0cc66"))
			var sp := 0.5 + 0.5 * sin(t * 6.0)
			draw_line(Vector2(3, bob - 5), Vector2(3, bob - 5 - 2 * sp), Color(1, 1, 0.8, sp), 0.6)
		"heart":
			Art.heart(self, Vector2(0, -2 + sin(t * 5.0)), 4.0, Color("e0485f"))
			draw_circle(Vector2(0, 6), 3.0, Color(0, 0, 0, 0.2))
		"shrine":
			draw_rect(Rect2(-8, -8, 16, 16), Color("26222e"))
			draw_circle(Vector2(0, 5), 7.0, Color(0.3, 0.5, 0.8, 0.12))
			draw_arc(Vector2(0, 5), 6.5, 0.0, TAU, 24, Color(0.4, 0.8, 1.0, 0.5 + 0.3 * sin(t * 2.0)), 0.6)
			draw_rect(Rect2(-6, 3, 12, 5), Color(Art.OUT))
			draw_rect(Rect2(-5.2, 3.6, 10.4, 3.8), Color("6a6478"))
			var bell := PackedVector2Array([Vector2(-5, 3), Vector2(5, 3), Vector2(4.0, -3), Vector2(2.5, -6.5), Vector2(0, -8), Vector2(-2.5, -6.5), Vector2(-4.0, -3)])
			draw_colored_polygon(bell, Color(Art.OUT))
			var inner := PackedVector2Array([Vector2(-4.2, 2.4), Vector2(4.2, 2.4), Vector2(3.3, -3), Vector2(2.0, -6), Vector2(0, -7.2), Vector2(-2.0, -6), Vector2(-3.3, -3)])
			draw_colored_polygon(inner, Color("8fa8d0"))
			draw_colored_polygon(PackedVector2Array([Vector2(-3.4, 2.0), Vector2(-2.2, 2.0), Vector2(-1.8, -5.5), Vector2(-2.6, -4)]), Color(1, 1, 1, 0.35))
			draw_line(Vector2(1, -6), Vector2(2.5, 1), Color(Art.OUT), 0.7)
			draw_circle(Vector2(0, 3.5), 1.2, Color(Art.OUT))
		"exit":
			draw_rect(Rect2(-8, -8, 16, 16), Color("1b1822"))
			draw_rect(Rect2(-6, -8, 12, 16), Color(Art.OUT))
			draw_arc(Vector2(0, -2), 6.0, PI, TAU, 12, Color("6a6a78"), 1.5)
			for i in 4:
				draw_rect(Rect2(-5 + i * 0.5, 0 + i * 2, 10 - i, 1.6), Color(0.2, 0.18, 0.26).lightened(i * 0.05))
		"portal", "final":
			var rr := 8.0 if kind == "portal" else 11.0
			if kind == "portal":
				draw_rect(Rect2(-8, -8, 16, 16), Color("1b1822"))
			for i in 5:
				var k := float(i) / 5.0
				var ang := t * (1.5 + k) + i
				draw_arc(Vector2.ZERO, rr * (1.0 - k * 0.7), ang, ang + 3.4, 14, Color(0.7 + k * 0.3, 0.55 + k * 0.4, 1.0, 0.5 + k * 0.4), 1.2)
			draw_circle(Vector2.ZERO, rr * 0.25, Color(1, 1, 1, 0.9))
		"table":
			draw_rect(Rect2(-8, -5, 16, 12), Color(Art.OUT))
			draw_rect(Rect2(-7.4, -4.4, 14.8, 10.8), Color("5a3d28"))
			draw_rect(Rect2(-7.4, -4.4, 14.8, 1.6), Color("7a5538"))
			draw_rect(Rect2(-5.5, -3, 11, 7), Color("e0d2a4"))
			draw_rect(Rect2(-5.5, -3, 11, 1.0), Color("f2e8c4"))
			draw_line(Vector2(-4, -0.5), Vector2(0, 1.2), Color("7a2a2a"), 0.5)
			draw_line(Vector2(0, 1.2), Vector2(3.5, -1.5), Color("7a2a2a"), 0.5)
			draw_line(Vector2(-3, 3), Vector2(4, 3), Color("2a3a6a"), 0.5)
			draw_circle(Vector2(2, 1.5), 0.9, Color("c0392b"))
		"cracked":
			draw_rect(Rect2(-8, -8, 16, 16), Color(Art.OUT))
			draw_rect(Rect2(-7.2, -7.2, 14.4, 14.4), Color("6b6478"))
			draw_rect(Rect2(-7.2, -7.2, 14.4, 2.0), Color("8d87a0"))
			for ln in [[Vector2(-7, -3), Vector2(-3, -1), Vector2(-4, 3), Vector2(1, 5)], [Vector2(2, -7), Vector2(1, -2), Vector2(5, 1), Vector2(4, 6)]]:
				for i in 3:
					draw_line(ln[i], ln[i + 1], Color(Art.OUT), 1.0)
			draw_rect(Rect2(-7.2, 5.2, 14.4, 2.0), Color("4a4659"))
			draw_circle(Vector2(-1, 0), 1.1, Color(1.0, 0.7, 0.3, 0.35 + 0.25 * sin(t * 3.0)))
		"gear":
			var gc := Color("a8864a")
			draw_circle(Vector2.ZERO, 9.5, Color(0, 0, 0, 0.18))
			for i in 10:
				var a := t * 0.35 + i * TAU / 10.0
				var pa := Vector2.from_angle(a)
				var pb := pa.orthogonal()
				draw_colored_polygon(PackedVector2Array([pa * 6.5 + pb * 1.9, pa * 9.0 + pb * 1.3, pa * 9.0 - pb * 1.3, pa * 6.5 - pb * 1.9]), Color(Art.OUT))
			draw_circle(Vector2.ZERO, 7.4, Color(Art.OUT))
			draw_circle(Vector2.ZERO, 6.6, gc)
			draw_arc(Vector2.ZERO, 4.6, 0, TAU, 20, gc.darkened(0.35), 1.0)
			draw_circle(Vector2.ZERO, 2.0, Color(Art.OUT))
			draw_circle(Vector2.ZERO, 1.3, gc.lightened(0.3))
			for i in 4:
				var a2 := t * 0.35 + i * TAU / 4.0 + 0.4
				draw_line(Vector2.from_angle(a2) * 2.0, Vector2.from_angle(a2) * 5.8, gc.darkened(0.35), 0.8)
		"candle":
			Art.candle(self, t, position.x)
		"torch":
			Art.torch(self, t, position.x)
		"npc":
			var npal: Dictionary = pal if not pal.is_empty() else {"aldous": Art.PAL_ALDOUS, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}.get(id, Art.PAL_ISOLDE)
			Art.person(self, Vector2(def.get("face", [0, 1])[0], def.get("face", [0, 1])[1]), t, npal, false)
			if is_interactable() and level.get("_nearest") == self:
				var bob := sin(t * 5.0) * 1.0
				draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -22 + bob), Vector2(2.5, -22 + bob), Vector2(0, -19 + bob)]), Color("ffd166"))
		"lamp":
			draw_rect(Rect2(-1.5, 5.5, 3, 2), Color(Art.OUT))
			draw_rect(Rect2(-0.9, -6, 1.8, 12), Color(Art.OUT))
			draw_rect(Rect2(-0.5, -6, 1, 12), Color("3a3644"))
			draw_rect(Rect2(-3.5, -12, 7, 7), Color(Art.OUT))
			draw_rect(Rect2(-2.5, -11, 5, 5), Color("ffd98a") if int(t * 3.0 + position.x) % 9 != 0 else Color("e8b860"))
			draw_rect(Rect2(-3.5, -13, 7, 1.6), Color("2a2630"))
		"entry":
			_draw_entry()
		"seal_bell", "seal_dagger", "seal_bolt":
			_draw_seal()
		"barrel":
			_draw_object()
		"chest", "crate", "urn", "tomes", "grave", "statue":
			_draw_object()


func _draw_seal() -> void:
	var O := Color(Art.OUT)
	var glow := Color(1.0, 0.85, 0.4) if kind == "seal_bell" else (Color(0.7, 0.55, 1.0) if kind == "seal_dagger" else Color(0.5, 0.95, 1.0))
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	draw_rect(Rect2(-7, 3, 14, 4), O)
	draw_rect(Rect2(-6, 4, 12, 2.5), Color("5a586a"))
	if lit:
		draw_circle(Vector2(0, -3), 11.0, Color(glow, 0.12 + 0.08 * pulse))
	match kind:
		"seal_bell":
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 3), Vector2(-4, -4), Vector2(-2, -8), Vector2(2, -8), Vector2(4, -4), Vector2(5, 3)]), O)
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 2.4), Vector2(-3, -3.6), Vector2(-1.6, -7), Vector2(1.6, -7), Vector2(3, -3.6), Vector2(4, 2.4)]), glow if lit else Color("6a8a9a"))
			draw_rect(Rect2(-3, -6, 1.4, 7), Color(1, 1, 1, 0.45))
			if not lit:
				draw_line(Vector2(-1, -6), Vector2(1, -1), O, 0.8)
				draw_line(Vector2(1, -1), Vector2(-1, 2), O, 0.8)
		"seal_dagger":
			draw_circle(Vector2(0, -3), 7.0, O)
			for i in 3:
				draw_circle(Vector2(0, -3), 6.0 - i * 2.0, glow if (lit and i % 2 == 0) else (Color("7a3a4a") if i % 2 == 0 else Color("d8d0c0")))
		"seal_bolt":
			draw_rect(Rect2(-6, -8, 12, 12), O)
			draw_rect(Rect2(-5, -7, 10, 10), Color("3a3a48"))
			draw_circle(Vector2(0, -2), 3.6, O)
			for i in 6:
				var a := (t * (3.0 if lit else 0.0)) + i * TAU / 6.0
				draw_circle(Vector2(0, -2) + Vector2.from_angle(a) * 3.2, 0.9, glow if lit else Color("8a7a50"))
			draw_circle(Vector2(0, -2), 1.6, glow if lit else Color("5a5040"))
	if _nearest_self() and not lit:
		var bob := sin(t * 5.0) * 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -15 + bob), Vector2(2.5, -15 + bob), Vector2(0, -12 + bob)]), Color("ffd166"))


func _searched() -> bool:
	return GameState.flag("found_" + str(def.get("id", "")))


func _draw_entry() -> void:
	var style: String = def.get("style", "door")
	var req: String = def.get("requires", "")
	var ready := req == "" or GameState.flag(req)
	if style == "gate":
		draw_rect(Rect2(-8, -8, 16, 16), Color(Art.OUT))
		draw_rect(Rect2(-7, -8, 14, 16), Color("231f2e"))
		draw_arc(Vector2(0, -1), 6.5, PI, TAU, 14, Color("6a6678"), 2.0)
		draw_rect(Rect2(-6, -1, 12, 9), Color("07050c"))
		var gc := Color("b894ff") if ready else Color("a03a3a")
		draw_rect(Rect2(-5, -1, 10, 9), Color(gc, 0.10 + 0.05 * sin(t * 2.0)))
		for x in [-3.5, 0.0, 3.5]:
			draw_rect(Rect2(x - 0.5, -1, 1, 9), Color("5f6370") if not ready else Color(0.35, 0.3, 0.45, 0.5))
		if not ready:
			draw_line(Vector2(-6, 1), Vector2(6, 5), Color("8a8f9c"), 1.2)
			draw_line(Vector2(-6, 5), Vector2(6, 1), Color("8a8f9c"), 1.2)
			draw_circle(Vector2(0, 3), 1.3, Color("d6b25a"))
	elif style == "inner":
		draw_rect(Rect2(-8, -8, 16, 16), Color("2a1c12"))
		draw_rect(Rect2(-6, -7, 12, 15), Color(Art.OUT))
		draw_rect(Rect2(-5, -6, 10, 14), Color("5a3a24"))
		draw_rect(Rect2(-5, -6, 10, 1.5), Color("7a5236"))
		draw_rect(Rect2(-0.4, -6, 0.8, 14), Color("3a2415"))
		draw_circle(Vector2(3, 1), 0.9, Color("d6b25a"))
		draw_rect(Rect2(-7, 8, 14, 1), Color(1.0, 0.8, 0.45, 0.25))
	else:
		draw_rect(Rect2(-8, -8, 16, 16), Color("352f3d"))
		draw_rect(Rect2(-6.5, -8, 13, 16), Color(Art.OUT))
		draw_rect(Rect2(-5.5, -7, 11, 15), Color("5a3a24"))
		draw_colored_polygon(PackedVector2Array([Vector2(-5.5, -4), Vector2(-3, -7), Vector2(3, -7), Vector2(5.5, -4)]), Color("5a3a24"))
		for x in [-3.0, 0.0, 3.0]:
			draw_line(Vector2(x, -7), Vector2(x, 8), Color("3a2415"), 0.5)
		draw_rect(Rect2(-5.5, -1, 11, 1.8), Color("4a4d58"))
		draw_circle(Vector2(3, 3), 0.9, Color("d6b25a"))
		draw_rect(Rect2(-7, -9, 14, 2), Color("1c1824"))
		draw_rect(Rect2(-6, 8, 12, 1.2), Color("6a6678"))
	if _nearest_self():
		var bob := sin(t * 5.0) * 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -14 + bob), Vector2(2.5, -14 + bob), Vector2(0, -11 + bob)]), Color("ffd166"))


func _nearest_self() -> bool:
	return level.get("_nearest") == self


func _draw_object() -> void:
	var done := _searched()
	var O := Color(Art.OUT)
	draw_rect(Rect2(-6.5, 3.5, 13, 3), Color(0, 0, 0, 0.28))
	match kind:
		"barrel":
			draw_rect(Rect2(-6, -8, 12, 15), O)
			draw_rect(Rect2(-5, -7, 10, 13), Color("6a4a2e"))
			draw_rect(Rect2(-5, -7, 3, 13), Color("84603c"))
			draw_rect(Rect2(3, -7, 2, 13), Color("4a3220"))
			for y in [-4.0, 2.5]:
				draw_rect(Rect2(-5, y, 10, 1.5), Color("3a3a46"))
				draw_rect(Rect2(-5, y, 10, 0.5), Color("6a6a7a"))
			draw_rect(Rect2(-5, -7, 10, 2), Color("8a6a40") if not done else Color("2a1c12"))
		"chest":
			draw_rect(Rect2(-7.5, -5, 15, 12), O)
			draw_rect(Rect2(-6.5, -1, 13, 7), Color("6a3e22"))
			draw_rect(Rect2(-6.5, -1, 13, 1.5), Color("8a5a30"))
			if done:
				draw_rect(Rect2(-6.5, -6, 13, 5), Color("1a0f08"))
				draw_rect(Rect2(-6.5, -9, 13, 3), Color("8a5a30"))
			else:
				draw_rect(Rect2(-6.5, -4.5, 13, 4), Color("8a5a30"))
				draw_rect(Rect2(-6.5, -4.5, 13, 1), Color("a87a48"))
				draw_rect(Rect2(-1.2, -2.5, 2.4, 3.5), Color("d6b25a"))
			for x in [-5.0, 4.0]:
				draw_rect(Rect2(x, -4.5, 1.5, 10.5), Color("4a4d58"))
		"crate":
			draw_rect(Rect2(-7, -7, 14, 14), O)
			draw_rect(Rect2(-6, -6, 12, 12), Color("8a6a3c") if not done else Color("6a5230"))
			draw_rect(Rect2(-6, -6, 12, 1.5), Color("a88a58"))
			draw_line(Vector2(-6, -6), Vector2(6, 6), Color("5a4226"), 1.2)
			draw_line(Vector2(6, -6), Vector2(-6, 6), Color("5a4226"), 1.2)
			draw_rect(Rect2(-6, -0.5, 12, 1), Color("5a4226"))
		"urn":
			draw_colored_polygon(PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(6, -2), Vector2(4, 6), Vector2(-4, 6), Vector2(-6, -2)]), O)
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -7), Vector2(2, -7), Vector2(5, -2), Vector2(3, 5), Vector2(-3, 5), Vector2(-5, -2)]), Color("6a5a7a"))
			draw_rect(Rect2(-4, -2, 8, 1.2), Color("c8a050"))
			draw_rect(Rect2(-4, -6, 1.5, 9), Color("8a7a9a"))
			draw_rect(Rect2(-3, -9, 6, 2), Color("8a7a9a"))
			if done:
				draw_line(Vector2(0, -7), Vector2(1, 3), O, 0.8)
		"tomes":
			var cols := [Color("6a1e30"), Color("2c4a7a"), Color("4a5a2e"), Color("6a5420")]
			for i in 4:
				var y := 3.0 - i * 3.4
				draw_rect(Rect2(-6.5 + (i % 2) * 1.0, y - 1.7, 13, 3.6), O)
				draw_rect(Rect2(-5.7 + (i % 2) * 1.0, y - 1.0, 11.4, 2.4), cols[i])
				draw_rect(Rect2(-5.7 + (i % 2) * 1.0, y - 1.0, 11.4, 0.6), cols[i].lightened(0.25))
				draw_rect(Rect2(3.5 + (i % 2) * 1.0, y - 1.0, 1.2, 2.4), Color("c8a050"))
			if done:
				draw_rect(Rect2(-1, -11, 1.2, 4), Color("d0405a"))
		"grave":
			draw_rect(Rect2(-6, 4, 12, 3), Color("2a3a2a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 5), Vector2(-5, -3), Vector2(-3, -7), Vector2(3, -7), Vector2(5, -3), Vector2(5, 5)]), O)
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 4.5), Vector2(-4, -3), Vector2(-2.4, -6), Vector2(2.4, -6), Vector2(4, -3), Vector2(4, 4.5)]), Color("7a7888"))
			draw_rect(Rect2(-4, -3, 1.5, 7.5), Color("9a98a8"))
			draw_rect(Rect2(-0.5, -5, 1, 6), Color("4a4858"))
			draw_rect(Rect2(-2, -3.2, 4, 1), Color("4a4858"))
			draw_rect(Rect2(-4, 2, 3, 2), Color(0.25, 0.5, 0.3, 0.7))
		"statue":
			draw_rect(Rect2(-6, 1, 12, 6), O)
			draw_rect(Rect2(-5, 2, 10, 4.5), Color("6a6878"))
			draw_rect(Rect2(-5, 2, 10, 1.2), Color("8a889a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 2), Vector2(-5, -4), Vector2(-3, -6), Vector2(-4, -9), Vector2(-1.5, -7), Vector2(1.5, -7), Vector2(4, -9), Vector2(3, -6), Vector2(5, -4), Vector2(4, 2)]), O)
			draw_colored_polygon(PackedVector2Array([Vector2(-3, 1.5), Vector2(-4, -4), Vector2(-2.2, -5.5), Vector2(-3, -7.5), Vector2(-1, -6.2), Vector2(1, -6.2), Vector2(3, -7.5), Vector2(2.2, -5.5), Vector2(4, -4), Vector2(3, 1.5)]), Color("86869a"))
			draw_rect(Rect2(-2, -4.5, 1, 1), Color("ff7a3a") if int(t) % 2 == 0 else Color("a04a20"))
			draw_rect(Rect2(1, -4.5, 1, 1), Color("ff7a3a") if int(t) % 2 == 0 else Color("a04a20"))
	if _nearest_self() and not done:
		var bob := sin(t * 5.0) * 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -15 + bob), Vector2(2.5, -15 + bob), Vector2(0, -12 + bob)]), Color("ffd166"))
