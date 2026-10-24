class_name Boss
extends CharacterBody2D

var dummy_player := Node2D.new()
@export var player: Node2D:
	get:
		if player && player.is_inside_tree():
			return player
		else:
			return dummy_player


@export var game: Game
@export var health_bar: TextureRect
@export var wound_particle_gradient: Gradient
@export var fire_sprinklers_parent: Node2D
@export var growl_sounds_parent: Node2D

@onready var action_timer: Timer = $ActionTimer
@onready var subaction_timer: Timer = $SubactionTimer
@onready var knockback_cooldown: Timer = $KnockbackCooldown
@onready var death_restart: Timer = $DeathRestart
@onready var eyes: BossEyes = $Eyes
@onready var laser_warn: Line2D = $LaserWarn
@onready var body_sprite: AnimatedSprite2D = $Body
@onready var wounds_sprite: Sprite2D = $P3Wounds
@onready var phase_2_anim_player: AnimationPlayer = $Phase2Transform
@onready var phase_3_anim_player: AnimationPlayer = $Phase3Anim
@onready var chase_path_follow: PathFollow2D = %BossPathFollow
@onready var failed_chase_path: Path2D = %FailedChasePath
@onready var mouth_projectile_spawn: Node2D = get_node("MouthProjectileSpawn")
@onready var teeth: BossTeeth = $Teeth


@onready var dash_sound: AudioStreamPlayer = $Sounds/DashSound
@onready var laser_sound: AudioStreamPlayer2D = $Sounds/ShootSound1
@onready var fireball_sound: AudioStreamPlayer2D = $Sounds/ShootSound2
@onready var bouncy_projectile_sound: AudioStreamPlayer2D = $Sounds/ShootSound3
@onready var laser_charge_sound: AudioStreamPlayer = $Sounds/LaserChargeSound
@onready var laser_shoot_sound: AudioStreamPlayer = $Sounds/LaserShootSound
@onready var death_sound: AudioStreamPlayer = $Sounds/DeathSound
@onready var phase_roar_sound: AudioStreamPlayer = $Sounds/PhaseRoarSound
@onready var spike_slide_out_sound: AudioStreamPlayer = $Sounds/SpikeSlideOutSound

var particle_scene := preload("res://scenes/colliding_particle.tscn")
var laser_projectile_scene := preload("res://scenes/boss_projectile_1.tscn")
var fireball_projectile_scene := preload("res://scenes/boss_projectile_2.tscn")
var curved_laser_projectile_scene := preload("res://scenes/boss_projectile_3.tscn")
var bouncy_projectile_scene := preload("res://scenes/boss_projectile_4.tscn")
const FUME_SCENE := preload("res://scenes/boss_fume.tscn")
const FIRE_SCENE := preload("res://scenes/boss_fire.tscn")
var laser_scene := preload("res://scenes/boss_laser.tscn")
var spike_orb_scene := preload("res://scenes/spike_orb.tscn")
var hp_minus_scene := preload("res://scenes/hp_minus.tscn")

var growl_sounds: Array[AudioStreamPlayer2D] = []
var last_growl_sounds: Array[int] = []
var fume_pool: Array[BossFume]
const FUME_SPREAD_ANGLE: float = PI / 8

var GROUND_LAYER := 9
var CHASE_SLOWING_ANGLE := PI / 4  # it's not the final chase, it's the Chase action used in fume/fire attacks
var ATTACK_COOLDOWN: int = 3  # after the boss performs an attack, it won't be repeating it for at least ATTACK_COOLDOWN of attacks
const WOUND_POSITIONS: Array[Vector2i] = [
	Vector2i(42, -47),
	Vector2i(-2, -62), Vector2i(-19, -68),
	Vector2i(-19, -37),
	Vector2i(-54, 4), Vector2i(-40, 18),
	Vector2i(4, 16), Vector2i(-10, 32),
	Vector2i(36, 49)
]  # Positions where particles spawn in the phase 3 transition

var dashing := false
var alive := true
var transitioning := false
var phase := 1
var final_chase_phase := 0
var falling := false
var perform_actions := true

var collided_during_dash := false
var open_exit_door := false
var exit_door_opened := false
var last_shot_eye := BossEyes.Direction.LEFT
var last_attack_numbers: Array[int] = []
var flash_effect := 0.0
const FLASH_ON_DAMAGE := 0.2
const FLASH_REDUCTION := 0.8

const MAX_HEALTH: float = 1000.0  # 65 for testing
const HEALTH_BAR_FLASH_THRESHOLD: float = 200.0
var health_bar_color: Color = Color(0.8, 0.08, 0.08, 1.0)
var health_bar_flash_timer := 0.0
var health := MAX_HEALTH
var health_effect := health


# These variables are mainly for append_random_movement_action(),
# which moves the boss between attacks. The values are for phase 1:
var general_movement_speed := 170.0
var general_movement_ease := 0.2
var general_rotation_speed := PI * 0.66

# Final chase
var final_chase_min_speed: float  # it's supposed to be modified externally so don't hardcode it here. Change variables below instead
const DEFAULT_FINAL_CHASE_MIN_SPEED: float = 200.0
const FINAL_CHASE_MAX_SPEED_DIFF: float = 40.0
const FINAL_CHASE_MAX_PLAYER_DISTANCE: float = 500.0


#signal activate_fire_sprinklers()
#signal activate_lockdown()
#signal deactivate_lockdown()


# ACTIONS


var actions := []
var current_action: Action = null
var current_subaction: Action = null

class Action:
	var duration: float

class Wait extends Action:
	var look_at_player := true
	var angular_velocity: float = 0
	var args: Array[String]
	func _init(time: float, look_at_player = false, angular_velocity = 0.0):
		self.duration = time
		self.look_at_player = look_at_player
		self.angular_velocity = abs(angular_velocity)
	func add_args(args: Array[String]) -> Wait:
		self.args.append_array(args)
		return self
	func setup(distance_to_player: float):
		if "laser attack" in args:
			self.duration += distance_to_player / 350


func handle_wait_action(action: Wait, delta: float):
	if action.look_at_player:
		rotate_towards_player(action.angular_velocity, delta)


func rotate_towards_player(angular_velocity: float, delta: float):
	var target_angle := (player.global_position - self.global_position).angle()
	var angle_diff := wrapf(target_angle - self.rotation, -PI, PI)
	var rotate_angle = clamp(angle_diff / (PI / 6), -1.0, 1.0) * angular_velocity * delta
	if abs(angle_diff) > PI / 45 && abs(angle_diff) >= abs(rotate_angle):
		rotate(rotate_angle)


class Move extends Action:
	var target_pos: Vector2
	var velocity_vector: Vector2
	var move_vector = null
	var speed: float
	var ease: float = 0.2
	var args := []
	var pos_difference: Vector2
	func _init() -> void:
		self.duration = 0.0
	func append_args(args: Array) -> Move:
		self.args.append_array(args)
		return self
	func init_by_target_pos(target_pos: Vector2, speed: float = 170.0, ease: float = 0.2) -> Move:
		self.target_pos = target_pos
		self.speed = speed
		self.ease = ease
		return self
	func init_by_vector(move_vector: Vector2, speed: float = 170.0, ease: float = 0.2) -> Move:
		self.move_vector = move_vector
		self.speed = speed
		self.ease = ease
		return self
	func set_forced_duration(duration: float) -> Move:
		self.duration = duration
		return self
	func setup(player_pos: Vector2, boss_pos: Vector2, boss_rotation: float):
		if "increase vector by distance to player" in self.args:
			self.move_vector.x += (player_pos - boss_pos).length()
		
		if self.move_vector == null:
			pos_difference = (target_pos - boss_pos)
		else:
			self.move_vector = self.move_vector.rotated(boss_rotation)
			pos_difference = self.move_vector
			
		if self.duration == 0:  # Auto duration
			self.duration = pos_difference.length() / speed
			if self.duration < 3.0 && "3s min duration" in self.args:
				self.duration = 3.0
				speed = pos_difference.length() / self.duration
		else:  # forced duration
			speed = pos_difference.length() / self.duration
		self.velocity_vector = pos_difference / self.duration


