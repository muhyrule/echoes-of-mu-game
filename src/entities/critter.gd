extends Node2D
## Ambient town life: cats, crows, pigeons and rats that wander and scatter from the player.

var level: Node
var kind := "cat"
var home := Vector2.ZERO
var target := Vector2.ZERO
var wait := 0.0
var t := 0.0
var face := 1.0
var fly := 0.0
var flying := false
var sit := false
var spd := 22.0


func setup(k: String, lvl: Node, pos: Vector2) -> void:
	kind = k
	level = lvl
	position = pos
	home = pos
	target = pos
	t = randf() * 10.0
	wait = randf_range(0.5, 4.0)
	spd = {"cat": 26.0, "crow": 18.0, "pigeon": 16.0, "rat": 44.0}.get(k, 20.0)
	z_index = 2


func _free_at(p: Vector2) -> bool:
	return not level._is_solid_char(Vector2i(int(p.x / 16.0), int(p.y / 16.0)))


func _process(delta: float) -> void:
	t += delta
	var pl: Vector2 = level.player.global_position
	var dp := pl.distance_to(position)
	if kind in ["crow", "pigeon"]:
		if flying:
			fly = minf(1.0, fly + delta * 2.0)
			position += Vector2(face * 70.0, -34.0) * delta * (0.5 + fly)
			if position.x < -40 or position.x > level.w * 16 + 40 or position.y < -40:
				flying = false
				fly = 0.0
				position = home
				wait = randf_range(6.0, 14.0)
				visible = false
				get_tree().create_timer(randf_range(5.0, 12.0)).timeout.connect(func(): visible = true)
		elif dp < 30.0:
			flying = true
			face = 1.0 if position.x >= pl.x else -1.0
			z_index = 18
		else:
			wait -= delta
			if wait <= 0.0:
				wait = randf_range(0.8, 3.0)
				var p := position + Vector2(randf_range(-14, 14), randf_range(-8, 8))
				if p.distance_to(home) < 40.0 and _free_at(p):
					target = p
			var dv := target - position
			if dv.length() > 1.0:
				position += dv.normalized() * spd * delta
				face = 1.0 if dv.x > 0 else -1.0
	else:
		var run := dp < 34.0
		if run:
			var away := (position - pl).normalized()
			var np := position + away * spd * 2.2 * delta
			if _free_at(np) and np.distance_to(home) < 110.0:
				position = np
				face = 1.0 if away.x > 0 else -1.0
			sit = false
		else:
			wait -= delta
			if wait <= 0.0:
				sit = kind == "cat" and randf() < 0.45
				wait = randf_range(1.5, 6.0)
				var p2 := position + Vector2(randf_range(-40, 40), randf_range(-24, 24))
				if not sit and _free_at(p2) and p2.distance_to(home) < 100.0:
					target = p2
			var dv2 := target - position
			if not sit and dv2.length() > 1.5:
				var np2 := position + dv2.normalized() * spd * delta
				if _free_at(np2):
					position = np2
					face = 1.0 if dv2.x > 0 else -1.0
				else:
					target = position
	queue_redraw()


func _draw() -> void:
	var O := Color(0.04, 0.03, 0.06)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
	if not flying:
		draw_circle(Vector2(0, 2), 3.0, Color(0, 0, 0, 0.25))
	match kind:
		"cat":
			var body := Color("2a2630") if int(home.x) % 3 != 0 else Color("a8744a")
			var bob := 0.0 if sit else sin(t * 9.0) * 0.4
			if sit:
				draw_rect(Rect2(-3, -4, 6, 6), O)
				draw_rect(Rect2(-2.4, -3.4, 4.8, 5.0), body)
				draw_rect(Rect2(0, -7, 4, 4), O)
				draw_rect(Rect2(0.6, -6.4, 2.8, 2.8), body)
				draw_rect(Rect2(0.6, -8, 1, 1.6), body)
				draw_rect(Rect2(2.6, -8, 1, 1.6), body)
				draw_rect(Rect2(1.2, -5.4, 0.8, 0.8), Color("e8d050"))
				draw_rect(Rect2(-5, 0 - sin(t * 2.0) * 0.6, 3, 1.2), body)
			else:
				draw_rect(Rect2(-4, -4 + bob, 8, 4), O)
				draw_rect(Rect2(-3.4, -3.4 + bob, 6.8, 2.8), body)
				draw_rect(Rect2(3, -6 + bob, 3.6, 3.6), O)
				draw_rect(Rect2(3.5, -5.5 + bob, 2.6, 2.6), body)
				draw_rect(Rect2(3.6, -7 + bob, 0.9, 1.4), body)
				draw_rect(Rect2(5.2, -7 + bob, 0.9, 1.4), body)
				draw_rect(Rect2(-6, -6 + bob + sin(t * 5.0), 2.4, 1.0), body)
				var lg := sin(t * 14.0)
				draw_rect(Rect2(-3 + lg, -0.6, 1.2, 1.6), O)
				draw_rect(Rect2(2 - lg, -0.6, 1.2, 1.6), O)
		"crow", "pigeon":
			var bc := Color("1c1a24") if kind == "crow" else Color("8a8e9a")
			if flying:
				var fl := sin(t * 22.0)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(-8, -3 - 5 * fl), Vector2(-3, 0)]), bc)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(8, -3 - 5 * fl), Vector2(3, 0)]), bc)
				draw_rect(Rect2(-2, -4, 4, 3), bc)
			else:
				draw_rect(Rect2(-3, -5, 6, 5), O)
				draw_rect(Rect2(-2.4, -4.4, 4.8, 3.8), bc)
				draw_rect(Rect2(1, -7, 3, 3), O)
				draw_rect(Rect2(1.5, -6.5, 2, 2), bc)
				draw_rect(Rect2(3.5, -6, 2, 1), Color("c8a050"))
				draw_rect(Rect2(-5, -4, 3, 2), bc)
				draw_rect(Rect2(-1, 0, 0.8, 1.5), Color("c8a050"))
				draw_rect(Rect2(1, 0, 0.8, 1.5), Color("c8a050"))
		"rat":
			var rc := Color("4a4048")
			draw_rect(Rect2(-3, -3, 6, 3), O)
			draw_rect(Rect2(-2.4, -2.4, 4.8, 1.8), rc)
			draw_rect(Rect2(2.6, -3, 2.4, 2.2), rc)
			draw_rect(Rect2(-7, -1.2 + sin(t * 12.0) * 0.8, 4, 0.7), Color("a08080"))
			draw_rect(Rect2(4.2, -2.4, 0.8, 0.8), Color("d04040"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
