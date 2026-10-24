extends Control

@export var speed_radians: float = PI / 2

func _process(delta: float) -> void:
	rotation += speed_radians * delta
