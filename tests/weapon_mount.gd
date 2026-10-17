extends SceneTree
## Regressions: floating grip, mirrored grip drift, recoil detachment and muzzle origin.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var grips := {"revolver": Vector2(5, 12), "shotgun": Vector2(7, 10), "wand": Vector2(5, 17), "return_blade": Vector2(9, 16), "grenade_launcher": Vector2(7, 13), "dual_pistols": Vector2(5, 10)}
	for weapon in grips:
		game.start_run(weapon)
		var actor = game.player
		actor.position = Vector2(37, 61)
		actor.aiming = true
		actor.moving = true
		actor.motion = Vector2.RIGHT * 170
		actor.move_blend = 1.0
		actor.animation_clock = 0.0
		actor.animate(0.0)
		# Visual fixtures from the side atlas: front fist in the new unified side walk frames 0 and 4.
		for frame in [0, 4]:
			actor.animation_clock = frame / actor.sprite.sprite_frames.get_animation_speed("walk")
			actor.animate(0.0)
			var expected := Vector2(7.540984, -20.22951) if frame == 0 else Vector2(9.508197, -20.88525)
			for angle in [-15.0, 0.0, 15.0]:
				actor.aim = Vector2.from_angle(deg_to_rad(angle))
				actor.recoil = 5.0
				actor._update_weapon(0.1)
				var actual: Vector2 = actor.held_weapon.to_global(grips[weapon] + actor.held_weapon.offset)
				assert(actual.distance_to(actor.to_global(expected)) < 0.02, "Handle detached during aiming/recoil: " + weapon)
				assert(actor.gripping_hand.global_position.distance_to(actual) < 0.001)
		# Left-facing artwork must keep the same grip after mirroring.
		actor.aim = Vector2.LEFT
		actor.on_shot()
		actor.animate(0.30)
		actor.animation_clock = 0.0
		actor.animate(0.0)
		var left_grip: Vector2 = actor.held_weapon.to_global(grips[weapon] + actor.held_weapon.offset)
		assert(left_grip.distance_to(actor.to_global(Vector2(-7.540984, -20.22951))) < 0.02)
		# All shots emerge at the weapon tip, even during a moving diagonal pose.
		for sector in range(8):
			game.start_run(weapon)
			game._spawn_enemy(0)
			var target = game.enemies[-1]
			var direction := Vector2.from_angle(sector * PI / 4)
			target.position = direction * 100
			game.player.moving = true
			game.player.motion = -direction * 170
			game.player.aiming = true
			game.player.aim = direction
			game.player.animate(0.30)
			game._fire(target)
			var muzzle: Vector2 = game.player.muzzle_position()
			for bullet in game.bullets:
				assert(bullet.position.distance_to(muzzle) < 0.001)
				var toward_target := muzzle.direction_to(target.position + Vector2(0, -15))
				assert(bullet.velocity.normalized().dot(toward_target) > 0.95)
			var back_view: bool = game.player.facing in [&"up", &"up_diagonal"]
			assert((game.player.weapon_pivot.z_index < 0) == back_view)
			assert(game.player.gripping_hand.visible != back_view)
		game.start_run(weapon)
		game._spawn_enemy(0)
		game.enemies[-1].position = Vector2(22, 0)
		game._fire(game.enemies[-1])
		for bullet in game.bullets:
			assert(bullet.velocity.x > 0.0, "A close target reversed a projectile through the hunter")
	print("PASS: atlas hand fixtures, aiming without grip drift, wrist recoil, mirrored grips, weapon layering and real muzzle origins for all weapons/directions")
	game.queue_free()
	await process_frame
	quit()
