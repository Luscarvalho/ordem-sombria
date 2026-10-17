extends Node2D
## First playable: one hunter, interchangeable weapons, escalating hordes and levels.

const Data = preload("res://scripts/game_data.gd")
const Actor = preload("res://scripts/actor.gd")
const HunterScene = preload("res://scenes/characters/hunter.tscn")
const EnemyScenes := [
	preload("res://scenes/characters/enemies/spider.tscn"),
	preload("res://scenes/characters/enemies/eye.tscn"),
	preload("res://scenes/characters/enemies/beast.tscn"),
	preload("res://scenes/characters/enemies/colossus.tscn"),
	preload("res://scenes/characters/enemies/runner.tscn"),
	preload("res://scenes/characters/enemies/armored_spider.tscn"),
	preload("res://scenes/characters/enemies/spitter.tscn"),
]
const MatriarchScene = preload("res://scenes/characters/enemies/matriarch.tscn")
const Arena = preload("res://scripts/arena.gd")
const Obstacles = preload("res://scripts/terrain_obstacles.gd")
const BossChest = preload("res://scripts/boss_chest.gd")
const BossArena = preload("res://scripts/boss_arena.gd")
const WeaponCycle = preload("res://scripts/weapon_cycle.gd")
const Interface = preload("res://scripts/interface.gd")
const PixelTheme = preload("res://scripts/pixel_theme.gd")
const Music = preload("res://scripts/music.gd")
const Buffs = preload("res://scripts/buffs.gd")
const LevelUpAura = preload("res://scripts/level_up_aura.gd")
const Encounters = preload("res://scripts/encounters.gd")
const Waves = preload("res://scripts/encounter_data.gd")
const AIM_OFFSET := Vector2(0, -15)

var state := "menu"
var previous_state := "playing"
var actors: Node2D
var combat_visuals: Node2D
var arena: Node2D
var obstacles: Node2D
var boss_arena: Node2D
var player: Actor
var camera: Camera2D
var ui: CanvasLayer
var music: Node
var buffs: RefCounted
var level_up_aura: Node2D
var encounters: RefCounted
var last_offers: Array[String] = []
var tracked_target: Node2D
var target_hold := 0.0
var enemies: Array[Actor] = []
var bullets: Array[Dictionary] = []
var gems: Array[Dictionary] = []
var chests: Array[Node2D] = []
var effects: Array[Dictionary] = []
var choices: Array[Dictionary] = []
var stacks: Dictionary = {}
var elapsed := 0.0
var kills := 0
var level := 1
var experience := 0
var next_level := Data.FIRST_LEVEL_XP
var health := 100.0
var max_health := 100.0
var damage_multiplier := 1.0
var rate_multiplier := 1.0
var move_speed := 170.0
var player_velocity := Vector2.ZERO
var pickup_radius := 65.0
var extra_pellets := 0
var extra_pierce := 0
var fire_damage := 0.0
var weapon_id := "revolver"
var weapon_cycle := WeaponCycle.new()
var spawn_clock := 0.0
var shot_clock := 0.0
var invincible := 0.0
var boss_clock := Waves.BOSS_INTERVAL
var touch_index := -1
var touch_origin := Vector2.ZERO
var touch_position := Vector2.ZERO
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_bind_inputs()
	music = Music.new()
	add_child(music)
	arena = Arena.new()
	arena.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(arena)
	arena.follow(Vector2.ZERO)
	boss_arena = BossArena.new()
	boss_arena.name = "BossArena"
	add_child(boss_arena)
	actors = $Actors
	move_child(arena, 0)
	move_child(boss_arena, 1)
	obstacles = Obstacles.new()
	obstacles.name = "TerrainObstacles"
	add_child(obstacles)
	obstacles.setup(actors)
	combat_visuals = Node2D.new()
	combat_visuals.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	combat_visuals.draw.connect(_draw_combat)
	add_child(combat_visuals)
	player = $Actors/Hunter
	player.weapon = weapon_id
	level_up_aura = LevelUpAura.new()
	player.add_child(level_up_aura)
	buffs = Buffs.new(self)
	encounters = Encounters.new(self)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	ui.show_menu()
	get_tree().root.focus_exited.connect(_on_focus_lost)

