class_name Camera
extends Camera2D

# INTERNAL
# @onready var ragdoll: Node2D = null
var shader_mat: ShaderMaterial
const MAX_VISIBLE_DISTANCE: Vector2 = Vector2i(600, 445)
var shake_intensity: float = 0.0
var shake_decrease := 0.0

# PUBLIC
static var instance: Camera2D = null
@export var follow_node: Node2D
var follow := true
var min_zoom: Vector2
signal zoom_changed(new_zoom: Vector2)

# INTERNAL

func _ready() -> void:
	if (instance != null && is_instance_valid(instance)):
		push_warning("Multiple Cameras detected")
	else:
		instance = self
		
	min_zoom = zoom
	var node = get_node_or_null("CameraEffects/ColorRect");
	if node && node.material is ShaderMaterial:
		shader_mat = node.material
		shader_mat.set_shader_parameter("intensity", 0.0)
	else:
		push_warning("No ColorRect for camera shaders found!")


func _process(delta):
	# Follow the follow node (usually player)
	if is_instance_valid(follow_node) && follow:
		var x := follow_node.global_position.x
		var y := follow_node.global_position.y
		if shake_intensity > 0:
			x += randf_range(-shake_intensity, shake_intensity)
			y += randf_range(-shake_intensity, shake_intensity)
			shake_intensity -= minf(shake_decrease * delta, shake_intensity)
		global_position = Vector2(x, y)
	handle_zoom()


func handle_zoom():
	var viewport_size := get_viewport_rect().size
	var calculated_zoom := viewport_size / (MAX_VISIBLE_DISTANCE * 2)
	var x_ratio := maxf(calculated_zoom.x / min_zoom.x, 1.0)
	var y_ratio := maxf(calculated_zoom.y / min_zoom.y, 1.0)
	
	var prev_zoom := zoom
	zoom = min_zoom * maxf(x_ratio, y_ratio)
	if zoom != prev_zoom: zoom_changed.emit(zoom)
	


# PUBLIC

func set_low_hp_effect(intensity: float):
	intensity = clampf(intensity, 0, 1)
	if shader_mat: shader_mat.set_shader_parameter("intensity", intensity)


func fly_to_pos(global_pos: Vector2, time: float = 1.0, fly_to_follow_node_after: float = -1.0) -> void:
	follow = false
	var prev_pos := global_position
	var tween := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", global_pos, time)
	if (fly_to_follow_node_after >= 0):
		await Utils.pausable_timer(time + fly_to_follow_node_after).timeout
		fly_to_follow_node(time)


func fly_to_follow_node(time: float) -> void:
	if !is_instance_valid(follow_node): return
	var tween := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", follow_node.global_position, time)
	await Utils.pausable_timer(time).timeout
	follow = true

func shake_effect(intensity: float, time: float = 1.0):
	shake_intensity = intensity
	shake_decrease = intensity / time
