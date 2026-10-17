extends SceneTree
## Run with Godot -s tools/presentation_test.gd; add -- --capture=/absolute/folder for images.

const Materials = preload("res://src/core/pixel_materials.gd")
const Art = preload("res://src/core/art.gd")
const CAPTURE_MAPS := ["chapel", "edinburgh", "prague_town", "vaults", "prague", "lantern_inn", "vault_arena", "prague_arena", "keep_arena", "ossuary_arena", "cliff_arena", "lazaretto_arena", "cave_arena"]

var failures := 0
var capture := ""
var state: Node


class Figure extends Node2D:
	var palette: Dictionary
	var facing := Vector2.DOWN
	var clock := 1.3
	var moving := true

	func _draw() -> void:
		Art.person(self, facing, clock, palette, moving)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture = arg.trim_prefix("--capture=")
	run.call_deferred()


func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1


func frames(count := 3) -> void:
	for frame in count:
		await process_frame


func screenshot(name: String) -> void:
	if capture.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	check(image.save_png(capture.path_join(name + ".png")) == OK, "capture: " + name)


func run() -> void:
	if not capture.is_empty():
		check(DisplayServer.get_name() != "headless", "captures require a rendering display")
		if DisplayServer.get_name() == "headless":
			quit(1)
			return
		check(DirAccess.make_dir_recursive_absolute(capture) == OK, "capture directory")
	state = root.get_node("GameState")
	state.new_game()
	state.set_flag("intro_done")
	state.party = ["isolde", "wren", "corvin"]
	for material in Materials.PALETTES:
		var hashes: Dictionary = {}
		for variant in 8:
			var image: Image = Materials.image_for(material, variant)
			check(image.get_size() == Vector2i(32, 32), "%s/%d pixel dimensions" % [material, variant])
			check(not image.detect_alpha(), "%s/%d opaque terrain" % [material, variant])
			check(image.get_data() == Materials.image_for(material, variant).get_data(), "%s/%d deterministic art" % [material, variant])
			hashes[hash(image.get_data())] = true
		check(hashes.size() > 1, material + " has visual variation")
		check(Materials.texture(material, 0) == Materials.texture(material, 8), material + " reuses bounded texture cache")

	var maps := DirAccess.get_files_at("res://data/maps")
	for file in maps:
		if not file.ends_with(".json"):
			continue
		var map_name := file.trim_suffix(".json")
		state.current_map = map_name
		state.spawn = "start"
		change_scene_to_file(state.LEVEL_SCENE)
		await frames()
		var level: Node2D = current_scene
		check(level != null and level.player != null, map_name + " loads")
		if level == null or level.player == null:
			continue
		level.hud.banner_t = 0
		level.hud.title_t = 0
		check(level.grid.size() == level.h, map_name + " retains map dimensions")
		check(level.cam.zoom.x >= 2.0, map_name + " retains camera scale")
		level.cam.reset_smoothing()
		level.cam.force_update_scroll()
		await frames(2)
		var feet: Vector2 = level.player.get_global_transform_with_canvas().origin
		var dock: Vector2 = level.hud.get_global_transform_with_canvas() * Vector2(0, level.hud.DOCK_TOP * 3)
		check(feet.y + 6 * level.cam.zoom.y < dock.y, map_name + " keeps hero feet above command bar")
		if map_name in CAPTURE_MAPS:
			paused = true
			for enemy in get_nodes_in_group("enemies"):
				if enemy.is_boss:
					enemy.state = "idle"
					enemy.phase = 2
					enemy.t = 2.5
					enemy.position = level.player.position + Vector2(0, -85)
					enemy.queue_redraw()
			level.cam.force_update_scroll()
			await frames(2)
			await screenshot(map_name)
			paused = false
		if map_name == "lantern_inn":
			level.open_status()
			await frames()
			await screenshot("inventory")
			for child in level.get_children():
				if child is CanvasLayer and child.layer == 20:
					var status: Control = child.get_child(0)
					for hero_index in status.heroes.size():
						status.hero_i = hero_index
						status._sync()
						status.queue_redraw()
						await frames()
						await screenshot("portrait_" + status.heroes[hero_index])
			for child in level.get_children():
				if child is CanvasLayer and child.layer == 20:
					child.get_child(0).closed.emit()
			await frames()
			level.open_shop("armor", 2)
			await frames()
			await screenshot("shop")
			for child in level.get_children():
				if child is CanvasLayer and child.layer == 20:
					child.get_child(0).closed.emit()
			await frames()
		check(Materials.cache.size() <= Materials.PALETTES.size() * 8, "material cache remains bounded")

	change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
	await frames()
	current_scene.intro = 1.0
	current_scene.t = 3.0
	current_scene.queue_redraw()
	await screenshot("menu")

	for party in [[], ["isolde"], ["wren", "corvin"], ["isolde", "wren", "corvin"]]:
		state.party = party
		state.journey_from = "chapel"
		state.journey_to = "edinburgh"
		change_scene_to_file("res://src/scenes/travel/Travel.tscn")
		await frames()
		var travel: Control = current_scene
		travel.set_process(false)
		travel.t = 6.0
		travel.fade = 0
		travel.queue_redraw()
		check(travel.cast.size() == party.size() + 1, "travel renders only active party")
		for hero in travel.cast:
			check(hero == "mu" or hero in party, "travel cast member is active: " + hero)
			check(travel.PALETTES[hero] == {"mu": Art.PAL_MU, "isolde": Art.PAL_ISOLDE, "wren": Art.PAL_WREN, "corvin": Art.PAL_CORVIN}[hero], "travel shares gameplay palette: " + hero)
		await screenshot("travel_%d" % party.size())

	var sheet := Node2D.new()
	root.add_child(sheet)
	current_scene.queue_free()
	current_scene = sheet
	var palettes := [Art.PAL_MU, Art.PAL_ISOLDE, Art.PAL_WREN, Art.PAL_CORVIN]
	var directions := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]
	for hero in palettes.size():
		for direction in directions.size():
			var figure := Figure.new()
			figure.palette = palettes[hero]
			figure.facing = directions[direction]
			figure.position = Vector2(280 + direction * 420, 225 + hero * 260)
			figure.scale = Vector2(9, 9)
			sheet.add_child(figure)
	await frames()
	await screenshot("hero_directions")
	if not capture.is_empty():
		await RenderingServer.frame_post_draw
		var before: PackedByteArray = root.get_texture().get_image().get_data()
		for figure in sheet.get_children():
			figure.clock += 0.19
			figure.queue_redraw()
		await frames()
		await RenderingServer.frame_post_draw
		check(before != root.get_texture().get_image().get_data(), "walking animation changes the rendered pose")
		await screenshot("hero_stride")
	print("PRESENTATION TEST DONE, failures: %d" % failures)
	quit(1 if failures else 0)
