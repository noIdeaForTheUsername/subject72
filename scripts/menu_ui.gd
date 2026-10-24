extends Control

@export var info_window: MenuWindow
@export var settings_window: MenuWindow
@export var credits_window: MenuWindow
@export var loading_window: Control


func _ready() -> void:
	loading_window.visible = false
	for window in [info_window, settings_window, credits_window] as Array[MenuWindow]:
		window.visible = false
		window.closed.connect(show_buttons)
	if (GameManager.display_menu_instructions):  # go to instructions on first start
		info_window.toggle(true)
		toggle_buttons(false)


func _on_play_button_pressed() -> void:
	AudioManager.play("MenuButton")
	loading_window.visible = true
	GameManager.start_game()


func _on_info_button_pressed() -> void:
	AudioManager.play("MenuButton")
	info_window.toggle(true)
	toggle_buttons(false)


func _on_credits_button_pressed() -> void:
	AudioManager.play("MenuButton")
	credits_window.toggle(true)
	toggle_buttons(false)


func _on_settings_button_pressed() -> void:
	AudioManager.play("MenuButton")
	settings_window.toggle(true)
	toggle_buttons(false)


func toggle_buttons(visible: bool) -> void:
	for node in get_children():
		if node is BaseButton:
			node.visible = visible
			node.process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED


func show_buttons() -> void:
	toggle_buttons(true)


func _on_exit_button_pressed() -> void:
	AudioManager.play("MenuButton")
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit.call_deferred()
