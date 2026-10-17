extends CharacterBody2D
## Shared frame animation, facing, idle breathing and weapon feedback.
## Simulation advances frames explicitly so pause/upgrade screens freeze actors.

const Data = preload("res://scripts/game_data.gd")
const WeaponArt = preload("res://scripts/pixel_icon.gd")
const Mount = preload("res://scripts/weapon_mount.gd")
const ANIMATIONS := [
	preload("res://assets/animations/hunter-final-v8.tres"),
	preload("res://assets/animations/crawler-directions-v1.tres"),
	preload("res://assets/animations/eye-directions-v1.tres"),
	preload("res://assets/animations/beast-directions-v1.tres"),
	preload("res://assets/animations/colossus-directions-v1.tres"),
	preload("res://assets/animations/spitter-directions-v1.tres"),
]
const REFERENCE_SPEEDS := [170.0, 56.0, 66.0, 96.0, 39.0, 45.0]
@export var enemy_type := -1
var brain: Dictionary = {}
@export var visual_height := 0.0
@export var base_tint := Color.WHITE
@export var gait_multiplier := 1.0
@onready var sprite: AnimatedSprite2D = $AnimatedBody
@onready var held_weapon: Sprite2D = get_node_or_null("WeaponPivot/HeldWeapon")
@onready var weapon_pivot: Node2D = get_node_or_null("WeaponPivot")
@onready var gripping_hand: Sprite2D = get_node_or_null("GrippingHand")
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var contact_hitbox: Area2D = get_node_or_null("ContactHitbox")
@onready var contact_shape: CollisionShape2D = get_node_or_null("ContactHitbox/CollisionShape2D")
var hand_textures: Dictionary = {}
var projectile_probe := SegmentShape2D.new()
@export var kind := 0
@export var hp := 100.0
@export var max_hp := 100.0
@export var speed := 150.0
@export var damage := 10.0
@export var radius := 12.0
@export var xp := 0
var flash := 0.0
var burn := 0.0
var burn_damage := 0.0
var slow_time := 0.0
var slow_factor := 1.0
var poison_time := 0.0
var poison_damage := 0.0
var knockback := Vector2.ZERO
var phase := 0.0
var moving := false
var motion := Vector2.ZERO
var aim := Vector2.RIGHT
var aiming := false
var weapon := ""
var animation_clock := 0.0
var move_blend := 0.0
var recoil := 0.0
var reload_progress := -1.0
var muzzle_flash := 0.0
var aim_hold := 0.0
var base_scale := 1.0
var foot_offset := 0.0
var equipped := ""
var visual_angle := 0.0
var facing: StringName = &"side"
var body_angle := 0.0
var stride_direction := 1.0
var flip_hold := 0.0
var finishing_aim := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	phase = randf() * TAU
	animation_clock = randf()
	sprite.animation = "idle"
	var canvas: Vector2 = sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
	base_scale = _height() / canvas.y
	foot_offset = -_height() * 0.5 + 6.0
	sprite.scale = Vector2.ONE * base_scale
	sprite.position.y = foot_offset
	if is_instance_valid(weapon_pivot):
		weapon_pivot.draw.connect(_draw_muzzle)

func move_with_velocity(desired_velocity: Vector2) -> void:
	velocity = desired_velocity
	move_and_slide()
	motion = get_real_velocity()
	moving = motion.length_squared() > 16.0

func touches_body(other: CharacterBody2D) -> bool:
	if not is_instance_valid(contact_hitbox) or not contact_hitbox.monitoring or contact_shape.disabled:
		return false
	var other_shape: CollisionShape2D = other.get_node("CollisionShape2D")
	if other_shape.disabled or (contact_hitbox.collision_mask & other.collision_layer) == 0:
		return false
	return contact_shape.shape.collide(contact_shape.global_transform, other_shape.shape, other_shape.global_transform)

func intersects_projectile(from: Vector2, to: Vector2) -> bool:
	if hurt_shape.disabled or not hurtbox.monitorable or hurtbox.collision_layer == 0:
		return false
	projectile_probe.a = from
	projectile_probe.b = to
	return hurt_shape.shape.collide(hurt_shape.global_transform, projectile_probe, Transform2D.IDENTITY)

