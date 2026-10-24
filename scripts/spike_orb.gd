class_name SpikeOrb
extends CharacterBody2D

@onready var rotating_nodes: Array[Node2D] = [$Sprite2D, $Spikes]
@onready var particle_scene := preload("res://scenes/colliding_particle.tscn")
@onready var animation_player: AnimationPlayer = $AnimationPlayer


@export var particle_color: Gradient

const EJECTION_SPEED: float = 400.0
const MAX_SPEED: float = 180.0
const ROTATION_SPEED: float = 3
const VECTOR_ROTATION_SPEED: float = 2

var destroyed := false

var start_speed_coefficient: float = -1.0  # If negative, the ejection animation is in progress
var move_vector := Vector2.RIGHT

var dummy_player = Node2D.new()
var player: Node2D:
	get:
		if player && player.is_inside_tree(): return player
		else: return dummy_player


var health := 3



func setup(global_pos: Vector2, player: Node2D, start_move_vector: Vector2 = Vector2.RIGHT) -> void:
	global_position = global_pos
	self.player = player
	move_vector = start_move_vector


func _process(delta: float) -> void:
	start_speed_coefficient = minf(start_speed_coefficient + delta, 1.0)


func _physics_process(delta: float) -> void:
	if destroyed: return
	
	if start_speed_coefficient <= 0.0:
		velocity = move_vector * EJECTION_SPEED * absf(start_speed_coefficient)
	else:
		var vec_to_player = player.global_position - global_position
		var angle_diff := move_vector.angle_to(vec_to_player)
		
		var vector_rotation := angle_diff
		var max_vector_rotation := VECTOR_ROTATION_SPEED * delta
		if vector_rotation > max_vector_rotation:
			vector_rotation = max_vector_rotation
		elif vector_rotation < -max_vector_rotation:
			vector_rotation = -max_vector_rotation
		move_vector = move_vector.rotated(vector_rotation)
		
		var orientation_speed_coefficient := 1.0 - clampf(absf(angle_diff) / (PI * 0.66), 0.0, 1.0)
		velocity = move_vector * MAX_SPEED * start_speed_coefficient * orientation_speed_coefficient
		
		var node_rotation := ROTATION_SPEED * delta * start_speed_coefficient
		for node in rotating_nodes:
			node.rotate(node_rotation)
	
	move_and_slide()


func damage() -> void:	
	if destroyed: return
	
	health -= 1
	if health <= 0: destroy()


func destroy() -> void:
	# Spawn particles
	for i in randi_range(8, 12):
		var new_particle: CollidingParticle = particle_scene.instantiate()
		get_node("/root/Game").add_child.call_deferred(new_particle)
		new_particle.setup(global_position, particle_color.sample(randf()), 6.0,
		Vector2(0, randf_range(-230, -70)).rotated(randf_range(-PI / 2, PI / 2)), 2.0, 1.5, 0.5)
	
	destroyed = true
	animation_player.play("destroy")  # Hides, disabled collison, plays sound and eventually destroys the object 1s later
