extends Control
## New-game prologue: twelve illustrated plates that dissolve into one another.

const PlateArt = preload("res://src/scenes/prologue/plate_art.gd")
const XFADE := 2.0
const CPS := 34.0
const READ_CPS := 15.0
const PLATES := [
	{"art": "age", "title": "I. The Waning Age",
	"text": "In the age of candle and plague, when the kirkyards grew fatter than the fields, the dead did not rest as the priests had promised. Men buried their kin in haste, and left the weeping unfinished."},
	{"art": "echo", "title": "II. What the Echoes Are",
	"text": "Know first what an Echo is. When a soul departs in sorrow, in terror, or in some great deed left undone, a part of it does not depart. It sinks into the stone about it, as a bell-note sinks into a belfry. That remnant is called an Echo: no ghost with a mind to haunt, but a memory made nigh solid, repeating its last hour."},
	{"art": "bellward", "title": "III. Why They Linger",
	"text": "An Echo wants but one thing: to be heard. It reaches, as the drowned reach for a rope, toward any that will hearken. Were it heard to the end, it would be eased, and fade as a candle fades at dawn. Thus Echoes drift toward bells and chapels, for a bell is the one voice that carries to the dead."},
	{"art": "gates", "title": "IV. The Seven Gates",
	"text": "In the elder days, holy men raised Seven Gates in seven forsaken places, and bound the greatest Echoes behind them with the tolling of a consecrated bell. The Gates did not destroy the dead; they gave them a place to wait, until one should come who could listen."},
	{"art": "rift", "title": "V. The Rending of the Veil",
	"text": "But bronze is mortal, and the binding-bell cracked at last. The Veil between the quick and the dead wore thin as old linen, and the crimson dark behind it bled through. The pent Echoes pressed against the Gates, and the Gates began to give."},
	{"art": "abom", "title": "VI. The Unheard Dead",
	"text": "An Echo long unheard curdles. Its sorrow hardens into rage, and rage takes the shape of whatever the folk of that place most feared: the drowned horse of the loch, the hollow knight, the Plague Physician, the black hound. These the learned call Abominations, and they cannot be slain for good. They must be answered, and quieted, or they will walk until the world is an echo too."},
	{"art": "foundling", "title": "VII. The Foundling",
	"text": "On a night of sleet and thunder, a babe was laid upon the step of the Wayfarer's Chapel, and the great bell tolled of itself, though no hand had touched the rope. Father Aldous took up the child and named him Mu, which in the oldest tongue signifies only: the one who listens."},
	{"art": "listener", "title": "VIII. The One Who Listens",
	"text": "Mu grew beneath the belfry, and whilst other children heard but wind, he heard voices in the walls, and a weeping beneath the floor. He was a Listener, one of the rarest born, whom the Echoes do not flee but follow. Aldous taught him sword and psalm alike, and warned him gravely: heed the dead, lad, but never follow them."},
	{"art": "gift", "title": "IX. The Gift and the Burden",
	"text": "A Listener who hears an Echo to its end may take up its strength for a time, and wear its shape: a fleeting form, borrowed from the dead, that can do what the living cannot. Such power is a loan, and the dead keep strict accounts. Each Echo Mu quiets will leave its mark upon him, and ask what he is willing to remember."},
	{"art": "toll", "title": "X. The Bell Tolls Anew",
	"text": "Upon the eve of Mu's eighteenth winter, the bell began to toll once more, thrice by night and thrice by day. Far off, in Edinburgh beneath its smoking roofs and in Golden Praha beneath its clocks, the Gates stood open, and the dead came crowding at the thresholds."},
	{"art": "farewell", "title": "XI. The Parting",
	"text": "Father Aldous placed the Tolling Blade in Mu's hands. 'I am too old for the road, and the bell will have a keeper here. Go to the Gates. Hear them out, every one, and bring home the quiet. Companions will meet thee, lad; each hath a sorrow of their own, and each shall be called away in time by a road that is theirs alone.'"},
	{"art": "road", "title": "XII. The Long Road",
	"text": "So Mu took up his father's sword and a lantern, and went out into the dark. Behind him the bell tolled once, softly, as one bids farewell. Before him lay a night with no end in sight, and a thousand voices waiting to be heard. Thus began the journey, and thus the telling of it."},
]

