class_name PlayerProjectile
extends Projectile


func _init() -> void:
	SCALE = 1.6
	SPEED = [16.0, 16.0]
	
	DAMAGE = 3.0
	
	# Particle settings

	SHOOT_PARTICLE_NUMBER = [3, 4]
	SHOOT_PARTICLE_SIZE = [1.5, 3.0]
	SHOOT_PARTICLE_SPEED = 520.0
	SHOOT_PARTICLE_DESPAWN_TIME = 0.2
	SHOOT_PARTICLE_FADE_AWAY_TIME = 0.0
	SHOOT_PARTICLE_GRAVITY_SCALE = 0.0

	HIT_PARTICLE_NUMBER = [2, 5]
	HIT_PARTICLE_SIZE = [1.5, 5.0]
	HIT_PARTICLE_SPEED = 330.0
	HIT_PARTICLE_DESPAWN_TIME = 0.4
	HIT_PARTICLE_FADE_AWAY_TIME = 0.2
	HIT_PARTICLE_GRAVITY_SCALE = 0.5

	PARTICLE_COLOR = {
		"min_hue": 320.0/360.0,
		"max_hue": 345.0/360.0,
		"min_sat": 0.4,
		"max_sat": 1.0,
		"min_val": 0.9,
		"max_val": 1.0,
	}
	
	PARTICLE_MATERIAL_OVERRIDE = CanvasItemMaterial.new()
	PARTICLE_MATERIAL_OVERRIDE.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func _on_body_entered(body: Node2D) -> void:
	if body is SpikeOrb: body.damage()
	destroy()
