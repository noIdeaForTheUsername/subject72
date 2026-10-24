class_name Grass
extends MultiMeshInstance2D


# Consts: distance
const BLADE_DISTANCE := 1.0
const MAX_DISTANCE := 1690.0
const BLADE_NUMBER := floori(MAX_DISTANCE / BLADE_DISTANCE)

# Consts: appearance
const BLADE_CURVE := PI / 6
const BLADE_ANGULAR_VEL := BLADE_CURVE * 3.0
const MAX_BLADE_Y_OFFSET := 7.0

# Consts: reaction to player proximity
const MIN_PLAYER_Y := -60
const SIDE_BLADE_CURVES: int = 10
const MIN_PLAYER_SPEED := 20.0 * 1.0/60.0


@export var player: Node2D
var last_player_pos: Vector2
var blades: Array[Blade]


enum Direction {
	LEFT = -1,
	NEUTRAL = 0,
	RIGHT = 1,
}


class Blade:
	var id: int  # IDs should be equal to the index in array
	var position: Vector2
	var rotation: float
	var target_rotation: float
	func _init(id: int, position: Vector2):
		self.id = id
		self.position = position
		self.rotation = 0
		target_rotation = 0
	func process(delta: float, multimesh: MultiMesh):
		if abs(target_rotation - rotation) < 0.001: return

		# Perform rotation
		if target_rotation < rotation:  # rotate left
			rotation -= BLADE_ANGULAR_VEL * delta
			if rotation - 0.001 <= target_rotation:
				rotation = target_rotation
				target_rotation = 0
		elif target_rotation > rotation:  # rotate right
			rotation += BLADE_ANGULAR_VEL * delta
			if rotation + 0.001 >= target_rotation:
				rotation = target_rotation
				target_rotation = 0
		
		multimesh.set_instance_transform_2d(id, Transform2D(rotation, position))
		
	
	func start_curve_anim(direction: Direction):
		if direction == Direction.LEFT:  # Rotate to left
			target_rotation = -BLADE_CURVE
		elif direction == Direction.RIGHT:  # x_diff <= 0 && target_rotation <= 0:  # Rotate to right
			target_rotation = BLADE_CURVE


func _ready() -> void:
	last_player_pos = player.position
	blades.resize(BLADE_NUMBER)
	multimesh.instance_count = BLADE_NUMBER
	for n in BLADE_NUMBER:
		blades[n] = Blade.new(n, Vector2(n * BLADE_DISTANCE, randf_range(-MAX_BLADE_Y_OFFSET, MAX_BLADE_Y_OFFSET)))
		multimesh.set_instance_transform_2d(n, Transform2D(blades[n].rotation, blades[n].position))


func _process(delta: float) -> void:
	var pos_diff := player.position - last_player_pos
	var local_player_pos := to_local(player.position)
	
	if local_player_pos.y > MIN_PLAYER_Y && abs(pos_diff.x) > MIN_PLAYER_SPEED:
		var movement_direction: Direction = Direction.NEUTRAL
		if pos_diff.x > 0: movement_direction = Direction.RIGHT
		elif pos_diff.x < 0: movement_direction = Direction.LEFT
		
		var blade_num := roundi(local_player_pos.x / BLADE_DISTANCE)
		for n in range(max(blade_num - SIDE_BLADE_CURVES, 0), min(blade_num + SIDE_BLADE_CURVES, BLADE_NUMBER)):
			blades[n].start_curve_anim(movement_direction)
	
	last_player_pos = player.position
	
	for blade in blades:
		blade.process(delta, multimesh)
		# multimesh.set_instance_transform_2d(blade.id, blade.node.transform)