func handle_move_action(action: Move, time_left: float = action_timer.time_left):
	var ease_time := action.duration * action.ease
	var time_elapsed := action.duration - time_left
	var max_velocity: Vector2 = (action.velocity_vector * action.duration) / (action.duration - ease_time)


	if time_elapsed < ease_time:
		self.velocity = max_velocity * (time_elapsed / ease_time)
	elif time_left < ease_time:
		self.velocity = max_velocity * (time_left / ease_time)
	else:
		self.velocity = max_velocity


class Rotate extends Action:
	var angular_velocity: float = 0
	var ease: float
	var rotate_angle = null
	var target_angle = null
	var forced_duration = false
	var target_look_at_pos = null
	func _init(angular_velocity: float, ease: float = 0.2, rotate_angle = null) -> void:
		self.angular_velocity = angular_velocity
		self.ease = clamp(ease, 0.0, 0.5)
		self.target_angle = null
		self.rotate_angle = rotate_angle
		if rotate_angle is float:
			self.duration = abs(rotate_angle / angular_velocity)
	# Call one of the functions below (unless you already passed a non-null value to rotate_angle in the contructor)
	# OR the boss will perform rotation to the player (ending at looking at them)
	func set_rotate_angle(rotate_angle: float) -> Rotate:
		self.rotate_angle = rotate_angle
		self.duration = abs(rotate_angle / angular_velocity)
		self.target_angle = null
		self.target_look_at_pos = null
		return self
	func set_target_angle(target_angle: float) -> Rotate:
		self.rotate_angle = null
		self.target_look_at_pos = null
		self.target_angle = target_angle
		return self
	func set_target_look_at_pos(pos: Vector2) -> Rotate:
		self.rotate_angle = null
		self.target_angle = null
		self.target_look_at_pos = pos
		return self
	# Call this just before the actions starts (next_action())
	func setup(player_pos: Vector2, boss_pos: Vector2, boss_rotation: float):
		if self.target_look_at_pos != null:
			target_angle = (target_look_at_pos - boss_pos).angle()
		elif target_angle == null && rotate_angle == null:
			target_angle = (player_pos - boss_pos).angle()  # Rotation to player
		
		if rotate_angle == null:
			rotate_angle = float(wrapf(target_angle - boss_rotation, -PI, PI))  # Set rotate angle to match target angle
		if forced_duration:
			angular_velocity = float(rotate_angle / duration)
		else:
			duration = abs(rotate_angle / angular_velocity)
		if (angular_velocity > 0) != (rotate_angle > 0):
			angular_velocity = -angular_velocity
		
	# Call whenever
	func set_forced_duration(duration: float) -> Rotate:
		forced_duration = true
		self.duration = duration
		if rotate_angle is float && abs(rotate_angle) > 0:
			angular_velocity = rotate_angle / duration
		return self


func handle_rotate_action(action: Rotate, delta: float, time_left: float):
	var ease_time := action.duration * action.ease
	var time_elapsed := action.duration - time_left
	var max_velocity := (action.angular_velocity * action.duration) / (action.duration - ease_time)
	# var max_velocity := action.angular_velocity / (1 - action.ease)
	
	var current_velocity: float
	
	if time_elapsed < ease_time:
		current_velocity = max_velocity * (time_elapsed / ease_time)
	elif time_left < ease_time:
		current_velocity = max_velocity * (time_left / ease_time)
	else:
		current_velocity = max_velocity
	
	rotate(current_velocity * delta)
	
	return current_velocity


class MoveAndRotate extends Action:
	var rotate: Rotate
	var move: Move
	var rotate_full_time: bool
	func _init(move: Move, rotate: Rotate, rotate_full_time: bool = false):
		self.move = move
		self.rotate = rotate
		self.rotate_full_time = rotate_full_time
	func setup(player_pos: Vector2, boss_pos: Vector2, boss_rotation: float):
		move.setup(player_pos, boss_pos, boss_rotation)
		self.duration = move.duration
		# if rotate action doesn't have a specified target/rotate angle, the setup will take the boss
		# target position and face player after the movement has been done
		if move.move_vector == null: 
			rotate.setup(player_pos, move.target_pos, boss_rotation)
		else:
			rotate.setup(player_pos, boss_pos + move.move_vector, boss_rotation)
		if rotate_full_time || rotate.duration > self.duration:
			rotate.set_forced_duration(move.duration)


class Chase extends Action:
	var speed: float
	var angular_velocity: float
	var ease: float
	func _init(duration: float, speed: float = 300.0, angular_velocity: float = PI / 2, ease: float = 0.1) -> void:
		self.duration = duration
		self.speed = speed
		self.angular_velocity = angular_velocity
		self.ease = ease


func handle_chase_action(action: Chase, delta: float):
	var velocity_multiplier_1 := 1.0
	var velocity_multiplier_2 := 1.0
	var ease_time := action.ease * action.duration
	
	var rotation_diff := wrapf(self.rotation - (player.global_position - self.global_position).angle(), -PI, PI)
	velocity_multiplier_2 = clamp(1.0 - (abs(rotation_diff) - CHASE_SLOWING_ANGLE) / (PI / 3), 0.0, 1.0)
		
	
	if action_timer.time_left > action.duration - ease_time:  # ease in
		velocity_multiplier_1 = (action_timer.wait_time - action_timer.time_left) / ease_time
	elif action_timer.time_left < ease_time:  # ease out
		velocity_multiplier_1 = action_timer.time_left / ease_time
	
	self.rotate_towards_player(action.angular_velocity * velocity_multiplier_1, delta)
	self.velocity = Vector2(action.speed * velocity_multiplier_1 * velocity_multiplier_2, 0).rotated(self.rotation)


class ToggleGroundCollision extends Action:
	var value: bool
	func _init(value: bool) -> void:
		self.duration = 0.0
		self.value = value

	
class PlaySound extends Action:
	var sound
	func _init(sound: Node, zero_duration: bool = true) -> void:
		self.sound = sound
		if zero_duration:
			self.duration = 0.0
		else:
			self.duration = sound.stream.get_length() * sound.pitch_scale


class SetVariable extends Action:
	var variable_name: String
	var value
	var object
	func _init(variable_name: String, value, object = null):
		self.variable_name = variable_name
		self.value = value
		self.object = object


class PlayAnimation extends Action:
	var anim_name: String
	var backwards: bool
	var start_frame: int
	func _init(anim_name: String, backwards: bool = false, start_frame: int = 0):
		self.anim_name = anim_name
		self.backwards = backwards
		self.start_frame = start_frame


class ToggleParticleEmitter extends Action:
	var particle_emitter: GPUParticles2D
	var value: bool
	func _init(particle_emitter: GPUParticles2D, value: bool = true) -> void:
		self.particle_emitter = particle_emitter
		self.value = value


class CallFunc extends Action:
	var func_name: String
	var params: Array
	var obj: Object = null
	func _init(name: String, params: Array = [], time: float = 0.0, obj: Object = null) -> void:
		self.func_name = name
		self.params = params
		self.duration = time
		self.obj = obj


class AimedShootAttack extends Action:
	var wait: Wait
	var shoot_cooldown: float
	var scene: Resource
	func _init(duration: float, scene: Resource, shoot_cooldown: float, angular_velocity: float = PI / 2):
		self.duration = duration
		self.shoot_cooldown = shoot_cooldown
		self.scene = scene
		wait = Wait.new(duration, true, angular_velocity)

