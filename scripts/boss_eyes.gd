class_name BossEyes
extends Node2D

enum Direction {LEFT, CENTER, RIGHT}


const FLASH_REDUCTION := 7.0

var look_at_player: bool = false;
var look_forward: bool = true;

const MAX_OFFSET := Vector2(13, 8)
const DEAD_COLOR := Color(0.48, 0.48, 0.48, 0.647)
var dead_time: float = 0.0

var player: Node2D
var boss: Node2D


class Eye:
	var sprite: Sprite2D
	var brightness: float = 1.0
	var pupil: Pupil
	var flashless_modulate := Color.WHITE
	func _init(sprite: Sprite2D, pupil: Pupil) -> void:
		self.sprite = sprite
		self.pupil = pupil
	func update_brightness(flash_reduction: float, delta: float):
		if abs(brightness - 1.0) > 0.02:
			brightness -= (brightness - 1.0) * flash_reduction * delta
		else:
			brightness = 1
		sprite.modulate = flashless_modulate * brightness


class Pupil:
	var sprite: Sprite2D
	var default_pos: Vector2
	var offset := Vector2(0.0, 0.0)
	var lock_movement := false
	var death_target_offset: Vector2
	func _init(sprite: Sprite2D, max_offset: Vector2):
		self.sprite = sprite
		self.default_pos = sprite.position
		self.death_target_offset = Vector2(max_offset.x * randf_range(-1.0, 1.0), max_offset.y * randf_range(-1.0, 1.0))


var left_eye: Eye
var center_eye: Eye
var right_eye: Eye

var eyes: Array[Eye]


func _ready() -> void:
	left_eye = Eye.new(get_node("LeftEye"), Pupil.new(get_node("LeftEye/Pupil"), MAX_OFFSET))
	center_eye = Eye.new(get_node("CenterEye"), Pupil.new(get_node("CenterEye/Pupil"), MAX_OFFSET))
	right_eye = Eye.new(get_node("RightEye"), Pupil.new(get_node("RightEye/Pupil"), MAX_OFFSET))
	
	eyes = [left_eye, center_eye, right_eye]


func _process(delta: float) -> void:
	if !player || !boss:
		return
	
	for eye in eyes:
		if eye == null: continue
		
		var pupil := eye.pupil
		
		if boss.alive:
			eye.update_brightness(FLASH_REDUCTION, delta)
		else:
			dead_time += delta
			#eye.sprite.modulate = flashless_modulate
			#pupil.sprite.modulate = flashless_modulate.lerp(DEAD_COLOR, min(dead_time / 5.0, 1.0))
		
		var target_offset: Vector2
		if !boss.alive:
			target_offset = pupil.death_target_offset
		elif pupil.lock_movement:
			target_offset = Vector2.ZERO
		elif look_at_player:
			var diff_vector := (player.global_position - boss.global_position)
			target_offset = diff_vector.rotated(-boss.global_rotation).normalized() * MAX_OFFSET
		elif look_forward:
			target_offset = Vector2(MAX_OFFSET.x * 0.8, 0)
		else:
			target_offset = Vector2.ZERO

		pupil.offset += (target_offset - pupil.offset) * 2 * delta
		pupil.sprite.position = pupil.default_pos + pupil.offset.rotated(-PI / 2)


func set_eyes_color(new_color: Color, transition_time: float):
	var tween := get_tree().create_tween().set_parallel(true)
	for eye in self.eyes:
		tween.tween_property(eye, "flashless_modulate", new_color, transition_time)


func set_flash_effect(eye: String, value: float):
	if eye == "left":
		left_eye.brightness = value
	elif eye == "right":
		right_eye.brightness = value
	elif eye == "center":
		center_eye.brightness = value
