extends SceneTree
## Freeze combat, play a quick aura, then reveal exactly one card selection.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock = 999
	game._spawn_enemy(0)
	game.enemies[-1].position = Vector2(200, 0)
	game.experience = game.next_level + 5
	game._physics_process(0.01)
	assert(game.state == "levelup" and game.level == 2)
	assert(game.level_up_aura.active and game.level_up_aura.visible)
	assert(not game.ui.overlay.visible and game.ui.hud.visible)
	assert(game.music.sfx_players.any(func(p): return p.get_meta("sound", "") == "level_up"))
	assert(game.experience == 5)
	var time_before: float = game.elapsed
	var enemy_position: Vector2 = game.enemies[-1].position
	var player_position: Vector2 = game.player.position
	var frame: int = game.player.sprite.frame
	var hp: float = game.health
	game.select_upgrade(0)
	assert(game.stacks.is_empty(), "The aura cannot be skipped by selecting an invisible card")
	game._physics_process(0.20)
	assert(game.state == "levelup")
	assert(game.elapsed == time_before and game.health == hp)
	assert(game.enemies[-1].position == enemy_position and game.player.position == player_position)
	assert(game.player.sprite.frame == frame, "The aura must not continue the walk cycle")
	# Pause/settings/background interruption preserve the effect's remaining time.
	var aura_time: float = game.level_up_aura.elapsed
	game.toggle_pause()
	assert(game.state == "paused" and game.previous_state == "levelup")
	game.ui.show_settings()
	game._physics_process(4.0)
	assert(game.level_up_aura.elapsed == aura_time)
	game.ui.go_back()
	game.toggle_pause()
	assert(game.state == "levelup")
	game._physics_process(0.34)
	assert(game.state == "levelup" and not game.ui.overlay.visible)
	game._physics_process(0.02)
	assert(game.state == "upgrade" and game.ui.screen == "upgrades")
	assert(game.ui.overlay.visible and not game.level_up_aura.visible)
	assert(game.elapsed == time_before and game.level == 2)
	game._physics_process(1.0)
	assert(game.state == "upgrade" and game.level == 2)
	game.select_upgrade(0)
	assert(game.state == "playing" and game.stacks.size() == 1)
	assert(not game.ui.overlay.visible and game.ui.overlay.modulate.a == 1.0)
	# Aborting during the aura cannot open stale cards in a subsequent run.
	game.experience = game.next_level
	game._physics_process(0.01)
	assert(game.state == "levelup")
	game.return_to_menu()
	assert(not game.level_up_aura.active)
	game._physics_process(2.0)
	assert(game.ui.screen == "home")
	game.start_run("wand")
	assert(not game.level_up_aura.active and game.level == 1 and game.stacks.is_empty())
	game.queue_free()
	await process_frame
	print("PASS: quick aura before cards, one level/selection, preserved XP, frozen combat, pause/settings/resume, input gating and clean reset")
	quit()
