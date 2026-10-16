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
    m.door(CX, 39, "vaults" if name == "vault_arena" else "prague", back_label, "gate")
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


def main():
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
