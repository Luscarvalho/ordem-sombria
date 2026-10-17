extends SceneTree
const Waves = preload("res://scripts/encounter_data.gd")
const Data = preload("res://scripts/game_data.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock = 999
	assert(game.boss_clock == 300.0 and game.next_level == Data.FIRST_LEVEL_XP)
	# Natural spawns unlock slowly, never by just making every old enemy tougher.
	for time in [0.0, 29.99, 30.0, 59.99, 60.0, 104.99, 105.0, 119.99, 120.0, 179.99, 180.0, 239.99, 240.0]:
		game.elapsed = time
		var allowed: Dictionary = Waves.PHASES[Waves.phase_index(time)].weights
		var observed := {}
		for i in range(1000):
			var kind: int = game.encounters.choose_type()
			assert(allowed.has(kind), "An enemy appeared before its introduction")
			observed[kind] = true
		if time < 60:
			assert(observed.size() == 1 and observed.has(0), "The first minute must contain only basic spiders")
		assert(not observed.has(3), "Bosses cannot be picked by the regular spawn lottery")
	# Density grows before new behaviours enter; ordinary spawn caps are respected.
	game.start_run("revolver")
	game.elapsed = 35
	game.spawn_clock = 0
	game.encounters.update(0.01)
	assert(game.enemies.size() == 2 and game.enemies.all(func(e): return e.enemy_type == 0))
	var cap: int = Waves.PHASES[1].cap
	while game.enemies.size() < cap:
		game._spawn_enemy(0)
	game.spawn_clock = 0
	game.encounters.update(0.01)
	assert(game.enemies.size() == cap)
	# Ranged population limits avoid an early wall of hostile projectiles.
	game.start_run("revolver")
	game.elapsed = 120
	game._spawn_enemy(1)
	game._spawn_enemy(1)
	for i in range(100):
		assert(game.encounters.choose_type() not in [1,6])
	# Both ranged species announce the shot, aim once, then fire dodgeable projectiles.
	for type in [1,6]:
		game.start_run("revolver")
		var shooter = game._spawn_enemy(type)
		shooter.position = Vector2(200,0)
		shooter.brain.clock = 0.0
		game._update_enemies(0.01)
		assert(shooter.brain.windup > 0.0 and game.encounters.hostile_bullets.is_empty())
		var locked_target: Vector2 = shooter.brain.target
		game.player.position = Vector2(0,80)
		game._update_enemies(0.70)
		assert(game.encounters.hostile_bullets.size() == (3 if type == 6 else 1))
		var middle: Dictionary = game.encounters.hostile_bullets[1 if type == 6 else 0]
		assert(middle.velocity.normalized().dot(Vector2(middle.position).direction_to(locked_target)) > 0.999)
		assert(middle.velocity.length() < game.move_speed)
		game.encounters.hostile_bullets.clear()
		shooter.position = Vector2(1400,0)
		shooter.brain.clock = 0.0
		game._update_enemies(0.01)
		assert(shooter.brain.windup == 0.0, "Offscreen shooters must not begin a shot")
	# Boss timing uses active run time, exactly at 5:00, 10:00, 15:00, ...
	game.start_run("revolver")
	game.spawn_clock = 999
	game.elapsed = 294.9
	game.encounters.update(0)
	assert(game.encounters.current_boss() == null)
	game.elapsed = 295
	game.encounters.update(0)
	assert(game.encounters.warned_boss == 1 and game.encounters.announcement_time == 5)
	game.elapsed = 299.99
	game.encounters.update(0)
	assert(game.encounters.current_boss() == null)
	game.elapsed = 300
	game.encounters.update(0)
	var boss = game.encounters.current_boss()
	assert(boss != null and boss.brain.archetype == "colossus")
	assert(game.boss_clock == 600 and game.encounters.boss_number == 1)
	game.encounters.update(0.01)
	assert(game.enemies.filter(func(e): return e.brain.boss).size() == 1)
	game.ui.update_hud()
	assert(game.ui.boss_panel.visible and game.ui.boss_health.max_value == boss.max_hp)
	# Colossus announces a locked charge and emits a ring at the end; half HP enrages it.
	boss.position = Vector2(200,0)
	boss.brain.clock = 0.0
	game._update_enemies(0.01)
	assert(boss.brain.windup > 0.0 and boss.brain.charge == 0)
	game.player.position = Vector2(0,60)
	game._update_enemies(0.90)
	assert(boss.brain.charge > 0.0 and Vector2(boss.brain.direction).dot(Vector2.LEFT) > 0.999)
	boss.hp = boss.max_hp * 0.4
	game._update_enemies(0.70)
	assert(boss.brain.enraged and game.encounters.hostile_bullets.size() == 10)
	game.elapsed = 600
	game.encounters.update(0)
	assert(game.boss_clock == 900 and game.encounters.boss_number == 2)
	var queens: Array = game.enemies.filter(func(e): return e.brain.get("archetype", "") == "matriarch")
	assert(queens.size() == 1)
	var queen = queens[0]
	assert(queen.max_hp > 1600 and queen.kind == 1)
	queen.position = Vector2(200,60)
	queen.brain.clock = 0.0
	game._update_enemies(0.01)
	game._update_enemies(0.90)
	assert(game.encounters.summons.size() == 4)
	game.encounters.flush_summons()
	assert(game.enemies.filter(func(e): return e.enemy_type == 4).size() == 4)
	game.health = 50
	boss.hp = 0
	game._remove_dead_enemies()
	assert(game.health == 70 and game.encounters.respite == 8)
	assert(game.encounters.hostile_bullets.is_empty())
	# Hostile bullets use swept collisions, the same shield and damage feedback as contact.
	game.start_run("revolver")
	game.invincible = 0
	game.encounters._add_bullet(Vector2(-50,-15), Vector2(200,0), 12, false)
	game.encounters.update_projectiles(0.5)
	assert(game.health == 88 and game.encounters.hostile_bullets.is_empty())
	game.stacks.shield = 1
	game.buffs.shield_ready = true
	game.invincible = 0
	game.encounters._add_bullet(Vector2(-50,-15), Vector2(200,0), 12, false)
	game.encounters.update_projectiles(0.5)
	assert(game.health == 88 and not game.buffs.shield_ready)
	for i in range(150):
		game.encounters._add_bullet(Vector2(900,-100), Vector2(100,0), 12, false)
	assert(game.encounters.hostile_bullets.size() == Waves.MAX_PROJECTILES)
	# Pauses and card/aura interruptions freeze bullets, waves, boss clock and warnings.
	var before: Vector2 = game.encounters.hostile_bullets[0].position
	var time_before: float = game.elapsed
	game.toggle_pause()
	game._physics_process(310)
	assert(game.elapsed == time_before and game.boss_clock == 300)
	assert(game.encounters.hostile_bullets[0].position == before)
	game.toggle_pause()
	game.experience = game.next_level
	game._physics_process(0.01)
	assert(game.state == "levelup")
	before = game.encounters.hostile_bullets[0].position
	game._physics_process(0.2)
	assert(game.encounters.hostile_bullets[0].position == before)
	game.return_to_menu()
	assert(game.encounters.hostile_bullets.is_empty() and game.encounters.current_boss() == null)
	game.start_run("wand")
	assert(game.boss_clock == 300 and game.encounters.boss_number == 0)
	game.queue_free()
	await process_frame
	print("PASS: staged introductions, first-minute spiders, density/ranged caps, telegraphed aimed shots, 5-minute bosses, distinct boss movesets, shield/collision, rewards, pause/aura and reset")
	quit()
