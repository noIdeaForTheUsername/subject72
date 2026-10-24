extends TextureButton

# mouse_entered/exited functions are also connected to focus entered/exited

func _on_mouse_entered() -> void:
	modulate = Color(0.6, 0.6, 0.6)
	AudioManager.play("ButtonHover")


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
