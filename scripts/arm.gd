class_name PlayerArm
extends Node2D

class Part:
	var sprite: Sprite2D
	var bone: Bone2D
	var default_sprite_offset_x: float
	var default_bone_x: float
	
	func _init(sprite: Sprite2D, bone: Bone2D):
		if sprite:
			self.sprite = sprite
			default_sprite_offset_x = sprite.offset.x
		if bone:
			self.bone = bone
			default_bone_x = bone.position.x
	
	func set_flipped(value: bool):
		if sprite:
			sprite.flip_h = value
			sprite.offset.x = default_sprite_offset_x
			if value: sprite.offset.x *= -1
		if bone:
			bone.position.x = default_bone_x
			if value: bone.position.x *= -1



@onready var parts: Array[Part] = [
	Part.new($Sprites/Arm, $Skeleton2D/Arm),  # Upper arm
	Part.new($Sprites/Forearm, $Skeleton2D/Arm/Forearm),  # Lower arm (forearm)
	Part.new(null, $Skeleton2D/Arm/Forearm/Hand),  # Hand (end)
]

var flipped: bool = false
# @onready var fore_arm = Part.new($Forearm, $Skeleton2D/Arm/Forearm)

#  for flipping - contraint angles on joint 1 (forearm)
var default_min_angle: float = -180
var default_max_angle: float = 180
var skeleton_mod: SkeletonModification2DCCDIK


func _ready():
	var skeleton: Skeleton2D = $Skeleton2D
	skeleton_mod = skeleton.get_modification_stack().get_modification(0)
	# for an unknown reason (probably godot's stupidity) the modification stack wasn't getting fully reset
	# on scene reload, resulting in incorrect values here. So the values are hardcoded now
	#default_min_angle = skeleton_mod.get_ccdik_joint_constraint_angle_min(1)
	#default_max_angle = skeleton_mod.get_ccdik_joint_constraint_angle_max(1)
	if self.name == "FrontArm":
		default_min_angle = deg_to_rad(-81.73)
		default_max_angle = deg_to_rad(38.834)
	elif self.name == "BackArm":
		default_min_angle = deg_to_rad(-97.298)
		default_max_angle = deg_to_rad(38.834)
	else:
		push_error("Player arm names incorrect: check arm.gd")
	set_flipped(false)


func set_flipped(value: bool):
	flipped = value
	for part in parts:
		part.set_flipped(value)
	
	if value:
		skeleton_mod.set_ccdik_joint_constraint_angle_min(1, -default_max_angle)
		skeleton_mod.set_ccdik_joint_constraint_angle_max(1, -default_min_angle)
	else:
		skeleton_mod.set_ccdik_joint_constraint_angle_min(1, default_min_angle)
		skeleton_mod.set_ccdik_joint_constraint_angle_max(1, default_max_angle)


func set_local_pos(pos: Vector2):
	if (flipped):
		pos.x *= -1
	position = pos
