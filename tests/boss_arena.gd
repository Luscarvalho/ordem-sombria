extends SceneTree
const Arena=preload("res://scripts/boss_arena.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func clear_of_props(game,point: Vector2,radius: float) -> bool:
	for data in game.obstacles.nearby(point,point,radius):
		if point.distance_to(data.position)<radius+float(data.radius)-0.01: return false
	return true
func run_checks() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game.spawn_clock=999
	game.shot_clock=999
	game.invincible=999
	assert(not game.boss_arena.active and game.camera.zoom==Vector2.ONE)
	# Start away from world zero, so a camera-following or origin-only cage fails.
	game.player.position=game.obstacles.safe_position(Vector2(910,650),game.player.radius)
	var entry: Vector2=game.player.position.round()
	game._sync_camera()
	var camera_before: Vector2 = game.camera.position
	var boss=game.encounters.spawn_boss(1)
	var arena: Node2D=game.boss_arena
	assert(arena.active and arena.visible and arena.position==entry)
	assert(arena.contains(boss.position,boss.radius) and clear_of_props(game,boss.position,boss.radius))
	assert(boss.position.distance_to(game.player.position)>100,"Boss spawned directly on the player")
	assert(game.camera.zoom == Vector2.ONE and game.camera.position == camera_before, "Boss arrival changed the camera scale or position")
	assert(arena.contains(entry + Vector2(350, 0), game.player.radius), "Arena does not provide the extra dodge space")
	# The actual player cannot leave in any direction, even at high speed/large delta.
	for sector in range(8):
		var angle:=sector*TAU/8
		var direction:=Vector2.from_angle(angle)
		game.player.position=entry
		game.player_velocity=direction*2000
		await physics_frame
		game._physics_process(1.0/60.0)
		assert(arena.contains(game.player.position,game.player.radius),"Player crossed the rim")
		assert(clear_of_props(game,game.player.position,game.player.radius),"Rim pushed the player into a prop")
		assert(arena.position==entry, "Arena follows the player")
		assert(game.camera.position == game.player.position and game.camera.zoom == Vector2.ONE, "Camera stopped following the player or changed zoom during the fight")
	# Slide at the rim rather than stick, and retain collision against nearby terrain.
	for sector in range(24):
		var direction:=Vector2.from_angle(sector*TAU/24)
		var start: Vector2=arena.fit_position(entry+direction*(Arena.RADIUS-12.2),12,game.obstacles)
		game.player.position = start
		await physics_frame
		game.player.move_with_velocity(direction.orthogonal() * 1200.0)
		var moved: Vector2 = game.player.position
		assert(arena.contains(moved,12) and clear_of_props(game,moved,12))
	# A charge has the same boundary as the player; approaching hordes can enter from outside.
	game.player.position=entry
	boss.position=arena.fit_position(entry+Vector2(130,0),boss.radius,game.obstacles)
	boss.brain.charge=5
	boss.brain.direction=Vector2.RIGHT
	for tick in range(60):
		await physics_frame
		game._update_enemies(1.0/60.0)
	assert(arena.contains(boss.position,boss.radius) and clear_of_props(game,boss.position,boss.radius))
	var spider=game._spawn_enemy(0)
	spider.position=game.obstacles.safe_position(entry-Vector2(Arena.RADIUS+160,0),spider.radius)
	for tick in range(900):
		await physics_frame
		game._update_enemies(1.0/60.0)
		if arena.contains(spider.position,spider.radius): break
	assert(arena.contains(spider.position,spider.radius),"Barrier strands all approaching hordes outside")
	# Effects and confinement persist while paused and while cards are displayed.
	var age: float=arena.age
	game.toggle_pause()
	game._physics_process(5)
	assert(arena.active and arena.age==age and arena.position==entry)
	game.toggle_pause()
	game.experience=game.next_level
	game._offer_upgrades()
	game._physics_process(0.55)
	assert(game.state=="upgrade" and arena.active and arena.age==age)
	game.select_upgrade(0)
	# A second boss reuses the same arena; defeating just one must not reopen it.
	var second=game.encounters.spawn_boss(2)
	assert(arena.position==entry and arena.contains(second.position,second.radius))
	assert(game.camera.zoom == Vector2.ONE and game.camera.position == game.player.position, "Second boss changed the camera")
	boss.hp=0
	game._remove_dead_enemies()
	assert(arena.active and game.chests.size()==1)
	second.hp=0
	game._remove_dead_enemies()
	assert(not arena.active and not arena.visible and game.chests.size()==2)
	assert(game.camera.zoom==Vector2.ONE and game.camera.position==game.player.position)
	var outside:=entry+Vector2(Arena.RADIUS+100,0)
	game.player.position=outside
	game.player_velocity=Vector2.ZERO
	game._physics_process(0)
	assert(game.player.position.distance_to(entry)>Arena.RADIUS,"Invisible wall remains after victory")
	# Restart and return-to-menu clear both the boundary and the fight camera.
	game.encounters.spawn_boss(3)
	assert(arena.active and arena.position==game.player.position.round())
	game.return_to_menu()
	assert(not arena.active and game.camera.zoom==Vector2.ONE and game.chests.is_empty())
	game.start_run("wand")
	assert(not arena.active and game.camera.position==Vector2.ZERO)
	game.queue_free()
	await process_frame
	print("PASS: larger fixed arena, unchanged camera scale at boss arrival, camera follows player during combat, confined player/charges, prop collision/sliding, incoming hordes, frozen effects, overlapping bosses, last-boss release, loot and clean reset")
	quit()
