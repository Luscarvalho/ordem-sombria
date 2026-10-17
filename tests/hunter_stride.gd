extends SceneTree
## Observe distinct light/occluded boot pixels, rather than trusting the frame counter.
const Actor = preload("res://scripts/actor.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func leg_centers(texture: AtlasTexture) -> Array[Vector2]:
	var image := texture.atlas.get_image()
	var sums: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var counts := [0,0]
	var region := texture.region
	for y in range(int(region.position.y + region.size.y * 0.75),int(region.end.y)):
		for x in range(int(region.position.x),int(region.end.x)):
			var color := image.get_pixel(x,y)
			# Brown leather only, excluding purple trousers/cape, outlines and alpha fringes.
			if color.a > 0.8 and color.r > 0.09 and color.r > color.g * 1.1 and color.g > color.b * 1.1:
				var leg := 0 if color.r > 0.27 else 1
				sums[leg] += Vector2(x,y) - region.position + texture.margin.position - texture.get_size() / 2
				counts[leg] += 1
	assert(counts[0] > 50 and counts[1] > 50,"Both boots must be readable")
	return [sums[0]/counts[0],sums[1]/counts[1]]

func run_checks() -> void:
	var actor := Actor.new()
	root.add_child(actor)
	if "--rejected-sheet" in OS.get_cmdline_user_args():
		actor.sprite.sprite_frames = load("res://assets/animations/hunter-standard-v4.tres")
	for sector in range(8):
		actor.reset_motion()
		actor.aiming = true
		actor.aim = Vector2.from_angle(sector * TAU / 8)
		actor.body_angle = actor.aim.angle()
		actor.moving = true
		actor.motion = actor.aim * 170
		actor.animate(0)
		var frames: SpriteFrames = actor.sprite.sprite_frames
		var poses: Array = []
		for frame in range(8):
			poses.append(leg_centers(frames.get_frame_texture(actor.sprite.animation,frame)))
		var scale: float = actor.base_scale
		var axis := Vector2.DOWN if actor.facing in [&"up", &"down"] else Vector2.RIGHT
		var first: float = (poses[0][0]-poses[0][1]).dot(axis)*scale
		var opposite: float = (poses[4][0]-poses[4][1]).dot(axis)*scale
		var required := 1.0 if axis == Vector2.DOWN else 3.0
		# Contacts must exchange leg order along the travel axis, not repeat a half-step.
		if first*opposite >= 0 or minf(absf(first),absf(opposite)) < required:
			push_error("The two contact poses repeat the same leg order in sector %d: %.2f / %.2f" % [sector,first,opposite])
			actor.free()
			quit(1)
			return
		# The light boot lifts in the first passing pose; the occluded boot in the second.
		assert((poses[2][1].y-poses[2][0].y)*scale > 0.8,"First swing did not lift a foot")
		assert((poses[6][0].y-poses[6][1].y)*scale > 0.8,"Opposite foot never swings")
		var seen := {}
		for tick in range(120):
			seen[actor.sprite.frame] = true
			actor.animate(1.0/60.0)
		assert(seen.size()==8,"Playback skipped part of the cycle")
	actor.free()
	print("PASS: actual leather pixels exchange front/back at opposite contacts and alternate lifted legs, with eight-frame playback in all eight directions")
	quit()
