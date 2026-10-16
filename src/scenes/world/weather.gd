extends Node2D
## Screen-space weather for outdoor towns. Blends between states over time.

const OPTIONS := {
	"town_e": ["mist", "drizzle", "rain", "storm", "clear", "rain", "mist"],
	"town_p": ["clear", "snow", "mist", "blizzard", "snow", "clear"],
}
const LABELS := {"clear": "Overcast", "mist": "Mist", "drizzle": "Drizzle", "rain": "Rain", "storm": "Thunderstorm", "snow": "Snowfall", "blizzard": "Blizzard"}

var level: Node
var kind := "clear"
var target := "clear"
var amt := 0.0
var timer := 0.0
var flash := 0.0
var next_bolt := 6.0
var drops: Array = []
var flakes: Array = []
var ripples: Array = []
var vp := Vector2(1920, 1080)


func _ready() -> void:
	z_index = 5
	var opts: Array = OPTIONS.get(level.theme, ["clear"])
	kind = GameState.weather if GameState.weather in opts else opts[0]
	target = kind
	amt = 1.0
	GameState.weather = kind
	timer = randf_range(50.0, 90.0)
	for i in 420:
		drops.append(Vector2(randf() * vp.x, randf() * vp.y))
	for i in 260:
		flakes.append(Vector3(randf() * vp.x, randf() * vp.y, randf()))


func label() -> String:
	return LABELS.get(kind, "")


func _intensity(k: String) -> float:
	return {"drizzle": 0.35, "rain": 0.7, "storm": 1.0, "snow": 0.55, "blizzard": 1.0, "mist": 0.0, "clear": 0.0}.get(k, 0.0)


func _process(delta: float) -> void:
	vp = get_viewport_rect().size
	timer -= delta
	if timer <= 0.0:
		var opts: Array = OPTIONS.get(level.theme, ["clear"])
		var pick: String = opts[randi() % opts.size()]
		if pick != target:
			target = pick
		timer = randf_range(45.0, 95.0)
	if kind != target:
		amt -= delta / 3.5
		if amt <= 0.0:
			amt = 0.0
			kind = target
			GameState.weather = kind
			level.hud.show_notice("The weather turns: %s" % label())
	else:
		amt = minf(1.0, amt + delta / 3.5)
	flash = maxf(0.0, flash - delta * 2.2)
	if kind == "storm":
		next_bolt -= delta
		if next_bolt <= 0.0:
			flash = 1.0
			next_bolt = randf_range(5.0, 13.0)
			level.shake(1.5)
	var a := amt * _intensity(kind)
	var fall := 1.0 if kind in ["rain", "drizzle", "storm"] else 0.0
	var wet := (amt if kind in ["mist", "rain", "drizzle", "storm"] else 0.0)
	var dark := 0.0
	match kind:
		"rain":
			dark = 0.12
		"storm":
			dark = 0.26
		"drizzle":
			dark = 0.06
		"blizzard":
			dark = 0.1
		"mist":
			dark = 0.04
	level.set_weather_dark(dark * amt + flash * -0.0)
	if fall > 0.0:
		var spd := 1100.0 + 500.0 * a
		var wind := 160.0 + (240.0 if kind == "storm" else 0.0)
		for i in drops.size():
			var d: Vector2 = drops[i]
			d += Vector2(wind, spd) * delta
			if d.y > vp.y:
				if randf() < 0.1 * a and ripples.size() < 40:
					ripples.append(Vector3(d.x - wind * 0.3, randf_range(vp.y * 0.35, vp.y), 0.0))
				d = Vector2(randf() * vp.x - 200, -randf() * 60)
			drops[i] = d
	if kind in ["snow", "blizzard"]:
		var wind2 := 40.0 + (260.0 if kind == "blizzard" else 0.0)
		for i in flakes.size():
			var f: Vector3 = flakes[i]
			f.x += (wind2 + sin(f.y * 0.01 + f.z * 6.0) * 30.0) * delta * (0.6 + f.z)
			f.y += (70.0 + 90.0 * f.z) * delta
			if f.y > vp.y:
				f.y = -6.0
				f.x = randf() * vp.x
			if f.x > vp.x:
				f.x = 0.0
			flakes[i] = f
	for i in range(ripples.size() - 1, -1, -1):
		ripples[i].z += delta * 1.6
		if ripples[i].z >= 1.0:
			ripples.remove_at(i)
	queue_redraw()


func _draw() -> void:
	var a := amt * _intensity(kind)
	if kind in ["mist", "rain", "drizzle", "storm", "blizzard"]:
		var m := amt * (0.16 if kind == "mist" else (0.1 if kind == "blizzard" else 0.06))
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.62, 0.68, 0.8, m))
	if kind in ["rain", "drizzle", "storm"]:
		var n := int(drops.size() * clampf(a, 0.0, 1.0))
		var col := Color(0.7, 0.8, 1.0, 0.28 + 0.2 * a)
		var wind := 160.0 + (240.0 if kind == "storm" else 0.0)
		var spd := 1100.0 + 500.0 * a
		var dir := Vector2(wind, spd).normalized() * (14.0 + 10.0 * a)
		for i in n:
			var d: Vector2 = drops[i]
			draw_line(d, d + dir, col, 1.6)
		for rp in ripples:
			var r: float = 4.0 + rp.z * 16.0
			draw_set_transform(Vector2(rp.x, rp.y), 0.0, Vector2(1.0, 0.4))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 14, Color(0.8, 0.88, 1.0, 0.35 * (1.0 - rp.z)), 1.4)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind in ["snow", "blizzard"]:
		var n2 := int(flakes.size() * clampf(a, 0.0, 1.0))
		for i in n2:
			var f: Vector3 = flakes[i]
			var sz := 1.6 + f.z * 2.6
			draw_circle(Vector2(f.x, f.y), sz, Color(0.95, 0.97, 1.0, 0.5 + 0.4 * f.z))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.85, 0.9, 1.0, 0.45 * flash * flash))
