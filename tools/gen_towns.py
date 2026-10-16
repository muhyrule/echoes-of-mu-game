#!/usr/bin/env python3
"""Generates the town and interior maps and data/dialogue_towns.json.

Run from the project root: python3 tools/gen_towns.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from towns_text import DIALOGUE, ITEMS, SECRETS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POOL = list("adefhijkmnpqstuvwyz") + list("O") + list("!*~^;:?()<>/") + list("αβγδεζηθικλμνξπρστυφχψω")
DOOR_CHARS = list("567890") + list("ΓΔΘΛΞΠΣΦΨΩ")


class Map:
    def __init__(self, name, w, h, theme, title, subtitle, music, wall="#"):
        self.name, self.w, self.h = name, w, h
        self.g = [[wall] * w for _ in range(h)]
        self.meta = {"theme": theme, "title": title, "subtitle": subtitle, "music": music,
                     "safe": True, "spawns": {"start": "@"}, "npcs": {}, "doors": {}, "objects": {},
                     "triggers": {}}
        self.pool = list(POOL)
        self.door_digits = list(DOOR_CHARS)
        self.kind_ch = {}
        self.decor = {}

    def rect(self, x, y, w, h, ch="."):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = ch

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def alloc(self):
        return self.pool.pop(0)

    def npc(self, x, y, id, pal, variants=None, face=(0, 1), hide_if=None, wander=0, shop=None, tier=2):
        ch = self.alloc()
        d = {"id": id, "pal": pal, "face": list(face)}
        vs = list(variants or [])
        if id + "_after" in DIALOGUE and not any(v["id"] == id + "_after" for v in vs):
            vs.insert(0, {"if": self.after_flag, "id": id + "_after"})
        if vs:
            d["variants"] = vs
        if hide_if:
            d["hide_if"] = hide_if
        if wander:
            d["wander"] = wander
        if shop:
            d["shop"] = shop
            d["tier"] = tier
        self.meta["npcs"][ch] = d
        self.put(x, y, ch)

    def obj(self, x, y, kind, id=None, reward=None):
        if not id and kind in self.kind_ch:
            self.put(x, y, self.kind_ch[kind])
            return
        ch = self.alloc()
        if not id:
            self.kind_ch[kind] = ch
        d = {"kind": kind}
        if id:
            d["id"] = id
            d["text"] = SECRETS[id]
            if id in ITEMS:
                d["item"] = ITEMS[id]
            d["reward"] = reward or ("relic" if id in ITEMS else "lore")
            if reward == "heal" and id in ITEMS:
                d["reward"] = "heal"
        d["empty"] = "You've already searched here."
        self.meta["objects"][ch] = d
        self.put(x, y, ch)

    def decorate(self, x, y, kind):
        ch = "%" if kind == "barrel" else "+"
        if ch not in self.meta["objects"]:
            self.meta["objects"][ch] = {"kind": kind, "empty": "Nothing but old stores and dust."}
            if ch in self.pool:
                self.pool.remove(ch)
        self.put(x, y, ch)

    def door(self, x, y, to, label, style="door", **extra):
        ch = self.door_digits.pop(0)
        d = {"map": to, "label": label, "style": style}
        d.update(extra)
        self.meta["doors"][ch] = d
        self.put(x, y, ch)

    def building(self, x, y, w, door_to=None, label="", rows=4):
        for yy in range(y, y + rows):
            for xx in range(x, x + w):
                self.g[yy][xx] = "H"
        if door_to:
            self.door(x + w // 2, y + rows - 1, door_to, label)

    def save(self):
        out = dict(self.meta)
        for k in ("npcs", "doors", "objects", "triggers"):
            if not out[k]:
                del out[k]
        out["ascii"] = ["".join(r) for r in self.g]
        with open(os.path.join(ROOT, "data", "maps", self.name + ".json"), "w") as f:
            json.dump(out, f, indent=1)
            f.write("\n")


def free(m, x, y):
    return 0 < x < m.w - 1 and 0 < y < m.h - 1 and m.g[y][x] == "."


def put_free(m, x, y, ch):
    if free(m, x, y):
        m.put(x, y, ch)


def rug(m, x0, y0, w, h):
    for yy in range(y0, y0 + h):
        for xx in range(x0, x0 + w):
            put_free(m, xx, yy, "R")


def table(m, x, y, n=2, chairs=True):
    for i in range(n):
        put_free(m, x + i, y, "T")
        if chairs:
            put_free(m, x + i, y - 1, "C")
            put_free(m, x + i, y + 1, "C")


def counter(m, x0, x1, y, gap=None):
    for x in range(x0, x1 + 1):
        if x != gap:
            put_free(m, x, y, "J")


def rack(m, x0, x1, y=2):
    for x in range(x0, x1 + 1):
        m.put(x, y, "F")


def auto_furnish(m):
    furnish(m, tables=[(4, m.h - 6, 2), (m.w - 7, m.h - 6, 2)], rugs=[(m.w // 2 - 5, m.h - 8, 10, 4)])


def furnish(m, tables=(), rugs=()):
    for r in rugs:
        rug(m, *r)
    for t in tables:
        table(m, *t)


def pal(coat, accent, hair, skin="#c4a083", style="short", **kw):
    d = {"coat": coat, "accent": accent, "hair": hair, "skin": skin, "style": style}
    d.update(kw)
    return d


def town(name, theme, title, sub, music, after_flag, back_spawn):
    m = Map(name, 112, 44, theme, title, sub, music)
    m.after_flag = after_flag
    m.rect(1, 3, 110, 40)
    m.meta["spawns"].update({"from_chapel": "$"})
    m.meta["exit"] = {"map": "chapel", "spawn": back_spawn}
    m.rect(53, 43, 6, 1, "E")
    m.put(56, 40, "$")
    m.put(57, 40, "@")
    for x in range(52, 61):
        m.put(x, 36, "1")
    return m


def street_lamps(m):
    for x in range(8, 106, 12):
        m.put(x, 10, "l")
        m.put(x, 34, "l")
    for y in range(6, 40, 6):
        m.put(51, y, "l")
        m.put(61, y, "l")


def market(m, x0, y0, n):
    for i in range(n):
        m.decorate(x0 + i * 3, y0, "crate" if i % 2 else "barrel")
        m.decorate(x0 + i * 3 + 1, y0, "barrel" if i % 2 else "crate")


def lamps(m, pts):
    for x, y in pts:
        m.put(x, y, "l")


def fence(m, x0, y0, x1, y1, gap):
    for x in range(x0, x1 + 1):
        m.put(x, y0, "=")
        m.put(x, y1, "=")
    for y in range(y0, y1 + 1):
        m.put(x0, y, "=")
        m.put(x1, y, "=")
    gx, gy = gap
    m.put(gx, gy, ".")


# ------------------------------------------------------------ interiors
def interior(name, title, sub, after_flag, town_map, w=30, h=18, music="inn"):
    m = Map(name, w, h, "interior", title, sub, music)
    m.after_flag = after_flag
    m.rect(1, 2, w - 2, h - 4)
    m.door(w // 2, h - 2, town_map, "Leave", style="inner")
    m.meta["spawns"]["start"] = "@"
    m.put(w // 2, h - 3, "@")
    return m


def shelves(m, x0, x1, y=2):
    for x in range(x0, x1 + 1):
        m.put(x, y, "Z")


def shop_interior(name, title, sub, af, town_map, kind, kid, kpal, secrets, tier=2, w=30, h=18):
    m = interior(name, title, sub, af, town_map, w=w, h=h)
    if kind == "weapons":
        rack(m, 3, 9)
        rack(m, 20, 26)
        m.put(14, 2, "Z")
    elif kind == "armor":
        rack(m, 3, 7)
        rack(m, 22, 26)
        rack(m, 11, 17)
    elif kind == "items":
        shelves(m, 2, 9)
        shelves(m, 20, 27)
        shelves(m, 12, 16)
    else:
        for bx in (3, 5, 7, 21, 23, 25):
            m.put(bx, 2, "Y")
        shelves(m, 11, 17)
    m.put(27, 3, "U")
    counter(m, 6, 23, 7, gap=14)
    m.npc(14, 7, kid, kpal, shop=kind, tier=tier)
    furnish(m, tables=[(4, 12, 2), (23, 12, 2)], rugs=[(10, 10, 10, 4)])
    for sx, sy, sk, sid, rw in secrets:
        m.obj(sx, sy, sk, sid, rw)
    m.decorate(2, 4, "barrel")
    m.decorate(2, 5, "crate")
    m.decorate(27, 14, "barrel")
    lamps(m, [(9, 5), (19, 5), (3, 14), (26, 10)])
    auto_furnish(m)
    m.save()


def enrich_edinburgh():
    af = "edinburgh_done"
    shop_interior("apothecary", "Ewan's Apothecary", "Dried herbs hang from every beam", af, "edinburgh", "items", "edin_ewan",
                  pal("#3a4a3a", "#c0a070", "#8a8a90", style="beard", item="none"),
                  [(4, 4, "urn", "ap_jar", "lore"), (25, 14, "chest", "ap_chest", None)])
    shop_interior("armoury", "Brenda's Armoury", "Plate, mail and leather, hung for fittings", af, "edinburgh", "armor", "edin_brenda",
                  pal("#5a3a2a", "#8a8d98", "#6a3a24", style="braid", mail=True, item="none"),
                  [(10, 4, "crate", "ar_helm", "lore"), (25, 14, "chest", "ar_trunk", None)], tier=2)
    shop_interior("weaponsmith", "Iain's Forge", "A cold anvil and a warm fire", af, "edinburgh", "weapons", "edin_iain",
                  pal("#4a3a30", "#a0a0a8", "#2a2a2e", style="beard", item="none"),
                  [(12, 4, "barrel", "wp_anvil", "lore"), (25, 14, "crate", "wp_crate", None)], tier=2)
    shop_interior("lantern_inn", "The Lantern Rest", "A lamp in every window, a bed for every road", af, "edinburgh", "inn", "edin_isla",
                  pal("#6a3a3a", "#c0a070", "#7a4a2a", style="braid", item="none"),
                  [(25, 14, "chest", "in_trunk", None), (4, 4, "barrel", "in_cask", "heal")])


def enrich_prague():
    af = "prague_done"
    shop_interior("silver_retort", "Ludek's Silver Retort", "Glass vessels, quietly bubbling", af, "prague_town", "items", "pra_ludek",
                  pal("#3a3a5a", "#c0a070", "#4a4a4e", style="beard", item="none"),
                  [(4, 4, "urn", "pa_jar", "lore"), (25, 14, "chest", "pa_chest", None)])
    shop_interior("guild_armoury", "Dagmar's Guild Armoury", "The last of the Bohemian Smiths", af, "prague_town", "armor", "pra_dagmar",
                  pal("#5a4a3a", "#8a8d98", "#2a2a2e", style="braid", mail=True, item="none"),
                  [(10, 4, "crate", "pr_rack", "lore"), (25, 14, "chest", "pr_trunk", None)], tier=3)
    shop_interior("bohemian_steel", "Radek's Bohemian Steel", "Every blade ringing a different note", af, "prague_town", "weapons", "pra_radek",
                  pal("#3a3a3a", "#b0b0b8", "#4a3a2a", style="beard", item="none"),
                  [(12, 4, "barrel", "pw_anvil", "lore"), (25, 14, "crate", "pw_crate", None)], tier=3)
    shop_interior("rose_inn", "The Rose and Hourglass", "Clean linen and a clock that keeps its own time", af, "prague_town", "inn", "pra_olga",
                  pal("#6a3a50", "#e0d0b0", "#2a1a1a", style="braid", item="none"),
                  [(25, 14, "chest", "pi_trunk", None), (4, 4, "barrel", "pi_cask", "heal")])


def build_edinburgh():
    af = "edinburgh_done"
    t = town("edinburgh", "town_e", "Edinburgh — The Old Town",
             "Nine storeys of houses leaning together against the dark", "edin", af, "from_vaults")
    t.meta["triggers"]["1"] = "edin_arrive"
    t.building(6, 4, 8, "marsh_cottage", "Enter Marsh Cottage")
    t.building(22, 4, 9, "mason_yard", "Enter the Mason's Yard")
    t.building(70, 4, 9, "drowned_candle", "Enter the Drowned Candle")
    t.building(88, 4, 9, "archive", "Enter the Archive")
    t.building(36, 4, 8)
    t.building(100, 4, 9)
    t.building(6, 15, 8, "chandlery", "Enter Peggy's Chandlery")
    t.building(20, 15, 7, "apothecary", "Enter the Apothecary")
    t.building(34, 15, 8, "armoury", "Enter the Armoury")
    t.building(70, 15, 8, "weaponsmith", "Enter the Weaponsmith")
    t.building(84, 15, 7, "lantern_inn", "Enter the Lantern Rest")
    t.building(6, 28, 9)
    t.building(20, 28, 7)
    t.door(56, 2, "vaults", "Descend into the Vaults", style="gate", requires="edin_writ", locked="edin_gate_locked")
    street_lamps(t)
    market(t, 40, 26, 4)
    t.obj(56, 22, "statue")
    t.obj(20, 11, "barrel", "e_barrel", "heal")
    t.obj(46, 12, "crate", "e_crate")
    t.obj(108, 11, "chest", "e_chest", "maxhp")
    fence(t, 80, 24, 109, 41, (80, 33))
    t.obj(86, 28, "grave", "e_grave1")
    t.obj(92, 28, "grave", "e_grave2")
    t.obj(98, 28, "grave", "e_grave3")
    t.obj(92, 34, "statue", "e_statue")
    t.obj(104, 38, "urn", "e_urn")
    for gx in (84, 88, 96, 102, 106):
        t.obj(gx, 38, "grave")
    t.npc(55, 4, "edin_hamish", pal("#3a2a30", "#8a7436", "#6a5a4a", style="beard", item="none", mail=True),
          [{"if": af, "id": "edin_hamish_after"}, {"if": "edin_writ", "id": "edin_hamish_writ"}])
    t.npc(24, 12, "edin_peggy", pal("#6a4a3a", "#c0a070", "#7a3a24", style="braid"), wander=3)
    t.npc(14, 20, "edin_rab", pal("#4a4a56", "#7a2a2e", "#4a3a2a"), wander=6)
    t.npc(82, 30, "edin_alasdair", pal("#22212c", "#6a6a74", "#b8b8c0", style="beard"), wander=2)
    t.npc(44, 22, "edin_bessie", pal("#6a4a4a", "#e0d0b0", "#a05a2a", style="braid", item="none"), wander=4)
    t.npc(66, 22, "edin_gideon", pal("#4a3a2a", "#8a8d98", "#2a2a2e", style="beard", item="none"), wander=3)
    t.npc(30, 34, "edin_nell", pal("#5a5a6a", "#c06a6a", "#c08a4a", style="braid"), wander=6)
    t.npc(72, 34, "edin_gilchrist", pal("#3a3a4a", "#9a9aa0", "#c8c8d0", style="braid", item="none"), wander=3)
    t.npc(56, 30, "edin_lachlan", pal("#2c3a5a", "#b0b0b8", "#5a4a3a", item="none", mail=True), wander=5)
    t.npc(12, 36, "edin_tam", pal("#4a5a5a", "#8a7436", "#7a5a3a", style="beard", item="none"), wander=4)
    t.save()

    c = interior("marsh_cottage", "Marsh Cottage", "A lamp is lit in the window", af, "edinburgh", music="inn")
    shelves(c, 2, 5)
    c.put(26, 3, "U")
    c.put(2, 7, "Y")
    c.put(2, 8, "Y")
    c.obj(4, 12, "chest", "c_trunk")
    c.obj(10, 4, "tomes", "c_shelf")
    c.obj(25, 12, "urn", "c_urn")
    c.decorate(22, 3, "barrel")
    c.npc(14, 7, "edin_marta", pal("#5a3a4a", "#c0a070", "#9a9aa0", style="braid", item="none"))
    lamps(c, [(14, 3), (21, 13)])
    auto_furnish(c)
    c.save()

    m = interior("mason_yard", "Rae's Masonry", "Chisels, chalk and a very old arch", af, "edinburgh", music="inn")
    shelves(m, 20, 25)
    m.obj(6, 4, "crate", "m_crate")
    m.obj(24, 12, "barrel", "m_barrel")
    m.obj(14, 4, "statue", "m_stone")
    m.decorate(3, 12, "crate")
    m.decorate(4, 12, "crate")
    m.npc(12, 9, "edin_duncan", pal("#5a4a3a", "#8a8d98", "#aaaaae", style="beard", item="none"))
    m.npc(20, 11, "edin_kirsty", pal("#4a5a4a", "#c0a070", "#4a2a1a", style="braid"))
    lamps(m, [(3, 3), (27, 3)])
    auto_furnish(m)
    m.save()

    d = interior("drowned_candle", "The Drowned Candle", "Fire, ale and a bard with a verse for everyone", af,
                 "edinburgh", w=36, h=20)
    d.put(17, 3, "U")
    d.put(18, 3, "U")
    for x in range(8, 14):
        d.decorate(x, 8, "crate")
    d.obj(3, 4, "barrel", "i_barrel", "heal")
    d.obj(33, 4, "chest", "i_chest")
    d.obj(33, 14, "crate", "i_crate")
    d.decorate(2, 4, "barrel")
    d.decorate(3, 3, "barrel")
    d.npc(10, 6, "edin_morag", pal("#6a3038", "#c0a070", "#7a3a24", style="braid", item="none"), shop="pub")
    d.npc(27, 10, "edin_fergus", pal("#2c4a5a", "#c0a070", "#4a3a2a", item="none"))
    lamps(d, [(6, 15), (30, 15)])
    auto_furnish(d)
    d.save()

    p = interior("chandlery", "Peggy's Chandlery", "Wax, wicks and candles that lean south", af, "edinburgh", music="inn")
    shelves(p, 2, 8)
    p.put(26, 3, "U")
    p.obj(12, 4, "crate", "ch_crate")
    p.obj(24, 12, "barrel", "ch_barrel", "heal")
    p.npc(14, 8, "edin_peggy_shop", pal("#6a4a3a", "#c0a070", "#7a3a24", style="braid"))
    lamps(p, [(10, 13), (21, 4)])
    auto_furnish(p)
    p.save()

    a = interior("archive", "The Burgh Archive", "Every name the town ever owned", af, "edinburgh")
    shelves(a, 2, 9)
    shelves(a, 18, 27)
    a.obj(12, 3, "tomes", "a_tomes1")
    a.obj(15, 3, "tomes", "a_tomes2")
    a.obj(26, 12, "urn", "a_urn")
    a.npc(14, 7, "edin_euphemia", pal("#2c3a5a", "#c0a070", "#3a3a44", style="braid", item="none"),
          [{"if": af, "id": "edin_euphemia_after"}, {"if": "edin_writ", "id": "edin_euphemia_again"},
           {"if": "edin_duncan", "id": "edin_euphemia_mark"}])
    a.npc(24, 10, "edin_ruaridh", pal("#4a4a56", "#8a7436", "#2a2a2e"))
    lamps(a, [(11, 4), (22, 12)])
    auto_furnish(a)
    a.save()


def build_prague():
    af = "prague_done"
    t = town("prague_town", "town_p", "Prague — Old Town Square",
             "An astronomical clock counts the hours of the dead", "praha", af, "from_prague")
    t.meta["triggers"]["1"] = "pra_arrive"
    t.building(6, 4, 9, "raven_tavern", "Enter the Sleeping Raven")
    t.building(22, 4, 8, "orloj_lodge", "Enter the Clock-Keeper's Lodge")
    t.building(70, 4, 9, "alchemist", "Enter the Alchemist's")
    t.building(88, 4, 9, "cartographer", "Enter the Cartographer's")
    t.building(36, 4, 8)
    t.building(100, 4, 9)
    t.building(6, 15, 8, "bakery", "Enter the Bakery")
    t.building(20, 15, 7, "silver_retort", "Enter the Silver Retort")
    t.building(34, 15, 8, "guild_armoury", "Enter the Guild Armoury")
    t.building(70, 15, 8, "bohemian_steel", "Enter Bohemian Steel")
    t.building(84, 15, 7, "rose_inn", "Enter the Rose and Hourglass")
    t.building(6, 28, 9)
    t.building(20, 28, 7)
    t.door(56, 2, "prague", "Descend to the Ossuary", style="gate", requires="pra_pass", locked="pra_gate_locked")
    street_lamps(t)
    market(t, 40, 26, 4)
    t.obj(56, 22, "statue")
    t.obj(46, 12, "barrel", "p_barrel")
    t.obj(14, 12, "urn", "p_urn1")
    t.obj(100, 12, "urn", "p_urn2")
    t.obj(26, 34, "crate", "p_crate")
    t.obj(108, 11, "chest", "p_chest", "maxhp")
    fence(t, 80, 24, 109, 41, (80, 33))
    t.obj(88, 28, "statue", "p_statue1")
    t.obj(100, 28, "statue", "p_statue2")
    for gx, gy in ((86, 36), (92, 36), (98, 36), (104, 36), (94, 31)):
        t.obj(gx, gy, "grave")
    t.npc(55, 4, "pra_jan", pal("#2c3a5a", "#b0b0b8", "#5a4a3a", style="beard", item="none", mail=True),
          [{"if": af, "id": "pra_jan_after"}, {"if": "pra_pass", "id": "pra_jan_pass"}])
    t.npc(24, 12, "pra_eliska", pal("#6a3a50", "#c0a070", "#2a2a2e", style="braid"), wander=4)
    t.npc(90, 30, "pra_marketa", pal("#2a2a32", "#c8c0b0", "#b8b8c0", style="braid", item="none", hood=True), wander=2)
    t.npc(44, 22, "pra_vit", pal("#6a5a3a", "#e0d0b0", "#4a3a2a", style="beard", item="none"), wander=4)
    t.npc(66, 22, "pra_tereza", pal("#6a4a6a", "#c0a070", "#c08a4a", style="braid"), wander=6)
    t.npc(30, 34, "pra_ondra", pal("#4a4a3a", "#8a7436", "#2a2a2e", item="none"), wander=5)
    t.npc(72, 34, "pra_anna", pal("#3a5a5a", "#c0a070", "#9a7a5a", style="braid", item="none"), wander=3)
    t.npc(56, 30, "pra_hynek", pal("#2c3a5a", "#b0b0b8", "#5a4a3a", item="none", mail=True), wander=5)
    t.npc(12, 36, "pra_student", pal("#2a2a3a", "#c0a070", "#6a3a24", item="none"), wander=4)
    t.save()

    b = interior("bakery", "Vit's Bakery", "Bread that never stales between the chimes", af, "prague_town", music="inn")
    shelves(b, 2, 6)
    b.put(26, 3, "U")
    b.put(25, 3, "U")
    b.obj(10, 4, "crate", "bk_crate")
    b.obj(24, 12, "barrel", "bk_barrel", "heal")
    b.npc(14, 8, "pra_vit_shop", pal("#6a5a3a", "#e0d0b0", "#4a3a2a", style="beard", item="none"))
    lamps(b, [(10, 13), (21, 4)])
    auto_furnish(b)
    b.save()

    r = interior("raven_tavern", "The Sleeping Raven", "Beer, bread and bad dreams", af, "prague_town", w=36, h=20)
    r.put(17, 3, "U")
    r.put(18, 3, "U")
    for x in range(8, 14):
        r.decorate(x, 8, "crate")
    r.obj(3, 4, "barrel", "t_barrel", "heal")
    r.obj(33, 4, "crate", "t_crate")
    r.obj(33, 14, "chest", "t_chest")
    r.decorate(2, 4, "barrel")
    r.npc(10, 6, "pra_anezka", pal("#6a3038", "#c0a070", "#2a1a1a", style="braid", item="none"), shop="pub")
    r.npc(22, 6, "pra_jiri", pal("#3a3a44", "#8a8d98", "#c8c8d0", style="beard", item="none"),
          [{"if": af, "id": "pra_jiri_again"}])
    lamps(r, [(6, 15), (30, 15)])
    auto_furnish(r)
    r.save()

    o = interior("orloj_lodge", "The Clock-Keeper's Lodge", "Thirty years of winding, and a cot in the attic", af,
                 "prague_town", music="inn")
    shelves(o, 2, 6)
    o.put(26, 3, "U")
    o.put(3, 8, "Y")
    o.put(3, 9, "Y")
    o.put(4, 8, "1")
    o.meta["triggers"]["1"] = "pra_pavel_note"
    o.obj(4, 13, "chest", "l_trunk")
    o.obj(8, 3, "tomes", "l_shelf")
    o.obj(2, 12, "crate", "l_pavel")
    o.npc(15, 8, "pra_lucie", pal("#4a3a5a", "#c0a070", "#3a2a1a", style="braid", item="none"),
          [{"if": af, "id": "pra_lucie_after"}, {"if": "pra_pass", "id": "pra_lucie_again"},
           {"if": "pra_rumour", "id": "pra_lucie_pass"}])
    lamps(o, [(14, 3), (22, 13)])
    auto_furnish(o)
    o.save()

    z = interior("alchemist", "Zdenek's Laboratory", "The vapours smell faintly of silence", af, "prague_town", music="inn")
    shelves(z, 2, 9)
    shelves(z, 20, 27)
    z.obj(12, 3, "barrel", "z_barrel", "heal")
    z.obj(26, 12, "urn", "z_urn")
    z.obj(16, 3, "tomes", "z_tomes")
    z.npc(14, 8, "pra_zdenek", pal("#3a4a3a", "#c0a070", "#9a9aa0", style="beard", item="none"))
    lamps(z, [(11, 4), (24, 12)])
    auto_furnish(z)
    z.save()

    c = interior("cartographer", "Miloš the Cartographer", "Maps of places that do not want to be mapped", af,
                 "prague_town", music="inn")
    shelves(c, 2, 5)
    c.put(12, 2, "Z")
    c.obj(7, 3, "tomes", "m_chart1")
    c.obj(16, 3, "tomes", "m_chart2")
    c.obj(26, 12, "urn", "m_urn")
    c.npc(14, 8, "pra_milos", pal("#5a3a2a", "#c0a070", "#4a4a4e", style="beard", item="none"))
    lamps(c, [(21, 4), (22, 13)])
    auto_furnish(c)
    c.save()


if __name__ == "__main__":
    build_edinburgh()
    build_prague()
    enrich_edinburgh()
    enrich_prague()
    import gen_more
    gen_more.main()
    import gen_vaults
    gen_vaults.check(gen_vaults.build())
    with open(os.path.join(ROOT, "data", "dialogue_towns.json"), "w") as f:
        json.dump(DIALOGUE, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("ok")
