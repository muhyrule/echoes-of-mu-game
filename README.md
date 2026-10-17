# Echoes of Mu

A gothic top-down action-adventure built with **Godot 4.3** (GDScript). Mu, a bell-ringer's apprentice, and a band of companions travel through real-world gothic locations to mend the Seven Silent Bells. Inspired by the *structure* of classic 16-bit action-adventures (real-time sword combat, form-shifting puzzles, dungeon-per-location, hub map, party arcs). All characters, story, dialogue, maps, art and audio are original and generated in code/data.

## Run
1. Install [Godot 4.3+](https://godotengine.org/download).
2. Open this folder as a project and press **Play** (main scene: `MainMenu.tscn`).

Controls: **WASD/Arrows** move · **Space/J** sword · **E/Enter** interact & advance text · **Q/K** shift form · **R** reset block puzzle · **Esc** pause.

## Vertical slice (Chapter I)
Wayfarer's Chapel (hub) → meet Isolde → Edinburgh South Bridge Vaults: key & locked door, block-and-plate puzzle, Wraith Form shrine (pass through iron bars, fast, weaker strikes), Nor' Loch Kelpie boss (charge attacks, adds at half health), return to the hub. Progress saves automatically on map change.

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

## Title screen & music
- Premise-themed title screen: lightning sky, echo rings, Edinburgh crag, Prague spires, a cathedral, and Mu and Isolde on a ledge.
- Music is synthesized at runtime from original compositions in the styles of Bach (organ fugue), Beethoven/Chopin (nocturne, funeral march), Vivaldi (concerto), Brahms (Hungarian-style dance), plus town themes `edin`, `praha` and `inn`. Nothing is a transcription of an existing score.
- The window override is 3840x2160 (see `project.godot`); lower it on smaller displays.

## 32-bit-inspired gothic presentation
- Original cached 32x32 material tiles replace flat floors: cold Edinburgh cobbles, warmer Praha paving, chapel inlays, vault flagstones, timber grain, layered roof tiles, weathered plaster, water and five regional arena materials. Town avenues have drainage grates and the squares have brass-inlaid borders.
- Character colour ramps, visible hooded faces, blinking, half-step walking poses and moving cloak hems are shared by gameplay, the title screen and the travelling party. Inventory portraits are separate original busts with hero-specific hair, clothing, braid, straps and brass eyepiece, using the equipped armour palette. Mu's silver hair and crimson lining also carry into the prologue.
- Boss bodies use directional shading and finer texture clusters. World clutter renders above the floor and below actors, with chapel manuscripts and wall candlework.
- Stepped brass-and-slate panels unify shops, inventory and menus. The compact command bar keeps forms, supplies, guards, party skills and cooldowns visible; camera bounds reserve space so it cannot conceal heroes at the lower map edge.
- The 1920x1080 canvas and all gameplay/collision data remain intact. Nearest texture sampling, clearer regional lighting and restrained grading replace film blur, colour fringing and crushed blacks; this is an art-direction pass, not a new 3D engine or a complete hand-painted asset set.
- Presentation regression/capture tool: `godot --fixed-fps 60 -s tools/presentation_test.gd`. Add `-- --capture=/absolute/output/folder` on a graphical display for representative maps, all seven arenas, menus, travel parties and directional/animated hero sheets. Without captures it can also run headlessly.

## Towns, interiors and secrets
- Each location is a town first: Edinburgh Old Town and Prague Old Town, reached from the chapel portal. The dungeon gate in each town stays shut until you earn it (Edinburgh: the Warrant of Descent from the Archive, after Duncan vouches for you; Prague: the Keeper's Pass from Lucie, after Old Jiri's rumour).
- Four enterable buildings per town (E at the door) with interiors, NPCs whose dialogue changes as you progress, and searchable barrels, chests, urns, tomes, graves and statues with hidden items. One secret per town raises max HP. Found items are saved (`GameState.items`).
- Maps and text are generated by `python3 tools/gen_towns.py` from `tools/towns_text.py`; the output is `data/maps/*.json` and `data/dialogue_towns.json`.

## Scrolling towns
- Towns are now 112x44 tiles with a smooth-following camera: a market square, rows of houses with chimney smoke, a fenced kirkyard, a lamp-lit avenue to the dungeon gate, and about 10 citizens each. Many citizens wander their neighbourhood. Each town gains a fifth enterable shop (Peggy's Chandlery, Vit's Bakery) with more secrets.

## Shops, gear and the economy

- Every town now has an Apothecary (supplies), an Armoury, a Weaponsmith and an Inn; the existing taverns are Pubs. Talk to the keeper to trade.
- Each hero has their own weapon class and armour class (Mu: sword/mail, Isolde: maul/plate, Wren: daggers/leathers, Corvin: clockwork/robes), with tiered gear defined in `src/core/gear.gd`. Mu's gear applies fully; party members' gear contributes as aid (Isolde: shield and defence, Wren: strike speed and +25% gold, Corvin: vitality).
- Gold drops from enemies, bosses and secret relics. Supplies are used with keys 1 (Tonic), 2 (Elixir), 3 (Warding Candle). The Inn's "Rest" fully heals and saves; towns no longer heal on entry.
- Shop UI: `src/scenes/world/shop.gd`. Maps use new furniture tiles (table `T`, counter `J`, rack `F`, chair `C`, rug `R`); regenerate with `python3 tools/gen_towns.py`.
- Music was smoothed (softer timbres, low-pass, light room reverb, soft limiting); verified numerically only.

## Party & Inventory, weather, gear
- **Tab / I** opens the Party & Inventory screen: per-hero stats and portrait, equip owned weapons/armour (A/D hero, W/S choose, Q section, E use/equip), use healing supplies, review relics. Heroes visibly change look with armour tier.
- Rare gear is found in secrets and dropped by bosses (never sold in shops).
- Towns have dynamic weather: Edinburgh (mist, drizzle, rain, thunderstorm), Prague (snow, blizzard, mist), with ripples, lightning, tint and puddles on the ground.
- Music was gently refined (warmer tone, longer reverb, ensemble detune).

## Living towns & the expanded Vaults
- ~40 more NPCs across Edinburgh, Prague and all interiors (see `tools/gen_more.py`, `tools/towns_text2.py`).
- Ambient critters (cats, crows, pigeons, rats), falling leaves/petals, flower boxes, shutters, banners, candles, stalls.
- The South Bridge Vaults are now 100x72: start hall, key gallery, optional Crypt of the Ringers and Cistern, ossuary, puzzle hall, shrine hall and warden's chamber, with new secrets (`tools/gen_vaults.py`, validated by BFS).

## Boss arenas

Each dungeon ends in a gate to its own arena map, holding a colossal multi-phase boss (phases at 66% / 33% HP, telegraphed attacks, exposed windows after a wall-crash take double damage).

Arenas are themed to their boss: the Kelpie fights in a flooded cistern of the Nor' Loch (animated rippling water, kelp, drowned pillars) and the Golem in the dusty attic of the Old-New Synagogue (floorboards, rafters, clay shards, light shafts). The boss name shows on the health bar only for the first few seconds of the fight, so it never blocks the view.

Arena motion: heroes, the boss and every strike kick up ripples, puddles and splashing droplets (water in the loch, dust in the attic); embers rise in the attic and swells drift across the loch.

New boss attacks (all telegraphed): Kelpie – **Tide** (a wall of water sweeping the arena with one safe gap), **Whirlpool** (pulls you toward a damaging core, phase 2+), geysers with rising steam; Golem – **Quake** (stomp shockwave rings plus dust blasts), **Ember Beam** (a rotating furnace beam, phase 2+).

Both bosses come from real regional folklore:

- **Nor' Loch Kelpie** (Drowned Cistern, Edinburgh): the Scottish water-horse that lures travellers onto its back and drowns them. Tide rings with a gap to slip through, weedy mane lashes, water geysers, drowned-light summons, charging rush.
- **Golem of Prague** (Attic of the Old-New Synagogue): Rabbi Loew's clay guardian, animated by the word *emet* on its brow (it loses the first letter in its final phase). Clay boulder volleys, sweeping arm blows, stomp shockwaves, mud pits that slow you, charging rush.

## Party combat
Isolde, Wren and Corvin now fight beside Mu with automatic attacks (Isolde's maul, Wren's twin daggers, Corvin's clockwork bolts) and skills that fire when ready or on demand:
- `4` Isolde: Bell Toll (AoE + ward)
- `5` Wren: Shadow Fan (five thrown daggers)
- `6` Corvin: Gearstorm (radial bolts, heals 1 HP)

### Switching heroes
Press `C` to cycle the hero you control (Mu, Isolde, Wren, Corvin). The hero you leave goes automatic (auto-attack plus skills) and the new one takes over with their own attack and skill key. Only Mu can shift forms (Q). Each hero's craft solves puzzles: in the Vaults' cistern gallery, three seals answer only to Isolde's Bell Toll, Wren's thrown daggers and Corvin's clockwork bolts, and together open a hidden reliquary. Mu gains `7` Moon Cleave when auto-controlled.

Bosses gained 16-bit style checker-dither shading, scale/brick/filigree detail, and heroes have refined signature gear.

## Dodge roll, guard and parry
- `Shift` (or `U`): a true tumbling roll with brief invulnerability and an afterimage trail. Mu rolls farthest, Wren fastest, Isolde and Corvin are heavier.
- Hold `V` (or `O`) to guard (slower movement, no attacks). A hit in the first moments is a perfect parry with a unique counter: Mu *Moonlit Parry* (crescent), Isolde *Bell Ward* (shockwave), Wren *Shadow Slip* (blink + brief invulnerability), Corvin *Aegis Plate* (brass ward). Three blocks in quick succession break the guard.
- Footstep and splash effects are specific to each arena: ripples in the loch and on the storm cliffs, dust in the attic, blood specks in the keep, bone dust in the ossuary, green smoke in the lazzaretto and ash in the cave.

## Echo Gates: the remaining legends
Five further giants, each based on a regional legend, wait behind **Echo Gates** on the north wall of the chapel. Each gate opens after the previous giant falls (the first after Prague):
- **Strigoi of Poenari** (Transylvania): stake volleys, blood rings, mist-step slams, bats, draining whirlpools.
- **Ankou, reaper of the ossuary** (Brittany / Paris): scythe sweeps, falling bone, death-cart lanes, soul orbs, knells.
- **Barghest of Whitby** (Yorkshire): howl cones, pounces, lightning strikes, ghost-fire spokes.
- **Il Medico della Peste** (Venice): miasma, lancet fans, censer sweeps, plague rats. Venice has no single well-documented monster, so this uses a real historical figure, the 1630 plague doctor.
- **Cacus of the Aventine** (Rome): fire breath, boulders, cattle stampede lanes, smoke, quakes and a furnace beam.

Each has its own themed arena (`keep`, `ossuary`, `cliff`, `lazaretto`, `cave`), three phases and original ornate art in `src/entities/boss_art2.gd`. Full towns and dungeons for these cities are future chapters.

## Prologue, voice and music

- **Prologue**: New Game opens 24 original animated story plates explaining the Echoes and Mu's calling. Vaulted interiors, regional reliquaries, candlelit masonry and weathered exteriors accompany staged moments: the foundling's rescue, young Mu hearing the walls, borrowed memories and Aldous passing on the blade. Camera moves and story beats scale to each plate's reading time. Enter reveals text, then advances; Shift hastens; Esc skips. The thin ornamental border leaves the illustration visible.
- **Travel**: the road cutscene shows only the heroes currently in the party, each speaking their own line.
- **Old gothic voice**: `src/autoload/voice.gd` applies archaic diction to the main cast and regional dialect to townsfolk (Scots in Edinburgh, Bohemian-flavoured in Praha).
- **Music engine**: 44.1 kHz stereo, per-voice panning, stereo room reverb, new choir/harp/flute/cello/drone voices. Region themes: chapel, Edinburgh, Praha, plus dungeon pieces `vaults` (Edinburgh) and `ossuary` (Praha), `road` for travel and `prologue`.
