extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func assert_inside(control: Control, viewport_size: Vector2) -> void:
	var bounds := control.get_global_rect()
	assert(bounds.position.x >= 0.0 and bounds.position.y >= 0.0, control.name + " starts outside the viewport")
	assert(bounds.end.x <= viewport_size.x and bounds.end.y <= viewport_size.y, control.name + " extends outside the viewport")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.elapsed = 138.0
	game.health = 78
	game.level = 8
	game.experience = 140
	game.next_level = 250
	game.kills = 93
	game.weapon_cycle.ammo = 4
	game.ui.update_hud()
	var ui = game.ui
	assert(ui.status_label.text == "02:18" and ui.health_label.text == "78" and ui.level_label.text == "NV 8")
	assert(ui.xp_bar.value == 140 and ui.xp_bar.max_value == 250)
	assert(ui.health_bar.value == 78 and ui.health_bar.max_value == 100)
	assert(ui.ammo_button.text == "4/6" and ui.ammo_bar.segments == 6)
	assert(ui.xp_bar.flat and ui.health_bar.flat and not ui.ammo_bar.flat)
	assert(ui.hud.mouse_filter == Control.MOUSE_FILTER_IGNORE and not ui.boss_panel.visible)
	for viewport_size in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(480, 320), Vector2i(540, 960)]:
		root.size = viewport_size
		root.content_scale_size = viewport_size
		for frame in range(3):
			await process_frame
		var dimensions: Vector2 = game.get_viewport_rect().size
		assert(ui.hud.size.y <= 52 and ui.xp_bar.size.y == 4)
		assert(is_equal_approx(ui.xp_bar.size.x, dimensions.x))
		assert(ui.health_bar.size == Vector2(80, 6) and ui.ammo_bar.size == Vector2(62, 8))
		for control in [ui.health_bar, ui.health_label, ui.ammo_button, ui.ammo_bar, ui.status_label, ui.level_label, ui.pause_button]:
			assert_inside(control, dimensions)
		assert(not ui.health_label.get_global_rect().intersects(ui.status_label.get_global_rect()))
		assert(not ui.ammo_button.get_global_rect().intersects(ui.pause_button.get_global_rect()))
		assert(not ui.status_label.get_global_rect().intersects(ui.level_label.get_global_rect()))
		assert(not ui.level_label.get_global_rect().intersects(ui.pause_button.get_global_rect()))
		assert(ui.pause_button.size.x >= 44 and ui.pause_button.size.y >= 44)
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	ui.ammo_button.pressed.emit()
	assert(game.weapon_cycle.reloading and ui.ammo_bar.segments == 1)
	assert(ui.ammo_button.text.begins_with("REC ") and ui.ammo_button.disabled)
	ui.pause_button.pressed.emit()
	assert(game.state == "paused" and ui.screen == "pause" and ui.overlay.visible)
	var summary := ""
	for child in ui.content.get_children():
		if child is Label:
			summary += child.text + "\n"
	assert("93 ABATES" in summary and "VIDA 78/100" in summary and "REVÓLVER" in summary)
	assert("OLHOS VIGIAS" in summary and "CHEFE EM 02:42" in summary and "RECARREGAR" in summary)
	game.toggle_pause()
	assert(game.state == "playing" and not ui.overlay.visible and ui.hud.visible)
	var boss = game.encounters.spawn_boss(1)
	boss.hp = boss.max_hp * 0.4
	boss.brain.enraged = true
	ui.update_hud()
	for viewport_size in [Vector2i(960, 540), Vector2i(480, 320)]:
		root.size = viewport_size
		root.content_scale_size = viewport_size
		for frame in range(3):
			await process_frame
		assert(ui.boss_panel.visible and ui.boss_health.flat and ui.boss_health.size.y == 6)
		assert(ui.boss_panel.size.y <= 28 and ui.boss_panel.position.y >= ui.hud.size.y)
		assert_inside(ui.boss_panel, game.get_viewport_rect().size)
	assert(ui.boss_health.value == boss.hp and ui.boss_health.max_value == boss.max_hp and "FÚRIA" in ui.boss_name.text)
	game.toggle_pause()
	assert(not ui.boss_panel.visible)
	game.toggle_pause()
	ui.update_hud()
	assert(ui.boss_panel.visible)
	boss.hp = 0
	ui.update_hud()
	assert(not ui.boss_panel.visible)
	game.return_to_menu()
	assert(not ui.hud.visible and not ui.boss_panel.visible)
	game.start_run("wand")
	assert(ui.hud.visible and ui.level_label.text == "NV 1" and ui.health_label.text == "100")
	game.queue_free()
	await process_frame
	print("PASS: minimal HUD bounds in four viewport sizes, thin edge XP, compact vitals/ammo, touch-sized pause, reload interaction, pause details, boss health/fury visibility and reset")
	quit()
