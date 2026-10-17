extends Control
## New-game prologue: twenty-four illustrated plates that dissolve into one another.

const PlateArt = preload("res://src/scenes/prologue/plate_art.gd")
const XFADE := 2.0
const CPS := 26.0
const READ_CPS := 15.0
const PLATES := [
	{"art": "age", "title": "I. The Waning Age",
	"text": "In the age of candle and plague, when the kirkyards grew fatter than the fields, the old world was dying by inches. Kings quarrelled over crowns of rust, bells rang for the dead more often than for the living, and every parish kept a cart for its sorrows. It is in this twilight that our tale begins."},
	{"art": "carts", "title": "II. The Black Carts",
	"text": "Each dusk the carts rolled through the fog, and the bell-men cried their grim trade: 'Bring out your dead!' Men buried their kin in haste, in trenches and in the churchyard's very walls, and left the weeping unfinished. Husbands were put in the earth unshriven, and mothers without a psalm. So much grief was never mourned."},
	{"art": "kirkyard", "title": "III. The Overfull Kirkyard",
	"text": "The kirkyards swelled until the stones leaned upon one another like drunkards, and the crows grew fat and bold. Yet the learned noticed a strangeness: where the dead lay thickest, the nights grew heavy with whispers, and the candles guttered all one way, as though bowing to something unseen."},
	{"art": "echo", "title": "IV. What the Echoes Are",
	"text": "Know first what an Echo is. When a soul departs in sorrow, in terror, or with some great deed undone, a part of it does not depart. It sinks into the stone about it, as a bell-note sinks into a belfry. That remnant is the Echo: not a ghost with a mind to haunt, but a memory made nigh solid, repeating its last hour, again and again, as a wound that will not close."},
	{"art": "cloister", "title": "V. A Memory That Walks",
	"text": "Whoever walks the old cloisters at night may glimpse one: a figure pacing the same flagstones, speaking the same unfinished words, reaching for a door that is no longer there. It knows not that it is dead. It knows not that you are watching. It knows only the hour of its sorrow, and it burns with a faint red glow, the colour of a heart still beating in the dark."},
	{"art": "bellward", "title": "VI. Why They Linger",
	"text": "An Echo wants but one thing: to be heard. It reaches toward any that will hearken, as the drowned reach for a rope. Were it heard to the end, it would be eased, and fade as a candle fades at dawn. Thus Echoes drift ever toward bells and chapels, for the bell is the one voice that carries to the dead, and the dead are drawn to it as moths to a flame."},
	{"art": "kinds", "title": "VII. The Many Faces of Grief",
	"text": "Each Echo keeps the hue of its grief. The drowned burn a cold sea-green; the keepers of hearth and hours, a weary amber; the wrathful and the betrayed, a deep and hungry crimson. And each takes root in its own place: the loch, the clocktower, the plague-pit, the cellar. Mark the colour and the place, and you may learn what the Echo most fears."},
	{"art": "gates", "title": "VIII. The Seven Gates",
	"text": "In the elder days, holy men raised Seven Gates in seven forsaken places, and bound the greatest Echoes behind them. The Gates did not destroy the dead; they gave them a place to wait. Each Gate was sealed with a bell of consecrated bronze, and each was watched by a keeper sworn to listen, should the dead one day speak."},
	{"art": "foundry", "title": "IX. The Bell-Founders",
	"text": "The bells were cast in a single night, in a foundry whose name is lost. Hooded men poured silver, bone-ash and the tears of the bereaved into the molten bronze, saying that a bell must be made of the thing it was meant to answer. When the metal cooled, it rang with a voice no living throat could shape: low as a grave, and sweet as a lullaby."},
	{"art": "binding", "title": "X. The Binding",
	"text": "With the great bell tolled in the chapel, every Gate was sealed in the same breath, and the Echoes fell quiet as children at a mother's song. The bell asked only that it be rung, and that someone listen. For long winters the binding held, and the Gates slept beneath the moss, and men forgot what had ever been bound."},
	{"art": "snowchapel", "title": "XI. A Peace of Many Winters",
	"text": "Generations passed, and the Wayfarer's Chapel became a place of travellers and travelling tales. Its keepers rang the bell by habit and listened by rote, until listening became only a custom, and the custom became only a bell. Snow fell upon the roof each winter and covered the old stones, and the dead waited, patient as the snow."},
	{"art": "crack", "title": "XII. The Cracking Bell",
	"text": "But bronze is mortal. One bitter night the great bell, rung once too often, split from lip to crown, and a thin red light welled from the crack like blood from a wound. The binding strained. Far away, in seven places, the seals shivered as though a hand beneath them had begun to knock."},
	{"art": "rift", "title": "XIII. The Rending of the Veil",
	"text": "The Veil between the quick and the dead wore thin as old linen, and the crimson dark behind it bled through. The pent Echoes pressed against their Gates, and the Gates began to give. Spires leaned; wells ran red; hounds howled at nothing. The world did not yet know that it stood upon the brink of an ancient reckoning."},
	{"art": "abom", "title": "XIV. The Unheard Dead",
	"text": "An Echo long unheard curdles. Its sorrow hardens into rage, and rage takes the shape of whatever the folk of that place most feared: the drowned horse of the loch, the hollow knight, the Plague Physician, the black hound. These the learned call Abominations. They cannot be slain for good; they must be answered, and quieted, or they will walk until the world itself is an echo too."},
	{"art": "edin", "title": "XV. Edinburgh of the Smoking Roofs",
	"text": "In the north, beneath the Old Town's crooked closes, lie the South Bridge Vaults: arches bricked up in a plague year, with the living walled in beside the dead. The Burgh has sealed them by writ and by chain. Yet the candle-flames in every window lean toward them nightly, and the old women say the vaults are counting."},
	{"art": "praha", "title": "XVI. Golden Praha",
	"text": "In the east, Praha of the hundred spires keeps its great Clock, and beneath the Clock lies an ossuary where the hours themselves are buried. There the Revenant counts the days of the dead aloud, and each count takes a toll upon the living. The Captain of the Watch has sent four men below, and four hourglasses came back empty."},
	{"art": "foundling", "title": "XVII. The Foundling",
	"text": "On a night of sleet and thunder, a babe was laid upon the step of the Wayfarer's Chapel, and the great bell tolled of itself, though no hand had touched the rope. Father Aldous took up the child, wrapped him in his own cloak, and named him Mu, which in the oldest tongue signifies only: the one who listens."},
	{"art": "belfry", "title": "XVIII. The Boy Under the Belfry",
	"text": "Mu grew in the shadow of the bell, and whilst other children heard but wind, he heard voices in the walls and a weeping beneath the floor. He would sit for hours with his ear to the cold stone, and answer softly, to no one. Aldous watched him from the door, and was afraid, and was proud, and said nothing."},
	{"art": "listener", "title": "XIX. The One Who Listens",
	"text": "He was a Listener, one of the rarest born, whom the Echoes do not flee but follow. Aldous taught him the sword and the psalm alike, and warned him gravely: 'Heed the dead, lad, but never follow them. They are very persuasive, and very lonely. Hear them out, and then let them go.' Mu promised, and meant it, as the young do."},
	{"art": "gift", "title": "XX. The Gift",
	"text": "A Listener who hears an Echo to its end may take up its strength for a time, and wear its shape: a fleeting form, borrowed from the dead, that can do what the living cannot. The drowned lend their swiftness; the stone-bound their weight; the keepers of time their stillness. Thus Mu will learn the secrets of every Gate, and open doors that no key was ever cut for."},
	{"art": "price", "title": "XXI. The Price",
	"text": "Yet such power is a loan, and the dead keep strict accounts. Each Echo Mu quiets will leave a mark upon him, a memory not his own, a face he cannot place, a grief he did not earn. Aldous knew this, and kept it from him. 'He will learn it soon enough,' he told the bell, 'and I would have him young a little longer.'"},
	{"art": "toll", "title": "XXII. The Bell Tolls Anew",
	"text": "Upon the eve of Mu's eighteenth winter, the bell began to toll once more, thrice by night and thrice by day, though its voice was cracked and wrong. Far off, in Edinburgh beneath its smoking roofs and in Golden Praha beneath its clocks, the Gates stood open, and the dead came crowding at the thresholds."},
	{"art": "farewell", "title": "XXIII. The Parting",
	"text": "Father Aldous placed the Tolling Blade in Mu's hands. 'I am too old for the road, and the bell will have a keeper here. Go to the Gates. Hear them out, every one, and bring home the quiet. Companions will meet thee, lad; each hath a sorrow of their own, and each shall be called away in time by a road that is theirs alone.'"},
	{"art": "road", "title": "XXIV. The Long Road",
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
	layer_a.duration = _dur(0)
	layer_b.modulate.a = 0.0


func _dur(i: int) -> float:
	var n: int = PLATES[i].text.length()
	return 1.5 + n / CPS + 5.0 + n / 28.0


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
		layer_b.duration = _dur(idx + 1)
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
		layer_a.duration = _dur(idx)
		layer_a.t = t
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
	_frame()
	ui.draw_rect(Rect2(0, 0, 1920, 100), Color(0, 0, 0, 0.92))
	ui.draw_rect(Rect2(0, 770, 1920, 310), Color(0, 0, 0, 0.88))
	ui.draw_rect(Rect2(0, 770, 1920, 2), Color(0.78, 0.62, 0.3, 0.7))
	ui.draw_string(font, Vector2(0, 66), pl.title, HORIZONTAL_ALIGNMENT_CENTER, 1920, 44, Color(0.92, 0.82, 0.55, fa))
	var full: String = pl.text
	ui.draw_multiline_string(font, Vector2(180, 835), full.substr(0, int(typed)), HORIZONTAL_ALIGNMENT_LEFT, 1560, 32, 8, Color(0.9, 0.88, 0.94, fa))
	ui.draw_string(font, Vector2(0, 1056), "Enter: complete / next    Shift: hasten    Esc: skip    (%d / %d)" % [idx + 1, PLATES.size()], HORIZONTAL_ALIGNMENT_RIGHT, 1860, 20, Color(0.7, 0.7, 0.8, 0.6))
	var progress := clampf(t / d, 0.0, 1.0)
	ui.draw_line(Vector2(180, 1008), Vector2(1740, 1008), Color(0.55, 0.44, 0.26, 0.2), 1.0)
	ui.draw_line(Vector2(180, 1008), Vector2(180 + 1560 * progress, 1008), Color(0.72, 0.58, 0.34, 0.6), 2.0)


func _frame() -> void:
	var gold := Color(0.78, 0.62, 0.3, 0.85)
	var soft := Color(gold, 0.45)
	var x0 := 22.0
	var x1 := 1898.0
	var y0 := 108.0
	var y1 := 764.0
	ui.draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), gold, false, 3.0)
	ui.draw_rect(Rect2(x0 + 9, y0 + 9, x1 - x0 - 18, y1 - y0 - 18), soft, false, 1.5)
	for sx in 2:
		for sy in 2:
			var cx := x0 if sx == 0 else x1
			var cy := y0 if sy == 0 else y1
			var dx := 1.0 if sx == 0 else -1.0
			var dy := 1.0 if sy == 0 else -1.0
			var c := Vector2(cx + dx * 46.0, cy + dy * 46.0)
			for k in 4:
				var a := k * TAU / 4.0 + PI / 4.0
				ui.draw_arc(c + Vector2(cos(a), sin(a)) * 11.0, 11.0, 0, TAU, 14, gold, 2.0)
			ui.draw_circle(c, 4.0, gold)
			ui.draw_line(Vector2(cx, cy + dy * 46.0), Vector2(cx + dx * 120.0, cy + dy * 46.0), soft, 1.5)
			ui.draw_line(Vector2(cx + dx * 46.0, cy), Vector2(cx + dx * 46.0, cy + dy * 120.0), soft, 1.5)
			var tip := Vector2(cx + dx * 150.0, cy)
			ui.draw_polyline(PackedVector2Array([Vector2(cx + dx * 96.0, cy), Vector2(cx + dx * 123.0, cy + dy * 22.0), tip]), gold, 2.0)
			ui.draw_polyline(PackedVector2Array([Vector2(cx, cy + dy * 96.0), Vector2(cx + dx * 22.0, cy + dy * 123.0), Vector2(cx, cy + dy * 150.0)]), gold, 2.0)
	for sy in 2:
		var ey := y0 if sy == 0 else y1
		var dy := 1.0 if sy == 0 else -1.0
		ui.draw_polyline(PackedVector2Array([Vector2(900, ey), Vector2(930, ey + dy * 30.0), Vector2(960, ey + dy * 58.0), Vector2(990, ey + dy * 30.0), Vector2(1020, ey)]), gold, 2.5)
		ui.draw_polyline(PackedVector2Array([Vector2(924, ey), Vector2(960, ey + dy * 38.0), Vector2(996, ey)]), soft, 1.5)
		ui.draw_circle(Vector2(960, ey + dy * 66.0), 4.0, gold)
		for k in 6:
			var fx := 300.0 + k * 100.0
			if k >= 3:
				fx += 420.0
			ui.draw_circle(Vector2(fx, ey + dy * 4.0), 3.0, soft)
