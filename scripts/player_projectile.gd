extends Area2D

const Art = preload("res://scripts/pixel_icon.gd")
@export_enum("return", "grenade") var projectile_kind := "return"
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var blast_shape: CollisionShape2D = $Blast/CollisionShape2D
var sweep := CapsuleShape2D.new()

func _ready() -> void:
	sprite.texture = Art.weapon_texture("return_blade" if projectile_kind == "return" else "grenade_projectile")
	sprite.scale = Vector2.ONE * (0.75 if projectile_kind == "return" else 1.0)

func intersects_enemy(enemy: CharacterBody2D, from: Vector2, to: Vector2) -> bool:
	if body_shape.disabled or enemy.hurt_shape.disabled or not enemy.hurtbox.monitorable or enemy.hurtbox.collision_layer == 0:
		return false
	sweep.radius = body_shape.shape.radius
	sweep.height = from.distance_to(to) + sweep.radius * 2.0
	var transform := Transform2D((to - from).angle() + PI * 0.5, (from + to) * 0.5)
	return sweep.collide(transform, enemy.hurt_shape.shape, enemy.hurt_shape.global_transform)

func blast_hits(enemy: CharacterBody2D, at: Vector2, radius: float) -> bool:
	if blast_shape.disabled or enemy.hurt_shape.disabled or not enemy.hurtbox.monitorable or enemy.hurtbox.collision_layer == 0:
		return false
	blast_shape.shape.radius = radius
	blast_shape.shape.height = radius * 2.0
	return blast_shape.shape.collide(Transform2D(0, at), enemy.hurt_shape.shape, enemy.hurt_shape.global_transform)

func update_visual(bullet: Dictionary, fraction: float) -> void:
	var point: Vector2 = Vector2(bullet.get("previous", bullet.position)).lerp(bullet.position, fraction)
	sprite.position = point - position
	sprite.rotation = bullet.age * 14.0 if projectile_kind == "return" else bullet.age * 7.0
