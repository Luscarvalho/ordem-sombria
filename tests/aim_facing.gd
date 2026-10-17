extends SceneTree
## Run: godot --headless --path . --script res://tests/aim_facing.gd

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var cases := [
		{"target": Vector2.UP, "inputs": ["move_down"], "animation": &"walk_up", "flip": false},
		{"target": Vector2.DOWN, "inputs": ["move_up"], "animation": &"walk_down", "flip": false},
		{"target": Vector2.LEFT, "inputs": ["move_right"], "animation": &"walk", "flip": true},
		{"target": Vector2.RIGHT, "inputs": ["move_left"], "animation": &"walk", "flip": false},
		{"target": Vector2(1, -1).normalized(), "inputs": ["move_down", "move_left"], "animation": &"walk_up_diagonal", "flip": false},
		{"target": Vector2(-1, -1).normalized(), "inputs": ["move_down", "move_right"], "animation": &"walk_up_diagonal", "flip": true},
		{"target": Vector2(1, 1).normalized(), "inputs": ["move_up", "move_left"], "animation": &"walk_down_diagonal", "flip": false},
		{"target": Vector2(-1, 1).normalized(), "inputs": ["move_up", "move_right"], "animation": &"walk_down_diagonal", "flip": true},
	]
	for weapon in ["revolver", "shotgun", "wand"]:
		for scenario in cases:
			game.start_run(weapon)
			game.spawn_clock = 999
			game._spawn_enemy(0)
			var target = game.enemies[0]
			target.speed = 0
			target.hp = 100000
			target.max_hp = 100000
			for action in scenario.inputs:
				Input.action_press(action)
			var observed := {}
			for tick in range(36):
				await physics_frame
				target.position = game.player.position + scenario.target * 110
				var clock_before: float = game.player.animation_clock
				game._physics_process(1.0 / 60.0)
				assert(game.player.aiming, "Reachable target was lost")
				if tick >= 20: # Smooth turns may traverse intermediate poses for up to 0.3 s.
					assert(game.player.sprite.animation == scenario.animation, "Body faces movement instead of target: " + weapon)
					assert(game.player.sprite.flip_h == scenario.flip)
					assert(game.player.animation_clock < clock_before, "Opposite movement should reverse the walk cycle")
				observed[game.player.sprite.frame] = true
			assert(observed.size() > 1, "Backpedaling animation is static")
			for action in scenario.inputs:
				Input.action_release(action)
	# Losing the target restores movement-facing after a short shot settle.
	game.start_run("shotgun")
	game.spawn_clock = 999
	game._spawn_enemy(0)
	game.enemies[0].speed = 0
	game.enemies[0].hp = 10000
	game.enemies[0].position = Vector2(0, -100)
	Input.action_press("move_down")
	game.shot_clock = 0
	for tick in range(12):
		await physics_frame
		game._physics_process(1.0 / 60.0)
	assert(game.player.facing == &"up")
	game.enemies[0].position = Vector2(0, -1000)
	for tick in range(18):
		await physics_frame
		game._physics_process(1.0 / 60.0)
	assert(not game.player.aiming and game.player.facing == &"down")
	Input.action_release("move_down")
	# Stationary shooting still tracks the target while the body turns smoothly.
	game.start_run("revolver")
	game.player.aim = Vector2.UP
	game.player.on_shot()
	game.player.aiming = true
	game.player.animate(0.20)
	assert(game.player.sprite.animation == &"idle_up")
	game.player.aim = Vector2.DOWN
	game.player.on_shot()
	game.player.animate(0.30)
	assert(game.player.sprite.animation == &"idle_down")
	# Diagonal movement and standing use the same diagonal art without a target.
	for direction in [Vector2(1,-1), Vector2(-1,-1), Vector2(1,1), Vector2(-1,1)]:
		game.start_run("revolver")
		game.player.motion = direction.normalized() * 170
		game.player.moving = true
		game.player.animate(0.3)
		var suffix := "up_diagonal" if direction.y < 0 else "down_diagonal"
		assert(game.player.sprite.animation == StringName("walk_" + suffix))
		assert(game.player.sprite.flip_h == (direction.x < 0))
		game.player.motion = Vector2.ZERO
		game.player.moving = false
		game.player.animate(0.5)
		assert(game.player.sprite.animation == StringName("idle_" + suffix))
	# Small angle changes near the 22.5-degree boundary must not flicker.
	game.start_run("revolver")
	game.player.aiming = true
	for angle in [21.0,24.0,22.0,25.0]:
		game.player.aim = Vector2.from_angle(deg_to_rad(angle))
		game.player.animate(0.016)
		assert(game.player.facing == &"side")
	game.player.aim = Vector2.from_angle(deg_to_rad(30))
	game.player.animate(0.016)
	assert(game.player.facing == &"down_diagonal")
	for angle in [23.0,20.0,25.0]:
		game.player.aim = Vector2.from_angle(deg_to_rad(angle))
		game.player.animate(0.016)
		assert(game.player.facing == &"down_diagonal")
	game.player.aim = Vector2.from_angle(deg_to_rad(15))
	game.player.animate(0.016)
	assert(game.player.facing == &"side")
	print("PASS: eight-direction aim/movement/idle, all weapons while backpedaling, reverse animation, target loss, smooth shot facing and angular hysteresis")
	game.queue_free()
	await process_frame
	quit()
