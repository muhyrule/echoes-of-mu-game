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

	var boss: Node2D
	for e in get_nodes_in_group("enemies"):
		if e.kind == "warden":
			boss = e
	check(boss != null, "boss present")
	lv.player.global_position = boss.global_position + Vector2(60, 0)
	await frames(600)
	check(boss.state != "dormant", "boss wakes")
	boss.hp = 2
	boss.hurt(2, Vector2.LEFT)
	await frames(1200)
	check(GS.flag("edinburgh_done"), "boss defeat completes the slice")
	var portal_ok := false
	for p in lv.walkovers:
		if is_instance_valid(p) and p.kind == "final":
			portal_ok = true
	check(portal_ok, "return portal spawned")

	GS.save_game()
	var before: Dictionary = GS.flags.duplicate()
	GS.new_game()
	check(GS.load_game() and GS.flags == before, "save/load round trip")

	print("SMOKE TEST DONE, failures: %d" % fails)
	quit(fails)
