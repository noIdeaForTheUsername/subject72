class_name PauseUI
extends CanvasLayer

@onready var pause_ui: Control = $Control
@export var settings_window: MenuWindow
@export var loading_window: Control

var tree: SceneTree
var paused := false:
	set (value):
		paused = value
		tree.paused = value
		pause_ui.visible = paused
		await tree.process_frame
		for node in Utils.get_children_recursive(tree.current_scene, "GPUParticles2D"):
			node.visible = !tree.paused

var lock_pause := false

func _ready() -> void:
	tree = get_tree()
	loading_window.visible = false
	pause_ui.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") && !lock_pause:
		paused = !paused


func _on_continue_button_pressed() -> void:
	AudioManager.play("MenuButton")
	paused = false


func _on_settings_button_pressed() -> void:
	AudioManager.play("MenuButton")
	if settings_window: settings_window.open()


func _on_settings_window_closed() -> void:
	AudioManager.play("MenuButton")


func _on_menu_button_pressed() -> void:
	AudioManager.play("MenuButton")
	loading_window.visible = true
	GameManager.enter_menu()
