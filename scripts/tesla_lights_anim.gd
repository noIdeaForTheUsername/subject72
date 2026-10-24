extends AnimationPlayer


func _on_tesla_charge_changed(value: float) -> void:
	if current_animation != "charging": play("charging")
	speed_scale = remap(value, 0, 100, 1, 10)

func _on_tesla_activated() -> void:
	speed_scale = 1
	play("running")
	seek(0.5, true)
