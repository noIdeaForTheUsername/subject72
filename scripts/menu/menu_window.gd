class_name MenuWindow
extends TextureRect

@onready var back_button: TextureButton = $BackButton


signal closed()


func _ready() -> void:
	if back_button: back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	AudioManager.play("MenuButton")
	toggle(false)


func toggle(show: bool) -> void:
	if show:
		visible = true
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		closed.emit()

func open() -> void:
	toggle(true)

func close() -> void:
	toggle(false)
