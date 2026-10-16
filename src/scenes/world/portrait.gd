extends Node2D
## Enlarged hero sprite for the status screen.

const Art = preload("res://src/core/art.gd")

var hero := "mu"
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var pal: Dictionary = {"mu": Art.PAL_MU, "isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}[hero]
	draw_circle(Vector2(0, -4), 14.0, Color(0.9, 0.7, 0.4, 0.07))
	Art.person(self, Vector2(0, 1), t, Gear.styled(hero, pal), false)
