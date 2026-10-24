class_name Door
extends Node2D


@onready var body: AnimatableBody2D = $AnimatableBody2D
@onready var movement_sound: AudioStreamPlayer2D = $MovementSound

const OPEN_OFFSET := -191.0
@export var initially_open: bool = false
@export var opening_time: float = 1.5

var opening: bool = false


func _ready() -> void:
	cycle_instantly(initially_open)
	

func open() -> void:
	if opening: return
	opening = true
	movement_sound.play()
	var tween := get_tree().create_tween()
	tween.tween_property(body, "position", Vector2(0.0, OPEN_OFFSET),
	opening_time * absf(body.position.y - OPEN_OFFSET) / absf(OPEN_OFFSET)).set_trans(Tween.TRANS_SINE)

func close() -> void:
	if !opening: return
	opening = false
	movement_sound.play()
	var tween := get_tree().create_tween()
	tween.tween_property(body, "position", Vector2(0.0, 1.0),
	opening_time * absf(body.position.y) / absf(OPEN_OFFSET)).set_trans(Tween.TRANS_SINE)

func cycle_instantly(to_open_pos: bool) -> void:
	opening = to_open_pos
	if to_open_pos: body.position.y = OPEN_OFFSET
	else: body.position.y = 1.0
