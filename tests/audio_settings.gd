extends SceneTree
## Integration coverage for persistent preferences and pause/menu navigation.

const Music = preload("res://scripts/music.gd")
const SAVE_PATH := "res://work/audio-test.cfg"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://work"))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.music.set_process(false)
	game.music.settings_path = SAVE_PATH
	game.music.set_enabled(true)
	game.music.set_volume("menu", 0.4)
	game.music.set_volume("game", 0.35)
	assert(game.music.context == "menu")
	game.music._process(2.0)
	assert(game.music.players.menu.playing)
	assert(is_equal_approx(game.music.players.menu.volume_linear, 0.4))
	for id in ["menu", "game"]:
		var stream: AudioStreamWAV = game.music.players[id].stream
		assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
		assert(stream.loop_begin == 0 and stream.loop_end > 600000)
		assert(stream.get_length() > 25.0)

	game.ui.content.find_child("SettingsButton", true, false).pressed.emit()
	assert(game.ui.screen == "settings" and game.state == "menu")
	game.ui.content.find_child("MenuVolume", true, false).value = 27
	assert(is_equal_approx(game.music.volumes.menu, 0.27))
	assert(is_equal_approx(game.music.players.menu.volume_linear, 0.27))
	game.ui.content.find_child("MusicToggle", true, false).button_pressed = false
	assert(not game.music.enabled)
	assert(game.music.players.menu.volume_linear == 0.0)
	game.ui.content.find_child("BackButton", true, false).pressed.emit()
	assert(game.ui.screen == "home")

	game.start_run("revolver")
	assert(game.music.context == "game")
	game.music._process(0.6)
	assert(game.music.players.menu.playing and game.music.players.game.playing)
	assert(is_equal_approx(game.music.weights.menu, 0.5))
	game.music._process(0.6)
	assert(not game.music.players.menu.playing)
	assert(game.music.players.game.playing)
	assert(game.music.players.game.volume_linear == 0.0, "Mute must survive a track change")
	game.music._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert(game.music.players.game.stream_paused)
	game.music._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert(not game.music.players.game.stream_paused)
	game.toggle_pause()
	game.ui.content.find_child("SettingsButton", true, false).pressed.emit()
	assert(game.ui.screen == "settings" and game.state == "paused")
	assert(game.music.context == "game", "Pause settings retain the gameplay score")
	var time_before: float = game.elapsed
	game._physics_process(10)
	assert(game.elapsed == time_before, "Settings must freeze combat")
	game.ui.content.find_child("GameVolume", true, false).value = 63
	game.ui.content.find_child("MusicToggle", true, false).button_pressed = true
	assert(is_equal_approx(game.music.players.game.volume_linear, 0.63))
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	game._unhandled_input(escape)
	assert(game.ui.screen == "pause" and game.state == "paused")
	game.ui.show_settings()
	game.toggle_pause() # P from settings returns to pause rather than restarting combat.
	assert(game.ui.screen == "pause" and game.state == "paused")
	game.toggle_pause()
	assert(game.state == "playing")
	game.return_to_menu()
	assert(game.music.context == "menu")
	game.music._process(2)
	assert(not game.music.players.game.playing)
	assert(is_equal_approx(game.music.players.menu.volume_linear, 0.27))

	# Reload a fresh manager to verify disk persistence, including mute.
	game.music.set_enabled(false)
	var restored := Music.new()
	restored.settings_path = SAVE_PATH
	root.add_child(restored)
	assert(not restored.enabled)
	assert(is_equal_approx(restored.volumes.menu, 0.27))
	assert(is_equal_approx(restored.volumes.game, 0.63))
	# Preferences cannot produce invalid gains even if the saved file is edited.
	var config := ConfigFile.new()
	config.set_value("music", "enabled", "invalid")
	config.set_value("music", "menu_volume", 30)
	config.set_value("music", "game_volume", -10)
	assert(config.save(SAVE_PATH) == OK)
	var safe := Music.new()
	safe.settings_path = SAVE_PATH
	root.add_child(safe)
	assert(safe.enabled and safe.volumes.menu == 1.0 and safe.volumes.game == 0.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	game.queue_free()
	restored.queue_free()
	safe.queue_free()
	await process_frame
	# AudioServer releases stopped playbacks on its own mixing thread.
	await create_timer(0.15).timeout
	print("PASS: looping tracks, crossfade, live volumes, mute, persistence, settings navigation and frozen combat")
	quit()
