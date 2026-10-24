class_name TeslaControlPanel
extends Control

@onready var charge_controls: ChargeControls = $Panel/ChargeControls
@onready var temp_controls: TempControls = $Panel/TempControls
@onready var codepad: Codepad = $Panel/Codepad
@onready var big_red_button: TextureButton = $Panel/BigRedButton
@onready var big_red_button_sound: AudioStreamPlayer = $Panel/BigRedButton/PressSound


@onready var guide_overlay_1: Control = $Panel/Guides/GuideOverlay1
@onready var guide_overlay_2: Control = $Panel/Guides/GuideOverlay2
@onready var guide_confirm_cooldown: Timer = $Panel/Guides/GuideConfirmCooldown
@onready var guide_switch_sound: AudioStreamPlayer = $Panel/Guides/GuideSwitchSound
@onready var guide_background: ColorRect = $GuideBackground

@export var show_on_charging_complete: Array[CanvasItem]

var default_bar_fill := load("res://graphics/control_panel/charge_bar_fill.png")
var red_bar_fill := load("res://graphics/control_panel/charge_bar_red_fill.png")
var green_bar_fill := load("res://graphics/control_panel/charge_bar_green_fill.png")


var charged := false
var completed := false

signal tesla_activated()

func _ready() -> void:
	var game := get_node_or_null("/root/Game")
	if game:
		tesla_activated.connect(game._on_tesla_activated)
		game.player_at_control_panel.connect(_on_player_at_control_panel)
		game.tesla_minigame_failed.connect(_on_tesla_minigame_failed)
	else:
		push_warning("No Game node as scene main Node!")
	toggle_ui_section(self, false)
	toggle_ui_section(guide_overlay_1, false)
	toggle_ui_section(guide_overlay_2, false)
	guide_background.visible = false


func _on_player_at_control_panel() -> void:
	toggle_ui_section(self, true)
	charge_controls.process_mode = Node.PROCESS_MODE_DISABLED
	temp_controls.process_mode = Node.PROCESS_MODE_DISABLED
	big_red_button.disabled = true
	

func _process(delta: float) -> void:
	if charged || completed: return
	update_params()


func update_params():
	# Decrease charge speed if the generator isn't set up correctly
	if temp_controls.status == StatusLight.Status.RED:
		charge_controls.charge_coeff = 0.0
		charge_controls.charge_bar.texture_progress = red_bar_fill
	elif temp_controls.status == StatusLight.Status.YELLOW:
		charge_controls.charge_coeff = 0.8
		charge_controls.charge_bar.texture_progress = default_bar_fill
	else:
		charge_controls.charge_coeff = 1.0
		charge_controls.charge_bar.texture_progress = default_bar_fill
	
	# Set gen heating rate depending on the current charge
	temp_controls.heating_rate_percentage = charge_controls.charge
	
	# Change working sound pitch
	AudioManager.get_player("TeslaWorking1").pitch_scale = lerpf(0.7, 3.0, charge_controls.charge / 100.0)
	AudioManager.get_player("TeslaWorking2").volume_db = clampf(remap(charge_controls.charge, 70.0, 90.0, -10.0, 11.0), -10.0, 11.0)
	AudioManager.get_player("TeslaWorking2").pitch_scale = clampf(remap(charge_controls.charge, 70.0, 100.0, 1.0, 6.0), 0.5, 6.0)


func _on_charging_complete() -> void:
	update_params()
	charged = true
	big_red_button.disabled = false
	charge_controls.charge_bar.texture_progress = green_bar_fill
	var tween := get_tree().create_tween().set_parallel(true)
	for node in show_on_charging_complete:
		node.visible = true
		var node_modulate := node.modulate
		node.modulate.a = 0.0
		tween.tween_property(node, "modulate", node_modulate, 0.5)


func _on_code_accepted() -> void:
	charge_controls.process_mode = Node.PROCESS_MODE_INHERIT
	charge_controls.charge_changed.emit(0.0)
	temp_controls.process_mode = Node.PROCESS_MODE_INHERIT
	AudioManager.get_player("TeslaWorking1").play()
	AudioManager.get_player("TeslaWorking2").play()
	toggle_ui_section(guide_overlay_1, true)
	guide_switch_sound.play()
	GameManager.game.pause_ui.lock_pause = true
	guide_background.visible = true
	get_tree().paused = true


func _on_big_red_button_pressed() -> void:
	if !charged || completed: return
	completed = true
	tesla_activated.emit()
	big_red_button_sound.play()
	visible = false
	charge_controls.process_mode = Node.PROCESS_MODE_DISABLED
	codepad.process_mode = Node.PROCESS_MODE_DISABLED
	temp_controls.process_mode = Node.PROCESS_MODE_DISABLED
	big_red_button.disabled = true

func _on_tesla_minigame_failed() -> void:
	toggle_ui_section(self, false)

# Next guide overlay
func _on_guide_button_pressed() -> void:
	if !guide_confirm_cooldown.is_stopped() || !guide_background.visible: return
	guide_confirm_cooldown.start()
	if guide_overlay_1.visible:
		toggle_ui_section(guide_overlay_1, false)
		toggle_ui_section(guide_overlay_2, true)
		guide_switch_sound.play()
	elif guide_overlay_2.visible:
		GameManager.game.pause_ui.lock_pause = false
		toggle_ui_section(guide_overlay_2, false)
		guide_switch_sound.play()
		get_tree().paused = false
		guide_background.visible = false
		codepad.toggle_buttons(false)

# Util function
func toggle_ui_section(section: Control, on: bool):
	if on:
		section.visible = true
		section.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		section.visible = false
		section.process_mode = Node.PROCESS_MODE_DISABLED
