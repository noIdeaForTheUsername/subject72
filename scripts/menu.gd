class_name Menu
extends Control

@onready var audio_node: Node = $Audio
@export var background_texture: TextureRect

var bg_texture_default_pos: Vector2
const BACKGROUND_MOVEMENT_COEFF := 0.1

func _ready() -> void:
	AudioManager.set_global_sounds_node(audio_node)
	if background_texture: bg_texture_default_pos = background_texture.position
	await get_tree().process_frame
	AudioManager.play("Music", true)

func _process(delta: float) -> void:
	if background_texture:
		var mouse_pos := get_global_mouse_position()
		var viewport_size := Vector2(get_viewport_rect().size)
		mouse_pos.x = clampf(mouse_pos.x, 0, viewport_size.x)
		mouse_pos.y = clampf(mouse_pos.y, 0, viewport_size.y)
		var mouse_offset := mouse_pos - viewport_size / 2.0
		background_texture.position = bg_texture_default_pos - mouse_offset * BACKGROUND_MOVEMENT_COEFF
