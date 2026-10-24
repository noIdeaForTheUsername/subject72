class_name BossProjectile3
extends Projectile

var body: CharacterBody2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var bounce_sound: AudioStreamPlayer2D = $BounceSound

var bounces := 2
const ANIMATION_TIME := 0.35
var anim_time_left := ANIMATION_TIME


func _init() -> void:
	SCALE = 1.0
	SPEED = [5.5, 5.5]
	
	Z_INDEX_OVERWRITE = 300
	
	DAMAGE = 20.0

	SHOOT_PARTICLE_NUMBER = [0, 0]

	HIT_PARTICLE_NUMBER = [5, 9]
	HIT_PARTICLE_SIZE = [4.0, 8.0]
	HIT_PARTICLE_SPEED = 330.0
	HIT_PARTICLE_DESPAWN_TIME = 1.0
	HIT_PARTICLE_FADE_AWAY_TIME = 0.5
	HIT_PARTICLE_GRAVITY_SCALE = 0.5
	

	PARTICLE_COLOR = {
		"min_hue": 0.0,
		"max_hue": 0.0,
		"min_sat": 0.3,
		"max_sat": 1.0,
		"min_val": 1.0,
		"max_val": 1.0,
	}
	
	


func custom_setup():
	body = CharacterBody2D.new()
	body.scale = scale
	body.collision_mask = self.collision_mask
	body.collision_layer = 0
	body.add_child(collision_shape.duplicate())
	get_parent().add_child(body)
	body.global_position = self.global_position


func _process(delta: float) -> void:
	anim_time_left -= delta
	if anim_time_left < 0:
		anim_time_left = ANIMATION_TIME
		sprite.flip_h = !sprite.flip_h


func _physics_process(delta: float) -> void:
	if !destroyed:
		body.global_scale = global_scale
		var collision := body.move_and_collide(move_vector * speed)
		if collision:
			if bounces > 0:
				move_vector = move_vector.bounce(collision.get_normal())
				bounce_sound.play()
				bounces -= 1
			else:
				destroy()
		global_position = body.global_position
		custom_physics_process(delta)
		visible = true
		moves_done += 1


func _on_body_entered(body: Node2D) -> void:
	destroy()


func destroy() -> void:
	body.queue_free()
	super.destroy()
