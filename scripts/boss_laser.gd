class_name BossLaser
extends Area2D

@onready var line: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var raycast: RayCast2D = $RayCast2D
@onready var active_sound: AudioStreamPlayer2D = $ActiveSound
@onready var shutdown_timer: Timer = $Shutdown
@onready var particle_emitter: CPUParticles2D = $CPUParticles2D

const MAX_LENGTH := 5000.0
var length: float = 32.0

var shutting_down := false


func _ready() -> void:
	pass


func setup(pos: Vector2, start_rotation: float):
	position = pos
	rotation = start_rotation


func set_active(value: bool) -> void:
	if value:
		monitorable = true
	else:
		monitorable = false


func _process(delta: float) -> void:
	line.points[1].x = length
	particle_emitter.position.x = length - 2.0
	if !shutdown_timer.is_stopped():
		line.modulate.a = 0.1 + 0.9 * (shutdown_timer.time_left / shutdown_timer.wait_time)
		active_sound.volume_db = -30 + (shutdown_timer.time_left / shutdown_timer.wait_time) * 30



func _physics_process(delta: float) -> void:
	if raycast.is_colliding():
		var collision_point := raycast.get_collision_point()
		length = raycast.to_local(collision_point).length()
	else:
		length = MAX_LENGTH
	
	(collision_shape.shape as RectangleShape2D).size.x = length + 5
	collision_shape.position.x = length / 2


func shutdown(time: float):
	if !shutting_down:
		shutdown_timer.wait_time = time
		shutdown_timer.start()
		shutting_down = true


func _on_shutdown_timeout() -> void:
	queue_free()
