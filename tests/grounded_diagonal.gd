extends SceneTree
## One sheet, equal canvas/rhythm, native frames, grounded silhouettes and fist sockets.
const Actor = preload("res://scripts/actor.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var actor := Actor.new()
	root.add_child(actor)
	actor.weapon = "revolver"
	var frames: SpriteFrames = actor.sprite.sprite_frames
	var image: Image = load("res://assets/animations/hunter-final-v8.png").get_image()
	assert(image.get_pixel(0,0).a==0,"Transparent sheet lost its alpha")
	for sector in range(8):
		actor.reset_motion()
		actor.aiming = true
		actor.aim = Vector2.from_angle(sector*TAU/8)
		actor.body_angle = actor.aim.angle()
		for walking in [false,true]:
			actor.moving = walking
			actor.motion = actor.aim*170 if walking else Vector2.ZERO
			actor.animate(0)
			var animation: StringName = actor.sprite.animation
			var count := frames.get_frame_count(animation)
			assert(count==(8 if walking else 1))
			var canvas := frames.get_frame_texture(animation,0).get_size()
			if walking:
				assert(is_equal_approx(count/frames.get_animation_speed(animation),1.0))
			for frame in range(count):
				actor.animation_clock = (frame+0.01)/frames.get_animation_speed(animation)
				actor.animate(0)
				assert(actor.sprite.visible and actor.get_node_or_null("DiagonalGait")==null)
				var texture := frames.get_frame_texture(animation,frame) as AtlasTexture
				assert(texture.atlas.resource_path=="res://assets/animations/hunter-final-v8.png","Mixed animation sources returned")
				assert(texture.get_size()==canvas)
				var lowest := -INF
				for y in range(int(texture.region.end.y)-5,int(texture.region.end.y)):
					for x in range(int(texture.region.position.x),int(texture.region.end.x)):
						if image.get_pixel(x,y).a>0.8:
							var p := Vector2(x,y)-texture.region.position+texture.margin.position-canvas/2
							lowest=maxf(lowest,(actor.sprite.transform*p).y)
				# Perspective views retain their real foot-depth differences rather than pinning a boot.
				assert(lowest>=2 and lowest<=6,"Silhouette floats or sinks in "+str(animation))
				var hand: Vector2 = texture.get_meta("hand_socket")
				assert(texture.region.has_point(hand))
				if actor.facing not in [&"up",&"up_diagonal"]:
					var skin := 0
					for y in range(int(hand.y)-3,int(hand.y)+4):
						for x in range(int(hand.x)-3,int(hand.x)+4):
							var c := image.get_pixel(x,y)
							if c.a>0.8 and c.r>0.7 and c.g>0.5 and c.b>0.4: skin+=1
					assert(skin>8,"Socket missed the visible fist")
				var mount: Dictionary = actor.Mount.WEAPONS[actor.weapon]
				var grip := actor.held_weapon.to_global(mount.grip+actor.held_weapon.offset)
				assert(grip.distance_to(actor.to_global(actor.Mount.hand_position(actor.sprite)))<0.001)
			if not walking:
				var transform := actor.sprite.transform
				for tick in range(90):
					actor.animate(1.0/60.0)
					assert(actor.sprite.transform==transform)
	actor.free()
	print("PASS: one PNG for every walk/idle direction, eight aligned native frames, equal periods, alpha, grounded silhouettes, fist sockets, mirrors and stable idle")
	quit()
