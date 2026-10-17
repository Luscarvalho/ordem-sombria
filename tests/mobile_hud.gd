extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.ui.free()
	var ui = game.Interface.new()
	ui.game = game
	ui.mobile_hud = true
	game.ui = ui
	game.add_child(ui)
	game.start_run("revolver")
	game.spawn_clock = 999
	game.health = 78
	game.weapon_cycle.ammo = 4
	ui.update_hud()
	var sizes := [Vector2i(1170, 540), Vector2i(960, 540), Vector2i(640, 360), Vector2i(480, 320), Vector2i(540, 960), Vector2i(1170, 540)]
	for viewport_size in sizes:
		root.size = viewport_size
		root.content_scale_size = viewport_size
		for frame in range(3):
			await process_frame
		var dimensions: Vector2 = game.get_viewport_rect().size
		var factor: float = minf(ui.MOBILE_HUD_SCALE, maxf(1.0, dimensions.x / 480.0))
		assert(ui.hud.scale == Vector2.ONE * factor)
		assert(is_equal_approx(ui.hud.get_global_rect().size.x, dimensions.x), "HUD scaling extends past the viewport")
		assert(is_equal_approx(ui.xp_bar.get_global_rect().size.x, dimensions.x))
		for control in [ui.health_bar, ui.health_label, ui.ammo_button, ui.ammo_bar, ui.status_label, ui.level_label, ui.pause_button]:
			var bounds: Rect2 = control.get_global_rect()
			assert(bounds.position.x >= 0 and bounds.position.y >= 0)
			assert(bounds.end.x <= dimensions.x and bounds.end.y <= dimensions.y, control.name + " leaves the phone viewport")
		assert(not ui.health_label.get_global_rect().intersects(ui.status_label.get_global_rect()))
		assert(not ui.status_label.get_global_rect().intersects(ui.level_label.get_global_rect()))
		assert(not ui.level_label.get_global_rect().intersects(ui.pause_button.get_global_rect()))
		var pause_size: Vector2 = ui.pause_button.get_global_rect().size
		assert(pause_size.x >= 44 * factor and pause_size.y >= 44 * factor)
		assert(is_equal_approx(ui.ammo_bar.get_global_rect().get_center().y, ui.ammo_button.get_global_rect().get_center().y), "Reload text and ammo bar no longer align")
		assert(game.camera.zoom == Vector2.ONE and game.player.position == Vector2.ZERO)
	assert(ui.hud.scale == Vector2(1.5, 1.5))
	assert(ui.pause_button.get_theme_stylebox("normal") is not StyleBoxEmpty)
	assert(ui.pause_button.get_global_rect().size == Vector2(66, 66))
	assert(ui.health_label.get_global_rect().size.y >= 18)
	assert(ui.ammo_button.get_global_rect().size.y == 66)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = ui.pause_button.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	var release := click.duplicate() as InputEventMouseButton
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	assert(game.state == "paused" and ui.overlay.visible)
	game.toggle_pause()
	ui.ammo_button.pressed.emit()
	assert(game.weapon_cycle.reloading and ui.ammo_bar.segments == 1)
	var boss = game.encounters.spawn_boss(1)
	ui.update_hud()
	for frame in range(3):
		await process_frame
	assert(ui.boss_panel.visible and ui.boss_health.max_value == boss.max_hp)
	assert(ui.boss_panel.get_global_rect().position.y >= ui.hud.get_global_rect().end.y)
	assert(is_equal_approx(ui.boss_health.get_global_rect().size.y, 9.0))
	game.return_to_menu()
	assert(not ui.hud.visible and not ui.boss_panel.is_visible_in_tree())
	game.start_run("wand")
	assert(ui.hud.visible and ui.health_label.text == "100" and ui.hud.scale == Vector2(1.5, 1.5))
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = Vector2(180, 380)
	touch.pressed = true
	game._unhandled_input(touch)
	assert(game.touch_index == 3 and game.touch_origin == touch.position)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = touch.position + Vector2(110, -20)
	game._input(drag)
	assert(game.touch_position == drag.position and game.touch_origin == touch.position)
	drag.index = 4
	drag.position = Vector2.ZERO
	game._input(drag)
	assert(game.touch_position != drag.position, "Second finger takes control of the joystick")
	touch.pressed = false
	game._input(touch)
	assert(game.touch_index == -1)
	touch.pressed = true
	game._unhandled_input(touch)
	game.toggle_pause()
	assert(game.touch_index == -1 and game.state == "paused")
	game.toggle_pause()
	assert(game.touch_index == -1)
	game.queue_free()
	await process_frame
	print("PASS: 50-percent mobile-only HUD scale, six viewport/rotation cases, visible 66-unit pause target, aligned ammo, input actions, boss layout, floating joystick drag/release/multitouch/pause, clean reset and unchanged camera/world")
	quit()