func handle_aimed_shoot_attack_action(action: AimedShootAttack, delta: float):
	handle_wait_action(action.wait, delta)
	if subaction_timer.time_left == 0:
		subaction_timer.start(action.shoot_cooldown)
		var eye := BossEyes.Direction.RIGHT if last_shot_eye == BossEyes.Direction.LEFT else BossEyes.Direction.LEFT
		last_shot_eye = eye
		fire_projectile_on_aimed_shoot_attack(action.scene, eye)


class AimedFireballAttack extends Action:
	var rotate: Rotate
	var shoot_cooldown: float
	var projectiles_per_shot: int
	# the difference between the boss orientation, and first or last projectile orientation
	var spread_angle: float
	func _init(duration: float, shoot_cooldown: float, projectiles_per_shoot: int = 3, spread_angle = PI / 4):
		self.duration = duration
		self.shoot_cooldown = shoot_cooldown
		self.projectiles_per_shot = projectiles_per_shoot
		self.spread_angle = spread_angle
		self.rotate = Rotate.new(PI, 0.3)

func handle_aimed_fireball_attack_action(action: AimedFireballAttack, delta: float):
	if subaction_timer.time_left == 0.0:
		# reset rotation
		var rotate_angle := wrapf((player.global_position - self.global_position).angle() - self.global_rotation, -PI, PI)
		rotate_angle = clamp(rotate_angle, -PI / 3, PI / 3)
		action.rotate = Rotate.new(action.rotate.angular_velocity, action.rotate.ease, rotate_angle).set_forced_duration(action.shoot_cooldown)
		action.rotate.setup(player.global_position, self.global_position, self.global_rotation)
		subaction_timer.start(action.rotate.duration)
		fireball_sound.play()
		# spawn projectiles
		if action.projectiles_per_shot == 1:
			spawn_projectile(self.fireball_projectile_scene, mouth_projectile_spawn.global_position, global_rotation, null, -1)
		elif action.projectiles_per_shot > 1:
			var projectile_rotation := global_rotation - action.spread_angle
			var rotation_diff := (action.spread_angle * 2) / (action.projectiles_per_shot - 1)
			for i in action.projectiles_per_shot:
				spawn_projectile(self.fireball_projectile_scene, mouth_projectile_spawn.global_position, projectile_rotation, null, -1)
				projectile_rotation += rotation_diff

	if subaction_timer.time_left > 0.0:
		handle_rotate_action(action.rotate, delta, subaction_timer.time_left)


class SpreadShootAttack extends Action:
	var rotate: Rotate
	var shoot_cooldown: float
	var shoot_cooldown_randomization: float
	func _init(duration: float, shoot_cooldown: float, angular_velocity: float = PI / 2, shoot_cooldown_randomization: float = 0.1):
		self.duration = duration
		self.shoot_cooldown = shoot_cooldown
		self.shoot_cooldown_randomization = shoot_cooldown_randomization
		self.rotate = Rotate.new(angular_velocity, 0.1, angular_velocity * duration)

func handle_spread_shoot_attack_action(action: SpreadShootAttack, delta: float):
	handle_rotate_action(action.rotate, delta, action_timer.time_left)
	if subaction_timer.time_left == 0:
		subaction_timer.start(action.shoot_cooldown + randf_range(-action.shoot_cooldown_randomization, action.shoot_cooldown_randomization))
		var eye := BossEyes.Direction.RIGHT if last_shot_eye == BossEyes.Direction.LEFT else BossEyes.Direction.LEFT
		last_shot_eye = eye
		fire_projectile_on_spread_shoot_attack(laser_projectile_scene, eye)


class SpreadFireballAttack extends Action:  # For Phase 3
	var rotate: Rotate
	var shoot_cooldown: float
	func _init(duration: float, shoot_cooldown: float, angular_velocity: float, rotate_ease: float = 0.1):
		self.duration = duration
		self.shoot_cooldown = shoot_cooldown
		self.rotate = Rotate.new(angular_velocity, rotate_ease, angular_velocity * duration)
	func setup(player_pos: Vector2, boss_pos: Vector2, boss_rotation: float):
		var vec_to_player = player_pos - boss_pos
		if Vector2.RIGHT.rotated(boss_rotation).angle_to(vec_to_player) < 0:
			self.rotate.set_rotate_angle(self.rotate.rotate_angle * -1)
		self.rotate.setup(player_pos, boss_pos, boss_rotation)
		
func handle_spread_fireball_attack_action(action: SpreadFireballAttack, delta: float):
	handle_rotate_action(action.rotate, delta, action_timer.time_left)
	var ease_time := action.rotate.ease * action.rotate.duration
	if (subaction_timer.time_left == 0 && action_timer.time_left > ease_time && action_timer.time_left < action.duration - ease_time):
	# only eject fireballs when the rotation speed is maximum
		subaction_timer.start(action.shoot_cooldown)
		fireball_sound.play()
		spawn_projectile(fireball_projectile_scene, global_position, global_rotation +
		(PI / 4) * clamp(action.rotate.angular_velocity, -0.1, 0.1) * 10)  # A bit of offset in the direction the boss is rotating in


class BouncyShootAttack extends Action:
	var wait: Wait
	var shots_number: int
	var shoot_cooldown: float
	# max difference between vector to player and shoot vector
	func _init(shots_number: int = 3, shoot_cooldown: float = 1.0, angular_velocity: float = PI * 0.66):
		self.duration = shots_number * shoot_cooldown
		self.shots_number = shots_number
		self.shoot_cooldown = shoot_cooldown
		self.wait = Wait.new(duration, true, angular_velocity)

func handle_bouncy_shoot_attack_action(action: BouncyShootAttack, delta: float):
	handle_wait_action(action.wait, delta)
	# spawn projectile
	if subaction_timer.time_left == 0.0:
		subaction_timer.start(action.shoot_cooldown)
		bouncy_projectile_sound.play()
		spawn_projectile(curved_laser_projectile_scene, eyes.get_node("CenterEye/Pupil").global_position, global_rotation)
		eyes.set_flash_effect("center", 7.0)



class LaserAttack extends Action:
	var laser: BossLaser
	var max_angular_velocity: float
	var ease_in: float
	var ease_out: float
	var clockwise: bool
	func _init(duration: float, max_angular_velocity: float = (PI / 3.0), ease_in: float = 0.3, ease_out: float = 0.1) -> void:
		self.duration = duration
		self.max_angular_velocity = max_angular_velocity
		self.ease_in = ease_in
		self.ease_out = ease_out
	func setup(scene: Resource, boss: Node2D, clockwise: bool = true):
		self.clockwise = clockwise
		laser = scene.instantiate()
		laser.setup(boss.to_local(boss.get_node("Eyes/CenterEye").global_position), 0)
		boss.add_child.call_deferred(laser)

func handle_laser_attack_action(action: LaserAttack, delta: float):
	var angular_velocity: float
	if !action.laser.active_sound.playing: action.laser.active_sound.play()
	
	angular_velocity = action.max_angular_velocity
	
	if action_timer.time_left >= action.duration * (1.0 - action.ease_in) && action.ease_in > 0:
		angular_velocity *= (action.duration - action_timer.time_left) / (action.ease_in * action.duration)
	elif action_timer.time_left < action.duration * action.ease_out && action.ease_out > 0:
		angular_velocity = action.max_angular_velocity * action_timer.time_left / (action.ease_out * action.duration)
		action.laser.shutdown(action.duration * action.ease_out)
	
	if !action.clockwise: angular_velocity *= -1
	action.laser.rotate(angular_velocity * delta)


