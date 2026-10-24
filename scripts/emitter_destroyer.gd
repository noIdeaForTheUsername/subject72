extends GPUParticles2D

@export var timer: Timer


func _ready() -> void:
	timer.start(lifetime)
	emitting = true

func _on_timer_timeout() -> void:
	queue_free()
