class_name ChargeControls
extends Control


@onready var charge_button: TextureButton = $ChargeButton
@onready var charge_bar: TextureProgressBar = $ChargeBar
@onready var charge_needle: TextureRect = $ChargeWheel/Needle
@onready var speed_decrease_timer: Timer = $SpeedDecreaseTimer
@onready var button_cooldown_timer: Timer = $ChargeButton/CooldownTimer
var charge_lights: Array[StatusLight] = []

@onready var charge_beep: AudioStreamPlayer = $ChargeBeep
@onready var button_sound: AudioStreamPlayer = $ButtonSound
@onready var error_sound: AudioStreamPlayer = $ChargeButton/ErrorSound

const MAX_NEEDLE_OFFSET_DEGREES := 33.0
const NEEDLE_SPEED := PI * 2/3
const MAX_CHARGING_SPEED := 5

var charging_speed: int = 0
var charge: float = 0.0

var charge_coeff: float = 1.0

var complete := false
signal charging_complete()
signal charge_changed(new_value: float)

func _ready() -> void:
	for light in $ChargeLights.get_children():
		if light is StatusLight: charge_lights.append(light)


func _process(delta: float) -> void:
	# Rotate the needle
	var rotation_change := NEEDLE_SPEED * (charging_speed + 1) * delta
	charge_needle.rotation = wrapf(charge_needle.rotation + rotation_change, -PI, PI)
	
	# CHANGE THE CHARGE
	var prev_charge_bar_value := charge_bar.value
	charge = clampf(charge + charging_speed * delta * charge_coeff, 0.0, 100.0)
	charge_bar.value = floor(charge / charge_bar.step) * charge_bar.step
	if charge_bar.value > prev_charge_bar_value:
		charge_beep.pitch_scale = remap(charge, 0, 100, 1, 1.5)
		charge_beep.play()
		charge_changed.emit(charge)
	if charge_bar.value >= 100.0 && !complete:  # WHEN CHARGING COMPLETE
		charging_complete.emit()
		complete = true


func _on_charge_button_pressed() -> void:
	button_sound.play()
	charge_button.disabled = true
	button_cooldown_timer.start()
	if absf(rad_to_deg(charge_needle.rotation)) < MAX_NEEDLE_OFFSET_DEGREES:
		if charging_speed == 0:
			charging_speed += 1
			speed_decrease_timer.start()
		elif charging_speed < MAX_CHARGING_SPEED:
			charging_speed += 1
		else:
			speed_decrease_timer.stop()
			speed_decrease_timer.start()
	else:
		charging_speed = maxi(charging_speed - 1, 0)
		if error_sound: error_sound.play()
		if charging_speed == 0: speed_decrease_timer.stop()
	update_lights()


func update_lights():
	for i in range(0, charging_speed):
		if i >= charge_lights.size(): return
		charge_lights[i].status = StatusLight.Status.ORANGE
	for i in range(charging_speed, charge_lights.size()):
		charge_lights[i].status = StatusLight.Status.OFF


func _on_speed_decrease_timer_timeout() -> void:
	charging_speed -= 1
	if charging_speed <= 0:
		charging_speed = 0
		speed_decrease_timer.stop()
	update_lights()


func _on_button_cooldown_timer_timeout() -> void:
	charge_button.disabled = false
