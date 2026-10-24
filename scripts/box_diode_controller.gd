extends Node2D

@export var max_time_offset := 0.5
@export var diodes: Array[BoxDiode]

func _ready() -> void:
	var value := randf_range(0.0, max_time_offset)
	for diode in diodes:
		diode.timer.stop()
		diode.timer.start(value)
