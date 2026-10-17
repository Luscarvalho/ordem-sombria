extends SceneTree

const Data = preload("res://scripts/game_data.gd")
const Waves = preload("res://scripts/encounter_data.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	for victim in range(6):
		var enemy = game._spawn_enemy(0, Vector2(50 + victim * 3, 0))
		enemy.hp = 0
	game._remove_dead_enemies()
	assert(game.kills == 6 and game.experience == 0 and game.gems.size() == 6)
	game._update_gems(1.0)
	assert(game.gems.is_empty() and game.experience == Data.FIRST_LEVEL_XP)
	game._offer_upgrades()
	assert(game.level == 2 and game.next_level == 29 and game.experience == 0)
	for trial in range(20):
		game.start_run("revolver")
		game.rng.seed = trial
		game.stacks.shield = 1
		for level in range(2, 6):
			game.level = level
			game._roll_upgrade_choices()
			assert(game.choices.size() == 3)
			assert(game.choices.any(func(card): return card.id in Data.STARTER_COMBAT_UPGRADES), "Early choices contain no combat improvement")
	game.start_run("revolver")
	for id in Data.STARTER_COMBAT_UPGRADES:
		game.stacks[id] = Data.upgrade(id).max_level
	game._roll_upgrade_choices()
	assert(not game.choices.is_empty() and game.choices.all(func(card): return card.id not in Data.STARTER_COMBAT_UPGRADES))
	game.start_run("revolver")
	var previous_size := root.size
	var previous_scale := root.content_scale_size
	for viewport_size in [Vector2i(960, 540), Vector2i(540, 960), Vector2i(480, 320)]:
		root.size = viewport_size
		root.content_scale_size = viewport_size
		await process_frame
		game.encounters.spawn_sectors.clear()
		var half: Vector2 = game.get_viewport_rect().size * 0.5
		for batch in range(4):
			var sectors := {}
			for member in range(Waves.SPAWN_SECTORS):
				var point: Vector2 = game.encounters.spawn_position(13.0)
				var offset: Vector2 = point - game.player.position
				var sector := floori(fposmod(offset.angle(), TAU) / TAU * Waves.SPAWN_SECTORS)
				assert(not sectors.has(sector), "Spawns repeatedly use one side before covering the perimeter")
				sectors[sector] = true
				var enemy = game._spawn_enemy(0, point)
				var placed: Vector2 = enemy.position - game.player.position
				assert(absf(placed.x) > half.x + enemy.radius or absf(placed.y) > half.y + enemy.radius, "Enemy appears inside the viewport")
			assert(sectors.size() == Waves.SPAWN_SECTORS)
	root.size = previous_size
	root.content_scale_size = previous_scale
	game.start_run("revolver")
	game.elapsed = 35.0
	for member in range(Waves.PRESSURE_LIMIT):
		game._spawn_enemy(0, Vector2.from_angle(member * TAU / Waves.PRESSURE_LIMIT) * 180.0)
	game.spawn_clock = 0.0
	game.encounters.update(0.0)
	assert(game.enemies.size() == Waves.PRESSURE_LIMIT and game.spawn_clock == Waves.PRESSURE_RETRY, "Dense nearby horde still receives reinforcements")
	game.enemies[0].hp = 0
	game.spawn_clock = 0.0
	game.encounters.update(0.0)
	assert(game.enemies.size() > Waves.PRESSURE_LIMIT, "Reinforcements never resume after pressure drops")
	game.start_run("revolver")
	var upper = game._spawn_enemy(0, Vector2(100, -16))
	var lower = game._spawn_enemy(0, Vector2(100, 16))
	game.encounters._index_neighbors()
	assert(game.encounters.movement(upper, 0.0).y < 0.0 and game.encounters.movement(lower, 0.0).y > 0.0, "Close enemies converge instead of making room")
	upper.brain.role = "charger"
	upper.brain.charge = 1.0
	upper.brain.direction = Vector2.RIGHT
	assert(game.encounters.movement(upper, 0.0) == Vector2.RIGHT * 205.0, "Separation bends the announced charge")
	game.start_run("revolver")
	game._drop_experience(Vector2(40000, 0), 18)
	game._drop_experience(Vector2(0, -1200), 7)
	game.elapsed = 295.0
	game.spawn_clock = 0.0
	game.encounters.update(0.0)
	assert(game.experience == 0 and game.gems.all(func(gem): return gem.attracted), "Boss warning grants free XP or fails to attract earned orbs")
	assert(game.enemies.is_empty() and game.spawn_clock >= 5.0, "Boss preparation does not leave a collection window")
	var orb_position: Vector2 = game.gems[0].position
	game.toggle_pause()
	game._physics_process(3.0)
	assert(game.gems[0].position == orb_position and game.elapsed == 295.0)
	game.toggle_pause()
	game._update_gems(2.1)
	assert(game.gems.is_empty() and game.experience == 25)
	game._offer_upgrades()
	assert(game.level == 2 and game.experience == 7, "Boss collection loses surplus experience")
	game.start_run("revolver")
	for orb in range(Data.MAX_EXPERIENCE_ORBS):
		game._drop_experience(Vector2(2000 + orb * 10, 0), 1)
	var last: Vector2 = game.gems[-1].position
	game._drop_experience(last + Vector2(4, 0), 7)
	assert(game.gems.size() == Data.MAX_EXPERIENCE_ORBS)
	assert(game.gems[-1].value == 8 and game.gems[0].value == 1, "Orb cap moves earned XP into a distant unrelated drop")
	game.start_run("revolver")
	game.encounters.spawn_boss(1)
	for member in range(Waves.BOSS_HORDE_CAP):
		game._spawn_enemy(0, Vector2(1000, member * 40))
	game.spawn_clock = 0.0
	game.encounters.update(0.0)
	assert(game.enemies.size() == Waves.BOSS_HORDE_CAP + 1, "Boss combat keeps reinforcing a full ordinary horde")
	game.return_to_menu()
	game.start_run("wand")
	assert(game.encounters.spawn_sectors.is_empty() and game.gems.is_empty() and game.next_level == Data.FIRST_LEVEL_XP)
	assert(game.pickup_radius == Data.BASE_PICKUP_RADIUS and game.boss_clock == 300.0)
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: six-kill first upgrade, early combat offers, eight balanced offscreen sectors in three viewport sizes, pressure relief/recovery, wider separation, straight charges, earned XP attraction before bosses, pause, overflow locality, boss horde cap and reset")
	quit()
