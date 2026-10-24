class_name BossProjectile1
extends Projectile

func _init() -> void:
	SCALE = 2.0
	SPEED = [7.0, 7.0]
	
	DAMAGE = 20.0
	
	Z_INDEX_OVERWRITE = 300

	SHOOT_PARTICLE_NUMBER = [0, 0]

	HIT_PARTICLE_NUMBER = [2, 5]
	HIT_PARTICLE_SIZE = [1.5, 5.0]
	HIT_PARTICLE_SPEED = 330.0
	HIT_PARTICLE_DESPAWN_TIME = 1.0
	HIT_PARTICLE_FADE_AWAY_TIME = 0.5
	HIT_PARTICLE_GRAVITY_SCALE = 0.5
	

	PARTICLE_COLOR = {
		"min_hue": 85.0/360.0,
		"max_hue": 120.0/360.0,
		"min_sat": 0.5,
		"max_sat": 1.0,
		"min_val": 1.0,
		"max_val": 1.0,
	}


func _on_body_entered(body: Node2D) -> void:
	destroy()