func reset_motion() -> void:
	velocity = Vector2.ZERO
	motion = Vector2.ZERO
	moving = false
	move_blend = 0.0
	animation_clock = 0.0
	recoil = 0.0
	reload_progress = -1.0
	muzzle_flash = 0.0
	aim_hold = 0.0
	aiming = false
	flash = 0.0
	aim = Vector2.RIGHT
	visual_angle = 0.0
	facing = &"side"
	body_angle = 0.0
	stride_direction = 1.0
	flip_hold = 0.0
	finishing_aim = false
	sprite.flip_h = false
	_set_body_animation(&"idle")
	sprite.frame = 0
	sprite.scale = Vector2.ONE * base_scale
	sprite.rotation = 0.0
	sprite.position = Vector2(0, foot_offset)
	sprite.modulate = Color.WHITE
	_update_weapon(0)
	reset_physics_interpolation()

func on_shot() -> void:
	recoil = 5.0 if weapon == "shotgun" else (2.0 if weapon == "wand" else 3.0)
	muzzle_flash = 0.055
	aim_hold = 0.18
	finishing_aim = true
	visual_angle = aim.angle()
	# Refresh the grip/flash now; the body keeps its smooth directional turn.
	animate(0.0)

func animate(delta: float) -> void:
	phase += delta * (3.0 if kind == 2 else 2.0)
	flash = maxf(0.0, flash - delta)
	aim_hold = maxf(0.0, aim_hold - delta)
	recoil = move_toward(recoil, 0.0, delta * 40.0)
	muzzle_flash = maxf(0.0, muzzle_flash - delta)
	flip_hold = maxf(0.0, flip_hold - delta)
	move_blend = lerpf(move_blend, 1.0 if moving else 0.0, 1.0 - exp(-delta * 16.0))
	if kind == 0:
		_update_hunter_facing(delta)
	else:
		_update_enemy_facing()
	var walking := (moving and motion.length_squared() > 16.0) or kind == 2
	var animation: StringName = "walk" if walking else "idle"
	if facing != &"side":
		animation = StringName(str(animation) + "_" + str(facing))
	_set_body_animation(animation)
	if walking:
		var pace := clampf(motion.length() / REFERENCE_SPEEDS[kind] * gait_multiplier, 0.0, 1.8)
		if kind == 2:
			pace = 1.0
		# Backpedal without turning away from the target. The foot cycle reverses
		# while body and weapon keep the same firing direction.
		var playback_direction := -1.0 if kind == 0 and motion.dot(_facing_vector()) < -motion.length() * 0.2 else 1.0
		# Reversing playback at the current phase keeps the feet continuous,
		# without a second slow-down on top of movement acceleration.
		stride_direction = playback_direction
		animation_clock += delta * pace * stride_direction
		var fps: float = sprite.sprite_frames.get_animation_speed(animation)
		sprite.frame = posmod(floori(animation_clock * fps), sprite.sprite_frames.get_frame_count(animation))
	else:
		sprite.frame = 0
	# No whole-body wobble during walking: the actual limb frames carry the step.
	var breath := sin(phase)
	var hover := sin(phase * 1.1) * 2.5 if kind == 2 else 0.0
	var idle := 1.0 - move_blend
	# Keep the hunter's pixel silhouette rigid; subpixel squash made outlines shimmer.
	if kind == 0:
		sprite.scale = Vector2.ONE * base_scale
		sprite.position = Vector2(0, foot_offset)
	else:
		sprite.scale = Vector2(1.0 + breath * 0.006 * idle, 1.0 - breath * 0.009 * idle) * base_scale
		sprite.position = Vector2(0, foot_offset + hover - breath * 0.3 * idle)
	sprite.modulate = Color(2.3, 1.6, 1.5) if flash > 0.0 else base_tint
	_update_weapon(delta)
	queue_redraw()

func _set_body_animation(animation: StringName) -> void:
	if sprite.animation == animation:
		return
	# Preserve the step phase when changing walking direction, avoiding a new
	# first-step pose every time diagonal movement crosses the dominant axis.
	var frames := sprite.sprite_frames
	var preserve_step := str(sprite.animation).begins_with("walk") and str(animation).begins_with("walk")
	var cycle := 0.0
	if preserve_step:
		cycle = fposmod(animation_clock * frames.get_animation_speed(sprite.animation) / frames.get_frame_count(sprite.animation), 1.0)
	sprite.animation = animation
	animation_clock = cycle * frames.get_frame_count(animation) / frames.get_animation_speed(animation) if preserve_step else 0.0
	var canvas := frames.get_frame_texture(animation, 0).get_size()
	base_scale = _height() / canvas.y

