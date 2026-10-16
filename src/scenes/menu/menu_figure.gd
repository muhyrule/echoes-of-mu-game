extends Node2D
## A party member standing on the title-screen ledge, drawn with the in-game sprite art.

const Art = preload("res://src/core/art.gd")

var pal: Dictionary = {}
var face := Vector2.UP
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	Art.person(self, face, t, pal, false)
