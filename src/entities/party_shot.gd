extends Node2D
## Projectile fired by a party member: Wren's daggers and Corvin's clockwork bolts.

const Art = preload("res://src/core/art.gd")

var level: Node2D
var vel := Vector2.ZERO
var dmg := 1
var life := 1.1
var kind := "dagger"
var t := 0.0


func _ready() -> void:
	top_level = true
	z_index = 6


func _process(delta: float) -> void:
	t += delta
	life -= delta
	position += vel * delta
	var cell := Vector2i(int(floor(position.x / 16.0)), int(floor(position.y / 16.0)))
	if life <= 0.0 or (level and level._is_solid_char(cell)):
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var st: String = str(e.get("state"))
		if st in ["dormant", "intro", "dying"]:
			continue
		if e.global_position.distance_to(position) < float(e.get("hit_radius")) + 4.0:
			e.hurt(dmg, vel.normalized())
			if level:
				level.spark(position, Color(1, 0.9, 0.6) if kind == "dagger" else Color(0.6, 0.9, 1.0), 5)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var d := vel.normalized()
	if kind == "dagger":
		draw_line(-d * 5.0, d * 4.0, Color(Art.OUT), 3.0)
		draw_line(-d * 4.0, d * 4.0, Color("c8d0e0"), 1.4)
		draw_line(-d * 5.0, -d * 3.0, Color("e0c27a"), 2.0)
	else:
		draw_circle(Vector2.ZERO, 5.0, Color(0.6, 0.9, 1.0, 0.25))
		draw_circle(Vector2.ZERO, 3.2, Color(Art.OUT))
		draw_circle(Vector2.ZERO, 2.4, Color("c8a050"))
		for i in 4:
			var a := t * 14.0 + i * TAU / 4.0
			draw_rect(Rect2(Vector2.from_angle(a) * 2.8 - Vector2(0.6, 0.6), Vector2(1.2, 1.2)), Color("e0c27a"))
