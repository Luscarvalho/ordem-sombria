extends SceneTree

const Preview = preload("res://scripts/enemy_preview.gd")
const FPS := 24.0

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(720, 480)
	root.content_scale_size = Vector2i(720, 480)
	var viewer = load("res://scenes/preview/enemies/00_all_directions.tscn").instantiate()
	root.add_child(viewer)
	viewer.set_process(false)
	var output_root := "res://assets/previews/characters"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_root))
	var manifest := {"characters": []}
	for character_index in range(Preview.SCENES.size()):
		viewer.show_character(character_index)
		viewer.playing = false
		var actor = viewer.actors[0]
		var pace: float = 1.0 if actor.kind == 2 else clampf(actor.motion.length() / actor.REFERENCE_SPEEDS[actor.kind] * actor.gait_multiplier, 0.0, 1.8)
		var cycle_seconds: float = actor.sprite.sprite_frames.get_frame_count("walk") / (actor.sprite.sprite_frames.get_animation_speed("walk") * pace)
		var cycles := 5 if actor.kind == 2 else maxi(2, roundi(3.0 / cycle_seconds))
		var duration := cycle_seconds * cycles
		var frame_count := ceili(duration * FPS)
		var frame_delta := duration / frame_count
		var character_id: String = Preview.IDS[character_index]
		var folder := "/tmp/horda-character-gifs/" + character_id
		DirAccess.make_dir_recursive_absolute(folder)
		for tick in range(3):
			await process_frame
		for frame in range(frame_count):
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			assert(not image.is_empty(), "Capture needs the native rendering driver")
			assert(image.save_png(folder + "/frame-%02d.png" % frame) == OK)
			if frame == 0:
				assert(image.save_png(output_root + "/" + character_id + ".png") == OK)
			viewer.advance(frame_delta)
		manifest.characters.append({"id": character_id, "name": Preview.NAMES[character_index], "frames": folder, "fps": 1.0 / frame_delta, "frame_count": frame_count, "output": output_root.trim_prefix("res://") + "/" + character_id + ".gif"})
		print("CAPTURED: " + character_id)
	var manifest_file := FileAccess.open(output_root + "/manifest.json", FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "\t") + "\n")
	viewer.free()
	quit()
