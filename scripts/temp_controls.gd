class_name TempControls
extends Control

@onready var status_light: StatusLight = $StatusLight
@onready var heat_button: TextureButton = $HeatButton
@onready var cool_button: TextureButton = $CoolButton
@onready var needle: TextureRect = $TempIndicator/Needle
@onready var button_sound: AudioStreamPlayer = $ButtonSound

const MIN_TEMP := 500.0
const MAX_TEMP := 1500.0
const YELLOW_RANGE_OFFSET := 250.0  # It assumes that the perfect point is in the middle and the yellow zone is in both directions
const RED_RANGE_OFFSET := 400.0  # as above
const MIN_NEEDLE_X := 2.0
const MAX_NEEDLE_X := 60.0
const MIN_COOLING_FLOW := -0.1  # -0.1 means it's actually heating
# - (yes, it's an ungly hack to just let the player restore temp quicker without messing with the code further)
const MAX_COOLING_FLOW := 0.5
const COOLING_FLOW_STEP := 0.05
const MIN_HEATING_RATE := 20.0
const MAX_HEATING_RATE := 400.0

@export var temperature: float = 500.0
@export var cooling_flow: float = 0.05
var heating_rate: float = 20.0

var heating_rate_percentage: float:
	set (value):
		value = clampf(value, 0.0, 100.0)
		heating_rate = lerpf(MIN_HEATING_RATE, MAX_HEATING_RATE, value / 100.0)
	get:
		return inverse_lerp(MIN_HEATING_RATE, MAX_HEATING_RATE, heating_rate) * 100.0

var status: StatusLight.Status = StatusLight.Status.GREEN:
	set (value):
		status = value
		status_light.status = value

func _ready() -> void:
	heat_button.disabled = cooling_flow == MIN_COOLING_FLOW
	cool_button.disabled = cooling_flow == MAX_COOLING_FLOW
	needle.position.x = lerpf(MIN_NEEDLE_X, MAX_NEEDLE_X,
	clampf((temperature - MIN_TEMP) / (MAX_TEMP - MIN_TEMP), 0.0, 1.0))

func _process(delta: float) -> void:
	# change temp
	var cooling_rate := cooling_flow * temperature
	temperature = clampf(temperature + (heating_rate - cooling_rate) * delta, MIN_TEMP, MAX_TEMP)
	
	# update needle pos
	needle.position.x = lerpf(MIN_NEEDLE_X, MAX_NEEDLE_X,
	clampf((temperature - MIN_TEMP) / (MAX_TEMP - MIN_TEMP), 0.0, 1.0))
	
	# Change the status
	var offset := absf((MIN_TEMP + MAX_TEMP) / 2 - temperature)
	if offset >= RED_RANGE_OFFSET:
		status = StatusLight.Status.RED
	elif offset >= YELLOW_RANGE_OFFSET:
		status = StatusLight.Status.YELLOW
	else:
		status = StatusLight.Status.GREEN


func _on_cool_button_pressed() -> void:
	button_sound.play()
	cooling_flow = clampf(cooling_flow + COOLING_FLOW_STEP, MIN_COOLING_FLOW, MAX_COOLING_FLOW)
	heat_button.disabled = cooling_flow == MIN_COOLING_FLOW
	cool_button.disabled = cooling_flow == MAX_COOLING_FLOW

func _on_heat_button_pressed() -> void:
	button_sound.play()
	cooling_flow = clampf(cooling_flow - COOLING_FLOW_STEP, MIN_COOLING_FLOW, MAX_COOLING_FLOW)
	heat_button.disabled = cooling_flow == MIN_COOLING_FLOW
	cool_button.disabled = cooling_flow == MAX_COOLING_FLOW
