class_name BossFume
extends Projectile


signal fume_destroyed(shard: BossFume)


@onready var sprite: Sprite2D = $Sprite2D


var initial_speed := 0.0
var vertical_velocity := 0.0
var speed_coefficient: float
@export var VERTICAL_ACCELERATION := 50.0
@export var MOVEMENT_DRAG := 0.5
@export var MIN_SPEED := 3.0

#var max_energy_color := Color(1, 0.95, 0)
#var min_energy_color := Color(0.2, 0.75, 0)

@export var color_gradient: Gradient

var energy := 1.0

func _init() -> void:
	SCALE = 10.0
	SPEED = [16.0, 16.0]
	
	DAMAGE = 15
	
	Z_INDEX_OVERWRITE = 0

	SHOOT_PARTICLE_NUMBER = [0, 0]
	HIT_PARTICLE_NUMBER = [0, 0]
	
	speed_coefficient = pow(1.0 - MOVEMENT_DRAG, 1.0 / Engine.physics_ticks_per_second)


func custom_setup():
	destroyed = false
	visible = true
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)
	moves_done = 0
	initial_speed = speed
	vertical_velocity = 0.0
	sprite.modulate = color_gradient.sample(0.0)
	sprite.modulate.a = 1.0


func custom_process(delta: float) -> void:
	if initial_speed > 0.0:
		energy = (speed - MIN_SPEED) / (initial_speed - MIN_SPEED)
	sprite.modulate = color_gradient.sample(1 - energy)
	DAMAGE = 15 * clamp(energy, 0.35, 1.0)
	# sprite.modulate = min_energy_color.lerp(max_energy_color, energy)
	# sprite.modulate.a = clamp(energy, 0.15, 1.0)


func custom_physics_process(delta: float) -> void:
	if moves_done < 1:
		initial_speed = speed
	position += Vector2.UP * vertical_velocity * delta
	vertical_velocity += VERTICAL_ACCELERATION * delta
	speed *= speed_coefficient
	if speed < 3.0:
		destroy()


func destroy() -> void:
	self.destroyed = true
	self.visible = false
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	emit_signal("fume_destroyed", self)


func _on_body_entered(body: Node2D) -> void:
	if moves_done > 1:
		destroy()
