class_name BoxDiode
extends Sprite2D

@export var min_time: float = 0.1
@export var max_time: float = 0.5
@export var randomized_start: bool = true
@export var saturation: float = 1.0
@export var value: float = 1.0
@export var alpha: float = 1.0

@onready var timer: Timer = $Timer


func _ready():
	if (randomized_start):
		timer.wait_time = randf_range(0.0, max_time)
	
	update_color()
	timer.start()


func update_color() -> void:
	modulate = Color.from_hsv(randf_range(0.0, 1.0), saturation, value, alpha)


func _on_timer_timeout() -> void:
	timer.wait_time = randf_range(min_time, max_time)
	update_color()
