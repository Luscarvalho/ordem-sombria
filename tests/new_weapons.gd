extends SceneTree

const Data = preload("res://scripts/game_data.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func reset_run(game, weapon: String) -> void:
	game.start_run(weapon)
	game.spawn_clock = 999
	game.shot_clock = 999
	game.invincible = 999

func target_at(game, point: Vector2):
	var target = game._spawn_enemy(0, point)
	target.hp = 10000
	target.max_hp = 10000
	target.speed = 0
	return target

func grant(game, id: String, rank: int) -> void:
	for level in range(rank):
		game.state = "upgrade"
		game.choices.assign([Data.upgrade(id)])
		game.select_upgrade(0)

func check_blade(game) -> void:
	reset_run(game, "return_blade")
	var target = target_at(game, Vector2(100, 0))
	game._fire(target)
	var blade: Dictionary = game.bullets[0]
	assert(blade.node is Area2D and blade.node.body_shape.shape is CapsuleShape2D and blade.node.sprite is Sprite2D)
	assert(blade.node.scene_file_path.ends_with("return_blade.tscn"))
	var returning := false
	var damage_events := 0
	for tick in range(300):
		var before: float = target.hp
		game._update_bullets(1.0 / 120.0)
		if target.hp < before:
			damage_events += 1
		if blade.phase == "returning":
			returning = true
		elif not game.bullets.is_empty():
			assert(Vector2(blade.position).distance_to(blade.origin) <= blade.reach + 0.01)
	assert(returning and damage_events == 2 and target.hp == 9960)
	assert(game.bullets.is_empty() and game.projectile_layer.get_child_count() == 0)
	reset_run(game, "return_blade")
	target = target_at(game, Vector2(100, 0))
	game._fire(target)
	blade = game.bullets[0]
	blade.node.body_shape.disabled = true
	for tick in range(300):
		game._update_bullets(1.0 / 120.0)
	assert(target.hp == 10000 and game.bullets.is_empty(), "Blade ignores the native collision shape")
	reset_run(game, "return_blade")
	target = target_at(game, Vector2(100, 0))
	game._fire(target)
	blade = game.bullets[0]
	game._update_bullets(0.1)
	game.toggle_pause()
	var point: Vector2 = blade.position
	var age: float = blade.age
	game._physics_process(3.0)
	assert(blade.position == point and blade.age == age)
	game.toggle_pause()
	game._begin_blade_return(blade)
	game._update_bullets(4.0)
	assert(game.bullets.is_empty(), "Returning blade can remain alive indefinitely")

func check_grenades(game) -> void:
	reset_run(game, "grenade_launcher")
	var target = target_at(game, Vector2(100, 0))
	var nearby = target_at(game, Vector2(120, 35))
	var distant = target_at(game, Vector2(210, 90))
	game._fire(target)
	var grenade: Dictionary = game.bullets[0]
	assert(grenade.node.get_node("Blast") is Area2D and grenade.node.blast_shape.shape is CapsuleShape2D)
	game._update_bullets(0.5)
	assert(target.hp == 9948 and nearby.hp == 9948 and distant.hp == 10000)
	assert(game.health == 100 and game.bullets.is_empty() and game.projectile_layer.get_child_count() == 0)
	game._update_bullets(1.0)
	assert(target.hp == 9948 and nearby.hp == 9948, "Impact and terminal explosions double-damage a target")
	reset_run(game, "grenade_launcher")
	target = target_at(game, Vector2(30, 0))
	game._fire(target)
	game._update_bullets(0.2)
	assert(target.hp == 9948 and game.health == 100, "Close explosions damage the hunter")
	reset_run(game, "grenade_launcher")
	target = target_at(game, Vector2(100, 0))
	game._fire(target)
	game.bullets[0].node.blast_shape.disabled = true
	game._update_bullets(0.5)
	assert(target.hp == 10000, "Explosion ignores its native CollisionShape2D")
	reset_run(game, "grenade_launcher")
	target = target_at(game, Vector2(100, 0))
	game._fire(target)
	target.hp = 0
	grenade = game.bullets[0]
	game._update_bullets(3.0)
	assert(game.bullets.is_empty() and Vector2(grenade.position).distance_to(grenade.origin) <= grenade.reach + 0.01)
	for level in range(4):
		reset_run(game, "grenade_launcher")
		grant(game, "pierce", level)
		var first = target_at(game, Vector2(60, 0))
		var second = target_at(game, Vector2(180, 0))
		game._fire(second)
		for tick in range(120):
			game._update_bullets(1.0 / 120.0)
		assert(first.hp == 9948)
		assert(second.hp == (9948 if level > 0 else 10000), "Grenade piercing or per-projectile blast deduplication is broken")
	reset_run(game, "grenade_launcher")
	grant(game, "ricochet", 1)
	var first = target_at(game, Vector2(60, 0))
	var second = target_at(game, Vector2(180, 0))
	game._fire(second)
	for tick in range(120):
		game._update_bullets(1.0 / 120.0)
	assert(first.hp == 9948 and second.hp == 9974, "Grenade ricochet does not halve the next blast's damage")

func check_cover(game) -> void:
	for weapon in ["return_blade", "grenade_launcher"]:
		reset_run(game, weapon)
		game.obstacles.records[Vector2i.ZERO] = {"cell": Vector2i.ZERO, "position": Vector2(140, 0), "radius": 25.0, "kind": 0, "variant": 0}
		var target = target_at(game, Vector2(240, 0))
		game._fire(target)
		game._update_bullets(0.8)
		assert(target.hp == 10000, "Special projectile crosses terrain")
		if weapon == "return_blade":
			assert(game.bullets.size() == 1 and game.bullets[0].phase == "returning")
			for tick in range(120):
				game._update_bullets(1.0 / 120.0)
		assert(game.bullets.is_empty())
		game.obstacles.records.erase(Vector2i.ZERO)

func check_pistols(game) -> void:
	reset_run(game, "dual_pistols")
	var target = target_at(game, Vector2(100, 0))
	var muzzles := []
	for shot in range(4):
		game._fire(target)
		muzzles.append(game.bullets[-1].position)
		assert(game.bullets[-1].position == game.player.muzzle_position())
	assert(muzzles[0].distance_to(muzzles[1]) > 4 and muzzles[0].distance_to(muzzles[2]) < 0.001)
	assert(game.weapon_cycle.ammo == 16 and game.buffs.shots == 4)
	assert(game.shot_clock == Data.WEAPONS.dual_pistols.interval)
	game._clear_bullets()
	game._update_weapon_cycle(0.0, true)
	grant(game, "lightning", 1)
	game._fire(target)
	assert(target.hp == 9980 and game.buffs.shots == 5, "Pistols count each barrel as two on-shot events")

func check_menu(game) -> void:
	assert(Data.WEAPONS.size() == 6 and Data.UPGRADES.size() == 22)
	for size in [Vector2i(960, 540), Vector2i(1170, 540)]:
		root.size = size
		root.content_scale_size = size
		game.ui.show_weapon_selection()
		for frame in range(3):
			await process_frame
		assert(game.ui.weapon_page == 0)
		assert(game.ui.content.find_child("PreviousWeaponsButton", true, false).disabled)
		game.ui.content.find_child("NextWeaponsButton", true, false).pressed.emit()
		for frame in range(3):
			await process_frame
		assert(game.ui.weapon_page == 1 and game.ui.content.find_child("NextWeaponsButton", true, false).disabled)
		for id in ["return_blade", "grenade_launcher", "dual_pistols"]:
			var card: Button = game.ui.content.find_child("Weapon_" + id, true, false)
			assert(card != null and card.is_visible_in_tree())
			var bounds := card.get_global_rect()
			assert(bounds.position.x >= 0 and bounds.end.x <= size.x and bounds.position.y >= 0 and bounds.end.y <= size.y)
			var stats: Control = card.find_child("Stats", true, false)
			assert(stats.get_child_count() == 7 and stats.get_global_rect().end.y < bounds.end.y)
			var action: Control = card.find_child("StartWeaponLabel", true, false)
			assert(action.get_global_rect().end.y < bounds.end.y, "Weapon action text overflows the card border")
		game.ui.content.find_child("PreviousWeaponsButton", true, false).pressed.emit()
		assert(game.ui.weapon_page == 0)
	for id in ["return_blade", "grenade_launcher", "dual_pistols"]:
		game.ui.show_weapon_selection(1)
		game.ui.content.find_child("Weapon_" + id, true, false).pressed.emit()
		assert(game.state == "playing" and game.weapon_id == id and game.player.equipped == id)
		var target = target_at(game, Vector2(100, 0))
		game._fire(target)
		game.return_to_menu()
		assert(game.bullets.is_empty() and game.projectile_layer.get_child_count() == 0)

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check_blade(game)
	check_grenades(game)
	check_cover(game)
	check_pistols(game)
	await check_menu(game)
	game.queue_free()
	await process_frame
	print("PASS: six selectable weapons, readable two-page menu, native special projectile scenes, blade outbound/return hits and lifetime, grenade AoE/no self-damage/deduplication, native shape toggles, piercing/ricochet, terrain, alternating pistol muzzles, on-shot events, pause and cleanup")
	quit()
