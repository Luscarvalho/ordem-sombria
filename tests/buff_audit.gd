extends SceneTree

const Data = preload("res://scripts/game_data.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func reset_run(game, weapon: String = "revolver") -> void:
	game.start_run(weapon)
	game.spawn_clock = 999.0
	game.shot_clock = 999.0
	game.invincible = 999.0

func grant(game, id: String, count: int) -> void:
	for level in range(count):
		game.state = "upgrade"
		game.choices.assign([Data.upgrade(id)])
		game.select_upgrade(0)
		assert(game.stacks[id] == level + 1)

func target_at(game, point: Vector2, health: float = 10000.0):
	var target = game._spawn_enemy(0, point)
	target.speed = 0.0
	target.hp = health
	target.max_hp = health
	return target

func check_piercing(game) -> void:
	for weapon_id in Data.WEAPONS:
		var weapon: Dictionary = Data.WEAPONS[weapon_id]
		if weapon.get("mode", "bullet") == "grenade":
			continue
		for level in range(4):
			reset_run(game, weapon_id)
			grant(game, "pierce", level)
			var targets := []
			for distance in [150, 120, 90, 60]:
				targets.append(target_at(game, Vector2(distance, 0)))
			game._fire(targets[0])
			var central: Dictionary = game.bullets[floori(game.bullets.size() * 0.5)]
			game.bullets.assign([central])
			game._update_bullets(1.0)
			var hit_count := mini(4, 1 + int(weapon.pierce) + level)
			for index in range(targets.size()):
				var expected: float = 10000.0 - (weapon.damage if targets.size() - index <= hit_count else 0.0)
				assert(targets[index].hp == expected, "%s pierce %d hits targets in spawn order instead of travel order" % [weapon_id, level])

func check_weapons(game) -> void:
	for weapon_id in Data.WEAPONS:
		var weapon: Dictionary = Data.WEAPONS[weapon_id]
		for level in range(1, 6):
			reset_run(game, weapon_id)
			grant(game, "damage", level)
			grant(game, "attack", level)
			var target = target_at(game, Vector2(100, 0))
			game._fire(target)
			assert(is_equal_approx(game.bullets[0].damage, weapon.damage * (1.0 + 0.25 * level)))
			assert(is_equal_approx(game.shot_clock, weapon.interval / pow(1.15, level)))
		for level in range(1, 4):
			reset_run(game, weapon_id)
			grant(game, "ammo", level)
			grant(game, "reload", level)
			grant(game, "projectile", level)
			var target = target_at(game, Vector2(100, 0))
			game._fire(target)
			assert(game.bullets.size() == int(weapon.pellets) + level)
			assert(game.weapon_cycle.capacity == int(weapon.ammo) + 2 * level)
			assert(game.weapon_cycle.ammo == game.weapon_cycle.capacity - 1)
			assert(game.reload_weapon())
			assert(is_equal_approx(game.weapon_cycle.reload_duration, weapon.reload_time / (1.0 + 0.2 * level)))
			game._update_weapon_cycle(game.weapon_cycle.reload_duration, true)
			assert(game.weapon_cycle.ammo == game.weapon_cycle.capacity and not game.weapon_cycle.reloading)
			reset_run(game, weapon_id)
			grant(game, "finisher", level)
			target = target_at(game, Vector2(100, 0))
			var interval := 10 - 2 * level
			for shot in range(1, interval + 1):
				if game.weapon_cycle.reloading:
					game._update_weapon_cycle(game.weapon_cycle.reload_duration, true)
				game.bullets.clear()
				game._fire(target)
				assert(game.bullets.size() == int(weapon.pellets))
				assert(game.bullets[0].damage == weapon.damage * (3.0 if shot == interval else 1.0))
			reset_run(game, weapon_id)
			grant(game, "vitality", 2)
			grant(game, "damage", 2)
			grant(game, "pact", level)
			assert(is_equal_approx(game.max_health, 140.0 * pow(0.75, level)) and game.health <= game.max_health)
			target = target_at(game, Vector2(100, 0))
			game._fire(target)
			assert(is_equal_approx(game.bullets[0].damage, weapon.damage * (1.5 + 0.4 * level)))

func check_statuses(game) -> void:
	for level in range(1, 4):
		reset_run(game)
		for id in ["ember", "poison", "frost"]:
			grant(game, id, level)
		var target = target_at(game, Vector2(100, 0))
		game.buffs.hit_projectile(target, {"damage": 1.0, "color": Color.WHITE})
		assert(target.burn_damage == 9.0 * level and target.poison_damage == 6.0 * level)
		assert(is_equal_approx(target.slow_factor, 0.8 - 0.1 * level))
		game._update_enemies(0.5)
		assert(is_equal_approx(target.hp, 9999.0 - 7.5 * level))
		game.buffs.hit_projectile(target, {"damage": 0.0, "color": Color.WHITE})
		assert(target.burn == 3.0 and target.poison_time == 4.0 and target.slow_time == 2.0)
		game._update_enemies(5.0)
		assert(is_equal_approx(target.hp, 9999.0 - 58.5 * level), "Elemental effects stack or tick beyond their duration")
		assert(target.burn == 0.0 and target.poison_time == 0.0 and target.slow_time == 0.0)
		reset_run(game)
		grant(game, "critical", level)
		target = target_at(game, Vector2(100, 0))
		var random := RandomNumberGenerator.new()
		random.seed = 4201
		game.rng.seed = 4201
		var expected := 0.0
		for hit in range(1000):
			expected += 2.0 if random.randf() < 0.15 * level else 1.0
			game.buffs.hit_projectile(target, {"damage": 1.0, "color": Color.WHITE})
		assert(target.hp == 10000.0 - expected, "Critical chance does not match the advertised rank")

func check_passives(game) -> void:
	for level in range(1, 4):
		reset_run(game)
		grant(game, "speed", level)
		grant(game, "magnet", level)
		assert(is_equal_approx(game.move_speed, 170.0 * pow(1.12, level)))
		assert(is_equal_approx(game.pickup_radius, Data.BASE_PICKUP_RADIUS * pow(1.45, level)))
		game._drop_experience(Vector2(Data.BASE_PICKUP_RADIUS + 5, 0), 3)
		game._update_gems(0.01)
		assert(game.gems[0].attracted and game.experience == 0)
		reset_run(game)
		game.health = 40.0
		grant(game, "vitality", level)
		assert(game.max_health == 100.0 + 20.0 * level and game.health == 40.0 + 30.0 * level)
		reset_run(game)
		grant(game, "shield", level)
		assert(game.buffs.shield_ready and game.buffs.block_hit() and not game.buffs.block_hit())
		var cooldown := 24.0 - 4.0 * level
		assert(game.buffs.shield_clock == cooldown)
		game.buffs.update(cooldown - 0.01)
		assert(not game.buffs.shield_ready)
		game.buffs.update(0.02)
		assert(game.buffs.shield_ready)
		reset_run(game)
		grant(game, "vampire", level)
		game.health = 50.0
		game.kills = 8
		target_at(game, Vector2(100, 0), 0)
		game._remove_dead_enemies()
		assert(game.health == 50.0)
		target_at(game, Vector2(100, 0), 0)
		game._remove_dead_enemies()
		assert(game.kills == 10 and game.health == 50.0 + 2.0 * level)
		game.kills = 19
		game.health = game.max_health - 1.0
		target_at(game, Vector2(100, 0), 0)
		game._remove_dead_enemies()
		assert(game.health == game.max_health)
		reset_run(game)
		grant(game, "revenge", level)
		var close = target_at(game, Vector2(30, 0))
		var far = target_at(game, Vector2(130, 0))
		game.invincible = 0.0
		assert(game._damage_player(10.0))
		assert(game.health == 90.0 and close.hp == 10000.0 - 15.0 * level and far.hp == 10000.0)
		assert(is_equal_approx(close.knockback.length(), 200.0 + 60.0 * level))
		grant(game, "shield", 1)
		game.invincible = 0.0
		assert(not game._damage_player(10.0) and close.hp == 10000.0 - 15.0 * level)

func check_specials(game) -> void:
	for level in range(1, 4):
		reset_run(game)
		grant(game, "lightning", level)
		var targets := []
		for distance in [60, 85, 110, 135, 160, 185]:
			targets.append(target_at(game, Vector2(distance, 0)))
		for shot in range(4):
			game._fire(targets[0])
		assert(targets.all(func(target): return target.hp == 10000.0))
		game._fire(targets[0])
		for index in range(targets.size()):
			assert(targets[index].hp == 10000.0 - (12.0 + 8.0 * level if index < 2 + level else 0.0))
		reset_run(game)
		grant(game, "orbs", level)
		var target = target_at(game, Vector2(56, -1))
		game.buffs.update(0.0)
		var amount := 8.0 + 6.0 * level
		assert(game.buffs.orbs.size() == 1 + level and target.hp == 10000.0 - amount)
		game.buffs.update(0.0)
		assert(target.hp == 10000.0 - amount)
		game.elapsed = TAU / 2.4
		game.buffs.update(0.0)
		assert(target.hp == 10000.0 - 2.0 * amount)
		reset_run(game)
		grant(game, "ricochet", level)
		targets.clear()
		for point in [Vector2(70, 0), Vector2(100, 35), Vector2(135, 0), Vector2(170, 35)]:
			targets.append(target_at(game, point))
		game._fire(targets[0])
		for tick in range(240):
			game._update_bullets(1.0 / 240.0)
		for index in range(targets.size()):
			var expected := 24.0 * pow(0.5, index) if index <= level else 0.0
			assert(targets[index].hp == 10000.0 - expected, "Ricochet rank/damage mismatch")
		reset_run(game)
		grant(game, "explosion", level)
		target = target_at(game, Vector2(100, 0))
		var corpse = target_at(game, Vector2(120, 0), 0)
		var random := RandomNumberGenerator.new()
		random.seed = 77
		game.rng.seed = 77
		var amount_total := 0.0
		for kill in range(100):
			if random.randf() < 0.10 + 0.10 * level:
				amount_total += 15.0 + 20.0 * level
			game.buffs.on_kill(corpse)
		assert(target.hp == 10000.0 - amount_total, "Explosion chance or damage does not match the advertised rank")
	reset_run(game)
	grant(game, "explosion", 3)
	grant(game, "vampire", 3)
	var random := RandomNumberGenerator.new()
	var sequence_seed := 0
	while true:
		random.seed = sequence_seed
		if random.randf() < 0.4 and random.randf() < 0.4:
			break
		sequence_seed += 1
		assert(sequence_seed < 10000)
	game.kills = 7
	game.health = 50
	target_at(game, Vector2(40, 0), 40)
	target_at(game, Vector2(80, 0), 40)
	target_at(game, Vector2(120, 0), 0)
	game.rng.seed = sequence_seed
	game._remove_dead_enemies()
	assert(game.enemies.is_empty() and game.kills == 10 and game.health == 56, "Explosive chains miss kills or life steal")
	assert(game.gems.size() == 3 and game.experience == 0)
	game._remove_dead_enemies()
	assert(game.kills == 10 and game.gems.size() == 3, "Explosive chains duplicate kills or XP")

func check_combined_build(game) -> void:
	for weapon_id in Data.WEAPONS:
		reset_run(game, weapon_id)
		for upgrade in Data.UPGRADES:
			grant(game, upgrade.id, upgrade.max_level)
		var target = target_at(game, Vector2(100, 0), 100000.0)
		game.buffs.shots = 3
		game._fire(target)
		assert(game.bullets.size() == int(Data.WEAPONS[weapon_id].pellets) + 3)
		var central: Dictionary = game.bullets[floori(game.bullets.size() * 0.5)]
		game.bullets.assign([central])
		var random := RandomNumberGenerator.new()
		var critical_seed := 0
		while true:
			random.seed = critical_seed
			if random.randf() < 0.45:
				break
			critical_seed += 1
		game.rng.seed = critical_seed
		var expected_damage: float = Data.WEAPONS[weapon_id].damage * 3.45 * 3.0 * 2.0
		game._update_bullets(0.25)
		assert(is_equal_approx(target.hp, 100000.0 - expected_damage), "Damage/pact/finisher/critical combination is incorrect: " + weapon_id)
		assert(target.burn_damage == 27 and target.poison_damage == 18 and is_equal_approx(target.slow_factor, 0.5))
		game._update_enemies(0.5)
		assert(is_equal_approx(target.hp, 100000.0 - expected_damage - 22.5), "Weapon bonuses change fixed elemental damage")
		var before: float = target.hp
		var burn: float = target.burn
		var poison: float = target.poison_time
		game.toggle_pause()
		game._physics_process(5.0)
		assert(target.hp == before and target.burn == burn and target.poison_time == poison)
		game.toggle_pause()

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check_piercing(game)
	check_weapons(game)
	check_statuses(game)
	check_passives(game)
	check_specials(game)
	check_combined_build(game)
	game.combat_visuals.queue_redraw()
	await process_frame
	game.queue_free()
	await process_frame
	print("PASS: all 22 buffs at every rank, six fully upgraded weapon builds, ordered piercing, exact damage/cadence/ammo/reload, DOT refresh/expiry, deterministic critical/explosion probabilities, collection, healing/caps, shield/revenge, lightning targets, orbital cooldowns, ricochet damage, explosive chain rewards and paused combined effects")
	quit()