var idx := 0
var t := 0.0
var done := false
var font: Font
var layer_a: Control
var layer_b: Control
var ui: Control
var post: Node
var typed := 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for n in 2:
		var c: Control = Control.new()
		c.set_script(PlateArt)
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(c)
		if n == 0:
			layer_a = c
		else:
			layer_b = c
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.draw.connect(_draw_ui)
	add_child(ui)
	post = CanvasLayer.new()
	post.set_script(load("res://src/core/post.gd"))
	post.set("grit", 1.1)
	add_child(post)
	Audio.play_music("prologue")
	layer_a.art = PLATES[0].art
	layer_b.modulate.a = 0.0


func _dur(i: int) -> float:
	var n: int = PLATES[i].text.length()
	return 1.0 + n / CPS + 3.0 + n / READ_CPS * 0.4


func _process(delta: float) -> void:
	t += delta * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	typed += delta * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0) * CPS
	if Input.is_action_just_pressed("ui_cancel") and not done:
		_finish()
		return
	var full: int = PLATES[idx].text.length()
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact")) and t > 0.5:
		if typed < full:
			typed = full
		elif t < _dur(idx) - XFADE:
			t = _dur(idx) - XFADE
	var d := _dur(idx)
	var fade_in := clampf(t / 1.5, 0.0, 1.0)
	layer_a.t = t
	layer_a.modulate.a = 1.0
	var into := t - (d - XFADE)
	if into > 0.0 and idx + 1 < PLATES.size():
		var k := clampf(into / XFADE, 0.0, 1.0)
		layer_b.art = PLATES[idx + 1].art
		layer_b.t = k * 2.0
		layer_b.modulate.a = k * k * (3.0 - 2.0 * k)
	else:
		layer_b.modulate.a = 0.0
	if idx == 0:
		layer_a.modulate.a = fade_in
	if t >= d:
		idx += 1
		if idx >= PLATES.size():
			_finish()
			return
		t = XFADE
		typed = 0.0
		layer_a.art = PLATES[idx].art
		layer_b.modulate.a = 0.0
	if idx == PLATES.size() - 1 and t > d - XFADE:
		layer_a.modulate.a = clampf((d - t) / XFADE, 0.0, 1.0)
	layer_a.queue_redraw()
	layer_b.queue_redraw()
	ui.queue_redraw()


func _finish() -> void:
	if done:
		return
	done = true
	GameState.set_flag("prologue_seen", true)
	get_tree().change_scene_to_file(GameState.LEVEL_SCENE)


func _draw_ui() -> void:
	var pl: Dictionary = PLATES[idx]
	var d := _dur(idx)
	var fa := clampf(t / 1.5, 0.0, 1.0) * clampf((d - t) / 1.5, 0.0, 1.0)
	if idx > 0:
		fa = maxf(fa, 0.0)
	if t >= d - XFADE or t < XFADE * 0.5:
		fa = clampf(minf(t / 1.2, (d - t) / 1.2), 0.0, 1.0)
	ui.draw_rect(Rect2(0, 0, 1920, 100), Color(0, 0, 0, 0.92))
	ui.draw_rect(Rect2(0, 770, 1920, 310), Color(0, 0, 0, 0.88))
	ui.draw_rect(Rect2(0, 770, 1920, 2), Color(0.62, 0.5, 0.78, 0.6))
	ui.draw_string(font, Vector2(0, 66), pl.title, HORIZONTAL_ALIGNMENT_CENTER, 1920, 44, Color(0.92, 0.82, 0.55, fa))
	var full: String = pl.text
	ui.draw_multiline_string(font, Vector2(180, 835), full.substr(0, int(typed)), HORIZONTAL_ALIGNMENT_LEFT, 1560, 32, 8, Color(0.9, 0.88, 0.94, fa))
	ui.draw_string(font, Vector2(0, 1056), "Enter: complete / next    Shift: hasten    Esc: skip    (%d / %d)" % [idx + 1, PLATES.size()], HORIZONTAL_ALIGNMENT_RIGHT, 1860, 20, Color(0.7, 0.7, 0.8, 0.6))
