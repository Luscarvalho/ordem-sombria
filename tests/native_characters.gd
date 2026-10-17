extends SceneTree

const Game = preload("res://scripts/game.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scenes: Array[PackedScene] = [Game.HunterScene]
	scenes.append_array(Game.EnemyScenes)
	scenes.append(Game.MatriarchScene)
	for scene in scenes:
		var actor: CharacterBody2D = scene.instantiate()
		var authored_sprite: AnimatedSprite2D = actor.get_node("AnimatedBody")
		var authored_transform := authored_sprite.transform
		root.add_child(actor)
		assert(actor.sprite.transform.is_equal_approx(authored_transform), "Editor and runtime show different character sizes or anchors")
		assert(actor.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING)
		assert(actor.body_shape.shape is CapsuleShape2D)
		assert(is_equal_approx(actor.body_shape.shape.radius, actor.radius))
		assert(actor.sprite is AnimatedSprite2D and actor.sprite.sprite_frames != null)
		assert(actor.hurtbox is Area2D and actor.hurt_shape.shape is CapsuleShape2D)
		if actor.kind == 0:
			assert(actor.weapon_pivot.get_node("HeldWeapon") is Sprite2D)
			assert(actor.gripping_hand is Sprite2D)
		else:
			assert(actor.get_node("ContactHitbox") is Area2D)
			assert(actor.contact_shape.shape is CapsuleShape2D)
		actor.free()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock = 999.0
	game.shot_clock = 999.0
	game.invincible = 999.0
	var enemy = game._spawn_enemy(0, Vector2(20, 0))
	assert(enemy.touches_body(game.player))
	enemy.contact_shape.position = Vector2(0, 100)
	assert(not enemy.touches_body(game.player), "Contact damage ignores the scene's CollisionShape2D")
	enemy.contact_shape.position = Vector2.ZERO
	enemy.contact_shape.disabled = true
	assert(not enemy.touches_body(game.player))
	enemy.contact_shape.disabled = false
	enemy.contact_hitbox.collision_mask = 0
	assert(not enemy.touches_body(game.player))
	enemy.contact_hitbox.collision_mask = 1
	assert(enemy.touches_body(game.player))
	assert(enemy.intersects_projectile(Vector2(0, -14), Vector2(50, -14)))
	enemy.hurt_shape.disabled = true
	assert(not enemy.intersects_projectile(Vector2(0, -14), Vector2(50, -14)))
	enemy.hurt_shape.disabled = false
	enemy.hurt_shape.position = Vector2(0, -100)
	assert(not enemy.intersects_projectile(Vector2(0, -14), Vector2(50, -14)), "Projectile damage ignores the scene's CollisionShape2D")
	game.boss_arena.begin(Vector2.ZERO)
	assert(game.boss_arena.boundary is StaticBody2D)
	assert(game.boss_arena.boundary.get_child(0).shape is RectangleShape2D)
	for sector in range(16):
		game.start_run("revolver")
		game.spawn_clock = 999.0
		game.shot_clock = 999.0
		game.invincible = 999.0
		game.boss_arena.begin(Vector2.ZERO)
		var direction := Vector2.from_angle(sector * TAU / 16.0)
		game.obstacles.ensure_collision(Vector2.ZERO, direction * 500.0, game.player.radius)
		await physics_frame
		game.player.move_with_velocity(direction * 30000.0)
		assert(game.player.get_slide_collision_count() > 0, "Native high-speed motion did not hit a collider")
		assert(game.boss_arena.contains(game.player.position, game.player.radius), "Native high-speed motion tunneled through the arena")
	game.start_run("wand")
	assert(game.player.position == Vector2.ZERO and game.player.velocity == Vector2.ZERO)
	assert(game.player.scene_file_path == Game.HunterScene.resource_path)
	assert(not game.boss_arena.active)
	var distant = game._spawn_enemy(0, Vector2(2500, 0))
	distant.hp = 17.0
	distant.speed = 88.0
	distant.burn = 1.0
	distant.slow_time = 1.0
	distant.slow_factor = 0.5
	await physics_frame
	game._update_enemies(1.0 / 60.0)
	assert(game.enemies.size() == 1 and game.enemies[0] != distant)
	var replacement = game.enemies[0]
	assert(replacement.hp == 17.0 and replacement.speed == 88.0)
	assert(is_equal_approx(replacement.burn, 1.0 - 1.0 / 60.0))
	assert(is_equal_approx(replacement.slow_time, 1.0 - 1.0 / 60.0) and replacement.slow_factor == 0.5)
	assert(replacement.position.distance_to(game.player.position) < 1000.0)
	assert(game.kills == 0 and game.gems.is_empty())
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: editable native character scenes, capsule footprints, shape-driven contact/projectile hitboxes, native arena walls, high-speed collision in 16 directions and clean player replacement")
	quit()
