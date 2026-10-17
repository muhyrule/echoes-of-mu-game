extends RefCounted
## Original 32x32 material tiles, cached once and drawn at half-unit pixel density.

const SIZE := 32
const PALETTES := {
	"chapel": ["514d49", "827664", "242a30"],
	"vault": ["39474a", "607177", "1c252c"],
	"prague": ["655c49", "968467", "2b2b2b"],
	"town_e": ["4a5660", "79828b", "242e38"],
	"town_p": ["6b5c4d", "9d8868", "342e2b"],
	"wood": ["62462d", "a07c4b", "2f241e"],
	"keep": ["542c35", "87505a", "291d26"],
	"ossuary": ["625d50", "9e957e", "292b2b"],
	"cliff": ["485762", "7d9199", "232e39"],
	"lazaretto": ["505d42", "839369", "252f26"],
	"cave": ["51372f", "89624a", "291d20"],
	"roof": ["929698", "d7d8d4", "3a4249"],
	"plaster": ["b3b0a7", "e4dfcd", "686b65"],
	"water": ["244a55", "608e93", "142e3c"],
}

static var cache: Dictionary = {}


static func noise(x: int, y: int, seed_value: int) -> int:
	return posmod((x * 73856093) ^ (y * 19349663) ^ (seed_value * 83492791), 65521)


static func texture(material: String, variant: int) -> Texture2D:
	assert(PALETTES.has(material), "Unknown pixel material: " + material)
	var key := "%s:%d" % [material, posmod(variant, 8)]
	if cache.has(key):
		return cache[key]
	var image := image_for(material, posmod(variant, 8))
	var result := ImageTexture.create_from_image(image)
	cache[key] = result
	return result


static func image_for(material: String, variant: int) -> Image:
	assert(PALETTES.has(material), "Unknown pixel material: " + material)
	var palette: Array = PALETTES[material]
	var base := Color(palette[0])
	var light := Color(palette[1])
	var deep := Color(palette[2])
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var grain := noise(x, y, variant)
			var row := y / 8
			var bx := posmod(x + (row % 2) * 8, 16)
			var by := y % 8
			var width := 16
			var height := 8
			if material in ["chapel", "prague", "vault", "ossuary", "keep"]:
				bx = x % 16
				by = y % 16
				height = 16
			elif material == "wood":
				bx = posmod(x + (y / 8 % 2) * 11 + variant * 3, 32)
				width = 32
			elif material == "roof":
				bx = posmod(x + (row % 2) * 4, 8)
				width = 8
			elif material == "plaster" or material == "water":
				bx = 8
				by = 8
			elif material == "cave" or material == "cliff":
				bx = posmod(x + (y / 16 % 2) * 11 + variant, 32)
				by = y % 16
				width = 32
				height = 16
			var cell := noise((x + variant * 32) / 16, y / height, variant)
			var col := base.lerp(light, (cell % 5) * 0.045)
			if bx == 0 or by == 0:
				col = deep
			elif bx == 1 or by == 1:
				col = col.lerp(light, 0.45)
			elif bx == width - 1 or by == height - 1:
				col = col.lerp(deep, 0.55)
			elif grain % 9 == 0:
				col = col.lerp(light, 0.12)
			elif grain % 7 == 0:
				col = col.lerp(deep, 0.15)
			if material == "wood" and by > 1 and by < 7:
				var line := posmod(y * 5 + x / 4 + variant * 3, 7)
				if line == 0:
					col = col.lerp(deep, 0.28)
				if bx == 3 and (by == 2 or by == 6):
					col = deep.lightened(0.08)
			if material == "roof" and by >= 5 and (bx <= by - 5 or bx >= 12 - by):
				col = deep
			if material == "plaster" and variant % 3 == 0 and x == 10 + y / 6 and y > 9:
				col = col.lerp(deep, 0.4)
			if material == "water":
				var wave := posmod(y + int(sin((x + variant * 4) * TAU / 32) * 2), 8)
				col = base.lerp(deep, 0.2)
				if wave == 0 and x % 13 < 7:
					col = base.lerp(light, 0.4)
				elif wave == 1:
					col = base.lerp(deep, 0.35)
				elif grain % 31 == 0:
					col = base.lerp(light, 0.15)
			if material in ["chapel", "prague"] and x >= 13 and x <= 18 and y >= 13 and y <= 18:
				var edge := absi(x - 16) + absi(y - 16)
				if edge == 3:
					col = Color("ad9161")
				elif edge < 3:
					col = deep
			if material in ["vault", "town_e", "lazaretto"] and grain % 113 == 0 and by > 2:
				col = Color("4d6242")
			if material == "cave" and variant == 3 and abs(y - 17 - int(sin(x * 0.4) * 3)) <= 1:
				col = Color("a04e29") if x % 3 else Color("e69943")
			image.set_pixel(x, y, col)
	return image


static func floor_tile(c: CanvasItem, r: Rect2, material: String, x: int, y: int, tint := Color.WHITE) -> void:
	var variant := noise(x, y, 41) % 8
	c.draw_texture_rect(texture(material, variant), r, false, tint)
