class_name Projectile
extends Area2D

@export var shooting_sound: AudioStreamPlayer2D
@export var destroying_sound: AudioStreamPlayer2D

#SCALE = 1.0
#SPEED = [16.0, 16.0]
#OVERRIDE_Z_INDEX = 0  # SET TO 0 IF YOU DON'T WANT TO OVERRIDE Z INDEX; This is also added to the particle scene's z_index
#
#SHOOT_PARTICLE_NUMBER = [3, 4]
#SHOOT_PARTICLE_SIZE = [1.5, 3.0]
#SHOOT_PARTICLE_SPEED = 520.0
#SHOOT_PARTICLE_DESPAWN_TIME = 0.2
#SHOOT_PARTICLE_FADE_AWAY_TIME = 0.0
#SHOOT_PARTICLE_GRAVITY_SCALE = 0.0
#
#HIT_PARTICLE_NUMBER = [2, 5]
#HIT_PARTICLE_SIZE = [1.5, 5.0]
#HIT_PARTICLE_SPEED = 330.0
#HIT_PARTICLE_DESPAWN_TIME = 0.4
#HIT_PARTICLE_FADE_AWAY_TIME = 0.2
#HIT_PARTICLE_GRAVITY_SCALE = 0.5
#
#PARTICLE_COLOR = {
	#"min_hue": 320.0/360.0,
	#"max_hue": 345.0/360.0,
	#"min_sat": 0.4,
	#"max_sat": 1.0,
	#"min_val": 0.9,
	#"max_val": 1.0,
#}


var SCALE = 1.0
var SPEED := [16.0, 16.0]

# This variable isn't used anywhere inside the projectile classes. However, it can be accessed
# from outside to deal proper damage (for example in player)
var DAMAGE = 20.0

var Z_INDEX_OVERWRITE = 0  # SET TO 0 IF YOU DON'T WANT TO OVERRIDE Z INDEX;  This is also added to the particle scene's z_index

var PARTICLE_SCENE := preload("res://scenes/colliding_particle.tscn")

var SHOOT_PARTICLE_NUMBER := [3, 4]
var SHOOT_PARTICLE_SIZE := [1.5, 3.0]
var SHOOT_PARTICLE_SPEED := 520.0
var SHOOT_PARTICLE_DESPAWN_TIME := 0.2
var SHOOT_PARTICLE_FADE_AWAY_TIME := 0.0
var SHOOT_PARTICLE_GRAVITY_SCALE := 0.0

var HIT_PARTICLE_NUMBER := [2, 5]
var HIT_PARTICLE_SIZE := [1.5, 5.0]
var HIT_PARTICLE_SPEED := 330.0
var HIT_PARTICLE_DESPAWN_TIME := 0.4
var HIT_PARTICLE_FADE_AWAY_TIME := 0.2
var HIT_PARTICLE_GRAVITY_SCALE := 0.5

var PARTICLE_COLOR := {
	"min_hue": 320.0/360.0,
	"max_hue": 345.0/360.0,
	"min_sat": 0.4,
	"max_sat": 1.0,
	"min_val": 0.9,
	"max_val": 1.0,
}

var PARTICLE_MATERIAL_OVERRIDE: Material = null

var move_vector := Vector2(1, 0)
var moves_done := 0
var destroyed := false
var speed := 10.0


func _init() -> void:
	self.position = Vector2(0, 0)
	self.visible = false

func setup(position: Vector2, rotation: float, flipped: bool = false, speed = null) -> void:
	if speed == null:
		self.speed = randf_range(SPEED[0], SPEED[1])
	else:
		self.speed = speed
	self.global_position = position
	self.global_rotation = rotation
	if get_node_or_null("Sprite2D"): get_node("Sprite2D").flip_v = flipped
	scale = Vector2(SCALE, SCALE)
	move_vector = Vector2(1, 0).rotated(rotation)
	if Z_INDEX_OVERWRITE != 0:
		z_index = Z_INDEX_OVERWRITE
	visible = true
	spawn_shoot_particles.call_deferred()
	custom_setup.call_deferred()


func custom_setup():
	pass


func _physics_process(delta: float) -> void: 
	if !destroyed:
		position += move_vector * speed
		custom_physics_process(delta)
		moves_done += 1


func custom_physics_process(delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if !destroyed:
		custom_process(delta)


func custom_process(delta: float) -> void:
	pass




func spawn_hit_particles():
	for n in range(randi_range(HIT_PARTICLE_NUMBER[0], HIT_PARTICLE_NUMBER[1])):
		var new_particle := PARTICLE_SCENE.instantiate()
		new_particle.z_index += Z_INDEX_OVERWRITE
		
		if PARTICLE_MATERIAL_OVERRIDE:
			new_particle.material = PARTICLE_MATERIAL_OVERRIDE
		
		new_particle.setup(self.global_position,
		Color.from_hsv(randf_range(PARTICLE_COLOR["min_hue"], PARTICLE_COLOR["max_hue"]), randf_range(PARTICLE_COLOR["min_sat"],
		PARTICLE_COLOR["max_sat"]), randf_range(PARTICLE_COLOR["min_val"], PARTICLE_COLOR["max_val"]), 1.0),
		randf_range(HIT_PARTICLE_SIZE[0], HIT_PARTICLE_SIZE[1]),
		(self.move_vector * -1).rotated(randf_range(-PI * 0.5, PI * 0.5)) * HIT_PARTICLE_SPEED,
		HIT_PARTICLE_DESPAWN_TIME, HIT_PARTICLE_FADE_AWAY_TIME, HIT_PARTICLE_GRAVITY_SCALE)
		get_node("/root/Game").call_deferred("add_child", new_particle)


func spawn_shoot_particles():
	for n in range(randi_range(SHOOT_PARTICLE_NUMBER[0], SHOOT_PARTICLE_NUMBER[1])):
		var new_particle := PARTICLE_SCENE.instantiate() as CollidingParticle
		# new_particle.z_index += Z_INDEX_OVERWRITE
		
		if PARTICLE_MATERIAL_OVERRIDE:
			new_particle.material = PARTICLE_MATERIAL_OVERRIDE
		
		new_particle.setup(self.global_position,
		Color.from_hsv(randf_range(PARTICLE_COLOR["min_hue"], PARTICLE_COLOR["max_hue"]), randf_range(PARTICLE_COLOR["min_sat"],
		PARTICLE_COLOR["max_sat"]), randf_range(PARTICLE_COLOR["min_val"], PARTICLE_COLOR["max_val"]), 1.0),
		randf_range(SHOOT_PARTICLE_SIZE[0], SHOOT_PARTICLE_SIZE[1]),
		(self.move_vector).rotated(randf_range(-PI * 0.25, PI * 0.25)) * SHOOT_PARTICLE_SPEED,
		SHOOT_PARTICLE_DESPAWN_TIME, SHOOT_PARTICLE_FADE_AWAY_TIME, SHOOT_PARTICLE_GRAVITY_SCALE)
		
		get_node("/root/Game").call_deferred("add_child", new_particle)


func destroy() -> void:
	destroyed = true
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	visible = false
	spawn_hit_particles()
	queue_free()
