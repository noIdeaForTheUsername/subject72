extends Node2D

@export var ROTATION_SPEED: float = 180.0:
	set(value):
		ROTATION_SPEED = value
		radians = value / 180.0 * PI

@onready var blades_sprite: Sprite2D = $Blades

var radians: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blades_sprite.rotate(randi_range(0, 360))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	blades_sprite.rotate(radians * delta)
