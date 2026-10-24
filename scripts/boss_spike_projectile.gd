class_name BossSpikeProjectile
extends Projectile


func _init() -> void:
	SCALE = 1.0
	SPEED = [30.0, 30.0]
	
	DAMAGE = 20.0
	
	Z_INDEX_OVERWRITE = 125

	SHOOT_PARTICLE_NUMBER = [0, 0]

	HIT_PARTICLE_NUMBER = [0, 0]


func set_sprite(sprite_instance: Sprite2D):
	self.add_child(sprite_instance)


func set_collision_polygon(poly_instance: CollisionPolygon2D) -> void:
	self.add_child(poly_instance)
	