func _height() -> float:
	return visual_height if visual_height > 0.0 else Data.HEIGHTS[kind]

func _update_enemy_facing() -> void:
	var direction := motion
	if brain.get("windup", 0.0) > 0.0 and brain.has("target"):
		direction = Vector2(brain.target) - (position + Vector2(0, -15))
	if direction.length_squared() <= 16.0 or flip_hold > 0.0:
		return
	if absf(angle_difference(_facing_vector().angle(), direction.angle())) <= PI / 4.0 + deg_to_rad(8.0):
		return
	if absf(direction.y) > absf(direction.x):
		facing = &"up" if direction.y < 0.0 else &"down"
		sprite.flip_h = false
	else:
		facing = &"side"
		sprite.flip_h = direction.x < 0.0
	flip_hold = 0.18

func _update_hunter_facing(delta: float) -> void:
	var direction := Vector2.ZERO
	if aiming or aim_hold > 0.0 or finishing_aim:
		direction = aim
	elif moving and motion.length_squared() > 16.0:
		direction = motion
	if direction.length_squared() > 0.001:
		# Eight sectors, each 45 degrees wide. A small angular deadband keeps
		# joystick/target noise from switching poses at the sector boundaries.
		# Visit intermediate directional poses instead of jumping across the body.
		var turn := angle_difference(body_angle, direction.angle())
		var step := deg_to_rad(900.0) * delta
		body_angle += clampf(turn, -step, step)
		if absf(angle_difference(body_angle, direction.angle())) < 0.001:
			finishing_aim = false
		var angle := body_angle
		if absf(angle_difference(_facing_vector().angle(), angle)) > PI / 8.0 + deg_to_rad(5.0):
			var sector := posmod(roundi(angle / (PI / 4.0)), 8)
			var poses: Array[StringName] = [&"side", &"down_diagonal", &"down", &"down_diagonal", &"side", &"up_diagonal", &"up", &"up_diagonal"]
			facing = poses[sector]
			sprite.flip_h = sector in [3, 4, 5]

func _facing_vector() -> Vector2:
	if facing == &"up":
		return Vector2.UP
	if facing == &"down":
		return Vector2.DOWN
	if facing == &"up_diagonal":
		return Vector2(-1 if sprite.flip_h else 1, -1).normalized()
	if facing == &"down_diagonal":
		return Vector2(-1 if sprite.flip_h else 1, 1).normalized()
	return Vector2.LEFT if sprite.flip_h else Vector2.RIGHT

func _update_weapon(delta: float) -> void:
	if kind != 0 or weapon.is_empty() or not is_instance_valid(weapon_pivot):
		return
	if equipped != weapon:
		equipped = weapon
		held_weapon.texture = WeaponArt.weapon_texture(weapon)
		var mount: Dictionary = Mount.WEAPONS[weapon]
		held_weapon.offset = -mount.grip
		held_weapon.scale = Vector2.ONE * mount.scale
		held_weapon.rotation = mount.rotation
	var target_angle := aim.angle() if aiming or aim_hold > 0 or finishing_aim else _facing_vector().angle()
	visual_angle = lerp_angle(visual_angle, target_angle, 1.0 - exp(-delta * 20.0))
	# Recoil kicks around the wrist instead of detaching the handle from the hand.
	var reload_tilt := sin(reload_progress * PI) * 0.55 * (-1.0 if sprite.flip_h else 1.0) if reload_progress >= 0 else 0.0
	weapon_pivot.rotation = visual_angle + reload_tilt - recoil * 0.012 * (-1.0 if cos(visual_angle) < 0.0 else 1.0)
	weapon_pivot.position = Mount.hand_position(sprite)
	# Mirror the entire weapon around its grip, not the image inside its bounds.
	weapon_pivot.scale = Vector2(1, -1 if cos(visual_angle) < 0.0 else 1)
	var behind := facing in [&"up", &"up_diagonal"]
	weapon_pivot.z_index = -1 if behind else 1
	_update_gripping_hand(behind)
	weapon_pivot.queue_redraw()

