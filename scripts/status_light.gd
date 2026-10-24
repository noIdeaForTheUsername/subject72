class_name StatusLight
extends TextureRect

enum Status {
	GREEN,
	ORANGE,
	OFF,
	# BLINKING:
	YELLOW,
	RED,
}

const textures = {
	Status.GREEN: preload("res://graphics/control_panel/light_green.png"),
	Status.ORANGE: preload("res://graphics/control_panel/light_orange.png"),
	Status.YELLOW: preload("res://graphics/control_panel/light_yellow.png"),
	Status.RED: preload("res://graphics/control_panel/light_red.png"),
	Status.OFF: preload("res://graphics/control_panel/light_black.png"),
}

@onready var timer: Timer = $Timer

@export var alarm: AudioStreamPlayer = null
@export var status: Status = Status.GREEN:
	set (value):
		if value == status: return
		status = value
		on_status_changed.call_deferred(value)


func on_status_changed(status: Status):
	texture = textures[status]
	if status == Status.YELLOW:
		if alarm: alarm.play()
		timer.wait_time = 0.4
		timer.start()
	elif status == Status.RED:
		if alarm: alarm.play()
		timer.wait_time = 0.2
		timer.start()
	elif timer && !timer.is_stopped():
		timer.stop()


func _on_timer_timeout() -> void:
	if status != Status.RED && status != Status.YELLOW:
		timer.stop()
		return
	elif texture == textures[status]:
		texture = textures[Status.OFF]
	else:
		texture = textures[status]
		if alarm: alarm.play()
	timer.start()
