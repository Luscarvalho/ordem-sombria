extends SceneTree
## Run: godot --headless --path . --script res://tests/weapon_range.gd

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for id in ["revolver", "shotgun", "wand"]:
		game.start_run(id)
		var reach: float = game.Data.WEAPONS[id].range
		var origin: Vector2 = game.player.position + game.AIM_OFFSET
		game._spawn_enemy(0)
		var target = game.enemies[0]
		# Outside the limit: neither targeting nor an explicit fire request shoots.
		target.position = origin + Vector2(reach + 1, 14)
		assert(game._nearest_enemy() == null, id + " acquired an out-of-range target")
		game._fire(target)
		assert(game.bullets.is_empty(), id + " fired beyond its range")
		# Exactly on the boundary is a valid target.
		target.position.x -= 1
		assert(game._nearest_enemy() == target, id + " rejected its exact range")
		game.extra_pellets = 3
		game.extra_pierce = 5
		game._fire(target)
		assert(not game.bullets.is_empty())
		target.hp = 0
		var references: Array = game.bullets.duplicate()
		game._spawn_enemy(0)
		var distant = game.enemies[-1]
		distant.position = origin + Vector2(reach + distant.radius + 10, 14)
		var before: float = distant.hp
		# Check the travelled distance at different speeds and at a very large
		# timestep. A projectile must never overshoot or hit beyond the limit.
		for bullet in game.bullets:
			bullet.velocity *= 1.7
		game._update_bullets(0.05)
		for bullet in references:
			assert(origin.distance_to(bullet.position) <= reach + 0.001)
		game._update_bullets(5.0)
		assert(game.bullets.is_empty(), id + " projectile did not expire")
		for bullet in references:
			assert(absf(origin.distance_to(bullet.position) - reach) < 0.001, id + " overshot its range")
		assert(distant.hp == before, id + " damaged an enemy beyond its reach")
	print("PASS: all weapon ranges, targeting boundaries, spread, piercing, speed independence, exact expiry and no hits beyond reach")
	game.queue_free()
	await process_frame
	quit()
