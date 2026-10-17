extends SceneTree

const DT := 1.0 / 60.0
const PRIORITY: Array[String] = ["projectile", "damage", "attack", "pierce", "orbs", "ember", "poison", "lightning", "ricochet", "reload", "critical", "finisher", "ammo", "magnet", "frost", "speed", "explosion", "revenge", "shield", "vitality", "vampire", "pact"]

func _initialize() -> void:
	call_deferred("simulate")

func simulate() -> void:
	seed(2026)
	var arguments := OS.get_cmdline_user_args()
	var weapon := arguments[0] if not arguments.is_empty() else "revolver"
	var invulnerable := arguments.size() < 3 or arguments[2] != "mortal"
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.rng.seed = 2026
	game.start_run(weapon)
	var report := {"weapon": weapon, "seed": 2026, "invulnerable_bot": invulnerable, "first_upgrade": -1.0, "levels": [], "peak_enemies": 0, "peak_cluster": 0}
	var sample := 60.0
	var ticks := 0
	while game.elapsed < 300.1 and game.state != "dead":
		await physics_frame
		if invulnerable:
			game.invincible = 999.0
		if game.state == "upgrade":
			var selected := 0
			var best := PRIORITY.size()
			for index in range(game.choices.size()):
				var rank := PRIORITY.find(game.choices[index].id)
				if rank < best:
					best = rank
					selected = index
			game.select_upgrade(selected)
		var target := Vector2.from_angle(game.elapsed * 0.22) * 200.0
		var closest := 500.0 * 500.0
		for gem in game.gems:
			if gem.attracted:
				continue
			var distance: float = game.player.position.distance_squared_to(gem.position)
			if distance >= closest:
				continue
			var safe := true
			for enemy in game.enemies:
				if enemy.hp > 0 and enemy.position.distance_to(gem.position) < enemy.radius + 45.0:
					safe = false
					break
			if safe:
				target = gem.position
				closest = distance
		var avoidance := Vector2.ZERO
		for enemy in game.enemies:
			var offset: Vector2 = game.player.position - enemy.position
			var distance := offset.length()
			if distance > 0.1 and distance < 110.0 and enemy.hp > 0:
				avoidance += offset / distance * (1.0 - distance / 110.0)
		var desired: Vector2 = ((target - game.player.position).limit_length(80.0) / 80.0 + avoidance * 1.6).limit_length(1.0)
		game.touch_index = 0
		game.touch_origin = Vector2.ZERO
		game.touch_position = desired * 55.0
		game._physics_process(DT)
		if game.level > 1 and report.first_upgrade < 0:
			report.first_upgrade = snappedf(game.elapsed, 0.1)
		report.peak_enemies = maxi(report.peak_enemies, game.enemies.size())
		if ticks % 60 == 0:
			for enemy in game.enemies:
				var cluster := 0
				for other in game.enemies:
					if other.hp > 0 and other.position.distance_squared_to(enemy.position) < 50.0 * 50.0:
						cluster += 1
				report.peak_cluster = maxi(report.peak_cluster, cluster)
		if game.elapsed >= sample:
			report.levels.append({"time": sample, "level": game.level, "kills": game.kills, "enemies": game.enemies.size()})
			sample += 60.0
		ticks += 1
		assert(ticks < 22000, "Progression simulation stopped advancing")
	report.level = game.level
	report.kills = game.kills
	report.stacks = game.stacks.duplicate()
	report.elapsed = snappedf(game.elapsed, 0.1)
	report.survived_to_boss = game.elapsed >= 300.0
	var ground_xp := 0
	for gem in game.gems:
		ground_xp += int(gem.value)
	report.uncollected_xp = ground_xp
	var serialized := JSON.stringify(report, "\t")
	if arguments.size() > 1:
		var file := FileAccess.open(arguments[1], FileAccess.WRITE)
		file.store_string(serialized + "\n")
	print(serialized)
	game.queue_free()
	await process_frame
	quit()