func _reset_player() -> void:
	actors.remove_child(player)
	player.queue_free()
	player = HunterScene.instantiate()
	player.weapon = weapon_id
	actors.add_child(player)
	level_up_aura = LevelUpAura.new()
	player.add_child(level_up_aura)
	player.reset_motion()

func _bind_inputs() -> void:
	var mappings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN]}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in mappings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)

func start_run(selected_weapon: String) -> void:
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	bullets.clear()
	gems.clear()
	_clear_chests()
	effects.clear()
	choices.clear()
	stacks.clear()
	last_offers.clear()
	buffs.reset()
	encounters.reset()
	level_up_aura.cancel()
	tracked_target = null
	target_hold = 0.0
	weapon_id = selected_weapon
	weapon_cycle.reset(selected_weapon)
	_reset_player()
	obstacles.follow(Vector2.ZERO)
	player_velocity = Vector2.ZERO
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	camera.reset_physics_interpolation()
	elapsed = 0.0
	kills = 0
	level = 1
	experience = 0
	next_level = Data.FIRST_LEVEL_XP
	health = 100.0
	max_health = 100.0
	damage_multiplier = 1.0
	rate_multiplier = 1.0
	move_speed = 170.0
	pickup_radius = 65.0
	extra_pellets = 0
	extra_pierce = 0
	fire_damage = 0.0
	spawn_clock = 0.5
	shot_clock = 0.3
	invincible = 1.0
	boss_clock = Waves.BOSS_INTERVAL
	touch_index = -1
	state = "playing"
	music.set_context("game")
	ui.hide_overlay()
	ui.update_hud()
	combat_visuals.queue_redraw()

func _process(_delta: float) -> void:
	if state == "playing":
		combat_visuals.queue_redraw()

func return_to_menu() -> void:
	weapon_cycle.reset(weapon_id)
	state = "menu"
	encounters.reset()
	level_up_aura.cancel()
	tracked_target = null
	target_hold = 0.0
	touch_index = -1
	player_velocity = Vector2.ZERO
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	bullets.clear()
	gems.clear()
	_clear_chests()
	effects.clear()
	choices.clear()
	buffs.reset()
	_reset_player()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	camera.reset_physics_interpolation()
	arena.follow(Vector2.ZERO)
	combat_visuals.queue_redraw()
	obstacles.follow(Vector2.ZERO)
	ui.show_menu()

