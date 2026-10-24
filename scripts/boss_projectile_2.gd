class_name BossProjectile2
extends Projectile


func _init() -> void:
	SCALE = 2.5
	SPEED = [5.7, 5.7]
	
	DAMAGE = 20.0
	
	Z_INDEX_OVERWRITE = 125

	SHOOT_PARTICLE_NUMBER = [0, 0]
	
	HIT_PARTICLE_NUMBER = [4, 10]
	HIT_PARTICLE_SIZE = [3.0, 7.0]
	HIT_PARTICLE_SPEED = 250.0
	HIT_PARTICLE_DESPAWN_TIME = 1.0
	HIT_PARTICLE_FADE_AWAY_TIME = 0.5
	HIT_PARTICLE_GRAVITY_SCALE = 0.65

	PARTICLE_COLOR = {
		"min_hue": 74.0/360.0,
		"max_hue": 110.0/360.0,
		"min_sat": 0.4,
		"max_sat": 1.0,
		"min_val": 0.9,
		"max_val": 1.0,
	}


func _on_body_entered(body: Node2D) -> void:
	if moves_done > 1:
		destroy()
