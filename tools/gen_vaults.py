#!/usr/bin/env python3
"""Generates the expanded South Bridge Vaults (data/maps/vaults.json). Run via gen_towns.py or directly."""
import json
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(__file__))
import gen_towns as G  # noqa: E402
import towns_text2  # noqa: F401,E402

W, H = 100, 72


def build():
    m = G.Map("vaults", W, H, "vault", "Edinburgh — The South Bridge Vaults",
              "Beneath the Old Town, something is ringing", "crypt")
    m.meta.pop("safe", None)
    m.meta["spawns"] = {"start": "@"}
    m.meta["triggers"] = {"1": "vault_enter", "2": "vault_puzzle", "3": "vault_shrine_hint", "4": "vault_bars"}
    m.meta["prefix"] = "vault"
    m.meta["exit"] = {"map": "edinburgh", "spawn": "door:vaults"}
    m.meta["shrine"] = {"form": "wraith", "dialogue": "shrine", "after": "shrine_after", "notice": "Wraith Form unlocked \u2014 press Q"}

    R = m.rect
    p = m.put
    R(2, 58, 26, 12)     # start hall
    R(2, 36, 26, 15)     # key gallery
    R(2, 10, 26, 21)     # crypt of the ringers (optional)
    R(34, 54, 22, 16)    # ossuary
    R(36, 28, 22, 13)    # puzzle hall
    R(30, 4, 62, 17)     # cistern gallery (optional)
    R(62, 24, 23, 17)    # shrine hall
    R(60, 43, 36, 27)    # warden's chamber
    R(13, 51, 3, 7)      # start -> gallery
    R(13, 31, 3, 5)      # gallery -> crypt
    R(28, 63, 6, 3)      # start -> ossuary
    R(48, 41, 1, 13)     # ossuary -> puzzle (door)
    R(47, 21, 3, 7)      # puzzle -> cistern
    R(58, 34, 4, 1)      # puzzle -> shrine (gate)
    R(73, 41, 1, 2)      # shrine -> warden (bars)

    p(2, 64, "E")
    p(4, 64, "@")
    p(7, 64, "1")
    p(24, 38, "K")
    p(48, 48, "D")
    p(48, 39, "2")
    p(42, 30, "S")
    p(42, 33, "P")
    p(58, 34, "g")
    p(63, 34, "3")
    p(73, 28, "W")
    p(73, 38, "4")
    p(73, 41, "B")
    p(73, 42, "B")
    m.door(78, 70, "vault_arena", "The Drowned Cistern Stair", "gate")

    def many(ch, pts):
        for x, y in pts:
            if G.free(m, x, y):
                p(x, y, ch)

    def colonnade(x0, x1, step, ys):
        for y in ys:
            many("o", [(x, y) for x in range(x0, x1 + 1, step)])

    def candles(pts):
        many("c", pts)

    # start hall
    colonnade(10, 22, 8, (61, 66))
    candles([(4, 58), (12, 58), (20, 58), (26, 58), (3, 69), (26, 69), (16, 69)])
    many("r", [(14, 63), (20, 64), (23, 60), (9, 67)])
    # key gallery
    colonnade(8, 20, 6, (40, 46))
    candles([(3, 36), (26, 36), (14, 36), (3, 50), (26, 50)])
    many("b", [(10, 42), (18, 45), (22, 40), (5, 44)])
    many("r", [(6, 40), (14, 38), (24, 47)])
    # crypt of the ringers
    colonnade(6, 24, 6, (16, 24))
    candles([(3, 10), (26, 10), (3, 30), (26, 30), (14, 12)])
    many("b", [(9, 14), (18, 14), (9, 28), (22, 22), (14, 20)])
    many("r", [(5, 20), (22, 18), (12, 26)])
    # ossuary
    colonnade(38, 52, 6, (57, 66))
    candles([(35, 54), (54, 54), (35, 69), (54, 69), (45, 54)])
    many("b", [(40, 60), (50, 60), (44, 66), (52, 64)])
    many("r", [(37, 63), (42, 56), (50, 68), (46, 62)])
    # puzzle hall
    many("o", [(38, 30), (38, 38), (46, 31), (52, 31), (52, 38), (40, 36), (55, 35), (55, 30)])
    candles([(37, 28), (56, 28), (37, 40), (56, 40), (48, 28)])
    many("r", [(40, 34), (54, 33), (50, 36)])
    many("b", [(45, 34), (50, 29)])
    # cistern
    colonnade(34, 88, 6, (8, 16))
    candles([(31, 4), (90, 4), (31, 20), (90, 20), (60, 4), (45, 4), (75, 4), (60, 20)])
    many("b", [(40, 12), (55, 10), (70, 14), (82, 8), (65, 18), (48, 17)])
    many("r", [(36, 6), (58, 14), (80, 18), (72, 6)])
    # shrine hall
    many("o", [(65, 27), (65, 37), (80, 27), (80, 37), (70, 33), (76, 33)])
    candles([(63, 24), (84, 24), (63, 40), (84, 40), (73, 24)])
    many("r", [(68, 36), (78, 36)])
    many("b", [(70, 30)])
    # warden's chamber
    many("o", [(66, 48), (66, 64), (72, 52), (72, 60), (84, 52), (84, 60), (90, 48), (90, 64), (78, 50), (78, 66)])
    candles([(61, 43), (95, 43), (61, 69), (95, 69), (73, 44), (78, 44)])

    # secrets
    m.obj(25, 60, "urn", "v_urn1")
    m.obj(52, 56, "crate", "v_crate")
    m.obj(36, 67, "barrel", "v_barrel", "heal")
    m.obj(4, 12, "tomes", "v_tomes")
    m.obj(24, 12, "chest", "v_chest1", "maxhp")
    for i, gx in enumerate((8, 14, 20)):
        m.obj(gx, 18, "grave", "v_grave%d" % (i + 1))
    for gx in (8, 14, 20):
        m.obj(gx, 26, "grave")
    m.obj(3, 48, "urn", "v_urn2")
    m.obj(89, 6, "chest", "v_chest2", "heal")
    m.obj(66, 30, "statue", "v_statue")
    m.obj(32, 18, "crate", "v_crate2")
    m.obj(60, 6, "urn", "v_urn3")
    m.save()
    return m


def check(m):
    g = m.g

    def reach(start, block):
        seen = {start}
        q = deque([start])
        while q:
            x, y = q.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if (nx, ny) in seen or not (0 <= nx < W and 0 <= ny < H):
                    continue
                c = g[ny][nx]
                if c in block or c in "#o" or c in m.meta["objects"] and m.meta["objects"][c]["kind"] in ("urn", "chest", "crate", "barrel", "tomes", "grave", "statue"):
                    continue
                seen.add((nx, ny))
                q.append((nx, ny))
        return seen

    def pos(ch):
        for y in range(H):
            if ch in g[y]:
                return g[y].index(ch), y

    start = pos("@")
    r0 = reach(start, "DgBP")
    assert pos("K") in r0, "key unreachable"
    assert pos("D") and not pos("S") in r0, "puzzle reachable without door"
    r1 = reach(start, "gBP")
    px, py = pos("P")
    assert (px, py + 1) in r1 and all(g[py - i][px] in ".S" for i in (1, 2, 3)), "block path"
    assert pos("W") not in r1, "shrine reachable without gate"
    r2 = reach(start, "BP")
    assert pos("W") in r2 and (78, 69) not in r2, "boss room reachable without bars"
    r3 = reach(start, "P")
    assert (78, 69) in r3, "belfry stair unreachable"


if __name__ == "__main__":
    mm = build()
    check(mm)
    print("vaults ok")
