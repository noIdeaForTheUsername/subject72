extends Area2D


signal player_at_control_panel_area()
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

@export var destroy_on_player_entered: Array[Node]

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_at_control_panel_area.emit()
		animation_player.play("RESET")
		for node in destroy_on_player_entered:
			if is_instance_valid(node): node.queue_free()
		queue_free()


func _ready() -> void:
	player_at_control_panel_area.connect((get_node("/root/Game") as Game)._on_player_at_control_panel_area)
