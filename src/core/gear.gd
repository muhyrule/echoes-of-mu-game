class_name Gear
extends RefCounted
## Original gear, supplies and the stat maths that turn them into gameplay.

const HEROES := ["mu", "isolde", "wren", "corvin"]
const HERO_NAMES := {"mu": "Mu", "isolde": "Isolde", "wren": "Wren", "corvin": "Corvin"}
const WEAPON_CLASS := {"mu": "Sword", "isolde": "Maul", "wren": "Daggers", "corvin": "Clockwork"}
const ARMOR_CLASS := {"mu": "Mail", "isolde": "Plate", "wren": "Leathers", "corvin": "Robes"}
const START_GEAR := {
	"mu": {"weapon": "mu_w0", "armor": "mu_a0"},
	"isolde": {"weapon": "iso_w0", "armor": "iso_a0"},
	"wren": {"weapon": "wre_w0", "armor": "wre_a0"},
	"corvin": {"weapon": "cor_w0", "armor": "cor_a0"},
}

# hero, slot, tier, atk, def, hp, price
const ITEMS := {
	"mu_w0": {"name": "Gravewarden's Blade", "hero": "mu", "slot": "weapon", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Plain steel, honestly kept."},
	"mu_w1": {"name": "Tallow-Edge Longsword", "hero": "mu", "slot": "weapon", "tier": 1, "atk": 1, "def": 0, "hp": 0, "price": 60, "desc": "Balanced, with a fuller for the wind."},
	"mu_w2": {"name": "Vesper Brand", "hero": "mu", "slot": "weapon", "tier": 2, "atk": 2, "def": 0, "hp": 0, "price": 150, "desc": "Blackened and bell-tempered."},
	"mu_w3": {"name": "Dawnbreaker of Mu", "hero": "mu", "slot": "weapon", "tier": 3, "atk": 3, "def": 0, "hp": 0, "price": 320, "desc": "Pale fire runs along the spine."},
	"mu_a0": {"name": "Pilgrim's Hauberk", "hero": "mu", "slot": "armor", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Patched mail over a wool coat."},
	"mu_a1": {"name": "Lamplighter's Mail", "hero": "mu", "slot": "armor", "tier": 1, "atk": 0, "def": 1, "hp": 1, "price": 70, "desc": "Riveted rings, oiled against the damp."},
	"mu_a2": {"name": "Thornwrought Brigandine", "hero": "mu", "slot": "armor", "tier": 2, "atk": 0, "def": 2, "hp": 2, "price": 170, "desc": "Plates riveted under dark cloth."},
	"mu_a3": {"name": "Cathedral Plate", "hero": "mu", "slot": "armor", "tier": 3, "atk": 0, "def": 3, "hp": 3, "price": 340, "desc": "Engraved with a litany nobody reads."},
	"iso_w0": {"name": "Parish Maul", "hero": "isolde", "slot": "weapon", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "A mallet meant for bells."},
	"iso_w1": {"name": "Iron-Bound Maul", "hero": "isolde", "slot": "weapon", "tier": 1, "atk": 2, "def": 0, "hp": 0, "price": 65, "desc": "Heavy enough to quiet a doubt."},
	"iso_w2": {"name": "Sexton's Hammer", "hero": "isolde", "slot": "weapon", "tier": 2, "atk": 4, "def": 0, "hp": 0, "price": 160, "desc": "Rings like a funeral bell."},
	"iso_w3": {"name": "Verdict", "hero": "isolde", "slot": "weapon", "tier": 3, "atk": 6, "def": 0, "hp": 0, "price": 330, "desc": "It settles arguments permanently."},
	"iso_a0": {"name": "Chapel Cuirass", "hero": "isolde", "slot": "armor", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Dented in all the right places."},
	"iso_a1": {"name": "Bulwark Plate", "hero": "isolde", "slot": "armor", "tier": 1, "atk": 0, "def": 1, "hp": 0, "price": 75, "desc": "A wall you can breathe in."},
	"iso_a2": {"name": "Reliquary Plate", "hero": "isolde", "slot": "armor", "tier": 2, "atk": 0, "def": 2, "hp": 1, "price": 180, "desc": "Saints' bones sealed in the pauldrons."},
	"iso_a3": {"name": "Aegis of the Vigil", "hero": "isolde", "slot": "armor", "tier": 3, "atk": 0, "def": 3, "hp": 1, "price": 350, "desc": "No night has yet got past it."},
	"wre_w0": {"name": "Gutter Knives", "hero": "wren", "slot": "weapon", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Two blades, three uses."},
	"wre_w1": {"name": "Needle Daggers", "hero": "wren", "slot": "weapon", "tier": 1, "atk": 1, "def": 0, "hp": 0, "price": 60, "desc": "Quick, and quieter than breath."},
	"wre_w2": {"name": "Rook-Feather Pair", "hero": "wren", "slot": "weapon", "tier": 2, "atk": 2, "def": 0, "hp": 0, "price": 155, "desc": "Fluted for a clean cut."},
	"wre_w3": {"name": "Twin Whispers", "hero": "wren", "slot": "weapon", "tier": 3, "atk": 3, "def": 0, "hp": 0, "price": 320, "desc": "You hear them only afterwards."},
	"wre_a0": {"name": "Rooftop Leathers", "hero": "wren", "slot": "armor", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Supple, soot-black, silent."},
	"wre_a1": {"name": "Cutpurse's Jerkin", "hero": "wren", "slot": "armor", "tier": 1, "atk": 0, "def": 1, "hp": 0, "price": 65, "desc": "Hidden pockets, mostly pockets."},
	"wre_a2": {"name": "Nightjar Leathers", "hero": "wren", "slot": "armor", "tier": 2, "atk": 0, "def": 2, "hp": 0, "price": 165, "desc": "Waxed to shed rain and questions."},
	"wre_a3": {"name": "Shade-Weave Cloak", "hero": "wren", "slot": "armor", "tier": 3, "atk": 0, "def": 3, "hp": 0, "price": 335, "desc": "Woven from something that is not light."},
	"cor_w0": {"name": "Winding Key Staff", "hero": "corvin", "slot": "weapon", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "A brass key longer than a man."},
	"cor_w1": {"name": "Escapement Rod", "hero": "corvin", "slot": "weapon", "tier": 1, "atk": 1, "def": 0, "hp": 0, "price": 70, "desc": "Ticks when danger is near."},
	"cor_w2": {"name": "Orrery Staff", "hero": "corvin", "slot": "weapon", "tier": 2, "atk": 2, "def": 0, "hp": 0, "price": 165, "desc": "Small planets orbit the head."},
	"cor_w3": {"name": "Astrolabe of Hours", "hero": "corvin", "slot": "weapon", "tier": 3, "atk": 3, "def": 0, "hp": 0, "price": 330, "desc": "It knows when you will need it."},
	"cor_a0": {"name": "Horologist's Robe", "hero": "corvin", "slot": "armor", "tier": 0, "atk": 0, "def": 0, "hp": 0, "price": 0, "desc": "Ink-stained, brass-buttoned."},
	"cor_a1": {"name": "Gearwoven Robe", "hero": "corvin", "slot": "armor", "tier": 1, "atk": 0, "def": 0, "hp": 1, "price": 70, "desc": "Tiny cogs turn in the hem."},
	"cor_a2": {"name": "Brass-Ribbed Mantle", "hero": "corvin", "slot": "armor", "tier": 2, "atk": 0, "def": 1, "hp": 2, "price": 170, "desc": "A rib cage of springs."},
	"cor_a3": {"name": "Regulator's Vestments", "hero": "corvin", "slot": "armor", "tier": 3, "atk": 0, "def": 1, "hp": 3, "price": 340, "desc": "Keeps good time with the heart."},
	"mu_w_f": {"name": "Warden's Own Blade", "hero": "mu", "slot": "weapon", "tier": 9, "atk": 2, "def": 0, "hp": 1, "price": 0, "desc": "Taken from the vault's first guardian. Still humming."},
	"mu_a_f": {"name": "Ossuary Hauberk", "hero": "mu", "slot": "armor", "tier": 9, "atk": 0, "def": 2, "hp": 2, "price": 0, "desc": "Bone-white rings, strangely light."},
	"iso_w_f": {"name": "Tomas's Bellmaul", "hero": "isolde", "slot": "weapon", "tier": 9, "atk": 4, "def": 0, "hp": 0, "price": 0, "desc": "Her brother's bell-hammer, bound in blue thread."},
	"iso_a_f": {"name": "Founder's Plate", "hero": "isolde", "slot": "armor", "tier": 9, "atk": 0, "def": 2, "hp": 1, "price": 0, "desc": "Older than the Old Town itself."},
	"wre_w_f": {"name": "Key-Shaped Blades", "hero": "wren", "slot": "weapon", "tier": 9, "atk": 2, "def": 0, "hp": 0, "price": 0, "desc": "They open more than locks."},
	"cor_a_f": {"name": "Winder's Mantle", "hero": "corvin", "slot": "armor", "tier": 9, "atk": 0, "def": 1, "hp": 2, "price": 0, "desc": "Thirty years of clockwork oil in the weave."},
	"cor_w_f": {"name": "Heartspring Staff", "hero": "corvin", "slot": "weapon", "tier": 9, "atk": 2, "def": 0, "hp": 1, "price": 0, "desc": "Wound tight, it never quite runs down."},
}

const SUPPLIES := {
	"tonic": {"name": "Healing Tonic", "price": 12, "key": "1", "desc": "Restores 3 hearts."},
	"elixir": {"name": "Grand Elixir", "price": 30, "key": "2", "desc": "Restores all hearts."},
	"candle": {"name": "Warding Candle", "price": 20, "key": "3", "desc": "Ward against harm for 8 seconds."},
}

const PUB_MENU := [
	{"id": "ale", "name": "Pint of Ale", "price": 3, "heal": 1, "desc": "Warms the hands. +1 heart."},
	{"id": "stew", "name": "Mutton Stew", "price": 6, "heal": 3, "desc": "Thick, salty, honest. +3 hearts."},
]

const INN_MENU := [
	{"id": "meal", "name": "Hot Meal", "price": 5, "heal": 2, "desc": "Bread, broth, a candle. +2 hearts."},
	{"id": "rest", "name": "Rest the Night", "price": 15, "heal": 99, "desc": "A bed till dawn. Full health, and the game saves."},
]


static func owned_for(hero: String, slot: String) -> Array:
	var out: Array = [START_GEAR[hero][slot]]
	for id in GameState.owned:
		if ITEMS.has(id) and ITEMS[id].hero == hero and ITEMS[id].slot == slot and id not in out:
			out.append(id)
	return out


static func tier_of(hero: String) -> int:
	var d: Dictionary = ITEMS[equipped(hero, "armor")]
	return int(d.tier) if d.tier < 9 else clampi(int(d.def) + 1, 1, 3)


static func styled(hero: String, pal: Dictionary) -> Dictionary:
	var t := tier_of(hero)
	if t <= 0:
		return pal
	var p := pal.duplicate()
	if t >= 2:
		p["mail"] = true
	var steel := Color("8a8fa0")
	var gold := Color("c8a050")
	if t == 1:
		p["accent"] = Color(p.accent).lightened(0.15)
	elif t == 2:
		p["coat"] = Color(p.coat).lerp(steel, 0.28)
		p["accent"] = gold.darkened(0.15)
	else:
		p["coat"] = Color(p.coat).lerp(steel, 0.5)
		p["accent"] = gold
	return p


static func equipped(hero: String, slot: String) -> String:
	return GameState.equip.get(hero, {}).get(slot, START_GEAR[hero][slot])


static func item(id: String) -> Dictionary:
	return ITEMS[id]


static func stock(hero: String, slot: String, max_tier: int) -> Array:
	var out: Array = []
	for id in ITEMS:
		var d: Dictionary = ITEMS[id]
		if d.hero == hero and d.slot == slot and d.tier >= 1 and d.tier <= max_tier:
			out.append(id)
	out.sort_custom(func(a, b): return ITEMS[a].tier < ITEMS[b].tier)
	return out


static func active_heroes() -> Array:
	var out: Array = ["mu"]
	for p in GameState.party:
		if p in HEROES and p != "mu":
			out.append(p)
	return out


static func _sum(hero: String, key: String) -> int:
	return int(ITEMS[equipped(hero, "weapon")][key]) + int(ITEMS[equipped(hero, "armor")][key])


static func atk_bonus() -> int:
	var v := int(ITEMS[equipped("mu", "weapon")].atk)
	if "isolde" in GameState.party:
		v += int(ITEMS[equipped("isolde", "weapon")].atk) / 3
	if "wren" in GameState.party:
		v += int(ITEMS[equipped("wren", "weapon")].atk) / 2
	if "corvin" in GameState.party:
		v += int(ITEMS[equipped("corvin", "weapon")].atk) / 2
	return v


static func def_total() -> int:
	var v := _sum("mu", "def")
	if "isolde" in GameState.party:
		v += _sum("isolde", "def")
	if "wren" in GameState.party:
		v += _sum("wren", "def") / 2
	if "corvin" in GameState.party:
		v += _sum("corvin", "def")
	return v


static func hp_bonus() -> int:
	var v := _sum("mu", "hp")
	for h in ["isolde", "corvin"]:
		if h in GameState.party:
			v += _sum(h, "hp")
	return v


static func cooldown_mult() -> float:
	if "wren" in GameState.party:
		return 1.0 - 0.04 * float(_sum("wren", "atk") + _sum("wren", "def"))
	return 1.0


static func gold_mult() -> float:
	return 1.25 if "wren" in GameState.party else 1.0


static func summary(hero: String) -> String:
	return "ATK %d  DEF %d  HP %d" % [_sum(hero, "atk"), _sum(hero, "def"), _sum(hero, "hp")]
