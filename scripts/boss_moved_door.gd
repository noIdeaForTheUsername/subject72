extends Node2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer
var rotated := false


func _on_boss_detector_body_entered(body: Node2D) -> void:
	if body is not Boss || rotated: return
	if animation_player: animation_player.play("rotate")
	rotated = true
