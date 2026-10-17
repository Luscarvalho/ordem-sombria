extends SceneTree
## Actual gameplay checks for ranked effects, draft rules, card art and XP pace.

const Data = preload("res://scripts/game_data.gd")
const Art = preload("res://scripts/buff_icon.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func grant(game, id: String, count: int = 1) -> void:
	for i in range(count):
		game.state = "upgrade"
		game.choices.assign([Data.upgrade(id)])
		game.select_upgrade(0)
		assert(game.state == "playing", "Buff could not be acquired: " + id)

func enemy_at(game, position: Vector2, hp: float = 10000.0):
	game._spawn_enemy(0)
	var enemy = game.enemies[-1]
	game.spawn_clock = 999.0
	enemy.position = position
	enemy.speed = 0.0
	enemy.hp = hp
	enemy.max_hp = hp
	return enemy

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	assert(Data.UPGRADES.size() == 22)
	var pact_preview := Data.upgrade_preview("pact", 0, {"stacks": {"damage": 2, "vitality": 1}, "weapon": "shotgun"})
	assert("18 > 23" in pact_preview and "120 > 90" in pact_preview, "Pact must explain actual damage/health for the current build")
	var ids := []
	for card in Data.UPGRADES:
		assert(card.id not in ids)
		ids.append(card.id)
		assert(Art.MASKS.has(card.id), "A card is missing its own sprite")
		assert(Art.MASKS[card.id].size() == 16)
		for line in Art.MASKS[card.id]:
			assert(line.length() == 16 and " " not in line, "Malformed sprite: " + card.id)
		for rank in range(card.max_level):
			assert(">" in Data.upgrade_preview(card.id, rank))
	# The first four costs are slower; extra XP is retained, not silently lost.
	game.start_run("revolver")
	for expected in [40, 64, 96, 140]:
		assert(game.next_level == expected)
		var previous: Array[String] = game.last_offers.duplicate()
		game.experience = expected + 7
		game._offer_upgrades()
		assert(game.experience == 7 and game.choices.size() == 3)
		assert(game.state == "levelup" and not game.ui.overlay.visible)
		game._physics_process(0.55)
		var offered := []
		for card in game.choices:
			assert(card.id not in offered and card.id not in previous)
			offered.append(card.id)
		game.select_upgrade(0)
	# Every card levels up to its cap, then disappears from future choices.
	game.start_run("revolver")
	for card in Data.UPGRADES:
		grant(game, card.id, card.max_level)
		assert(game.stacks[card.id] == card.max_level)
		game.state = "upgrade"
		game.choices.assign([card])
		game.select_upgrade(0)
		assert(game.stacks[card.id] == card.max_level, "Level cap was bypassed")
	game.state = "playing"
	game.experience = game.next_level
	game._offer_upgrades()
	assert(game.choices.is_empty() and game.state == "playing", "All-maxed buffs must not trap the player")
	game.stacks.shield = 2
	game.experience = game.next_level
	game._offer_upgrades()
	assert(game.choices.size() == 1 and game.choices[0].id == "shield")
	game._physics_process(0.55)
	game.select_upgrade(0)
	assert(game.stacks.shield == 3)
	game.start_run("revolver")
	grant(game, "damage", 2)
	grant(game, "attack", 2)
	grant(game, "speed", 3)
	grant(game, "magnet", 2)
	assert(is_equal_approx(game.damage_multiplier, 1.5))
	assert(is_equal_approx(game.rate_multiplier, 1.3225))
	assert(is_equal_approx(game.move_speed, 170 * pow(1.12, 3)))
	assert(is_equal_approx(game.pickup_radius, 65 * pow(1.45, 2)))
	# Fire and poison both damage over time; frost changes real movement speed.
	game.start_run("revolver")
	grant(game, "ember", 2)
	grant(game, "poison", 3)
	grant(game, "frost", 3)
	var target = enemy_at(game, Vector2(150, 0))
	target.speed = 100
	game.buffs.hit_projectile(target, {"damage": 10.0, "color": Color.WHITE})
	assert(target.hp == 9990 and target.burn_damage == 18 and target.poison_damage == 18)
	for tick in range(60):
		await physics_frame
		game._update_enemies(1.0 / 60.0)
	assert(is_equal_approx(target.hp, 9954))
	assert(target.position.distance_to(Vector2(100, 0)) < 0.01, "Rank III frost must halve movement")
	game._update_enemies(5.0)
	assert(target.burn == 0 and target.poison_time == 0 and target.slow_time == 0)
	# Critical chance has a real effect with a deterministic random sequence.
	game.start_run("revolver")
	grant(game, "critical", 3)
	target = enemy_at(game, Vector2(100, 0))
	game.rng.seed = 4201
	for i in range(1000):
		game.buffs.hit_projectile(target, {"damage": 1.0, "color": Color.WHITE})
	var dealt: float = 10000 - target.hp
	assert(dealt > 1400 and dealt < 1500)
	# Rank III finisher triggers every fourth shot; each shotgun volley counts once.
	game.start_run("shotgun")
	grant(game, "finisher", 3)
	target = enemy_at(game, Vector2(100, 0))
	for shot in range(1, 5):
		if game.weapon_cycle.reloading:
			game._update_weapon_cycle(game.weapon_cycle.reload_remaining, true)
		game.bullets.clear()
		game._fire(target)
		assert(game.bullets.size() == 5)
		assert(game.bullets[0].damage == (36.0 if shot == 4 else 12.0))
	# Chain lightning hits only the configured number of distinct nearby targets.
	game.start_run("revolver")
	grant(game, "lightning")
	var chain := []
	for i in range(5):
		chain.append(enemy_at(game, Vector2(100 + i * 50, 0)))
	for i in range(5):
		game._fire(chain[0])
	assert(chain[0].hp == 9980 and chain[1].hp == 9980 and chain[2].hp == 9980)
	assert(chain[3].hp == 10000 and chain[4].hp == 10000)
	# A ricochet consumes range, halves damage and never hits the same target twice.
	game.start_run("revolver")
	grant(game, "ricochet", 2)
	var first = enemy_at(game, Vector2(100, 0))
	var second = enemy_at(game, Vector2(150, 60))
	game._fire(first)
	game._update_bullets(0.16)
	assert(first.hp == 9976 and not game.bullets.is_empty())
	assert(game.bullets[0].bounces == 1 and game.bullets[0].damage == 12)
	game._update_bullets(0.14)
	assert(second.hp == 9988 and first.hp == 9976)
	# Shield, retaliation and life steal affect player/enemies, not just UI numbers.
	game.start_run("revolver")
	grant(game, "shield", 3)
	target = enemy_at(game, Vector2(10, 0))
	game.invincible = 0
	game._update_enemies(0.01)
	assert(game.health == 100 and not game.buffs.shield_ready)
	assert(game.buffs.shield_clock == 12)
	game.buffs.update(12.0)
	assert(game.buffs.shield_ready)
	game.start_run("revolver")
	grant(game, "revenge", 3)
	target = enemy_at(game, Vector2(10, 0))
	game.invincible = 0
	game._update_enemies(0.01)
	assert(game.health < 100 and target.hp == 9955 and target.knockback.length() > 0)
	game.start_run("revolver")
	grant(game, "vampire", 3)
	game.health = 50
	game.kills = 9
	target = enemy_at(game, Vector2(100, 0), 0)
	game._remove_dead_enemies()
	assert(game.health == 56)
	# Orbitals respect hit cooldowns, and an exploding corpse damages neighbours.
	game.start_run("revolver")
	grant(game, "orbs", 3)
	target = enemy_at(game, Vector2(56, -1))
	game.buffs.update(0)
	assert(game.buffs.orbs.size() == 4 and target.hp == 9974)
	game.buffs.update(0)
	assert(target.hp == 9974)
	game.start_run("revolver")
	grant(game, "explosion", 3)
	target = enemy_at(game, Vector2(100, 0))
	var corpse = enemy_at(game, Vector2(120, 0), 0)
	game.rng.seed = 77
	for i in range(30):
		game.buffs.on_kill(corpse)
	assert(target.hp < 10000)
	# Pact and vitality commute: acquisition order cannot bypass the health cost.
	game.start_run("revolver")
	grant(game, "vitality", 2)
	grant(game, "pact", 3)
	var limit: float = game.max_health
	assert(is_equal_approx(limit, 140 * pow(0.75, 3)))
	assert(is_equal_approx(game.damage_multiplier, 2.2))
	game.start_run("revolver")
	grant(game, "pact", 3)
	grant(game, "vitality", 2)
	assert(is_equal_approx(game.max_health, limit) and game.health <= limit)
	# Pausing freezes recharge, orbitals, statuses and all passive visual timers.
	grant(game, "shield")
	grant(game, "orbs")
	game.buffs.block_hit()
	game.buffs.update(0.1)
	var clock: float = game.buffs.shield_clock
	game.toggle_pause()
	game._physics_process(10.0)
	assert(game.buffs.shield_clock == clock)
	game.start_run("wand")
	assert(game.stacks.is_empty() and game.buffs.orbs.is_empty())
	assert(not game.buffs.shield_ready and game.buffs.shots == 0 and game.max_health == 100)
	print("PASS: 22 sprites, ranked previews/caps, slower XP, draft variety, all 12 new combat effects, health tradeoffs, pause and reset")
	game.queue_free()
	await process_frame
	quit()
