class_name Bolt
extends Sprite2D

@export var spawn_position: Vector2
@export_range(-180.0, 180.0) var spawn_rotation_deg: float = 5.0
@export var max_offset: Vector2 = Vector2(32.0, 16.0)

var default_modulate: Color
var lights: Array[PointLight2D] = []

func _ready() -> void:
	for node in get_children():
		if node is PointLight2D: lights.append(node)
	default_modulate = modulate

func spawn(disappear_time: float = 0.8) -> void:
	self.position = spawn_position + Vector2(
		max_offset.x * randf_range(-1.0, 1.0), max_offset.y * randf_range(-1.0, 1.0))
	
	if randi() % 2 == 0: scale.y = 1
	else: scale.y = -1
	
	self.visible = true
	modulate = default_modulate
	var target_modulate = default_modulate
	target_modulate.a = 0.0
	var tween := get_tree().create_tween().set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", target_modulate, disappear_time)

func _process(delta: float) -> void:
	if !visible: return
	for light in lights:
		light.color.a = modulate.a
