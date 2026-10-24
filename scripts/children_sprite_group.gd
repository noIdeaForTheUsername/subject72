extends Node2D

@export var group_name: String
@export var type_name: String = ""


func _ready() -> void:
	var children := Utils.get_children_recursive(self, type_name)
	for child in children:
		child.add_to_group(group_name)
