extends Sprite2D


var player: CharacterBody2D
@export var pivot: Node2D
var shader_material: ShaderMaterial

func _ready():
	player = get_node("/root/Game/Player")
	shader_material = material
	shader_material.set_shader_parameter("sprite_size", self.get_rect().size * self.scale)

func _process(delta):
	if player && shader_material:
		shader_material.set_shader_parameter("relative_player_position", (player.global_position - pivot.global_position))
