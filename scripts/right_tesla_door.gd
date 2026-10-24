extends Sprite2D


@export var door: Door
@export var player_block: CollisionObject2D
@export var granted_sound: AudioStreamPlayer2D
@export var first_keypad: Sprite2D
@export var second_keypad: Sprite2D
@export var left_tesla_door: Door


func _ready() -> void:
	first_keypad.visible = true
	second_keypad.visible = false

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body is not Player || GameManager.game.boss_won_chase || GameManager.game.player_won_chase: return
	
	GameManager.game.on_player_won_chase()
	granted_sound.play()
	first_keypad.visible = false
	second_keypad.visible = true
	door.close()
	if left_tesla_door: left_tesla_door.close()
	player_block.process_mode = Node.PROCESS_MODE_INHERIT
