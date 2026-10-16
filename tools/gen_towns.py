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
POOL = list("adefhijkmnpqstuvwyz") + list("CFJORT") + list("!%*+~^;:?()<>/")


class Map:
    def __init__(self, name, w, h, theme, title, subtitle, music, wall="#"):
        self.name, self.w, self.h = name, w, h
        self.g = [[wall] * w for _ in range(h)]
        self.meta = {"theme": theme, "title": title, "subtitle": subtitle, "music": music,
                     "safe": True, "spawns": {"start": "@"}, "npcs": {}, "doors": {}, "objects": {},
                     "triggers": {}}
        self.pool = list(POOL)
        self.door_digits = list("5678960")
        self.decor = {}

    def rect(self, x, y, w, h, ch="."):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = ch

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def alloc(self):
        return self.pool.pop(0)

    def npc(self, x, y, id, pal, variants=None, face=(0, 1), hide_if=None):
        ch = self.alloc()
        d = {"id": id, "pal": pal, "face": list(face)}
        vs = list(variants or [])
        if id + "_after" in DIALOGUE and not any(v["id"] == id + "_after" for v in vs):
            vs.insert(0, {"if": self.after_flag, "id": id + "_after"})
        if vs:
            d["variants"] = vs
        if hide_if:
            d["hide_if"] = hide_if
        self.meta["npcs"][ch] = d
        self.put(x, y, ch)

    def obj(self, x, y, kind, id=None, reward=None):
        ch = self.alloc()
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


def pal(coat, accent, hair, skin="#c4a083", style="short", **kw):
    d = {"coat": coat, "accent": accent, "hair": hair, "skin": skin, "style": style}
    d.update(kw)
    return d


def town(name, theme, title, sub, music, after_flag, back_spawn):
    m = Map(name, 56, 34, theme, title, sub, music)
    m.after_flag = after_flag
    m.rect(1, 3, 54, 30)
    m.rect(26, 33, 4, 1, "#")
    m.meta["spawns"].update({"from_chapel": "$"})
    m.meta["exit"] = {"map": "chapel", "spawn": back_spawn}
    m.rect(25, 32, 6, 1, "E")
    m.put(27, 30, "$")
    m.put(28, 30, "@")
    for x in range(24, 31):
        m.put(x, 27, "1")
    return m


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


def build_edinburgh():
    af = "edinburgh_done"
    t = town("edinburgh", "town_e", "Edinburgh — The Old Town",
             "Nine storeys of houses leaning together against the dark", "edin", af, "from_vaults")
    t.meta["triggers"]["1"] = "edin_arrive"
    t.building(4, 4, 7, "marsh_cottage", "Enter Marsh Cottage")
    t.building(16, 4, 8, "mason_yard", "Enter the Mason's Yard")
    t.building(30, 4, 9, "drowned_candle", "Enter the Drowned Candle")
    t.building(44, 4, 8, "archive", "Enter the Archive")
    t.building(4, 15, 6)
    t.building(14, 18, 7)
    t.building(32, 12, 5)
    t.door(27, 2, "vaults", "Descend into the Vaults", style="gate", requires="edin_writ", locked="edin_gate_locked")
    lamps(t, [(8, 9), (20, 9), (34, 9), (48, 9), (27, 4), (27, 14), (27, 24), (52, 4), (12, 24), (45, 18)])
    # Kirkyard
    fence(t, 38, 20, 53, 31, (38, 25))
    t.obj(42, 23, "grave", "e_grave1")
    t.obj(46, 23, "grave", "e_grave2")
    t.obj(50, 23, "grave", "e_grave3")
    t.obj(46, 27, "statue", "e_statue")
    t.obj(51, 29, "urn", "e_urn")
    t.obj(41, 29, "grave")
    t.obj(53, 3, "chest", "e_chest", "maxhp")
    t.obj(33, 8, "barrel", "e_barrel", "heal")
    t.obj(25, 8, "crate", "e_crate")
    for x, y in [(2, 10), (3, 10), (14, 9), (36, 9)]:
        t.decorate(x, y, "barrel" if x < 10 else "crate")
    t.npc(30, 3, "edin_hamish", pal("#3a2a30", "#8a7436", "#6a5a4a", style="beard", item="none"),
          [{"if": af, "id": "edin_hamish_after"}, {"if": "edin_writ", "id": "edin_hamish_writ"}])
    t.npc(20, 10, "edin_peggy", pal("#6a4a3a", "#c0a070", "#7a3a24", style="braid"))
    t.npc(10, 12, "edin_rab", pal("#4a4a56", "#7a2a2e", "#4a3a2a"))
    t.npc(37, 25, "edin_alasdair", pal("#22212c", "#6a6a74", "#b8b8c0", style="beard"))
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
    d.npc(10, 6, "edin_morag", pal("#6a3038", "#c0a070", "#7a3a24", style="braid", item="none"))
    d.npc(27, 10, "edin_fergus", pal("#2c4a5a", "#c0a070", "#4a3a2a", item="none"))
    lamps(d, [(6, 15), (30, 15)])
    d.save()

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
    a.save()


