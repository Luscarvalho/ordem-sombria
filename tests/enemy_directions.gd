extends SceneTree

const Game = preload("res://scripts/game.gd")
const CASES := [
	{"direction": Vector2.RIGHT, "suffix": "", "flip": false},
	{"direction": Vector2.LEFT, "suffix": "", "flip": true},
	{"direction": Vector2.DOWN, "suffix": "_down", "flip": false},
	{"direction": Vector2.UP, "suffix": "_up", "flip": false},
]

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scenes: Array[PackedScene] = []
	scenes.append_array(Game.EnemyScenes)
	scenes.append(Game.MatriarchScene)
	var sheets := {}
	for scene in scenes:
		var actor: Game.Actor = scene.instantiate()
		root.add_child(actor)
		var frames := actor.sprite.sprite_frames
		var canvas := frames.get_frame_texture("walk", 0).get_size()
		var regions := {}
		var sources := {}
		for suffix in ["", "_down", "_up"]:
			var walk: String = "walk" + suffix
			assert(frames.get_frame_count(walk) == 6)
			assert(frames.get_frame_count("idle" + suffix) == 1)
			assert(frames.get_animation_loop(walk))
			assert(is_equal_approx(frames.get_animation_speed(walk), frames.get_animation_speed("walk")))
			for frame_index in range(6):
				var texture := frames.get_frame_texture(walk, frame_index) as AtlasTexture
				assert(texture.get_size() == canvas, "Turning changes the animation canvas")
				assert(not regions.has(texture.region), "Directional poses reuse the same source region")
				regions[texture.region] = true
				sources[texture.atlas.resource_path] = true
		assert(sources.size() == 1 and regions.size() == 18)
		var source: String = sources.keys()[0]
		assert(source.ends_with("-directions-v1.png"))
		sheets[source] = true
		assert(frames.get_frame_texture("walk", 0).atlas.get_image().get_pixel(0, 0).a == 0.0)
		for scenario in CASES:
			actor.reset_motion()
			actor.moving = true
			actor.motion = scenario.direction * actor.REFERENCE_SPEEDS[actor.kind]
			actor.animate(0.2)
			assert(actor.sprite.animation == StringName("walk" + scenario.suffix))
			assert(actor.sprite.flip_h == scenario.flip)
			actor.moving = false
			actor.motion = Vector2.ZERO
			actor.animate(0.2)
			var idle := "walk" if actor.kind == 2 else "idle"
			assert(actor.sprite.animation == StringName(idle + scenario.suffix), "Stopping loses the last facing")
		actor.reset_motion()
		actor.moving = true
		actor.motion = Vector2.RIGHT * actor.REFERENCE_SPEEDS[actor.kind]
		actor.animate(0.0)
		actor.animation_clock = 0.31 * 6.0 / frames.get_animation_speed("walk")
		actor.motion = Vector2.UP * actor.REFERENCE_SPEEDS[actor.kind]
		actor.animate(0.0)
		assert(actor.sprite.animation == &"walk_up")
		assert(is_equal_approx(actor.animation_clock * frames.get_animation_speed("walk_up") / 6.0, 0.31), "Turning resets the step phase")
		actor.reset_motion()
		actor.moving = true
		for tick in range(90):
			actor.motion = Vector2.from_angle(deg_to_rad(44.0 if tick % 2 == 0 else 46.0)) * 50.0
			actor.animate(1.0 / 60.0)
			assert(actor.facing == &"side", "Small diagonal noise flickers between directions")
		actor.reset_motion()
		actor.brain = {"windup": 1.0, "target": actor.position + Vector2(0, -150)}
		actor.animate(0.2)
		assert(actor.facing == &"up", "Enemy attack telegraph ignores its target direction")
		actor.free()
	assert(sheets.size() == 5, "Enemy families are not split into five separate sheets")
	print("PASS: five transparent family sheets, 18 unique poses each, four cardinal facings for every enemy and boss, native mirrored left view, matching idle, hovering eye, stable diagonals, preserved step phase and attack facing")
	quit()
