extends SceneTree
## Headless smoke test: godot --headless -s tools/smoke_test.gd
## Plays through the vertical slice programmatically and asserts key milestones.

var GS: Node  # autoloads are not compile-time globals in -s scripts
var Dlg: Node
var fails := 0
var tick := 0


func check(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		# Alternate press/release so dialogue advances automatically.
		if Dlg.active:
			if tick % 2 == 0:
				Input.action_press("interact")
			else:
				Input.action_release("interact")
		else:
			Input.action_release("interact")
		tick += 1
		await process_frame


func load_level(map: String, spawn := "start") -> Node:
	GS.current_map = map
	GS.spawn = spawn
	change_scene_to_file(GS.LEVEL_SCENE)
	await frames(3)
	return current_scene


func cell_pos(lv: Node, c: Vector2i) -> Vector2:
	return lv._cell_center(c)


func char_pos(lv: Node, ch: String) -> Vector2:
	for y in lv.h:
		var x: int = lv.grid[y].find(ch)
		if x >= 0:
			return lv._cell_center(Vector2i(x, y))
	return Vector2.ZERO


func _initialize() -> void:
	GS = root.get_node("GameState")
	Dlg = root.get_node("Dialogue")
	run.call_deferred()


func run() -> void:
	GS.new_game()
	var lv: Node = await load_level("chapel")
	await frames(5)
	check(lv.player != null, "chapel loads with player")
	await frames(600)
	check(GS.flag("intro_done"), "intro dialogue plays and completes")

	var isolde: Node2D
	for p in lv.interactables:
		if p.kind == "npc" and p.id == "isolde":
			isolde = p
	check(isolde != null, "Isolde NPC present before joining")
	lv.player.global_position = isolde.position + Vector2(0, 16)
	await frames(3)
	lv.interact()
	await frames(900)
	check(GS.flag("isolde_joined"), "Isolde joins party")

	lv = await load_level("vaults")
	await frames(5)
	check(lv.blocks.size() == 1 and lv.gates.size() == 1, "puzzle objects spawned")
	GS.max_hp = 999
	GS.hp = 999
	lv.player.global_position = char_pos(lv, "1")
	await frames(500)
	check(GS.flag("seen_vault_enter"), "vault entry trigger fires")

	lv.player.global_position = char_pos(lv, "K")
	await frames(5)
	check(GS.keys == 1, "key picked up")
	await frames(300)

	var door: Node2D
	for p in lv.interactables:
		if p.kind == "door":
			door = p
	lv.player.global_position = door.position + Vector2(0, 14)
	await frames(3)
	lv.interact()
	await frames(5)
	check(GS.flag("vault_door_open") and GS.keys == 0, "door unlocks with key")

	var blk: Node2D = lv.blocks[0]
	for i in 3:
		blk.push(Vector2.UP)
		await frames(20)
	check(GS.flag("vault_gate_open"), "block on plate opens gate")
	await frames(60)

	var shrine: Node2D
	for p in lv.interactables:
		if is_instance_valid(p) and p.kind == "shrine":
			shrine = p
	lv.player.global_position = shrine.position + Vector2(0, 14)
	await frames(3)
	lv.interact()
	await frames(900)
	check("wraith" in GS.forms, "shrine grants Wraith form")

	lv.player.cycle_form()
	check(GS.form == "wraith" and lv.player.collision_mask == 1, "wraith form ignores bars mask")
	lv.player.global_position = char_pos(lv, "B") - Vector2(0, 12)
	Input.action_press("move_down")
	await frames(90)
	Input.action_release("move_down")
	check(lv.player.global_position.y > char_pos(lv, "B").y + 16, "wraith walks through iron bars")
	lv.player.cycle_form()
	check(GS.form == "mu", "can shift back to Mu")

	var stair: Node2D
	for e in lv.entries:
		if e.def.map == "vault_arena":
			stair = e
	check(stair != null, "vaults end in a stair to the belfry arena")

	var boss_set := {
		"kelpie_giant": ["vault_arena", ["toll", "lash", "drop", "rush", "summon", "tide", "whirl"]],
		"golem_giant": ["prague_arena", ["cogs", "hands", "vents", "rush", "rift", "quake", "beam"]],
		"strigoi_giant": ["keep_arena", ["stakes", "bloodring", "mist", "bats", "drain", "rush"]],
		"ankou_giant": ["ossuary_arena", ["scythe", "bonerain", "cart", "souls", "knell", "rush"]],
		"barghest_giant": ["cliff_arena", ["howl", "pounce", "lightning", "hellfire", "rush"]],
		"plague_giant": ["lazaretto_arena", ["miasma", "lancet", "censer", "rats", "knell", "rush"]],
		"cacus_giant": ["cave_arena", ["breath", "boulders", "stampede", "smoke", "quake", "beam", "rush"]],
	}
	for kind in boss_set:
		var arena_name: String = boss_set[kind][0]
		var atk_list: Array = boss_set[kind][1]
		lv = await load_level(arena_name)
		await frames(5)
		check(lv.entries.size() == 1, kind + " arena has a retreat door")
		var boss: Node2D
		for e in get_nodes_in_group("enemies"):
			if e.kind == kind:
				boss = e
		check(boss != null and boss.hp >= 60, kind + " arena holds a giant")
		GS.max_hp = 999
		GS.hp = 999
		lv.player.global_position = boss.global_position + Vector2(0, 150)
		await frames(600)
		check(boss.state != "dormant", kind + " wakes")
		var seen := {}
		for i in 2:
			for a in atk_list:
				if boss.has_method("_a_" + a):
					boss.phase = 3
					boss.state = "idle"
					boss.queue.clear()
					boss.fx.clear()
					boss.call("_a_" + a)
					seen[a] = true
					await frames(60)
		check(seen.size() == atk_list.size(), kind + " every attack pattern runs without error")
		boss.state = "idle"
		boss.queue.clear()
		boss.fx.clear()
		boss.hp = 2
		boss.hurt(2, Vector2.LEFT)
		await frames(1500)
		var flag: String = lv.meta.boss.done_flag
		check(GS.flag(flag), kind + " defeat completes the chapter")
		var portal_ok := false
		for p in lv.walkovers:
			if is_instance_valid(p) and p.kind == "final":
				portal_ok = true
		check(portal_ok, kind + " return portal spawned")

	GS.save_game()
	var before: Dictionary = GS.flags.duplicate()
	GS.new_game()
	check(GS.load_game() and GS.flags == before, "save/load round trip")

	# Towns: gated dungeon, interiors, secrets
	GS.new_game()
	GS.set_flag("intro_done")
	GS.set_flag("isolde_joined")
	lv = await load_level("edinburgh", "from_chapel")
	check(lv.entries.size() == 10, "edinburgh has 9 buildings and a dungeon gate")
	var gate: Node2D
	for e in lv.entries:
		if e.def.map == "vaults":
			gate = e
	check(gate != null and gate.def.has("requires"), "dungeon gate requires a writ")
	lv.player.global_position = gate.position + Vector2(0, 16)
	await frames(3)
	lv._enter(gate)
	await frames(120)
	check(current_scene.map_name == "edinburgh", "locked gate keeps heroes in town")
	GS.set_flag("edin_writ")
	lv._enter(gate)
	await frames(60)
	check(current_scene.map_name == "vaults", "writ opens the vault gate")
	lv = await load_level("archive", "start")
	check(lv.theme == "interior" and lv.interactables.size() > 3, "interior loads with searchable objects")
	var secret: Node2D
	for p in lv.interactables:
		if p.def.get("id", "") == "a_tomes1":
			secret = p
	check(secret != null, "secret object present")
	lv.player.global_position = secret.position + Vector2(0, 16)
	lv._search(secret)
	await frames(600)
	check(GS.flag("found_a_tomes1") and "Register Leaf of 1631" in GS.items, "searching a secret grants its item")
	lv = await load_level("edinburgh", "door:archive")
	var arch: Node2D
	for e in lv.entries:
		if e.def.map == "archive":
			arch = e
	check(lv.w >= 100 and lv.player.position.distance_to(arch.position) < 40.0, "leaving an interior returns to its door")

	# Shops, gear, supplies, inn
	GS.new_game()
	GS.set_flag("intro_done")
	GS.party = ["isolde"]
	GS.gold = 500
	for m in ["apothecary", "armoury", "weaponsmith", "lantern_inn", "drowned_candle", "silver_retort", "guild_armoury", "bohemian_steel", "rose_inn"]:
		lv = await load_level(m, "start")
		var keeper_shop := ""
		for p in lv.interactables:
			if p.def.has("shop"):
				keeper_shop = p.def.shop
		check(keeper_shop != "", m + " has a shopkeeper")
	lv = await load_level("armoury", "start")
	var before_hp: int = GS.max_hp
	lv.open_shop("armor", 2)
	await frames(10)
	var sh: Node
	for ch in lv.get_children():
		if ch is CanvasLayer and ch.get_child_count() > 0 and ch.get_child(0).has_method("_buy"):
			sh = ch.get_child(0)
	check(sh != null and lv.frozen, "shop opens and freezes the world")
	sh._buy(sh.entries[0])
	check("mu_a1" in GS.owned and GS.equip["mu"]["armor"] == "mu_a1", "buying armour equips it")
	check(GS.max_hp == before_hp + 1 and GS.gold == 430, "armour raises max hp and costs gold")
	sh.closed.emit()
	await frames(10)
	check(not lv.frozen, "closing the shop thaws the world")
	GS.hp = 2
	lv.player.use_supply("tonic")
	check(GS.hp == 5 and int(GS.supplies.get("tonic", 0)) == 0, "tonic heals three hearts")
	GS.save_game()
	var g0: int = GS.gold
	GS.gold = 0
	GS.equip = {}
	GS.load_game()
	check(GS.gold == g0 and GS.equip["mu"]["armor"] == "mu_a1" and GS.max_hp == before_hp + 1, "gear and gold survive save and load")
	var gear := load("res://src/core/gear.gd")
	check(gear.atk_bonus() == 0 and gear.def_total() >= 1, "gear stat maths")
	GS.owned.append("mu_w_f")
	check(gear.owned_for("mu", "weapon").size() >= 1, "owned_for lists weapons")
	lv.open_status()
	await frames(5)
	check(lv.frozen, "status screen opens and freezes")
	for ch in lv.get_children():
		if ch is CanvasLayer and ch.get_child_count() > 0 and ch.get_child(0).has_signal("closed") and not ch.get_child(0).has_method("_buy"):
			ch.get_child(0).closed.emit()
	await frames(10)
	check(not lv.frozen, "status screen closes")

	print("SMOKE TEST DONE, failures: %d" % fails)
	quit(fails)