class FumeAttack extends Action:
	var chase: Chase
	var excess_time := 0.0
	var time_per_shard: float
	var shard_initial_speed: float
	var scene: Resource
	var spread_angle: float
	func _init(duration: float, angular_velocity: float = PI / 3, boss_speed: float = 150.0, shard_initial_speed: float = 8.0, 
	shards_per_second: float = 500.0, spread_angle: float = FUME_SPREAD_ANGLE, scene: Resource = FUME_SCENE) -> void:
		self.duration = duration
		self.time_per_shard = 1.0 / shards_per_second
		self.shard_initial_speed = shard_initial_speed
		self.chase = Chase.new(duration, boss_speed, angular_velocity, 0.2)
		self.spread_angle = spread_angle
		self.scene = scene


func handle_fume_attack_action(action: FumeAttack, delta: float):
	handle_chase_action(action.chase, delta)
	action.excess_time += delta
	var shards_to_spawn: int = floor(action.excess_time / action.time_per_shard)
	action.excess_time -= shards_to_spawn * action.time_per_shard
	for i in shards_to_spawn:
		spawn_fume_shard(action.scene, mouth_projectile_spawn.global_position,
		self.global_rotation + randf_range(-action.spread_angle, action.spread_angle), action.shard_initial_speed)


class OrbAttack extends Action:
	var move: Move
	var orb_number: int
	var orbs_left: int
	var cooldown: float
	func _init(move: Move, orbs: int) -> void:
		self.move = move
		self.move.append_args(["3s min duration"])
		self.orb_number = orbs
		self.orbs_left = orbs
	func setup(player_pos: Vector2, boss_pos: Vector2, boss_rot: float) -> void:
		move.setup(player_pos, boss_pos, boss_rot)
		self.duration = move.duration
		self.cooldown = self.duration / self.orb_number - 0.02


func handle_orb_attack_action(action: OrbAttack, delta: float):
	handle_move_action(action.move, action_timer.time_left)
	if subaction_timer.time_left == 0 && action.orbs_left > 1:
		eject_spike_orb()
		action.orbs_left -= 1
		subaction_timer.start(action.cooldown)

# Spike attack
func show_spike_warnings():
	for spike in get_tree().get_nodes_in_group("boss_spikes") as Array[BossSpike]:
		spike.show_eject_warn()

func eject_spikes(regen_time: float = 1):
	for spike in get_tree().get_nodes_in_group("boss_spikes") as Array[BossSpike]:
		spike.eject(regen_time)


# FUNCTIONS HANDLING THE ACTIONS SYSTEM

func handle_actions(delta: float):
	if current_action is Wait:
		handle_wait_action(current_action, delta)
	elif current_action is Move:
		handle_move_action(current_action)
	elif current_action is Rotate:
		handle_rotate_action(current_action, delta, action_timer.time_left)
	elif current_action is MoveAndRotate:
		handle_move_action(current_action.move)
		handle_rotate_action(current_action.rotate, delta, subaction_timer.time_left)
	elif current_action is Chase:
		handle_chase_action(current_action, delta)
	elif current_action is AimedShootAttack:
		handle_aimed_shoot_attack_action(current_action, delta)
	elif current_action is SpreadShootAttack:
		handle_spread_shoot_attack_action(current_action, delta)
	elif current_action is AimedFireballAttack:
		handle_aimed_fireball_attack_action(current_action, delta)
	elif current_action is SpreadFireballAttack:
		handle_spread_fireball_attack_action(current_action, delta)
	elif current_action is BouncyShootAttack:
		handle_bouncy_shoot_attack_action(current_action, delta)
	elif current_action is LaserAttack:
		handle_laser_attack_action(current_action, delta)
	elif current_action is OrbAttack:
		handle_orb_attack_action(current_action, delta)
	elif current_action is FumeAttack:
		handle_fume_attack_action(current_action, delta)


func next_action():
	if !alive: return
	
	# Reset previous action
	if current_action is Move || current_action is MoveAndRotate:
		self.velocity = Vector2(0, 0)
		collided_during_dash = false
	elif current_action is LaserAttack:
		current_action.laser.queue_free()
		laser_warn.rotation = 0
		laser_warn.visible = false
	elif current_action is FumeAttack:
		for fume in fume_pool:
			fume.queue_free()
		fume_pool.clear()
	elif current_action is OrbAttack:
		eject_spike_orb()
	
	
	# Load next action
	if (actions.size() > 0):
		current_action = actions.pop_front()
	else:
		current_action = null
	
	
	# setup next action
	if current_action == null:
		match phase:
			1: append_phase_1_attack()
			2: append_phase_2_attack()
			3: append_phase_3_attack()
			_: return
		next_action()
	if current_action is Wait:
		current_action.setup((player.global_position - self.global_position).length())
		action_timer.start(current_action.duration)
	elif current_action is Move:
		current_action.setup(player.global_position, self.global_position, self.global_rotation)
		action_timer.start(current_action.duration)
	elif current_action is Rotate:
		current_action.setup(player.global_position, self.global_position, self.global_rotation)
		action_timer.start(current_action.duration)
	elif current_action is MoveAndRotate:
		current_action.setup(player.global_position, self.global_position, self.global_rotation)
		action_timer.start(current_action.duration)
		subaction_timer.start(current_action.rotate.duration)
	elif current_action is PlaySound:
		current_action.sound.play()
	elif current_action is ToggleGroundCollision:
		toggle_ground_collision(current_action.value)
		next_action()
	elif current_action is PlayAnimation:
		if current_action.backwards:
			body_sprite.play_backwards(current_action.anim_name)
		else:
			body_sprite.play(current_action.anim_name)
		body_sprite.frame = current_action.start_frame
		next_action()
	elif current_action is LaserAttack:
		current_action.setup(laser_scene, self,
			wrapf((player.global_position - eyes.global_position).angle() - self.global_rotation, -PI, PI) >= 0)
		action_timer.start(current_action.duration)
	elif (current_action is AimedShootAttack || current_action is SpreadShootAttack || current_action is BouncyShootAttack):
		action_timer.start(current_action.duration)
		subaction_timer.start(current_action.shoot_cooldown)
	elif current_action is SpreadFireballAttack:
		current_action.setup(player.global_position, self.global_position, self.global_rotation)
		action_timer.start(current_action.duration)
	elif current_action is OrbAttack:
		current_action.setup(player.global_position, self.global_position, self.global_rotation)
		action_timer.start(current_action.duration)
		subaction_timer.start(current_action.cooldown)
	elif current_action is FumeAttack || current_action is AimedFireballAttack:
		action_timer.start(current_action.duration)
	elif current_action is ToggleParticleEmitter:
		current_action.particle_emitter.emitting = current_action.value
		next_action()
	elif current_action is SetVariable:
		if current_action.object == null:
			self.set(current_action.variable_name, current_action.value)
		else:
			current_action.object.set(current_action.variable_name, current_action.value)
		#if current_action.variable_name == "dashing":
			#self.dashing = current_action.value
		#elif current_action.variable_name == "eyes.look_at_player":
			#eyes.look_at_player = current_action.value
		#elif current_action.variable_name == "eyes.look_forward":
			#eyes.look_forward = current_action.value
		#elif current_action.variable_name == "laser_warn.visible":
			#laser_warn.visible = current_action.value
		#elif current_action.variable_name == "eyes.center_eye.pupil.lock_movement":
			#eyes.center_eye.pupil.lock_movement = current_action.value
		#elif current_action.variable_name == "open_exit_door":
			#open_exit_door = current_action.value
		next_action()
	elif current_action is CallFunc:
		if current_action.obj == null:
			callv(current_action.func_name, current_action.params)
		else:
			current_action.obj.callv(current_action.func_name, current_action.params)
		
		action_timer.start(current_action.duration)
		#if (current_action.duration > 0.0):
			#action_timer.start(current_action.duration)
		#else:
			#next_action()
	else:
		action_timer.start(current_action.duration)
	
	if current_action && current_action.duration <= 0:  # in case of the calcualted duration being 0, begin a new action
		action_timer.stop()
		subaction_timer.stop()
		next_action()


