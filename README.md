# Echoes of Mu

A gothic top-down action-adventure built with **Godot 4.3** (GDScript). Mu, a bell-ringer's apprentice, and a band of companions travel through real-world gothic locations to mend the Seven Silent Bells. Inspired by the *structure* of classic 16-bit action-adventures (real-time sword combat, form-shifting puzzles, dungeon-per-location, hub map, party arcs). All characters, story, dialogue, maps, art and audio are original and generated in code/data.

## Run
1. Install [Godot 4.3+](https://godotengine.org/download).
2. Open this folder as a project and press **Play** (main scene: `MainMenu.tscn`).

Controls: **WASD/Arrows** move · **Space/J** sword · **E/Enter** interact & advance text · **Q/K** shift form · **R** reset block puzzle · **Esc** pause.

## Vertical slice (Chapter I)
Wayfarer's Chapel (hub) → meet Isolde → Edinburgh South Bridge Vaults: key & locked door, block-and-plate puzzle, Wraith Form shrine (pass through iron bars, fast, weaker strikes), Hollow Warden boss (charge attacks, adds at half health), return to the hub. Progress saves automatically on map change.

## Layout
- `src/autoload/` – `GameState` (flags, party, save/load, input), `Audio` (procedural SFX/music), `Dialogue` (JSON-driven text box)
- `src/entities/` – player, enemies/boss, map props, party follower
- `src/scenes/world/` – data-driven level builder and HUD; `src/scenes/menu/` – title screen
- `data/maps/*.json` – ASCII maps with legend (see `level.gd`); `data/dialogue.json` – all dialogue
- `tools/smoke_test.gd` – headless playthrough test:
  `godot --headless --fixed-fps 60 -s tools/smoke_test.gd`

## Roadmap
Prague (Ossuary Clock) → Transylvania → Paris Catacombs → Whitby Abbey → Venice → Rome. Companions Corvin and Wren join; companions part ways for their own arcs. Gargoyle Form (break cracked walls, push heavy objects), proper pixel art and composed music.

## Chapter II update
- **Gargoyle form** (shrine in Prague): slow, heavy stone strikes, reduced damage taken, breaks cracked walls.
- **Party**: Wren (Prague) and Corvin (cell chamber) join; Isolde leaves after the Revenant boss.
- **Chapter II – Prague, The Ossuary Clock**: gear orrery, bars/key puzzle, cracked-wall passage, Revenant boss.
- **Scrolling chapel**: 64x42 hub with nave, transepts, vestry and chapter house; portal leads to Edinburgh, then Prague.
