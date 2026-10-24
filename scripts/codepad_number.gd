class_name CodepadNumber
extends TextureButton


@onready var label: Label = get_node_or_null("Label")
@export var number: int = -1  # -1 is the erase button ("backspace")
@export var press_sound: AudioStreamPlayer

signal activated(number: int)

func _ready() -> void:
	if number >= 0 && label: label.text = str(number)

func _on_pressed() -> void:
	if press_sound: press_sound.play()
	activated.emit(number)
	
