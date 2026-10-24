extends AnimatableBody2D


@export var block_collider: Node2D
@export var animation_player: AnimationPlayer
@export var sound: AudioStreamPlayer2D

var start_pos: Vector2

func _ready() -> void:
	self.start_pos = position


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Start ascending
	if body is not Player || position.y < start_pos.y: return
	GameManager.game.section_manager.load_next()
	await get_tree().process_frame
	if block_collider: block_collider.process_mode = Node.PROCESS_MODE_INHERIT
	if animation_player: animation_player.play("ascend")
	if sound: sound.play()
