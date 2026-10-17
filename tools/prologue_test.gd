extends SceneTree
## godot --path . -s tools/prologue_test.gd [-- --capture=/absolute/output/folder]

var failures := 0
var capture := ""
var contact_sheet: Image


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture = arg.trim_prefix("--capture=")
	run.call_deferred()


func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1


func run() -> void:
	var state := root.get_node("GameState")
	state.new_game()
	var scene: PackedScene = load("res://src/scenes/prologue/Prologue.tscn")
	change_scene_to_packed(scene)
	for frame in 3:
		await process_frame
	var prologue: Control = current_scene
	check(prologue != null, "prologue scene instantiated")
	if prologue == null:
		quit(1)
		return
	prologue.set_process(false)
	check(prologue.PLATES.size() == 24, "24 story plates retained")
	var arts: Dictionary = {}
	if not capture.is_empty():
		check(DirAccess.make_dir_recursive_absolute(capture) == OK, "capture directory available")
		contact_sheet = Image.create(1920, 720, false, Image.FORMAT_RGB8)
	for index in prologue.PLATES.size():
		var plate: Dictionary = prologue.PLATES[index]
		check(not arts.has(plate.art), "unique illustration: " + plate.art)
		arts[plate.art] = true
		var duration: float = prologue._dur(index)
		check(duration > plate.text.length() / prologue.CPS + 10, "reading allowance: " + plate.art)
		prologue.idx = index
		prologue.layer_a.art = plate.art
		prologue.layer_a.duration = duration
		for sample in 3:
			prologue.t = duration * [0.12, 0.5, 0.85][sample]
			prologue.typed = plate.text.length()
			prologue._process(0.0)
			check(is_equal_approx(prologue.layer_a._beat(0.12, 0.85), [0.0, smoothstep(0.12, 0.85, 0.5), 1.0][sample]), "normalized staging: %s/%d" % [plate.art, sample])
			await process_frame
			if not capture.is_empty():
				await RenderingServer.frame_post_draw
				var image := root.get_viewport().get_texture().get_image()
				image.resize(960, 540, Image.INTERPOLATE_LANCZOS)
				check(image.save_png(capture.path_join("%02d_%s_%d.png" % [index + 1, plate.art, sample])) == OK, "captured: %s/%d" % [plate.art, sample])
				if sample == 1:
					image.resize(320, 180, Image.INTERPOLATE_LANCZOS)
					image.convert(Image.FORMAT_RGB8)
					contact_sheet.blit_rect(image, Rect2i(0, 0, 320, 180), Vector2i((index % 6) * 320, (index / 6) * 180))
		if index < prologue.PLATES.size() - 1:
			prologue.t = duration - prologue.XFADE * 0.5
			prologue._process(0.0)
			check(prologue.layer_b.art == prologue.PLATES[index + 1].art, "incoming illustration: " + plate.art)
			check(is_equal_approx(prologue.layer_b.modulate.a, 0.5), "midpoint dissolve: " + plate.art)
			prologue.t = duration - 0.001
			prologue._process(0.002)
			check(prologue.idx == index + 1, "advance: " + plate.art)
			check(is_equal_approx(prologue.layer_a.t, prologue.XFADE), "continuous incoming time: " + plate.art)
			check(is_equal_approx(prologue.layer_a.duration, prologue._dur(index + 1)), "incoming duration: " + plate.art)
	if not capture.is_empty():
		check(contact_sheet.save_png(capture.path_join("contact_sheet.png")) == OK, "contact sheet saved")
	prologue.idx = 0
	prologue.t = 5
	prologue.typed = 0
	Input.action_press("ui_accept")
	prologue._process(0.0)
	check(prologue.typed == prologue.PLATES[0].text.length(), "Enter completes text before advancing")
	Input.action_release("ui_accept")
	await process_frame
	Input.action_press("ui_accept")
	prologue._process(0.0)
	check(is_equal_approx(prologue.t, prologue._dur(0) - prologue.XFADE), "second Enter begins dissolve")
	Input.action_release("ui_accept")
	prologue.idx = 23
	prologue.t = prologue._dur(23) - 0.001
	var post_ref: WeakRef = weakref(prologue.post)
	prologue._process(0.002)
	for frame in 3:
		await process_frame
	check(state.flag("prologue_seen"), "completion persists prologue flag")
	check(post_ref.get_ref() == null, "prologue effects removed on departure")
	print("PROLOGUE TEST DONE, failures: %d" % failures)
	quit(1 if failures else 0)
