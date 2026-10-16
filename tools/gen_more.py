"""Adds extra townsfolk and street dressing to the generated towns and interiors."""
import json
import os

import gen_towns as G
import towns_text2  # noqa: F401  (merges its lines into DIALOGUE)

ROOT = G.ROOT


def load(name):
    with open(os.path.join(ROOT, "data", "maps", name + ".json")) as f:
        meta = json.load(f)
    rows = meta.pop("ascii")
    m = G.Map(name, len(rows[0]), len(rows), meta["theme"], meta["title"], meta["subtitle"], meta["music"])
    m.g = [list(r) for r in rows]
    for k in ("npcs", "doors", "objects", "triggers"):
        meta.setdefault(k, {})
    m.meta = meta
    used = {c for r in m.g for c in r}
    m.pool = [c for c in G.POOL if c not in used]
    m.after_flag = ""
    return m


def near(m, x, y, avoid=()):
    for r in range(0, 12):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                xx, yy = x + dx, y + dy
                if G.free(m, xx, yy) and (xx, yy) not in avoid:
                    return xx, yy
    raise RuntimeError("no space near %d,%d in %s" % (x, y, m.name))


def add(m, x, y, id, pal, wander=3):
    x, y = near(m, x, y)
    m.npc(x, y, id, pal, wander=wander)


P = G.pal

EDIN = [
    (30, 9, "edin_cormac", P("#5a2a2e", "#c0a070", "#4a3a2a", style="beard", item="none"), 4),
    (16, 24, "edin_jean", P("#6a5a6a", "#e0d0b0", "#7a5a3a", style="braid", item="none"), 4),
    (47, 24, "edin_ailsa", P("#7a3a4a", "#c0a070", "#2a1a1a", style="braid", item="none"), 3),
    (50, 7, "edin_dougal", P("#2c3a5a", "#b0b0b8", "#6a4a2a", item="none", mail=True), 1),
    (94, 11, "edin_maisie", P("#4a5a6a", "#c08a4a", "#8a5a3a", style="braid", item="none"), 5),
    (98, 21, "edin_magnus", P("#3a3a3a", "#8a7436", "#b8b8c0", style="beard", item="none", mail=True), 2),
    (8, 23, "edin_ina", P("#5a6a4a", "#e0d0b0", "#a05a2a", style="braid", item="none"), 5),
    (76, 36, "edin_fraser", P("#3a2a22", "#8a8d98", "#2a2a2e", style="beard", item="none"), 5),
    (90, 31, "edin_beatrix", P("#22212c", "#6a6a74", "#c8c8d0", style="braid", item="none"), 1),
    (108, 21, "edin_anselm", P("#4a3a2a", "#c0a070", "#8a8a90", style="beard", item="none", hood=True), 2),
]
PRAGUE = [
    (50, 7, "pra_karel", P("#2a3a5a", "#b0b0b8", "#4a3a2a", style="beard", item="none", mail=True), 4),
    (30, 9, "pra_dorota", P("#6a3a50", "#e0b0c0", "#6a3a24", style="braid", item="none"), 4),
    (48, 25, "pra_matyas", P("#5a2a4a", "#c0a070", "#2a1a1a", item="none"), 3),
    (96, 11, "pra_rebeka", P("#2a3a4a", "#c8c0b0", "#2a2a32", style="braid", item="none"), 2),
    (60, 13, "pra_pavel", P("#3a3a5a", "#d6b25a", "#7a5a3a", item="none"), 3),
    (16, 24, "pra_zora", P("#5a3a2a", "#c0334f", "#2a1a1a", style="braid", item="none"), 4),
    (100, 21, "pra_bohdan", P("#4a4a3a", "#8a7436", "#6a6a74", style="beard", item="none"), 3),
    (40, 36, "pra_emil", P("#3a3a44", "#d6b25a", "#4a3a2a", item="none"), 6),
    (10, 22, "pra_vaclav", P("#4a3a32", "#8a7a62", "#6a4a2a", item="none"), 5),
    (92, 31, "pra_ludmila", P("#22212c", "#6a6a74", "#b8b8c0", style="braid", item="none"), 1),
    (76, 36, "pra_agnes", P("#2a2a32", "#c8c0b0", "#b8b8c0", style="braid", item="none", hood=True), 3),
]
INTERIOR = {
    "drowned_candle": ("edin_in_candle", P("#4a3a2a", "#8a7436", "#5a3a24", style="beard", item="none")),
    "archive": ("edin_in_archive", P("#2c3a4a", "#c0a070", "#8a8a90", style="beard", item="none")),
    "mason_yard": ("edin_in_mason", P("#5a4a3a", "#8a8d98", "#6a4a2a", item="none")),
    "chandlery": ("edin_in_chandlery", P("#6a3a3a", "#e0d0b0", "#2a1a1a", style="braid", item="none")),
    "marsh_cottage": ("edin_in_cottage", P("#5a5a6a", "#c0a070", "#b8b8c0", style="braid", item="none")),
    "apothecary": ("edin_in_apoth", P("#4a4a3a", "#8a7a62", "#6a5a3a", item="none")),
    "armoury": ("edin_in_armoury", P("#2c3a5a", "#b0b0b8", "#4a3a2a", item="none")),
    "weaponsmith": ("edin_in_forge", P("#3a2a22", "#a0a0a8", "#7a3a24", item="none")),
    "lantern_inn": ("edin_in_inn", P("#5a3a5a", "#c0a070", "#2a1a1a", style="braid", item="none")),
    "raven_tavern": ("pra_in_tavern", P("#4a3a2a", "#8a7436", "#6a4a2a", style="beard", item="none")),
    "orloj_lodge": ("pra_in_lodge", P("#3a3a5a", "#d6b25a", "#8a8a90", style="beard", item="none")),
    "alchemist": ("pra_in_alchemist", P("#4a2a4a", "#c0a070", "#2a1a1a", item="none")),
    "cartographer": ("pra_in_cartographer", P("#2a4a4a", "#c0a070", "#6a3a24", style="braid", item="none")),
    "bakery": ("pra_in_bakery", P("#6a5a3a", "#e0d0b0", "#3a2a1a", style="braid", item="none")),
    "silver_retort": ("pra_in_retort", P("#3a3a5a", "#c0a070", "#5a4a3a", item="none")),
    "guild_armoury": ("pra_in_guild", P("#2c3a5a", "#b0b0b8", "#6a4a2a", item="none", mail=True)),
    "bohemian_steel": ("pra_in_steel", P("#4a3a30", "#a0a0a8", "#2a2a2e", style="beard", item="none")),
    "rose_inn": ("pra_in_rose", P("#6a3a50", "#e0b0c0", "#4a2a1a", style="braid", item="none")),
}


