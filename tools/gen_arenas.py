#!/usr/bin/env python3
"""Generates the two boss arenas and wires the dungeon gates that lead to them."""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import gen_towns as G  # noqa: E402

W, H = 56, 42
CX, CY = 28, 20


def arena(name, theme, style, title, sub, music, boss, final_exit, back_label, pillars, candles):
    m = G.Map(name, W, H, theme, title, sub, music)
    m.meta.pop("safe", None)
    m.meta["prefix"] = name
    m.meta["arena"] = style
    m.meta["boss"] = boss
    m.meta["final_exit"] = final_exit
    for y in range(H):
        for x in range(W):
            if ((x - CX) / 24.0) ** 2 + ((y - CY) / 17.5) ** 2 <= 1.0:
                m.g[y][x] = "."
    m.rect(CX - 2, 37, 5, 3)
    for i in range(pillars):
        a = math.tau * i / pillars + 0.2
        px, py = int(CX + math.cos(a) * 17), int(CY + math.sin(a) * 12.5)
        if abs(px - CX) < 5 and py > 30:
            continue
        m.put(px, py, "o")
    for i in range(candles):
        a = math.tau * (i + 0.5) / candles
        cx_, cy_ = int(CX + math.cos(a) * 22), int(CY + math.sin(a) * 16)
        if G.free(m, cx_, cy_):
            m.put(cx_, cy_, "c")
    m.put(CX, 36, "@")
    m.put(CX, 14, "G")
    m.put(CX, 4, "X")
    back = {"vault_arena": "vaults", "prague_arena": "prague"}.get(name, "chapel")
    m.door(CX, 39, back, back_label, "gate")
    m.save()


def patch_dungeon(name, ch_old, label, target):
    path = os.path.join(G.ROOT, "data", "maps", name + ".json")
    d = json.load(open(path))
    rows = [list(r) for r in d["ascii"]]
    ch = "\u03a9"
    doors = d.setdefault("doors", {})
    if ch in doors:
        doors[ch]["label"] = label
        json.dump(d, open(path, "w"), indent=1)
        open(path, "a").write("\n")
        return
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c in ("G", "X"):
                rows[y][x] = "."
    gy, gx = (70, 78) if name == "vaults" else (1, 45)
    rows[gy][gx] = ch
    doors[ch] = {"map": target, "label": label, "style": "gate"}
    d.pop("boss", None)
    d.pop("final_exit", None)
    d["ascii"] = ["".join(r) for r in rows]
    json.dump(d, open(path, "w"), indent=1)
    open(path, "a").write("\n")


NEW = [
    # name, style, title, sub, music, kind, flag, requires, gate label, pillars, candles, x on chapel row 1
    ("keep_arena", "keep", "The Hall of Stakes, Poenari Keep", "A forest of the impaled, and a throne of old blood", "crypt",
     "strigoi", "strigoi_done", "prague_done", "Echo Gate: Poenari Keep", 8, 10, 26),
    ("ossuary_arena", "ossuary", "The Great Ossuary of the Ankou", "Ten thousand skulls, and one who counts them", "crypt",
     "ankou", "ankou_done", "strigoi_done", "Echo Gate: Paris Ossuary", 12, 14, 32),
    ("cliff_arena", "cliff", "The Abbey Cliffs of Whitby", "Ruined arches, a storm, and eyes like coals", "clock",
     "barghest", "barghest_done", "ankou_done", "Echo Gate: Whitby Cliffs", 10, 12, 38),
    ("lazaretto_arena", "lazaretto", "The Lazzaretto of Venice", "Green smoke over the lagoon, and a beak that knows your name", "crypt",
     "plague", "plague_done", "barghest_done", "Echo Gate: Venetian Lazzaretto", 10, 14, 44),
    ("cave_arena", "cave", "The Cave of Cacus, Aventine Hill", "Charred bones, stolen cattle, and a mountain that breathes", "clock",
     "cacus", "cacus_done", "plague_done", "Echo Gate: Aventine Cave", 8, 12, 50),
]


def patch_chapel():
    path = os.path.join(G.ROOT, "data", "maps", "chapel.json")
    d = json.load(open(path))
    rows = [list(r) for r in d["ascii"]]
    doors = {}
    chars = "56789\u0393\u0394\u0398\u039b\u039e"
    for i, (name, style, title, sub, music, kind, flag, req, label, pil, can, gx) in enumerate(NEW):
        ch = chars[i]
        rows[1][gx] = ch
        doors[ch] = {"map": name, "label": label, "style": "gate", "requires": req, "locked": "echo_gate_locked"}
    d["doors"] = doors
    d["ascii"] = ["".join(r) for r in rows]
    json.dump(d, open(path, "w"), indent=1)
    open(path, "a").write("\n")


def main():
    for name, style, title, sub, music, kind, flag, req, label, pil, can, gx in NEW:
        arena(name, "vault", style, title, sub, music,
              {"kind": kind + "_giant", "done_flag": flag, "intro": kind + "_intro", "defeated": kind + "_defeated"},
              {"map": "chapel", "spawn": "door:" + name}, "Back through the Echo Gate", pil, can)
    patch_chapel()
    arena("vault_arena", "vault", "loch", "The Drowned Cistern of the Nor' Loch", "Black water, and something that remembers every drowning", "crypt",
          {"kind": "kelpie_giant", "done_flag": "edinburgh_done", "intro": "kelpie_intro", "defeated": "kelpie_defeated"},
          {"map": "chapel", "spawn": "from_vaults"}, "Back down to the Vaults", 10, 14)
    arena("prague_arena", "prague", "attic", "The Attic of the Old-New Synagogue", "Clay, ash, and a word written on a brow", "clock",
          {"kind": "golem_giant", "done_flag": "prague_done", "intro": "golem_intro", "defeated": "golem_defeated", "leave": "isolde"},
          {"map": "chapel", "spawn": "from_prague"}, "Back to the Ossuary Clock", 12, 16)
    patch_dungeon("prague", "G", "The Altneuschul Attic", "prague_arena")


if __name__ == "__main__":
    main()
    print("arenas ok")
