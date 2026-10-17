extends SceneTree
## Regressions for fast legs, unequal direction rhythms and abrupt target flips.
const Actor = preload("res://scripts/actor.gd")
const HunterScene = preload("res://scenes/characters/hunter.tscn")
const ColossusScene = preload("res://scenes/characters/enemies/colossus.tscn")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var actor := HunterScene.instantiate()
	root.add_child(actor)
	actor.weapon = "revolver"
	actor.reset_motion()
	var frames: SpriteFrames = actor.sprite.sprite_frames
	for animation in ["walk", "walk_up", "walk_down", "walk_up_diagonal", "walk_down_diagonal"]:
		var seconds := frames.get_frame_count(animation) / frames.get_animation_speed(animation)
		assert(is_equal_approx(seconds, 1.0), "Changing direction changed the step rhythm")
	assert(6.0 / Actor.ANIMATIONS[3].get_animation_speed("walk") >= 0.75)
	assert(6.0 / Actor.ANIMATIONS[4].get_animation_speed("walk") >= 1.3)
	actor.moving = true
	actor.motion = Vector2.RIGHT * 10
	actor.animate(1.0)
	assert(actor.animation_clock < 0.1, "Slow movement still plays fast legs")
	actor.moving = false
	actor.motion = Vector2.ZERO
	actor.animate(0.01)
	assert(actor.sprite.animation == &"idle", "Feet keep cycling after stopping")
	actor.reset_motion()
	actor.aiming = true
	actor.aim = Vector2.LEFT
	actor.animate(1.0 / 60.0)
	assert(actor.facing == &"side" and not actor.sprite.flip_h, "A 180-degree turn snapped instantly")
	var poses := {}
	for i in range(20):
		actor.animate(1.0 / 60.0)
		poses[str(actor.facing)] = true
	assert(actor.sprite.flip_h and actor.facing == &"side")
	assert(poses.has("down_diagonal") or poses.has("up_diagonal"), "Turn skipped intermediate art")
	# Turn without a continuing target must finish even after shot-hold expires.
	actor.reset_motion()
	actor.aim = Vector2.LEFT
	actor.on_shot()
	for i in range(20):
		actor.animate(1.0 / 60.0)
	assert(actor.sprite.flip_h and not actor.finishing_aim)
	# Walk cycles must retain the same normalized phase through a directional turn.
	actor.reset_motion()
	actor.moving = true
	actor.motion = Vector2.RIGHT * 170
	actor.move_blend = 1.0
	actor.animate(0)
	actor.animation_clock = 0.45
	actor.animate(0)
	actor.aiming = true
	actor.aim = Vector2.DOWN
	actor.animate(0.10)
	assert(absf(fposmod(actor.animation_clock, 1.0) - 0.55) < 0.01)
	# Near-vertical monster movement should not mirror the whole large sprite.
	var giant := ColossusScene.instantiate()
	root.add_child(giant)
	giant.moving = true
	for i in range(30):
		giant.motion = Vector2(-4 if i % 2 else 4, 39)
		giant.animate(1.0 / 60.0)
		assert(not giant.sprite.flip_h)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run("revolver")
	game._spawn_enemy(0)
	game._spawn_enemy(0)
	var a = game.enemies[0]
	var b = game.enemies[1]
	a.position = Vector2(100, 0)
	b.position = Vector2(-105, 0)
	assert(game._tracking_target() == a)
	game.target_hold = 0.0
	b.position = Vector2(-99, 0)
	assert(game._tracking_target() == a, "Tiny distance changes make the hunter flip repeatedly")
	b.position = Vector2(-50, 0)
	assert(game._tracking_target() == b, "A substantially closer threat should take priority")
	b.hp = 0
	assert(game._tracking_target() == a, "Dead targets must release immediately")
	a.position = Vector2(1000, 0)
	assert(game._tracking_target() == null)
	actor.queue_free()
	giant.queue_free()
	game.queue_free()
	await process_frame
	print("PASS: matched walk periods, slower large-monster steps, speed-matched feet, smooth intermediate turns, phase continuity and stable target tracking")
	quit()