func _on_action_timer_timeout() -> void:
	next_action()






# ------------------------------------------------------------------------------------------------------------------------------------------------------
# MAIN FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func _ready():
	load_growl_sounds()
	toggle_ground_collision(false)
	eyes.player = player
	eyes.boss = self
	if health_bar && health_bar.material is ShaderMaterial: health_bar.material.set_shader_parameter("texture_size", health_bar.texture.get_size())
	
	append_growl_action()
	var action_1 := Move.new()
	action_1.init_by_vector(Vector2(1000, 0))
	actions.append(action_1)
	actions.append(ToggleGroundCollision.new(true))
	actions.append(SetVariable.new("look_at_player", true, eyes))
	next_action()


func _process(delta: float) -> void:
	update_health_bar(delta)
	if final_chase_phase == 0: handle_flash_effect(delta)
	#if Input.is_action_just_pressed("kill_boss"):
		#change_health(-100000)
		#phase = 4
		#final_chase_setup()
		#process_mode = PROCESS_MODE_INHERIT
		#start_final_chase()
		#actions.clear()
		#next_action()
		#chase_path_follow.progress_ratio = 0.95
	if phase == 4 && final_chase_phase == 0 && open_exit_door && global_position.x > 450:
		# BIODOME FIGHT END - DOOR OPENING
		if !exit_door_opened:
			game.deactivate_lockdown()
			exit_door_opened = true
		
	if phase >= 4 && current_action == null:
		next_action()


func _physics_process(delta: float) -> void:
	# Falling
	if falling:
		handle_fall(delta)
		move_and_collide(self.velocity * delta)
	# Final chase
	elif get_parent() is PathFollow2D && final_chase_phase == 1:
		process_path_follow(delta)
	elif final_chase_phase == 2 || 4:
		handle_actions(delta)
		move_and_slide()
	elif final_chase_phase == 3:
		pass
	# Default behaviour (during the battle)
	elif alive && !falling:
		handle_actions(delta)
		var previous_pos := self.global_position
		var expected_pos_diff := velocity * delta
		move_and_slide()
		collided_during_dash = false
		if dashing && ((previous_pos + expected_pos_diff) - self.global_position).length() > expected_pos_diff.length() * 0.05:
			collided_during_dash = true

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# LOAD FUNCIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func load_growl_sounds() -> void:
	if !growl_sounds_parent: return
	var found := growl_sounds_parent.get_children()
	for i in found.size():
		if found[i] is not AudioStreamPlayer2D: continue
		growl_sounds.append(found[i])
		if i % 2 == 1:
			last_growl_sounds.append(i)
	#var node: Node2D = $Sounds
	#if not node:
		#node = self
	#
	#var files := DirAccess.get_files_at("res://audio/growling")
	#var index := 0
	#while index < files.size():
		#var file_name := files[index]
		#if !(file_name.ends_with(".mp3") || file_name.ends_with(".wav") || file_name.ends_with(".ogg")):
			#files.remove_at(index)
		#index += 1
	#
	#var num := 1
	#for file_name in files:
		#var stream: AudioStream = ResourceLoader.load("res://audio/growling/" + file_name)
		#var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		#player.stream = stream
		#player.name = "Growl" + var_to_str(num)
		#player.pitch_scale = 2
		#node.add_child(player) 
		#growl_sounds.append(player)
		#if num % 2 == 1: last_growl_sounds.append(num)
		#num += 1


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# MECHANICS FUNCIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func change_health(amount: float) -> void:
	if (phase >= 4 || transitioning) && amount < 0:
		amount *= 0.2
	health = min(MAX_HEALTH, health + amount)
	if health < MAX_HEALTH * 0.01:
		health = MAX_HEALTH * 0.01
	#if health <= 0 && alive:
	#	die()

	if transitioning: return
	
	if health <= MAX_HEALTH * 0.6 && phase < 2:
		transitioning = true
		actions.append(CallFunc.new("phase_2_transition", [], 3.0))
	elif health <= MAX_HEALTH * 0.2 && phase < 3:
		transitioning = true
		actions.append(CallFunc.new("phase_3_transition", [], 3.0))
	elif health <= MAX_HEALTH * 0.05 && phase < 4:
		transitioning = true
		actions.append(CallFunc.new("phase_4_transition", [], 0.0))


func die() -> void:
	laser_warn.visible = false
	health = 0
	var emitter := get_node_or_null("Eyes/CenterEye/Pupil/LaserParticles") as GPUParticles2D
	if emitter != null:
		emitter.emitting = false
	if current_action is LaserAttack:
		current_action.laser.queue_free()
	for hair in get_node("Hair").get_children() as Array[AnimatedSprite2D]:
		hair.pause()
	for spike in get_tree().get_nodes_in_group("boss_spikes") as Array[BossSpike]:
		spike.set_deferred("monitorable", false)
		spike.set_deferred("monitoring", false)
		spike.eject_warn.visible = false
	current_action = null
	alive = false
	death_sound.play()
	death_restart.start()


func _on_death_restart_timeout() -> void:
	GameManager.start_game()


func _on_projectile_hitbox_entered(area: Area2D) -> void:
	if area is PlayerProjectile:
		self.change_health(-area.DAMAGE)
		set_flash_effect(FLASH_ON_DAMAGE)
		var particle := hp_minus_scene.instantiate() as GPUParticles2D
		particle.global_position = area.global_position
		particle.global_rotation = randf_range(-PI, PI)
		get_node("/root/Game").add_child.call_deferred(particle)
		area.destroy()


func toggle_ground_collision(value: bool = false):
	if value:
		self.collision_mask |= 1 << (GROUND_LAYER - 1)
	else:
		self.collision_mask &= ~(1 << (GROUND_LAYER - 1))


func handle_fall(delta: float):
	velocity.y += get_gravity().y * 0.1 * delta
	velocity.x *= 0.99


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# VISUAL FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------


func update_health_bar(delta: float) -> void:
	if health_effect > health:
		health_effect = clamp(health_effect - MAX_HEALTH * delta * 0.05, health, health_effect)
	
	var fill := health_bar.get_node("Fill") as CanvasItem
	if health_bar && fill:
		if health <= HEALTH_BAR_FLASH_THRESHOLD && final_chase_phase < 1:  # Add flash effect
			var flash_color := health_bar_color.lerp(Color(0.95, 0.95, 0.95, 1.0), 0.7)
			var speed_coeff := lerpf(5.0, 1.0, health / HEALTH_BAR_FLASH_THRESHOLD)
			health_bar_flash_timer += delta * 2 * PI * speed_coeff
			var weight := (cos(health_bar_flash_timer) + 1) / 2.0
			fill.modulate = health_bar_color.lerp(flash_color, weight)
		else: fill.modulate = health_bar_color
		
		if fill.material is ShaderMaterial:
			fill.material.set_shader_parameter("white_fill", health_effect / MAX_HEALTH)
			fill.material.set_shader_parameter("fill", health / MAX_HEALTH)


func set_flash_effect(value: float):
	flash_effect = value

func handle_flash_effect(delta: float) -> void:
	flash_effect = maxf(0, flash_effect - delta * FLASH_REDUCTION)
	modulate = Color.WHITE * (1 + flash_effect)


