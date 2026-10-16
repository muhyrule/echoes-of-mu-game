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
var light: PointLight2D
var base_energy := 1.0


func setup(k: String, c: Vector2i, lvl: Node2D, npc_id := "") -> void:
	kind = k
	cell = c
	home_cell = c
	level = lvl
	id = npc_id
	position = Vector2(c) * 16.0 + Vector2(8, 8)
	solid = kind in ["door", "gate", "bars", "block", "npc", "shrine", "table"]
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
		"table":
			light = Art.make_light(Color("ffcf80"), 0.5, 0.5)
	if light:
		base_energy = light.energy
		add_child(light)


func is_interactable() -> bool:
	if kind == "door":
		return not open
	return kind in ["npc", "shrine", "table", "portal"]


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


func _process(delta: float) -> void:
	t += delta
	if light:
		match kind:
			"candle", "torch":
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
		"candle":
			Art.candle(self, t, position.x)
		"torch":
			Art.torch(self, t, position.x)
		"npc":
			var pal: Dictionary = Art.PAL_ALDOUS if id == "aldous" else Art.PAL_ISOLDE
			Art.person(self, Vector2.DOWN, t, pal, false)
			if is_interactable() and level.get("_nearest") == self:
				var bob := sin(t * 5.0) * 1.0
				draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -22 + bob), Vector2(2.5, -22 + bob), Vector2(0, -19 + bob)]), Color("ffd166"))
