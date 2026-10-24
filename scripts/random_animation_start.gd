extends AnimatedSprite2D


@export var animation_name := "default"
@export var max_time: float = 1.0
@onready var timer: Timer = $AnimationStart


func _ready() -> void:
	timer.wait_time =randf_range(0.0, max_time)
	timer.start()


func _on_animation_start_timeout() -> void:
	play(animation_name)