func release_spikes(delay: float = 0.2):
	for spike in get_tree().get_nodes_in_group("boss_spikes") as Array[BossSpike]:
		spike.slide_out(delay)
		if spike_slide_out_sound:
			spike_slide_out_sound.stop()
			spike_slide_out_sound.play()
		await Utils.pausable_timer(delay).timeout


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# TRANSITION FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------


func phase_2_transition():
	phase = 2
	AudioManager.music_transition("Phase2Music")
	phase_2_anim_player.play("transform")
	general_movement_speed = 200.0
	general_movement_ease = 0.1
	general_rotation_speed = PI * 0.75
	last_attack_numbers.clear()
	transitioning = false

func phase_3_transition():
	phase = 3
	AudioManager.music_transition("Phase3Music")
	phase_3_anim_player.play("anim")
	play_phase_roar()
	for pos in WOUND_POSITIONS:
		for n in randi_range(6, 8):
			var particle := particle_scene.instantiate() as CollidingParticle
			particle.setup(to_global(pos), wound_particle_gradient.sample(randf()), randf_range(3.0, 7.0),
			Vector2.LEFT.rotated(randf_range(0, PI)) * 100.0, 4.0, 3.0, 0.25)
			particle.z_index = 305
			get_node("/root/Game").add_child.call_deferred(particle)
	wounds_sprite.visible = true
	general_movement_speed = 220.0
	general_movement_ease = 0.1
	general_rotation_speed = PI
	last_attack_numbers.clear()
	transitioning = false

func phase_4_transition():
	phase = 4
	if %SectionManager: %SectionManager.load_next()
	play_phase_roar()
	eyes.set_eyes_color(Color(1, 0.833, 0), 2.5)
	actions.append(Wait.new(2.0, true, PI / 3))
	actions.append(FumeAttack.new(8.0, PI / 2, 60.0, 7.0, 200, PI / 10, FIRE_SCENE))
	await Utils.pausable_timer(8.0).timeout
	AudioManager.play("FireDetectedAnn")
	DialogueManager.display("[ANNOUNCER]: Warning! Fire detected in: Biodome.")
	AudioManager.play("FireAlarm", true)
	await Utils.pausable_timer(2.0).timeout
	eyes.set_eyes_color(Color.WHITE, 1.0)
	await Utils.pausable_timer(0.5).timeout
	# Fire sprinklers and flame "fadeout"
	game.activate_fire_sprinklers()
	await Utils.pausable_timer(0.5).timeout
	var target_pos := Vector2(440.0, -1290.0)
	var move_action := Move.new().init_by_target_pos(target_pos, 180, 0.1)
	var rotate_action := Rotate.new(PI, 0.2).set_target_angle((target_pos - self.global_position).angle())
	actions.append(SetVariable.new("open_exit_door", true))  # Door opening performed in _process
	actions.append(SetVariable.new("look_at_player", false, eyes))
	actions.append(SetVariable.new("look_forward", true, eyes))
	actions.append(rotate_action)
	actions.append(move_action)
	actions.append(Rotate.new(PI, 0.1).set_target_angle(0.0))
	actions.append(CallFunc.new("toggle_ground_collision", [false]))
	actions.append(Move.new().init_by_target_pos(Vector2(1650.0, -1290.0), 240.0, 0.1))
	actions.append(CallFunc.new("final_chase_setup"))


func play_phase_roar():
	phase_roar_sound.play()


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ATTACK UTIL FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func fire_projectile_on_aimed_shoot_attack(projectile_scene: Resource, eye: BossEyes.Direction, sound: AudioStreamPlayer2D = laser_sound) -> void:
	var shoot_pos: Vector2
	var shoot_rot: float
	if eye == BossEyes.Direction.LEFT:
		shoot_pos = eyes.get_node("RightEye/Pupil").global_position
		shoot_rot = clamp((player.global_position - shoot_pos).angle(), self.global_rotation - PI / 6, self.global_rotation)
		eyes.set_flash_effect("right", 5.0)
	else:
		shoot_pos = eyes.get_node("LeftEye/Pupil").global_position
		shoot_rot = clamp((player.global_position - shoot_pos).angle(), self.global_rotation, self.global_rotation + PI / 6)
		eyes.set_flash_effect("left", 5.0)
	
	spawn_projectile(projectile_scene, shoot_pos, shoot_rot, null, 2)
	sound.play()


func fire_projectile_on_spread_shoot_attack(projectile_scene: Resource, eye: BossEyes.Direction, sound: AudioStreamPlayer2D = laser_sound) -> void:
	var shoot_pos: Vector2
	var shoot_rot: float
	if eye == BossEyes.Direction.LEFT:
		shoot_pos = eyes.get_node("RightEye/Pupil").global_position
		eyes.set_flash_effect("right", 5.0)
	else:
		shoot_pos = eyes.get_node("LeftEye/Pupil").global_position
		eyes.set_flash_effect("left", 5.0)
	
	spawn_projectile(projectile_scene, shoot_pos, self.global_rotation + randf_range(-PI / 8, PI / 8), null, 2)
	sound.play()


func eject_spike_orb() -> void:
	var orb := spike_orb_scene.instantiate() as SpikeOrb
	get_node("/root/Game").add_child(orb)
	orb.setup(global_position, player, Vector2.RIGHT.rotated(global_rotation))
	body_sprite.play("shoot")


func spawn_projectile(projectile_scene: Resource, pos: Vector2, rot: float, speed = null, z_offset: int = 0):
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.z_index = self.z_index + z_offset
	if speed == null:
		projectile.setup(pos, rot, false)
	else:
		projectile.setup(pos, rot, false, speed)
	get_node("/root/Game").add_child(projectile)
	return projectile


func spawn_fume_shard(projectile_scene: Resource, pos: Vector2, rot: float, initial_speed: float):
	var fume: BossFume
	if fume_pool.size() == 0:
		fume = projectile_scene.instantiate()
		fume.connect("fume_destroyed", on_fume_destoyed)
		get_node("/root/Game").add_child(fume)
	else:
		fume = fume_pool.pop_back()
	
	fume.setup(pos, rot, false, initial_speed)
	return fume


func on_fume_destoyed(fume: BossFume):
	if current_action is FumeAttack:
		fume_pool.append(fume)
	else:
		fume.queue_free()


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# SPECIAL ACTION FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func play_growl() -> void:
	if growl_sounds.size() == 0: return
	var num := randi_range(0, growl_sounds.size() - 1)
	while num in last_growl_sounds:
		num = randi_range(0, growl_sounds.size() - 1)
	last_growl_sounds.append(num)
	last_growl_sounds.remove_at(0)
	growl_sounds[num].play()

func append_growl_action() -> void:
	#if growl_sounds.size() == 0: return
	#var num := randi_range(0, growl_sounds.size() - 1)
	#while num in last_growl_sounds:
		#num = randi_range(0, growl_sounds.size() - 1)
	#last_growl_sounds.append(num)
	#last_growl_sounds.remove_at(0)
	actions.append(CallFunc.new("play_growl"))

func append_random_movement_action(args: Array[String] = []):
	var target_pos := player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	if "move to center" in args:
		target_pos = Vector2(clamp(player.global_position.x + randf_range(-150, 150), -600, 170), -1485)
	
	var move_action := Move.new().init_by_target_pos(target_pos, general_movement_speed, general_movement_ease)
	var rotate_action := Rotate.new(general_rotation_speed, general_movement_ease).set_target_angle((target_pos - self.global_position).angle())
	actions.append(rotate_action)
	actions.append(move_action)
	
	return target_pos


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ATTACK MANAGEMENT FUNCIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func get_new_attack_num(max_number: int) -> int:
	var num: int
	while true:
		num = randi_range(1, max_number)
		if !last_attack_numbers.has(num): break
	last_attack_numbers.append(num)
	if last_attack_numbers.size() > ATTACK_COOLDOWN:
		last_attack_numbers.remove_at(0)
	return num


