extends SceneTree
## Run: godot --headless --path . --script res://tests/actor_animation.gd

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_run("revolver")
	for kind in range(5):
		var actor = game.player
		if kind > 0:
			game._spawn_enemy(kind - 1)
			actor = game.enemies[-1]
		var frames: SpriteFrames = actor.sprite.sprite_frames
		assert(frames.get_frame_count("walk") == (8 if kind == 0 else 6))
		var canvas := frames.get_frame_texture("walk", 0).get_size()
		for i in range(frames.get_frame_count("walk")):
			assert(frames.get_frame_texture("walk", i).get_size() == canvas, "Frame dimensions must remain aligned")
		actor.motion = Vector2.RIGHT * actor.REFERENCE_SPEEDS[kind]
		actor.moving = true
		var observed := {}
		for tick in range(120):
			actor.animate(1.0 / 60.0)
			observed[actor.sprite.frame] = true
		assert(observed.size() == frames.get_frame_count("walk"), "Animation did not visit every frame")
		actor.moving = false
		actor.motion = Vector2.ZERO
		for tick in range(60):
			actor.animate(1.0 / 60.0)
		assert(actor.sprite.animation == ("walk" if kind == 2 else "idle"))
	game.player.aim = Vector2.LEFT
	game.player.on_shot()
	assert(game.player.recoil > 0 and game.player.muzzle_flash > 0)
	for tick in range(20):
		game.player.animate(1.0 / 60.0)
	assert(game.player.sprite.flip_h)
	for tick in range(60):
		game.player.animate(1.0 / 60.0)
	assert(game.player.recoil == 0 and game.player.muzzle_flash == 0)
	game.player.motion = Vector2.RIGHT * 170
	game.player.moving = true
	game.player.animate(0.15)
	game.toggle_pause()
	var frame: int = game.player.sprite.frame
	var transform: Transform2D = game.player.sprite.transform
	game._physics_process(0.5)
	assert(game.player.sprite.frame == frame and game.player.sprite.transform == transform, "Pause must freeze animation")
	game.toggle_pause()
	# Acceleration and stopping must remain independent of physics frequency.
	var distances: Array[float] = []
	for hz in [30, 60, 120]:
		game.start_run("revolver")
		game.spawn_clock = 999
		Input.action_press("move_right")
		for tick in range(hz):
			game._physics_process(1.0 / hz)
		Input.action_release("move_right")
		for tick in range(hz / 2):
			game._physics_process(1.0 / hz)
		assert(game.player_velocity == Vector2.ZERO, "Character failed to stop")
		distances.append(game.player.position.x)
	assert(distances.max() - distances.min() < 3, "Movement depends too much on tick rate")
	game.start_run("wand")
	assert(game.player.sprite.animation == "idle" and game.player.recoil == 0 and game.player_velocity == Vector2.ZERO)
	# Vertical movement has its own front/back art and retains that idle facing.
	for direction in [Vector2.UP, Vector2.DOWN]:
		game.start_run("revolver")
		var suffix := "up" if direction.y < 0 else "down"
		game.player.motion = direction * 170
		game.player.moving = true
		var observed := {}
		for tick in range(90):
			game.player.animate(1.0 / 60.0)
			observed[game.player.sprite.frame] = true
		assert(game.player.sprite.animation == StringName("walk_" + suffix))
		assert(observed.size() == 8)
		var canvas: Vector2 = game.player.sprite.sprite_frames.get_frame_texture(game.player.sprite.animation, 0).get_size()
		assert(is_equal_approx(canvas.y * game.player.base_scale, game.Data.HEIGHTS[0]), "Facing changed body scale")
		game.player.aim = Vector2.LEFT
		game.player.on_shot()
		game.player.animate(0.20)
		assert(game.player.sprite.animation == &"walk" and game.player.sprite.flip_h, "Body must face a shot to the left while moving vertically")
		# After the last shot settles and no target remains, movement sets facing.
		game.player.animate(0.3)
		assert(game.player.sprite.animation == StringName("walk_" + suffix))
		game.player.moving = false
		game.player.motion = Vector2.ZERO
		for tick in range(60):
			game.player.animate(1.0 / 60.0)
		assert(game.player.sprite.animation == StringName("idle_" + suffix))
		game.player.motion = Vector2.RIGHT * 170
		game.player.moving = true
		game.player.animate(0.2)
		assert(game.player.sprite.animation == &"walk")
	game.start_run("revolver")
	assert(game.player.facing == &"side" and game.player.sprite.animation == &"idle")
	print("PASS: monster cycles, front/back/side walk and idle, shot facing, movement fallback, scale, pause, recoil and reset")
	game.queue_free()
	await process_frame
	quit()