def dress(m, rng_seed):
    """Candles beside every door, barrels at building corners, extra lamps and market stalls."""
    doors = [(x, y) for y, r in enumerate(m.g) for x, c in enumerate(r) if c in m.meta["doors"] and m.meta["doors"][c]["style"] == "door"]
    for x, y in doors:
        for dx in (-2, 2):
            if G.free(m, x + dx, y + 1):
                m.put(x + dx, y + 1, "c")
    corners = [(5, 9), (16, 9), (35, 9), (68, 9), (86, 9), (98, 9), (5, 20), (17, 20), (32, 20), (68, 20), (80, 20)]
    for i, (x, y) in enumerate(corners):
        for k in range(2):
            if G.free(m, x + k, y):
                m.decorate(x + k, y, "barrel" if (i + k) % 2 else "crate")
    for x in range(14, 100, 16):
        for y in (22, 38):
            if G.free(m, x, y):
                m.put(x, y, "l")
    G.market(m, 14, 33, 2)
    G.market(m, 90, 22, 2)


def main():
    for name, lst in (("edinburgh", EDIN), ("prague_town", PRAGUE)):
        m = load(name)
        for x, y, id, pal, wander in lst:
            add(m, x, y, id, pal, wander)
        dress(m, 0)
        m.save()
    for name, (id, pal) in INTERIOR.items():
        m = load(name)
        add(m, m.w // 2 + 4, m.h // 2 + 1, id, pal, wander=2)
        m.save()


if __name__ == "__main__":
    main()