def build_prague():
    af = "prague_done"
    t = town("prague_town", "town_p", "Prague — Old Town Square",
             "An astronomical clock counts the hours of the dead", "praha", af, "from_prague")
    t.meta["triggers"]["1"] = "pra_arrive"
    t.building(4, 4, 8, "raven_tavern", "Enter the Sleeping Raven")
    t.building(17, 4, 7, "orloj_lodge", "Enter the Clock-Keeper's Lodge")
    t.building(30, 4, 8, "alchemist", "Enter the Alchemist's")
    t.building(44, 4, 8, "cartographer", "Enter the Cartographer's")
    t.building(4, 15, 7)
    t.building(14, 18, 6)
    t.building(32, 12, 6)
    t.door(27, 2, "prague", "Descend to the Ossuary", style="gate", requires="pra_pass", locked="pra_gate_locked")
    lamps(t, [(8, 9), (20, 9), (34, 9), (48, 9), (27, 4), (27, 14), (27, 24), (52, 4), (12, 24), (45, 18)])
    fence(t, 38, 20, 53, 31, (38, 25))
    t.obj(42, 23, "statue", "p_statue1")
    t.obj(50, 23, "statue", "p_statue2")
    t.obj(10, 14, "urn", "p_urn1")
    t.obj(46, 10, "urn", "p_urn2")
    t.obj(25, 8, "barrel", "p_barrel")
    t.obj(6, 24, "crate", "p_crate")
    t.obj(53, 3, "chest", "p_chest", "maxhp")
    for x, y in [(2, 10), (3, 10), (14, 9), (36, 9)]:
        t.decorate(x, y, "barrel" if x < 10 else "crate")
    t.npc(30, 3, "pra_jan", pal("#2c3a5a", "#b0b0b8", "#5a4a3a", style="beard", item="none", mail=True),
          [{"if": af, "id": "pra_jan_after"}, {"if": "pra_pass", "id": "pra_jan_pass"}])
    t.npc(15, 10, "pra_eliska", pal("#6a3a50", "#c0a070", "#2a2a2e", style="braid"))
    t.npc(45, 25, "pra_marketa", pal("#2a2a32", "#c8c0b0", "#b8b8c0", style="braid", item="none", hood=True))
    t.save()

    r = interior("raven_tavern", "The Sleeping Raven", "Beer, bread and bad dreams", af, "prague_town", w=36, h=20)
    r.put(17, 3, "U")
    r.put(18, 3, "U")
    for x in range(8, 14):
        r.decorate(x, 8, "crate")
    r.obj(3, 4, "barrel", "t_barrel", "heal")
    r.obj(33, 4, "crate", "t_crate")
    r.obj(33, 14, "chest", "t_chest")
    r.decorate(2, 4, "barrel")
    r.npc(10, 6, "pra_anezka", pal("#6a3038", "#c0a070", "#2a1a1a", style="braid", item="none"))
    r.npc(22, 6, "pra_jiri", pal("#3a3a44", "#8a8d98", "#c8c8d0", style="beard", item="none"),
          [{"if": af, "id": "pra_jiri_again"}])
    lamps(r, [(6, 15), (30, 15)])
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
    o.save()

    z = interior("alchemist", "Zdenek's Laboratory", "The vapours smell faintly of silence", af, "prague_town", music="inn")
    shelves(z, 2, 9)
    shelves(z, 20, 27)
    z.obj(12, 3, "barrel", "z_barrel", "heal")
    z.obj(26, 12, "urn", "z_urn")
    z.obj(16, 3, "tomes", "z_tomes")
    z.npc(14, 8, "pra_zdenek", pal("#3a4a3a", "#c0a070", "#9a9aa0", style="beard", item="none"))
    lamps(z, [(11, 4), (24, 12)])
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
    c.save()


if __name__ == "__main__":
    build_edinburgh()
    build_prague()
    with open(os.path.join(ROOT, "data", "dialogue_towns.json"), "w") as f:
        json.dump(DIALOGUE, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("ok")