func _physics_process(delta: float) -> void:
	if state == "levelup":
		level_up_aura.advance(delta)
		if not level_up_aura.active:
			state = "upgrade"
			ui.show_upgrades(choices, true)
		return
	if state != "playing":
		if state == "menu":
			player.moving = false
			player.motion = Vector2.ZERO
			player.animate(delta)
		return
	elapsed += delta
	boss_arena.advance(delta)
	invincible = maxf(0.0, invincible - delta)
	target_hold = maxf(0.0, target_hold - delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_index >= 0:
		movement = (touch_position - touch_origin).limit_length(55) / 55
	var acceleration := 1400.0 if movement.length_squared() > 0.01 else 1800.0
	player_velocity = player_velocity.move_toward(movement * move_speed, acceleration * delta)
	obstacles.ensure_collision(player.position, player.position + player_velocity * delta, player.radius)
	player.move_with_velocity(player_velocity)
	player_velocity = player.motion
	_sync_camera()
	arena.follow(player.position)
	obstacles.follow(player.position)
	encounters.update(delta)
	_sync_camera()
	buffs.update(delta)
	_update_enemies(delta)
	if state != "playing":
		return
	encounters.flush_summons()
	encounters.update_projectiles(delta)
	if state != "playing":
		return
	# Track a reachable target every tick, not only when the weapon cooldown
	# expires, so body facing stays consistent between shots.
	var target := _tracking_target()
	player.aiming = target != null
	if target != null:
		player.aim = (player.position + AIM_OFFSET).direction_to(target.position + Vector2(0, -15))
	_update_weapon_cycle(delta, target != null)
	player.animate(delta)
	player.sprite.modulate.a = 0.45 if invincible > 0 and fmod(invincible, 0.16) < 0.08 else 1.0
	player.gripping_hand.modulate.a = player.sprite.modulate.a
	shot_clock -= delta
	if shot_clock <= 0 and target != null:
		_fire(target)
	_update_bullets(delta)
	_remove_dead_enemies()
	_update_gems(delta)
	_update_chests(delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= delta
		effects[i].position.y -= delta * 20.0
		if effects[i].life <= 0:
			effects.remove_at(i)
	if state == "playing" and experience >= next_level:
		_offer_upgrades()
	ui.update_hud()
	combat_visuals.queue_redraw()

func _sync_camera(reset: bool = false) -> void:
	camera.zoom = Vector2.ONE
	camera.position = player.position
	if reset:
		camera.reset_physics_interpolation()

func _spawn_enemy(forced_kind: int = -1, spawn_point: Variant = null, scene: PackedScene = null) -> Actor:
	var type := forced_kind
	if type < 0:
		type = encounters.choose_type()
	var enemy: Actor = (EnemyScenes[type] if scene == null else scene).instantiate()
	encounters.setup(enemy, type)
	enemy.max_hp *= 1.0 + minf(1.5, maxf(0, elapsed - 60.0) / 1200.0)
	enemy.hp = enemy.max_hp
	enemy.speed *= minf(1.2, 1.0 + elapsed / 3600.0)
	var distance := get_viewport_rect().size.length() * 0.55 + rng.randf_range(40, 100)
	var point: Vector2 = player.position + Vector2.from_angle(rng.randf() * TAU) * distance if spawn_point == null else spawn_point
	enemy.position = obstacles.safe_position(point, enemy.radius)
	obstacles.ensure_collision(enemy.position, enemy.position, enemy.radius)
	actors.add_child(enemy)
	enemy.reset_physics_interpolation()
	enemies.append(enemy)
	return enemy

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		if enemy.burn > 0:
			enemy.hp -= enemy.burn_damage * minf(delta, enemy.burn)
			enemy.burn = maxf(0.0, enemy.burn - delta)
		if enemy.poison_time > 0:
			enemy.hp -= enemy.poison_damage * minf(delta, enemy.poison_time)
			enemy.poison_time = maxf(0.0, enemy.poison_time - delta)
		if enemy.hp <= 0:
			continue
		var slow: float = enemy.slow_factor if enemy.slow_time > 0.0 else 1.0
		enemy.slow_time = maxf(0.0, enemy.slow_time - delta)
		var desired_velocity: Vector2 = encounters.movement(enemy, delta) * slow + enemy.knockback
		enemy.knockback = enemy.knockback.move_toward(Vector2.ZERO, 700.0 * delta)
		# Outside hordes can enter; once inside, bodies cannot escape through the rim.
		var confine: bool = boss_arena.active and (enemy.brain.get("boss", false) or boss_arena.contains(enemy.position, enemy.radius))
		enemy.set_collision_mask_value(4, confine)
		obstacles.ensure_collision(enemy.position, enemy.position + desired_velocity * delta, enemy.radius)
		enemy.move_with_velocity(desired_velocity)
		enemy.animate(delta)
		if enemy.hp > 0 and invincible <= 0 and enemy.touches_body(player):
			_damage_player(enemy.damage)
			if state == "dead":
				return
		if not enemy.brain.get("boss", false) and enemy.position.distance_squared_to(player.position) > 2200.0 * 2200.0:
			enemy.queue_free()
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if enemy.is_queued_for_deletion() and enemy.hp > 0:
			var point: Vector2 = player.position + player.position.direction_to(enemy.position) * 750.0
			var replacement := _spawn_enemy(enemy.enemy_type, point)
			for property in ["hp", "max_hp", "speed", "damage", "xp", "burn", "burn_damage", "slow_time", "slow_factor", "poison_time", "poison_damage", "knockback"]:
				replacement.set(property, enemy.get(property))
			replacement.brain = enemy.brain.duplicate(true)
			enemies.remove_at(index)

func _damage_player(amount: float) -> bool:
	if invincible > 0.0 or state != "playing":
		return false
	if buffs.block_hit():
		invincible = 0.25
		return false
	health = maxf(0, health - amount)
	music.play_sfx("player_hurt")
	invincible = 0.8
	player.flash = 0.14
	_effect(player.position + Vector2(0, -42), "-%d" % amount, Color("f08b8b"))
	buffs.on_player_hurt()
	if health <= 0:
		state = "dead"
		touch_index = -1
		ui.update_hud()
		ui.show_death()
	return true

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var origin := player.position + AIM_OFFSET
	var reach: float = Data.WEAPONS[weapon_id].range
	var best_distance := reach * reach
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		var distance: float = origin.distance_squared_to(enemy.position + Vector2(0, -14))
		if distance <= best_distance and obstacles.clear_shot(origin, enemy.position + Vector2(0, -14)):
			best_distance = distance
			best = enemy
	return best

func _tracking_target() -> Node2D:
	var nearest := _nearest_enemy()
	var origin := player.position + AIM_OFFSET
	var valid := is_instance_valid(tracked_target)
	if valid:
		valid = tracked_target.hp > 0 and origin.distance_to(tracked_target.position + Vector2(0, -14)) <= float(Data.WEAPONS[weapon_id].range)
		valid = valid and obstacles.clear_shot(origin, tracked_target.position + Vector2(0, -14))
	if valid:
		if nearest == null or nearest == tracked_target or target_hold > 0.0:
			return tracked_target
		var current_distance := origin.distance_to(tracked_target.position + Vector2(0, -14))
		var new_distance := origin.distance_to(nearest.position + Vector2(0, -14))
		if new_distance >= current_distance * 0.75:
			return tracked_target
	tracked_target = nearest
	target_hold = 0.18
	return tracked_target

func reload_weapon() -> bool:
	if state != "playing" or not weapon_cycle.begin_reload():
		return false
	music.play_sfx("reload_start")
	player.reload_progress = 0.0
	player._update_weapon(0)
	player.queue_redraw()
	ui.update_weapon_hud()
	return true

func _update_weapon_cycle(delta: float, has_target: bool) -> void:
	if state != "playing":
		return
	var events := weapon_cycle.advance(delta, has_target)
	if events.started: music.play_sfx("reload_start")
	if events.finished: music.play_sfx("reload_end")
	player.reload_progress = weapon_cycle.progress() if weapon_cycle.reloading else -1.0

func _fire(target: Node2D) -> void:
	if state != "playing" or not weapon_cycle.can_fire():
		return
	var weapon: Dictionary = Data.WEAPONS[weapon_id]
	var origin: Vector2 = player.position + AIM_OFFSET
	if target.hp <= 0 or origin.distance_squared_to(target.position + Vector2(0, -14)) > weapon.range * weapon.range:
		return
	if not weapon_cycle.consume_shot():
		return
	var direction: Vector2 = origin.direction_to(target.position + Vector2(0, -15))
	player.aim = direction
	player.on_shot()
	music.play_sfx(weapon_id)
	var muzzle: Vector2 = player.muzzle_position()
	var from_muzzle := muzzle.direction_to(target.position + Vector2(0, -15))
	# A touching enemy can overlap the barrel. Keep shooting forwards rather
	# than reversing piercing projectiles back through the hunter.
	if from_muzzle.dot(direction) > 0.0:
		direction = from_muzzle
	var shot_multiplier: float = buffs.on_shot(target, muzzle)
	var count: int = weapon.pellets + extra_pellets
	var spread: float = maxf(weapon.spread, 0.09 if count > 1 else 0)
	for i in range(count):
		var angle := (i - (count - 1) * 0.5) * spread
		var shot_direction := direction.rotated(angle)
		var velocity := shot_direction * float(weapon.speed)
		# Start at the actual barrel. Intersect each pellet's ray with the same
		# range circle so hand positions and spread never extend weapon reach.
		var offset := muzzle - origin
		var projection := offset.dot(shot_direction)
		var remaining := -projection + sqrt(maxf(0.0, projection * projection + weapon.range * weapon.range - offset.length_squared()))
		bullets.append({"position": muzzle, "velocity": velocity, "remaining": remaining, "origin": origin, "reach": weapon.range, "damage": weapon.damage * damage_multiplier * shot_multiplier, "hits": [], "pierce": extra_pierce + weapon.pierce, "bounces": buffs.rank("ricochet"), "color": Color("efb775") if shot_multiplier > 1.0 else weapon.color})
	shot_clock = weapon.interval / rate_multiplier
	if weapon_cycle.ammo == 0:
		reload_weapon()
	ui.update_weapon_hud()

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var old: Vector2 = bullet.position
		bullet.previous = old
		var travel := minf(bullet.velocity.length() * delta, bullet.remaining)
		bullet.position += bullet.velocity.normalized() * travel
		var terrain_fraction: float = obstacles.projectile_fraction(old, bullet.position)
		var blocked := terrain_fraction < 1.0
		if blocked:
			bullet.position = old.lerp(bullet.position, terrain_fraction)
		bullet.remaining -= travel
		for enemy in enemies:
			if enemy.hp <= 0 or enemy.get_instance_id() in bullet.hits:
				continue
			var center: Vector2 = enemy.position + Vector2(0, -14)
			var closest := Geometry2D.get_closest_point_to_segment(center, old, bullet.position)
			if not enemy.intersects_projectile(old, bullet.position):
				continue
			buffs.hit_projectile(enemy, bullet)
			bullet.hits.append(enemy.get_instance_id())
			if bullet.hits.size() > bullet.pierce:
				var end: Vector2 = bullet.position
				bullet.position = closest
				bullet.remaining += end.distance_to(closest)
				if buffs.ricochet(bullet):
					blocked = false
					break
				bullet.remaining = 0
				break
		if bullet.remaining <= 0 or blocked:
			bullets.remove_at(i)

func _remove_dead_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if enemy.hp > 0:
			continue
		kills += 1
		buffs.on_kill(enemy)
		encounters.on_death(enemy)
		if enemy.brain.get("boss", false):
			_drop_boss_chest(enemy.position)
		if gems.size() < 240:
			gems.append({"position": enemy.position, "value": enemy.xp, "attracted": false})
		else:
			# Preserve all earned XP even when the number of visible gems is capped.
			gems[0].value += enemy.xp
		_effect(enemy.position, "+", Color("74b7a8"))
		enemy.queue_free()
		enemies.remove_at(i)

func _update_gems(delta: float) -> void:
	for i in range(gems.size() - 1, -1, -1):
		var gem: Dictionary = gems[i]
		gem.previous = gem.position
		var distance: float = gem.position.distance_to(player.position)
		if distance < pickup_radius:
			gem.attracted = true
		if gem.attracted:
			gem.position = gem.position.move_toward(player.position, 360 * delta)
		if gem.position.distance_to(player.position) < 15:
			experience += gem.value
			gems.remove_at(i)

func _drop_boss_chest(at: Vector2) -> Node2D:
	var chest := BossChest.new()
	chest.name = "BossChest"
	chest.position = obstacles.safe_position(at, 18.0)
	actors.add_child(chest)
	chests.append(chest)
	return chest

func _clear_chests() -> void:
	for chest in chests:
		chest.get_parent().remove_child(chest)
		chest.queue_free()
	chests.clear()

func _update_chests(delta: float) -> void:
	if state != "playing":
		return
	for i in range(chests.size()-1,-1,-1):
		var chest := chests[i]
		chest.advance(delta)
		if chest.opened:
			if chest.age >= BossChest.OPEN_LIFETIME:
				chest.queue_free()
				chests.remove_at(i)
			continue
		if chest.age >= BossChest.PICKUP_DELAY and player.position.distance_to(chest.position) <= BossChest.PICKUP_RADIUS:
			chest.open()
			_offer_chest_upgrade()
			# Collect one reward at a time; pending floor loot and XP wait for the choice.
			return

func _offer_chest_upgrade() -> void:
	_roll_upgrade_choices()
	music.play_sfx("level_up")
	if choices.is_empty():
		buffs.heal(max_health)
		_effect(player.position + Vector2(0,-48), "VIDA RESTAURADA", Color("ffdc91"))
		return
	state = "upgrade"
	touch_index = -1
	player.sprite.modulate = Color.WHITE
	player.gripping_hand.modulate = Color.WHITE
	ui.update_hud()
	ui.show_upgrades(choices, true, true)

func _roll_upgrade_choices() -> void:
	choices.clear()
	var pool: Array = Data.UPGRADES.filter(func(upgrade: Dictionary) -> bool:
		return stacks.get(upgrade.id, 0) < upgrade.max_level)
	if pool.is_empty():
		return
	var fresh: Array = pool.filter(func(upgrade: Dictionary) -> bool: return upgrade.id not in last_offers)
	if fresh.size() >= 3:
		pool = fresh
	# When possible, include one evolution of a buff already owned.
	var owned: Array = pool.filter(func(upgrade: Dictionary) -> bool: return stacks.get(upgrade.id, 0) > 0)
	if not owned.is_empty():
		var evolution: Dictionary = owned[rng.randi_range(0, owned.size() - 1)]
		choices.append(evolution)
		pool.erase(evolution)
	while choices.size() < 3 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		choices.append(pool.pop_at(index))
	last_offers.clear()
	for choice in choices:
		last_offers.append(choice.id)

func _offer_upgrades() -> void:
	experience -= next_level
	level += 1
	next_level = roundi(next_level * Data.LEVEL_XP_GROWTH + Data.LEVEL_XP_FLAT)
	_roll_upgrade_choices()
	if choices.is_empty():
		_effect(player.position + Vector2(0, -48), "PODER MÁXIMO", Color("efb775"))
		return
	state = "levelup"
	touch_index = -1
	player.sprite.modulate = Color.WHITE
	player.gripping_hand.modulate = Color.WHITE
	level_up_aura.start(level)
	music.play_sfx("level_up")
	ui.update_hud()

func select_upgrade(index: int) -> void:
	if state != "upgrade" or index < 0 or index >= choices.size():
		return
	var id: String = choices[index].id
	if stacks.get(id, 0) >= choices[index].max_level:
		return
	stacks[id] = stacks.get(id, 0) + 1
	buffs.refresh_stats()
	if id == "vitality":
		buffs.heal(30.0)
	if id == "shield" and stacks[id] == 1:
		buffs.shield_ready = true
	state = "playing"
	invincible = maxf(invincible, 0.6)
	ui.hide_overlay()
	ui.update_hud()

func toggle_pause() -> void:
	if ui.screen == "settings":
		ui.go_back()
		return
	if state in ["playing", "levelup"]:
		previous_state = state
		state = "paused"
		touch_index = -1
		ui.show_pause()
	elif state == "paused":
		state = previous_state
		ui.hide_overlay()

func _on_focus_lost() -> void:
	if state in ["playing", "levelup"]:
		toggle_pause()

func _input(event: InputEvent) -> void:
	# Release must clear the stick even if a menu consumed the original touch.
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
		touch_index = -1
	if event is InputEventScreenDrag and event.index == touch_index:
		touch_position = event.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and (state == "menu" or ui.screen == "settings"):
			ui.go_back()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			toggle_pause()
		if state == "playing" and event.keycode == KEY_R:
			reload_weapon()
		if state == "upgrade" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			select_upgrade(event.keycode - KEY_1)
	if state == "playing" and event is InputEventScreenTouch and event.pressed:
		if touch_index < 0 and event.position.x < get_viewport_rect().size.x * 0.65:
			touch_index = event.index
			touch_origin = event.position
			touch_position = event.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and state in ["playing", "levelup"]:
		toggle_pause()

func _effect(at: Vector2, text: String, color: Color) -> void:
	if effects.size() < 100:
		effects.append({"position": at, "text": text, "color": color, "life": 0.55})

func time_label() -> String:
	return "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]

func _draw_combat() -> void:
	var fraction := Engine.get_physics_interpolation_fraction()
	buffs.draw(combat_visuals, fraction)
	encounters.draw(combat_visuals, fraction)
	for gem in gems:
		var p: Vector2 = Vector2(gem.get("previous", gem.position)).lerp(gem.position, fraction)
		combat_visuals.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 0), p + Vector2(0, 5), p + Vector2(-4, 0)]), Color("70c9b5"))
	for bullet in bullets:
		var p: Vector2 = Vector2(bullet.get("previous", bullet.position)).lerp(bullet.position, fraction)
		combat_visuals.draw_line(p - bullet.velocity.normalized() * 12, p, bullet.color, 3.0)
		combat_visuals.draw_circle(p, 2.0, Color("fff0c8"))
	var font := PixelTheme.font()
	for effect in effects:
		var color: Color = effect.color
		color.a = minf(1.0, effect.life * 3.0)
		combat_visuals.draw_string(font, effect.position.round(), effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