func _update_gripping_hand(behind: bool) -> void:
	gripping_hand.visible = not behind
	if behind:
		return
	var key := "%s:%d" % [sprite.animation, sprite.frame]
	if not hand_textures.has(key):
		# Redraw the existing fist above the handle, with the exact same source pixels.
		var body_frame: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		var hand := AtlasTexture.new()
		hand.atlas = body_frame.atlas
		var half_size := Vector2.ONE * float(body_frame.get_meta("hand_radius", 17.0))
		var source_hand: Vector2 = Mount.source_hand(sprite)
		hand.region = Rect2(source_hand - half_size, half_size * 2)
		hand.filter_clip = true
		hand_textures[key] = hand
	gripping_hand.texture = hand_textures[key]
	gripping_hand.position = weapon_pivot.position
	gripping_hand.scale = sprite.scale
	gripping_hand.flip_h = sprite.flip_h
	gripping_hand.modulate = sprite.modulate

func muzzle_position() -> Vector2:
	return weapon_pivot.to_global(_local_muzzle())

func _local_muzzle() -> Vector2:
	var mount: Dictionary = Mount.WEAPONS[weapon]
	return held_weapon.transform * (mount.muzzle - mount.grip)

func _draw_muzzle() -> void:
	if muzzle_flash <= 0:
		return
	var color := Color("83c9b3") if weapon == "wand" else Color("ffdc91")
	var muzzle := _local_muzzle()
	weapon_pivot.draw_rect(Rect2(muzzle + Vector2(0, -2), Vector2(8, 4)), color)
	weapon_pivot.draw_rect(Rect2(muzzle + Vector2(2, -5), Vector2(4, 10)), color)
	weapon_pivot.draw_rect(Rect2(muzzle + Vector2(2, -1), Vector2(4, 2)), Color("fff4d1"))

func _draw() -> void:
	var shadow_width := radius * 1.1
	if kind == 2:
		shadow_width *= 0.9 + sin(phase * 1.1) * 0.08
	draw_ellipse(Vector2(0, 6), shadow_width, radius * 0.37, Color(0, 0, 0, 0.35))
	if kind == 0:
		draw_arc(Vector2(0, 5), 17, 0, TAU, 24, Color(0.48, 0.84, 0.76, 0.42), 1.0)
		if reload_progress >= 0:
			draw_rect(Rect2(-15, 27, 30, 5), Color("211b2b"))
			draw_rect(Rect2(-14, 28, floorf(28*reload_progress), 3), Color("83c9b3") if weapon == "wand" else Color("efb775"))
	if burn > 0:
		draw_circle(Vector2(-8, -8 + sin(phase * 3) * 3), 3, Color("ee9456"))
	if slow_time > 0:
		draw_arc(Vector2(0, 2), radius + 2, 0, TAU, 8, Color("8fd4ed"), 2.0)
	if poison_time > 0:
		draw_rect(Rect2(8, -12 + sin(phase * 4) * 2, 4, 5), Color("add77e"))
	if brain.get("windup", 0.0) > 0.0:
		var color := Color("ffca8a") if brain.get("boss", false) else Color("ef7d94")
		draw_arc(Vector2(0, -_height() * 0.45), radius + 6, 0, TAU, 12, color, 2.0)
	if brain.get("role", "") == "armored":
		draw_arc(Vector2(0, -15), 14, PI, TAU, 6, Color("a6bdd5"), 3.0)
	if brain.get("archetype", "") == "matriarch":
		var top := -_height() + 13
		draw_colored_polygon(PackedVector2Array([Vector2(-14,top), Vector2(-14,top-9), Vector2(-6,top-4), Vector2(0,top-14), Vector2(6,top-4), Vector2(14,top-9), Vector2(14,top)]), Color("efb775"))
	if kind > 0 and hp < max_hp and not brain.get("boss", false):
		draw_rect(Rect2(-18, -_height() * 0.9, 36, 3), Color("352d3c"))
		draw_rect(Rect2(-18, -_height() * 0.9, 36 * maxf(hp / max_hp, 0), 3), Color("c76a75"))