func append_phase_1_attack():
	var attack_number := get_new_attack_num(7)
	match attack_number:
		1, 6: append_dash_attack()
		2: append_aimed_shoot_attack()
		3: append_laser_attack(10, 1.5)
		4: append_spread_shoot_attack(randf_range(3.0, 8.0))
		5: append_fume_attack(randf_range(2.0, 5.0))
		7: append_aimed_fireball_attack(randf_range(3.7, 6.5))


func append_phase_2_attack():
	var attack_number := get_new_attack_num(14)
	match attack_number:
		1, 2, 3: append_dash_attack(3 * PI, 100, 0.7, 800)
		4: append_aimed_shoot_attack(5.0, 0.5)
		5: append_laser_attack(10, 1.0)
		6: append_spread_shoot_attack(randf_range(3.0, 8.0), 0.15, PI * 0.66)
		7: append_fume_attack(randf_range(2.0, 5.0))
		8: append_aimed_fireball_attack(randf_range(3.7, 6.5), 0.6, 3)
		9, 10, 11: append_spike_attack(1.5)
		12: append_bouncy_shoot_attack(randi_range(4, 7), 0.8, PI * 0.66)
		13: append_aimed_shoot_attack_2(5.0, 0.5)
		14: append_orb_attack()


func append_phase_3_attack():
	var attack_number := get_new_attack_num(6)
	match attack_number:
		1, 2, 3: append_dash_series_attack(randi_range(3, 4), 3 * PI, 100, 0.7, 800)
		# 4: append_aimed_fireball_attack(randf_range(3.7, 6.5), 0.6, 5, PI / 3)
		4: append_spike_attack(1.5, 2 * PI, 3, 1.5, true)
		5: append_spread_fireball_attack(randf_range(7.0, 9.0), 0.04, 2 * PI, 0.1, 0.4)
		6: append_aimed_shoot_attack_2(2.5, 0.1, PI / 8)
		# 6: append_chase_attack(20.0, 270, PI / 2, 0.1)


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# APPEND-X-ATTACK FUNCIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------


func append_dash_attack(rotation_speed: float = 2 * PI, charge_distance: float = 100,
charge_duration: float = 1.0, dash_speed: float = 650):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(SetVariable.new("look_at_player", false, eyes))
	actions.append(Rotate.new(rotation_speed))
	actions.append(Move.new().init_by_vector(Vector2(-absf(charge_distance), 0)).set_forced_duration(charge_duration))
	actions.append(PlaySound.new(dash_sound))
	actions.append(SetVariable.new("dashing", true))
	actions.append(PlayAnimation.new("open_mouth"))
	actions.append(Move.new().init_by_vector(Vector2(350, 0), dash_speed).append_args(["increase vector by distance to player"]))
	actions.append(SetVariable.new("dashing", false))
	actions.append(PlayAnimation.new("default"))
	actions.append(SetVariable.new("look_at_player", true, eyes))
	

func append_dash_series_attack(number: int, rotation_speed: float = 2 * PI, charge_distance: float = 100,
charge_duration: float = 1.0, dash_speed: float = 650):  # FOR PHASE 3
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(SetVariable.new("look_at_player", false, eyes))
	for n in number:
		actions.append(Rotate.new(rotation_speed))
		actions.append(Move.new().init_by_vector(Vector2(-absf(charge_distance), 0)).set_forced_duration(charge_duration))
		actions.append(PlaySound.new(dash_sound))
		actions.append(SetVariable.new("dashing", true))
		actions.append(PlayAnimation.new("open_mouth"))
		actions.append(Move.new().init_by_vector(Vector2(350, 0), dash_speed).append_args(["increase vector by distance to player"]))
		actions.append(SetVariable.new("dashing", false))
		actions.append(PlayAnimation.new("default"))
	actions.append(SetVariable.new("look_at_player", true, eyes))


# Casual, green laser projectiles
func append_aimed_shoot_attack(duration: float = 5.0, shoot_cooldown: float = 0.7, angular_velocity: float = PI / 2):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(Rotate.new(PI))
	actions.append(SetVariable.new("look_at_player", false, eyes))
	actions.append(AimedShootAttack.new(duration, laser_projectile_scene, shoot_cooldown, angular_velocity))
	actions.append(SetVariable.new("look_at_player", true, eyes))


# Green fireballs
func append_aimed_fireball_attack(duration: float, shoot_cooldown: float = 0.9,
projectiles_per_shoot: int = 3, spread_angle = PI / 4):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(Rotate.new(PI))
	# actions.append(AimedFireballAttack.new(randf_range(3.7, 6.5), 0.9))
	actions.append(AimedFireballAttack.new(duration, shoot_cooldown, projectiles_per_shoot, spread_angle))


# Green fireballs in phase 3
func append_spread_fireball_attack(duration: float, shoot_cooldown: float = 0.9,
angular_velocity: float = PI, rotate_ease: float = 0.1, wait_time: float = 0.4):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(CallFunc.new("set_eyes_color", [Color(0.637, 1, 0.48), 0.7], 0.0, eyes))
	actions.append(Wait.new(wait_time, true, PI * 0.5))
	actions.append(SpreadFireballAttack.new(duration, shoot_cooldown, angular_velocity, rotate_ease))
	actions.append(CallFunc.new("set_eyes_color", [Color.WHITE, 1.0], 0.0, eyes))


# Green laser projectiles but in random directions
func append_spread_shoot_attack(duration: float, shoot_cooldown: float = 0.2,
angular_velocity: float = PI / 2, shoot_cooldown_randomization: float = 0.1):
	append_growl_action()
	append_random_movement_action(["move to center"])
	append_growl_action()
	actions.append(SetVariable.new("look_at_player", false, eyes))
	# phase 1 duration: randf_range(3.0, 8.0)
	actions.append(SpreadShootAttack.new(duration, shoot_cooldown, angular_velocity, shoot_cooldown_randomization))
	actions.append(SetVariable.new("look_at_player", true, eyes))


# Bouncing red projectiles
func append_bouncy_shoot_attack(shots_number: float = 3, shoot_cooldown: float = 1.0, angular_velocity: float = PI * 0.66):
	append_growl_action()
	append_random_movement_action()
	actions.append(Rotate.new(PI))
	actions.append(BouncyShootAttack.new(shots_number, shoot_cooldown, angular_velocity))


# Yellow-green lasers which rotate and change directions after shooting
func append_aimed_shoot_attack_2(duration: float = 5.0, shoot_cooldown: float = 0.7, angular_velocity: float = PI / 2):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	actions.append(Rotate.new(PI))
	actions.append(SetVariable.new("look_at_player", false, eyes))
	actions.append(AimedShootAttack.new(duration, bouncy_projectile_scene, shoot_cooldown, angular_velocity))
	actions.append(SetVariable.new("look_at_player", true, eyes))



func append_laser_attack(duration: float = 10.0, min_warning_time: float = 1.0):
	append_growl_action()
	append_random_movement_action(["move to center"])
	append_growl_action()
	actions.append(ToggleParticleEmitter.new(eyes.get_node("CenterEye/Pupil/LaserParticles"), true))
	actions.append(SetVariable.new("lock_movement", true, eyes.center_eye.pupil))
	actions.append(Rotate.new(PI))
	actions.append(SetVariable.new("visible", true, laser_warn))
	actions.append(PlaySound.new(laser_charge_sound))
	actions.append(Wait.new(min_warning_time, true, PI / 16).add_args(["laser attack"]))
	actions.append(SetVariable.new("visible", false, laser_warn))
	actions.append(PlaySound.new(laser_shoot_sound))
	actions.append(LaserAttack.new(duration, PI / 3.0, 0.3, 0.1))
	actions.append(ToggleParticleEmitter.new(eyes.get_node("CenterEye/Pupil/LaserParticles"), false))
	actions.append(SetVariable.new("lock_movement", false, eyes.center_eye.pupil))


