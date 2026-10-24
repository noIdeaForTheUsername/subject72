extends StaticBody2D

var defeault_modulate: Color

var default_light_energy: float
var default_ext_light_energy: float

var energy: float = 1.0:
	set(value):
		energy = value
		update_energy(clamp(value, 0.0, 1.0))

@export var external_light: PointLight2D

@export var blinks_per_min := 0.0:
	set(value):
		blinks_per_min = value
		update_blinking(value)

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: PointLight2D = $PointLight2D
@onready var blink_timer: Timer = $BlinkTimer
@onready var blink_sound: AudioStreamPlayer2D = $BlinkSound

var min_sound_pitch := 0.8
var max_sound_pitch := 1.5

var time := 0.0
var next_blink := 1000000.0
var time_between_blinks := 10.0

func _ready():
	defeault_modulate = sprite.modulate
	default_light_energy = glow.energy
	if external_light:
		default_ext_light_energy = external_light.energy
	
	if blinks_per_min > 0:
		time_between_blinks = 60.0 / blinks_per_min
		next_blink = randf_range(time_between_blinks / 2, time_between_blinks * 1.5)


func _process(delta: float):
	if blinks_per_min > 0:
		time += delta
		
		if time > next_blink:
			time = 0.0
			next_blink = randf_range(time_between_blinks / 2, time_between_blinks * 1.5)
			blink()
			


func update_energy(value: float):
	sprite.modulate = defeault_modulate * clamp(value, 0.3, 1.0)
	sprite.modulate.a = defeault_modulate.a
	glow.energy = default_light_energy * value
	if external_light:
		external_light.energy = default_ext_light_energy * value


func update_blinking(value: float):
	if (value > 0):
		time_between_blinks = 60.0 / value
		next_blink = randf_range(time_between_blinks / 2, time_between_blinks * 1.5)


func blink():
	blink_sound.pitch_scale = randf_range(min_sound_pitch, max_sound_pitch)
	blink_sound.play(0.0)
	energy = 0.0
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	if energy == 0.0:
		energy = 1.0
	else:
		blink()
