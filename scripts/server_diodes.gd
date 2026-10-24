extends Node2D


class Diode:
	static var color_on := Color(0, 1.0, 0, 1.0)
	static var color_off := Color(0.1, 0.1, 0.1, 1.0)
	var blink_time: float
	var period_time: float
	var cycle_time: float
	var sprite: Sprite2D
	var blinking := true
	func _init(sprite: Sprite2D) -> void:
		if randf() < 0.5:
			blinking = false
			sprite.modulate = color_on
		else:
			blinking = true
			self.sprite = sprite
			blink_time = randf_range(0.5, 2.0)
			period_time = randf_range(0.1, 0.5)
			cycle_time = blink_time + period_time
	func update(time: float) -> void:
		if fmod(time, cycle_time) <= blink_time:  # if active, set color to green
			sprite.modulate = color_on
		else:
			sprite.modulate = color_off


var blinking_diodes: Array[Diode] = []
var time: float

func _ready() -> void:
	for child in get_children() as Array[Sprite2D]:
		var diode := Diode.new(child)
		if diode.blinking: blinking_diodes.append(diode)

func _process(delta: float) -> void:
	time += delta
	for diode in blinking_diodes:
		diode.update(time)
