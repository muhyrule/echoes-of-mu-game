extends Node2D
## Party member that trails the player (Isolde in the vertical slice).

const Art = preload("res://src/core/art.gd")

var target: Node2D
var trail: Array = []
var pal: Dictionary = Art.PAL_ISOLDE
var facing := Vector2.DOWN
var t := 0.0
var hero := ""
var moving := false
const DELAY := 16


func start(p: Node2D, palette: Dictionary = Art.PAL_ISOLDE) -> void:
	target = p
	pal = palette
	global_position = p.global_position + Vector2(-12, 4)
	for i in DELAY:
		trail.append(global_position)


func _process(delta: float) -> void:
	t += delta
	if target == null:
		return
	if trail.is_empty() or trail.back().distance_to(target.global_position) > 3.0:
		trail.append(target.global_position)
	while trail.size() > DELAY:
		var next: Vector2 = trail.pop_front()
		var d := next - global_position
		moving = d.length() > 0.5
		if moving:
			facing = d.normalized()
		global_position = next
	queue_redraw()


func _draw() -> void:
	Art.person(self, facing, t, Gear.styled(hero, pal) if hero != "" else pal, moving)
