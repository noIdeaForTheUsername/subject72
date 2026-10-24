class_name Gun
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_sound: AudioStreamPlayer = $ProjectileSpawnPos/FireSound
@onready var projectile_spawn_pos: Node2D = $ProjectileSpawnPos
@onready var projectile_raycast: RayCast2D = $ProjectileRaycast
@export var pivot: Node2D:
	get:
		if pivot && pivot.is_inside_tree():
			return pivot
		else:
			return self


const SHOOT_COOLDOWN := 0.2
const PROJECTILE_SPAWN_POS: Vector2 = Vector2(53.0, 0.0)
const MAX_TILT = 70.0
const RECOIL = 4.0  # In degrees
const RECOIL_REDUCTION = 1.0  # A part of the recoil that will be reducted before the shoot cooldown expires (degrees)
# To calculate max recoil possible (the angle difference between mouse and shooting direction): RECOIL * (1 / RECOIL_REDUCTION)

var projectile_scene := preload("res://scenes/player_projectile.tscn")

var pivot_pos_x: float
var flipped := false
var degrees := 0.0

var current_recoil := 0.0:
	set(value): if value < 0: current_recoil = 0
	else: current_recoil = value
var current_recoil_reduction := 0.0

var time_not_shooting: float = 0.0:
	set(value):if value < 0: time_not_shooting = 0
	else: time_not_shooting = value

var previously_faced_left := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pivot_pos_x = pivot.position.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_not_shooting += delta
	#  Rotate and flip pivot
	animated_sprite.flip_v = flipped
	pivot.rotation = deg_to_rad(degrees)
	pivot.position.x = pivot_pos_x
	if flipped: pivot.position.x *= -1


func add_recoil(value: float = RECOIL) -> void:
	current_recoil += value
	current_recoil_reduction = current_recoil * RECOIL_REDUCTION


# Call in physics_process
func handle_rotation(delta: float, player_global_pos: Vector2, player_direction_x: float) -> void:
	# Handle aim
	var mouse_pos := get_global_mouse_position()
	var direction := mouse_pos - pivot.global_position
	degrees = rad_to_deg(direction.angle())
	
	# Prevent an error where the player flips every frame if the cursor is between the flipped GunPivot positions
	if (mouse_pos - player_global_pos).x >= 0:  # Cursor on the right side of the player
		degrees = clampf(degrees, -89.5, 89.5)
	elif degrees < 0:  # cursor on the left side of the player - top
		degrees = clampf(degrees, -180.0, -90.5)
	else:  # left side - bottom
		degrees = clampf(degrees, 90.5, 180.0)
	
	# Handle flip and recoil
	if degrees > 0 && ((degrees <= 90 || (degrees - current_recoil <= 90 && !previously_faced_left)) &&
	!(degrees + current_recoil > 90 && previously_faced_left)):  # Right-bottom I HAVE NO IDEA WHAT'S HAPPENING IN THIS "IF" ANYMORE
		degrees -= current_recoil
		degrees = clamp(degrees, -MAX_TILT, MAX_TILT)
		flipped = false
	elif (degrees > 90 || degrees + current_recoil > 90) && degrees < 180:  # Left-bottom
		degrees += current_recoil
		degrees = clamp(degrees, 180 - MAX_TILT, 180 + MAX_TILT)
		flipped = true
	elif degrees >= -180 && degrees < -90:  # Left-top
		degrees = clamp(degrees, -180 - MAX_TILT, -180 + MAX_TILT)
		degrees += current_recoil
		if degrees > -90: degrees = -90
		flipped = true
	elif degrees >= -90 && degrees <= 0:  # Right-top
		degrees = clamp(degrees, -MAX_TILT, MAX_TILT)
		degrees -= current_recoil
		if degrees < -90: degrees = -90
		flipped = false
	
	# Flip if player is walking in the opposite direction to the aim while not shooting
	if (time_not_shooting > 1.0 &&
	((abs(degrees) < 90 && player_direction_x == -1)
	|| (abs(degrees) > 90 && player_direction_x == 1))):
		flipped = !flipped
		if (degrees < 0):
			degrees += (-90 - degrees) * 2
		else:
			degrees += (90 - degrees) * 2
	
	previously_faced_left = flipped
	
	# Reduce recoil
	current_recoil -= current_recoil_reduction * (delta / SHOOT_COOLDOWN)


func fire() -> void:
	if self.time_not_shooting >= SHOOT_COOLDOWN:
		time_not_shooting = 0
		fire_sound.play()
		if !projectile_raycast.is_colliding(): call_deferred("spawn_projectile")
		call_deferred("add_recoil")
		# call_deferred("handle_rotation")
		animated_sprite.play("off")
		animated_sprite.play("fire")


func spawn_projectile() -> void:
	var new_projectile := projectile_scene.instantiate() as PlayerProjectile
	new_projectile.setup(projectile_spawn_pos.global_position, global_rotation, flipped)
	get_node("/root/Game").add_child(new_projectile)


func get_flipped() -> bool:
	return flipped
