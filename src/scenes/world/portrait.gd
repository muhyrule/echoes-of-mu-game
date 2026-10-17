extends Node2D
## Original, separately drawn pixel-scale busts rather than magnified walking sprites.

const Art = preload("res://src/core/art.gd")

var hero := "mu"
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var pal: Dictionary = {"mu": Art.PAL_MU, "isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}[hero]
	pal = Gear.styled(hero, pal)
	var skin: Color = pal.skin
	var hair: Color = pal.hair
	var coat: Color = pal.coat
	var accent: Color = pal.accent
	var ink := Color("101923")
	var gold := Color("c4a66d")
	var breath := snappedf(sin(t * 1.6) * 0.4, 0.5)
	var blink := fposmod(t, 4.8) < 0.13
	draw_rect(Rect2(-44, -71, 88, 78), Color("18232b"))
	for line in 18:
		draw_rect(Rect2(-42, -69 + line * 4, 84, 2), Color("1d2b34"))
	for side in [-1, 1]:
		draw_line(Vector2(side * 40, -66), Vector2(side * 40, 3), gold.darkened(0.6), 1)
		draw_rect(Rect2(side * 39 - 1, -67, 2, 2), gold)
	draw_colored_polygon(PackedVector2Array([Vector2(-36, 4), Vector2(-34, -11 + breath), Vector2(-15, -24), Vector2(14, -24), Vector2(34, -11 + breath), Vector2(37, 4)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-33, 4), Vector2(-31, -10 + breath), Vector2(-13, -21), Vector2(11, -21), Vector2(31, -10 + breath), Vector2(33, 4)]), coat)
	draw_colored_polygon(PackedVector2Array([Vector2(9, -20), Vector2(30, -10 + breath), Vector2(33, 4), Vector2(17, 4)]), coat.darkened(0.35))
	for seam in 5:
		draw_line(Vector2(-27 + seam * 11, -5), Vector2(-29 + seam * 12, 4), coat.lightened(0.18), 1)
	draw_rect(Rect2(-8, -29, 17, 15), skin.darkened(0.3))
	if hero in ["mu", "wren"]:
		draw_colored_polygon(PackedVector2Array([Vector2(-24, -24), Vector2(-23, -52), Vector2(-16, -65), Vector2(-6, -69), Vector2(12, -67), Vector2(23, -54), Vector2(24, -22), Vector2(16, -16), Vector2(-17, -16)]), ink)
		draw_colored_polygon(PackedVector2Array([Vector2(-21, -24), Vector2(-20, -51), Vector2(-14, -62), Vector2(-5, -66), Vector2(11, -64), Vector2(20, -53), Vector2(21, -24), Vector2(15, -19), Vector2(-16, -19)]), coat.lightened(0.16))
		for seam in 4:
			draw_rect(Rect2(-19 + seam, -51 - seam * 3, 1, 10), coat.lightened(0.32))
	elif hero == "isolde":
		draw_colored_polygon(PackedVector2Array([Vector2(-20, -27), Vector2(-20, -52), Vector2(-13, -64), Vector2(5, -67), Vector2(18, -60), Vector2(22, -42), Vector2(17, -20)]), hair.darkened(0.35))
		for braid in 9:
			var bx := -19.0 + (braid % 2)
			draw_rect(Rect2(bx, -39 + braid * 4, 5, 5), hair.darkened(0.15))
			draw_rect(Rect2(bx, -39 + braid * 4, 3, 2), hair.lightened(0.3))
		draw_rect(Rect2(-19, -4, 5, 2), gold)
	else:
		draw_rect(Rect2(-17, -59, 33, 29), hair.darkened(0.4))
	var face := PackedVector2Array([Vector2(-14, -50), Vector2(-10, -59), Vector2(1, -62), Vector2(12, -57), Vector2(16, -46), Vector2(13, -31), Vector2(6, -24), Vector2(-5, -25), Vector2(-12, -32)])
	draw_colored_polygon(face, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(9, -57), Vector2(16, -46), Vector2(13, -31), Vector2(6, -24), Vector2(4, -33), Vector2(8, -43)]), skin.darkened(0.3))
	draw_rect(Rect2(-13, -47, 3, 12), skin.lightened(0.12))
	draw_rect(Rect2(-11, -36, 6, 3), skin.darkened(0.08))
	draw_rect(Rect2(6, -36, 5, 3), skin.darkened(0.2))
	draw_rect(Rect2(-2, -43, 2, 9), skin.lightened(0.32))
	draw_rect(Rect2(0, -35, 3, 2), skin.darkened(0.35))
	draw_rect(Rect2(-4, -30, 9, 1), skin.darkened(0.48))
	draw_rect(Rect2(-2, -28, 5, 1), skin.lightened(0.18))
	for eye in [-7, 7]:
		draw_rect(Rect2(eye - 3, -47, 6, 2), hair.darkened(0.55))
		draw_rect(Rect2(eye - 2, -44, 5, 1 if blink else 3), ink)
		if not blink:
			draw_rect(Rect2(eye - 1, -44, 3, 1), Color("d5cfb5"))
			draw_rect(Rect2(eye, -44, 1, 2), Color("607e7c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -49), Vector2(-14, -57), Vector2(-6, -63), Vector2(6, -62), Vector2(14, -55), Vector2(15, -50), Vector2(5, -55), Vector2(-3, -52), Vector2(-2, -57), Vector2(-11, -50)]), hair)
	for strand in 7:
		var hx := -11 + strand * 3
		draw_rect(Rect2(hx, -58 + absi(strand - 3), 1, 5), hair.lightened(0.28))
	draw_rect(Rect2(-19, -20, 38, 5), accent.darkened(0.25))
	draw_rect(Rect2(-17, -20, 33, 1), accent.lightened(0.35))
	if hero == "corvin":
		draw_colored_polygon(PackedVector2Array([Vector2(-11, -34), Vector2(-4, -32), Vector2(2, -33), Vector2(12, -34), Vector2(10, -23), Vector2(1, -18), Vector2(-8, -24)]), hair.darkened(0.2))
		for strand in 7:
			draw_rect(Rect2(-8 + strand * 3, -30, 1, 6 - absi(strand - 3)), hair.lightened(0.2))
		draw_rect(Rect2(3, -48, 12, 11), gold)
		draw_rect(Rect2(5, -46, 8, 7), Color("4c747b"))
		draw_rect(Rect2(6, -45, 3, 1), Color("c1dde0"))
		draw_line(Vector2(15, -41), Vector2(18, -16), gold.darkened(0.3), 1)
	elif hero == "isolde":
		draw_rect(Rect2(-32, -11, 13, 6), Color("697d7d"))
		draw_rect(Rect2(-32, -11, 13, 1), Color("a6b6ad"))
		draw_rect(Rect2(-4, -12, 3, 13), gold)
		draw_rect(Rect2(-8, -8, 11, 3), gold)
	elif hero == "wren":
		draw_line(Vector2(-26, -13), Vector2(22, 4), gold.darkened(0.35), 3)
		for buckle in 4:
			draw_rect(Rect2(-20 + buckle * 10, -12 + buckle * 4, 3, 2), gold)
	else:
		draw_rect(Rect2(-6, -13, 12, 8), ink)
		draw_rect(Rect2(-5, -12, 10, 6), gold)
		draw_rect(Rect2(-1, -14, 2, 11), Color("e8d6a1"))
		draw_rect(Rect2(-3, -10, 6, 2), Color("e8d6a1"))
	draw_rect(Rect2(-44, 5, 88, 2), ink)
