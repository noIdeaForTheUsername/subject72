extends Node2D

@onready var light_pivot: Node2D = $LightPivot
@onready var light: PointLight2D = $LightPivot/PointLight2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var alarm_sound: AudioStreamPlayer2D = $AlarmSound


@export var rotation_speed: float = PI
@export var fade: float = PI / 3
@export var period_time: float = 0.5
@export var total_rotation: float = PI
@export var sprite_modulate_on: Color = Color(1.0, 0.0, 0.0, 1.0):
	set(value):
		sprite_modulate_on = value
		calculate_sprite_modulate_diff()

var sprite_modulate_off: Color:
	set(value):
		sprite_modulate_off = value
		calculate_sprite_modulate_diff()
var sprite_modulate_difference: Color
var default_rotation: float
var default_light_energy := 0.0

var rotation_phase: float = 0
var energy_coefficient: float = 0
var cycle_time: float = 0

var sound_played := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_rotation = light_pivot.rotation
	default_light_energy = light.energy
	sprite_modulate_off = sprite.modulate
	light.energy = 0
	light_pivot.rotation = 0
	cycle_time = randf_range(0.0, period_time)


func calculate_sprite_modulate_diff():
	sprite_modulate_difference = Color(sprite_modulate_on.r - sprite_modulate_off.r, sprite_modulate_on.g - sprite_modulate_off.g,
	sprite_modulate_on.b - sprite_modulate_off.b, sprite_modulate_on.a - sprite_modulate_off.a)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cycle_time += delta
	
	if cycle_time > period_time:
		if !sound_played:
			alarm_sound.play()
			sound_played = true
		rotation_phase += rotation_speed * delta
		if rotation_phase <= total_rotation / 2:
			energy_coefficient = clamp(rotation_phase / fade, 0.0, 1.0)
		else:
			energy_coefficient = clamp(1.0 - (rotation_phase - (total_rotation - fade)) / fade, 0.0, 1.0)

		if rotation_phase > total_rotation:
			cycle_time = 0
			sound_played = false
	else:
		rotation_phase = 0
		energy_coefficient = 0
	
	light.energy = energy_coefficient * default_light_energy
	sprite.modulate = Color(sprite_modulate_off.r + sprite_modulate_difference.r * energy_coefficient, sprite_modulate_off.g + sprite_modulate_difference.g * energy_coefficient,
	sprite_modulate_off.b + sprite_modulate_difference.b * energy_coefficient, sprite_modulate_off.a + sprite_modulate_difference.a * energy_coefficient)
	
	light_pivot.rotation = default_rotation + rotation_phase - PI / 2
