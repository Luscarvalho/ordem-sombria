extends SceneTree
## Combat sounds, pooling, impact limiting and independent saved effect volume.
const Music = preload("res://scripts/music.gd")
const SAVE_PATH := "res://work/sfx-settings-test.cfg"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work"))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.music.settings_path = SAVE_PATH
	for id in Music.SFX:
		var clip: AudioStreamWAV = Music.SFX[id]
		assert(clip.get_length() > 0.05 and clip.get_length() < 0.6)
		assert(clip.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	assert(game.music.sfx_players.size() == 8)
	for weapon in ["revolver", "shotgun", "wand"]:
		game.start_run(weapon)
		game._spawn_enemy(0)
		game.enemies[-1].position = Vector2(100, 0)
		game._fire(game.enemies[-1])
		assert(game.music.sfx_players.any(func(p): return p.get_meta("sound", "") == weapon and p.playing))
	# Simultaneous pellets make one short impact, not dozens of stacked sounds.
	game.music.last_sfx.clear()
	assert(game.music.play_sfx("enemy_hit"))
	assert(not game.music.play_sfx("enemy_hit"))
	assert(not game.music.play_sfx("unknown"))
	# Player damage triggers its own sound; a shield has a separate feedback sound.
	game.start_run("revolver")
	game._spawn_enemy(0)
	game.enemies[-1].position = Vector2(10, 0)
	game.invincible = 0
	game._update_enemies(0.01)
	assert(game.health < 100)
	assert(game.music.sfx_players.any(func(p): return p.get_meta("sound", "") == "player_hurt"))
	game.stacks.shield = 1
	game.buffs.shield_ready = true
	game.invincible = 0
	var before: float = game.health
	game._update_enemies(0.01)
	assert(game.health == before)
	assert(game.music.sfx_players.any(func(p): return p.get_meta("sound", "") == "shield_block"))
	# Music mute leaves effects adjustable, and sliders update already-active voices.
	game.music.set_enabled(false)
	game.music.set_volume("effects", 0.23)
	for voice in game.music.sfx_players:
		assert(is_equal_approx(voice.volume_linear, 0.23 * float(voice.get_meta("gain", 1.0))))
	game.toggle_pause()
	game.ui.show_settings()
	game.ui.content.find_child("EffectsVolume", true, false).value = 0
	assert(not game.music.play_sfx("revolver"))
	for voice in game.music.sfx_players:
		assert(voice.volume_linear == 0.0)
	game.ui.content.find_child("EffectsVolume", true, false).value = 37
	var restored := Music.new()
	restored.settings_path = SAVE_PATH
	root.add_child(restored)
	assert(is_equal_approx(restored.volumes.effects, 0.37) and not restored.enabled)
	# Old settings files still gain a safe default for the new sound category.
	var old := ConfigFile.new()
	old.set_value("music", "enabled", true)
	old.set_value("music", "menu_volume", 0.2)
	assert(old.save(SAVE_PATH) == OK)
	var migrated := Music.new()
	migrated.settings_path = SAVE_PATH
	root.add_child(migrated)
	assert(is_equal_approx(migrated.volumes.effects, 0.55))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	game.queue_free()
	restored.queue_free()
	migrated.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: distinct weapon/damage/block sounds, limited impacts, voice pool, independent volume, persistence and old settings migration")
	quit()
