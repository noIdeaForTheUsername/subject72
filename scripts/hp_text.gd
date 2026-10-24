class_name HPText
extends Label


@export var gradient_heal: Gradient
@export var gradient_damage: Gradient
@export var size_curve: Curve

const MAX_LIFETIME := 1.5
const MIN_SPEED := 200.0
const MAX_SPEED := 300.0
const MAX_DIRECTION_OFFSET := 0.0
const MAX_SCALE_OFFSET := 0.2

var lifetime := 0.0
var move_vector := Vector2.ZERO
var initial_scale := Vector2.ONE
var gradient: Gradient
var set_global_pos := Vector2.ZERO

enum Type {
	HEAL,
	DAMAGE,
	CUSTOM,
}


func setup(global_pos: Vector2, floating_dir: Vector2, type: Type = Type.CUSTOM, speed_overwrite: float = NAN, scale_overwrite: Vector2 = Vector2.INF):
	set_global_pos = global_pos
	var speed := randf_range(MIN_SPEED, MAX_SPEED)
	if !is_nan(speed_overwrite): speed = speed_overwrite
	scale += scale * randf_range(-MAX_SCALE_OFFSET, MAX_SCALE_OFFSET)
	if is_finite(scale_overwrite.x) && is_finite(scale_overwrite.y): scale = scale_overwrite
	
	self.move_vector = floating_dir.rotated(randf_range(-MAX_DIRECTION_OFFSET, MAX_DIRECTION_OFFSET))
	self.move_vector *= speed
	if type == Type.HEAL:
		text = "+HP"
		self.gradient = gradient_heal
	elif type == Type.DAMAGE:
		text = "-HP"
		self.gradient = gradient_damage


func _ready() -> void:
	initial_scale = scale
	global_position = set_global_pos
	if self.gradient == null:
		self.gradient = gradient_damage


func _process(delta: float) -> void:
	position += move_vector * delta
	lifetime += delta
	var t := lifetime / MAX_LIFETIME
	if t < 1.0:
		modulate = self.gradient.sample(t)
		scale = initial_scale * size_curve.sample(t)
	else:
		queue_free()
