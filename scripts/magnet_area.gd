extends Area2D


func _ready() -> void:
	body_entered.connect(GameManager.game._on_magnet_area_body_entered)
