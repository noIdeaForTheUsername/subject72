extends Node


func pausable_timer(seconds) -> SceneTreeTimer:
	return get_tree().create_timer(seconds, false)


# Set target_modulate to null to set it to the modulate value of the object in the moment of the function call
func fade_in_object(object: CanvasItem, time: float, target_modulate: Color = Color.WHITE):
	if target_modulate == null: target_modulate = object.modulate
	object.modulate.a = 0.0
	object.visible = true
	var tween := get_tree().create_tween()
	object.tree_exited.connect(Callable(tween, "kill"), CONNECT_ONE_SHOT)
	tween.tween_property(object, "modulate", target_modulate, time)
	await tween.finished


func fade_out_object(object: CanvasItem, time: float):
	var tween := get_tree().create_tween()
	object.tree_exited.connect(Callable(tween, "kill"), CONNECT_ONE_SHOT)
	tween.tween_property(object, "modulate", Color.TRANSPARENT, time)
	await tween.finished
	object.visible = false


func get_children_recursive(node: Node, type_filter: String = "") -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		if type_filter == "" || child.get_class() == type_filter:
			result.append(child)
		result.append_array(get_children_recursive(child, type_filter))
	return result
