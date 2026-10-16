extends Node2D
## Animated environment layer for themed boss arenas: rippling loch water, or dusty attic light shafts.

var level: Node2D
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	var T: int = 16
	var loch: bool = level.arena == "loch"
	var cam: Camera2D = level.cam
	var c := cam.get_screen_center_position() if cam else Vector2(level.w * T / 2.0, level.h * T / 2.0)
	var x0 := clampi(int((c.x - 520) / T), 0, level.w - 1)
	var x1 := clampi(int((c.x + 520) / T), 0, level.w - 1)
	var y0 := clampi(int((c.y - 300) / T), 0, level.h - 1)
	var y1 := clampi(int((c.y + 300) / T), 0, level.h - 1)
	if loch:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if level.grid[y][x] == "#":
					continue
				var p := Vector2(x * T, y * T)
				var ph := t * 1.6 + x * 0.9 + y * 0.55
				var a := 0.12 + 0.1 * sin(ph)
				var xo := 3.0 + 4.0 * (0.5 + 0.5 * sin(ph * 0.7))
				draw_rect(Rect2(p.x + xo, p.y + 6 + 3 * sin(ph * 0.5), 7, 1), Color(0.6, 0.95, 1.0, a))
				if (x * 7 + y * 3) % 5 == 0:
					var r := 3.0 + fmod(t * 3.0 + x + y, 5.0)
					draw_arc(p + Vector2(8, 9), r, 0, TAU, 14, Color(0.7, 0.95, 1.0, 0.22 * (1.0 - r / 8.0)), 1.0)
		for i in 14:
			var fx: float = fmod(i * 97.0 + t * (4.0 + i % 3), level.w * T)
			var fy: float = float(i * 53 % (level.h * T)) + 6.0 * sin(t * 0.6 + i)
			draw_circle(Vector2(fx, fy), 2.0, Color(0.5, 0.95, 0.8, 0.12 + 0.08 * sin(t * 2 + i)))
	else:
		for i in 5:
			var sx := 120.0 + i * 210.0
			var sway := 10.0 * sin(t * 0.3 + i)
			var shaft := PackedVector2Array([
				Vector2(sx + sway, 0), Vector2(sx + 60 + sway, 0),
				Vector2(sx + 260 + sway, level.h * T * 0.9), Vector2(sx + 140 + sway, level.h * T * 0.9)])
			draw_colored_polygon(shaft, Color(1.0, 0.85, 0.5, 0.055 + 0.02 * sin(t * 0.8 + i)))
		for i in 40:
			var mx: float = fmod(i * 131.0 + t * 5.0, level.w * T)
			var my: float = fmod(i * 77.0 + t * (3.0 + i % 4), level.h * T)
			draw_circle(Vector2(mx, my), 1.0, Color(1.0, 0.9, 0.6, 0.3))
