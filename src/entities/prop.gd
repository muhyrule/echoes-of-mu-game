extends Node2D
## A map object: door, gate, bars, block, plate, key, heart, shrine, npc, portal, etc.

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
	queue_redraw()


func _draw() -> void:
	match kind:
		"door":
			draw_rect(Rect2(-8, -8, 16, 16), Color("4a3524"))
			draw_rect(Rect2(-8, -8, 16, 16), Color("2a1c12"), false, 1.0)
			draw_line(Vector2(-8, -3), Vector2(8, -3), Color("7a7a86"), 2.0)
			draw_line(Vector2(-8, 4), Vector2(8, 4), Color("7a7a86"), 2.0)
			draw_circle(Vector2(0, 0), 2.0, Color("d9b34a"))
		"gate":
			draw_rect(Rect2(-8, -8, 16, 16), Color("1b1822"))
			for x in [-6, -2, 2, 6]:
				draw_line(Vector2(x, -8), Vector2(x, 8), Color("8a8f9c"), 2.0)
			draw_line(Vector2(-8, -4), Vector2(8, -4), Color("5f6370"), 2.0)
			draw_line(Vector2(-8, 4), Vector2(8, 4), Color("5f6370"), 2.0)
		"bars":
			draw_rect(Rect2(-8, -8, 16, 16), Color("111018"))
			for x in [-6, -2, 2, 6]:
				draw_line(Vector2(x, -8), Vector2(x, 8), Color("9aa0ae"), 1.5)
			draw_line(Vector2(-8, 0), Vector2(8, 0), Color("6c7180"), 1.5)
		"block":
			draw_rect(Rect2(-7, -7, 14, 14), Color("6e6a7c"))
			draw_rect(Rect2(-7, -7, 14, 3), Color("918ca6"))
			draw_rect(Rect2(-7, -7, 14, 14), Color("2a2735"), false, 1.0)
			draw_line(Vector2(-4, 1), Vector2(3, 4), Color("2a2735"), 1.0)
		"plate":
			var lit: bool = level.flags_plate
			draw_rect(Rect2(-6, -6, 12, 12), Color("3a3646"))
			draw_rect(Rect2(-4, -4, 8, 8), Color("66e0ff") if lit else Color("7a5a8a"))
		"key":
			var bob := sin(t * 4.0) * 1.5
			draw_circle(Vector2(-3, bob), 3.0, Color("e6c15a"))
			draw_circle(Vector2(-3, bob), 1.2, Color("2a2018"))
			draw_rect(Rect2(-1, bob - 1, 8, 2), Color("e6c15a"))
			draw_rect(Rect2(5, bob, 2, 4), Color("e6c15a"))
		"heart":
			Art.heart(self, Vector2(0, -1 + sin(t * 5.0)), 4.0, Color("d6455d"))
		"shrine":
			draw_rect(Rect2(-8, -8, 16, 16), Color("26222e"))
			var glow := 0.5 + sin(t * 3.0) * 0.25
			draw_circle(Vector2(0, -1), 9.0, Color(0.4, 0.8, 1.0, 0.12 + glow * 0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 6), Vector2(5, 6), Vector2(4, -3), Vector2(0, -8), Vector2(-4, -3)]), Color("8fa3c8"))
			draw_circle(Vector2(0, 5), 1.2, Color("1b1822"))
		"exit":
			draw_rect(Rect2(-8, -8, 16, 16), Color("1b1822"))
			draw_rect(Rect2(-5, -8, 10, 14), Color("0d0b12"))
			draw_arc(Vector2(0, -2), 5.0, PI, TAU, 8, Color("5f6370"), 1.5)
		"portal":
			var p := 0.6 + sin(t * 4.0) * 0.2
			draw_rect(Rect2(-8, -8, 16, 16), Color("1b1822"))
			draw_circle(Vector2.ZERO, 8.0, Color(0.55, 0.35, 0.9, p * 0.6))
			draw_circle(Vector2.ZERO, 5.0, Color(0.8, 0.9, 1.0, p))
		"final":
			var p2 := 0.6 + sin(t * 4.0) * 0.2
			draw_circle(Vector2.ZERO, 10.0, Color(0.55, 0.9, 1.0, p2 * 0.5))
			draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, p2))
		"table":
			draw_rect(Rect2(-8, -6, 16, 12), Color("5a3d28"))
			draw_rect(Rect2(-6, -4, 12, 8), Color("d8c99a"))
			draw_line(Vector2(-4, -1), Vector2(3, 1), Color("7a2a2a"), 1.0)
			draw_line(Vector2(-2, 2), Vector2(4, -2), Color("2a3a6a"), 1.0)
		"candle":
			Art.candle(self, t, position.x)
		"npc":
			var pal: Dictionary = Art.PAL_ALDOUS if id == "aldous" else Art.PAL_ISOLDE
			Art.person(self, Vector2.DOWN, t, pal, false)
			if id == "aldous":
				draw_rect(Rect2(-3, -6, 6, 6), Color("d8d8e0"))