func append_fume_attack(duration: float, warning_time: float = 1.0, angular_velocity: float = PI / 3,
boss_speed: float = 120.0, shard_speed: float = 9.0):
	append_growl_action()
	append_random_movement_action()
	actions.append(SetVariable.new("look_at_player", false, eyes))
	actions.append(Rotate.new(PI))
	actions.append(FumeAttack.new(warning_time, PI / 2, 120.0, 4.0, 100.0))  # "warning" at the beginning of the attack
	actions.append(FumeAttack.new(duration, angular_velocity, boss_speed, shard_speed))
	actions.append(SetVariable.new("look_at_player", true, eyes))


func append_chase_attack(duration: float = 15.0, speed: float = 270.0, angular_velocity: float = PI / 2, ease: float = 0.1):
	append_growl_action()
	actions.append(Chase.new(duration, speed, angular_velocity, ease))


func append_spike_attack(warning_time: float = 1.5, rotation_speed: float = 2 * PI, repeats: int = 1,
repeat_buff_coeff: float = 1.5, with_spike_orb: bool = false):
	append_growl_action()
	append_random_movement_action()
	append_growl_action()
	var regen_time: float = 1.0
	var slide_out_time: float = 0.5
	for n in repeats:
		actions.append(Rotate.new(rotation_speed, 0.1).set_target_angle(randf_range(-PI, PI)))
		actions.append(CallFunc.new("show_spike_warnings"))
		if with_spike_orb: actions.append(CallFunc.new("eject_spike_orb"))
		actions.append(Wait.new(warning_time, false))
		actions.append(CallFunc.new("eject_spikes", [regen_time]))
		actions.append(Wait.new(0.5, false))
		if n == 0 && repeats > 1:
			rotation_speed *= repeat_buff_coeff
			warning_time *= 1 / repeat_buff_coeff
			regen_time = 0.1


func append_orb_attack() -> void:
	append_growl_action()
	var target_pos_1: Vector2 = append_random_movement_action()
	append_growl_action()
	var target_pos_2 := Vector2(randf_range(-700, 500), -1485)
	var move_action := Move.new().init_by_target_pos(target_pos_2, general_movement_speed * 0.66, general_movement_ease)
	var rotate_action := Rotate.new(general_rotation_speed, general_movement_ease).set_target_angle((target_pos_2 - target_pos_1).angle() + PI / 2)
	actions.append(rotate_action)
	actions.append(OrbAttack.new(move_action, 3))


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# FINAL CHASE FUNCIONS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func final_chase_setup():
	transitioning = false
	toggle_ground_collision(false)
	
	# Teleport the boss to the begin of the chase path
	var path_follow: PathFollow2D = %BossPathFollow
	assert(is_instance_valid(path_follow), "The Boss dikd not find a %BossPathFollow (PathFollow2D) in the scene tree to follow during the final chase.")
	self.get_parent().remove_child(self)
	path_follow.add_child(self)
	position = Vector2(0, 0)
	eyes.look_at_player = true
	eyes.look_forward = false
	process_mode = PROCESS_MODE_DISABLED


func start_final_chase(speed: float = 200.0) -> void:
	final_chase_phase = 1
	final_chase_min_speed = speed
	body_sprite.play("final_chase")

func process_path_follow(delta: float) -> void:
	var player_distance := (player.global_position - self.global_position).length()
	var current_speed := lerpf(final_chase_min_speed, final_chase_min_speed + FINAL_CHASE_MAX_SPEED_DIFF,
	clampf(player_distance / FINAL_CHASE_MAX_PLAYER_DISTANCE, 0.0, 1.0))
	
	var prev_progress := chase_path_follow.progress
	chase_path_follow.progress += delta * current_speed
	if prev_progress >= chase_path_follow.progress && final_chase_min_speed > 0: on_path_ended()

# It's not actually a signal but I don't know how else to call it
func on_path_ended() -> void:
	body_sprite.play("default")
	if game.player_won_chase:
		self.reparent(game, true)
		await Utils.pausable_timer(1.0).timeout
		actions.append(SetVariable.new("final_chase_phase", 2))
		actions.append(Move.new().init_by_target_pos(Vector2(10009, -2764), 150.0))
		actions.append(Wait.new(1.0))
		actions.append(Rotate.new(PI / 3).set_target_angle(deg_to_rad(-23)))
		append_growl_action()
		actions.append(Wait.new(1.0))
		actions.append(SetVariable.new("final_chase_phase", 3))
		actions.append(CallFunc.new("play_glass_hitting_animation", [], 0.0, game))
	elif chase_path_follow.get_parent() == failed_chase_path:  # If the finished path is the FailedChasePath
		self.reparent(game, true)
		actions.append(CallFunc.new("append_failed_chase_kill_action"))
	else:  # If the finished path is the primary chase path ("BossChasePath")
		game.boss_won_chase = true
		chase_path_follow.reparent(failed_chase_path, true)
		chase_path_follow.progress = 0

# Calls when the boss is in the middle of the Tesla control room to determine the direction and append the final Move action
func append_failed_chase_kill_action() -> void:
	if !(player as Player).alive: return
	if player.global_position.x < self.global_position.x && (player as Player).alive:
		actions.append(Rotate.new(PI).set_target_angle(-PI))
		actions.append(Move.new().init_by_target_pos(Vector2(10603, -2955), 220.0))
	else:
		actions.append(Rotate.new(PI).set_target_angle(0.0))
		actions.append(Move.new().init_by_target_pos(Vector2(10895, -2955), 220.0))


func _on_player_death() -> void:
	if final_chase_phase >= 1:
		get_tree().create_tween().tween_property(self, "final_chase_min_speed", 0.0, 1.0)
		actions.clear()
		next_action()
		if body_sprite.animation == "final_chase": body_sprite.play("default")

func append_failed_tesla_kill_action_1() -> void:
		final_chase_phase = 4
		var move := Move.new().init_by_target_pos(Vector2(10791, -2953), 230.0, 0.0)
		var rotate := Rotate.new(PI).set_target_angle(0.0)
		actions.append(MoveAndRotate.new(move, rotate, true))
		actions.append(CallFunc.new("append_failed_tesla_kill_action_2"))

# Calls after the boss breaks the glass and enters the tesla room
func append_failed_tesla_kill_action_2() -> void:
	if !(player as Player).alive: return
	elif player.global_position.x > 10860:  # top of the control room
		actions.append(Move.new().init_by_target_pos(Vector2(10900, -2953), 230.0, 0.0))
	else:  # downstairs
		actions.append(Rotate.new(PI).set_target_angle(PI / 2))
		actions.append(Move.new().init_by_target_pos(Vector2(10791, -2763), 200.0, 0.2))
		actions.append(Rotate.new(PI).set_target_angle(-PI))
		actions.append(Move.new().init_by_target_pos(Vector2(10605, -2763), 200.0, 0.2))


func _on_ending_sequence_start() -> void:
	self.collision_layer = 0
	teeth.collision_layer = 0
	eyes.process_mode = Node.PROCESS_MODE_DISABLED
	for spike in get_tree().get_nodes_in_group("boss_spikes") as Array[BossSpike]:
		spike.process_mode = Node.PROCESS_MODE_DISABLED
	for hair in get_node("Hair").get_children() as Array[AnimatedSprite2D]:
		hair.process_mode = Node.PROCESS_MODE_DISABLED
	health_bar.visible = false
	phase_3_anim_player.stop(true)
