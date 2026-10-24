class_name Player
extends CharacterBody2D


const SPEED = 60.0
const BACKWARDS_SPEED = 60.0
var ROLL_SPEED = 85.0
const JUMP_VELOCITY = -440
const FRICTION = 0.2
const LATE_JUMP_TOLERANCE = 0.075
const MEDKIT_COOLDOWN := 20.0
const MEDKIT_HEAL := 35.0
const ONE_WAY_COLLISON_DISABLED_TIME = 0.2
const ONE_WAY_COLLISON_LAYER = 4
const MAX_CLIMB_ANGLE = deg_to_rad(45)
const ROLL_TIME: float = 1.0
var ROLL_COOLDOWN: float = 2.0
const DAMAGE_PARTICLES_AMOUNT := 5
var KNOCKBACK_X: float = 3000
var KNOCKBACK_Y: float = 600
const RAGDOLL_VELOCITY_COEFFICIENT := 0.25
const RAGDOLL_ANGULAR_VELOCITY_COEFFICIENT := 0.03

const ARM_POSITIONS := {
	"idle":
		[
			# FIRST (0) - FRONT ARM;  SECOND (1) - BACK ARM
			[Vector2(-7.25, -13.372), Vector2(2.862, -13.196)],
			[Vector2(-7.25, -14.222), Vector2(2.862, -14.46)],
			[Vector2(-7.25, -12.522), Vector2(2.862, -12.346)],
			[Vector2(-7.25, -12.522), Vector2(2.862, -12.346)],
		],
	"jump_down":
		[
			[Vector2(-4.695, -16.774), Vector2(3.715, -14.9)],
		],
	"jump_up":
		[
			[Vector2(-1.294, -15.92), Vector2(6.272, -14.898)],
		],
	"walk":
		[
			[Vector2(1.262, -13.369), Vector2(5.437, -13.18)],
			[Vector2(2.968, -14.225), Vector2(4.575, -13.182)],
			[Vector2(6.389, -15.928), Vector2(4.583, -15.729)],
			[Vector2(5.509, -13.361), Vector2(4.575, -13.2)],
			[Vector2(4.668, -10.831), Vector2(2.863, -12.34)],
			[Vector2(4.668, -12.52), Vector2(2.865, -13.185)],
			[Vector2(2.949, -14.212), Vector2(2.865, -14.058)],
			[Vector2(2.105, -14.22), Vector2(4.569, -14.061)],
		],
}

# [0]: gun pivot x, [1]: gun x
const GUN_OFFSETS := {
	"idle": [-7, 14],  # "idle": [-7, 14]
	"jump_down": [0, 10],
	"jump_up": [5, 10],
	"walk": [6, 10],
}

var frame_bitmap_sizes := {}

@export var camera: Camera
@export var health_bar: TextureRect
@export var medkit_indicator: TextureProgressBar
@export var roll_indicator: TextureProgressBar
@export var boss: Boss
@export var damage_overlay: ColorRect
@export var rescale_on_flip: Array[Node2D]

@onready var animated_sprite_default: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_with_arms: AnimatedSprite2D = $ArmsAnimatedSprite2D
var animated_sprite: AnimatedSprite2D:
	get:
		if has_gun: return animated_sprite_default
		else: return animated_sprite_with_arms

@onready var front_arm: PlayerArm = $FrontArm
@onready var back_arm: PlayerArm = $BackArm
@onready var gun: Gun = $GunPivot/Gun
@onready var death_restart: Timer = $DeathRestart
@onready var laser_damage_cooldown: Timer = $DamageHitbox/LaserDamageCooldown
@onready var fume_damage_cooldown: Timer = $DamageHitbox/FumeDamageCooldown
@onready var collision_damage_cooldown: Timer = $DamageHitbox/CollisionDamageCooldown
@onready var base_collision_shape: CollisionShape2D = $BaseCollisionShape
@onready var walk_collision_shape: CollisionShape2D = $WalkCollisionShape
@onready var projectile_destruction_shape: CollisionPolygon2D = $ProjectileDestructionArea/ProjectileDestructionShape
@onready var damage_shape: CollisionPolygon2D = $DamageHitbox/DamageShape
@onready var damage_hitbox: Area2D = $DamageHitbox
@onready var roll_damage_shape: CollisionShape2D = $DamageHitbox/RollShape
@onready var roll_collision_shape: CollisionShape2D = $RollCollisionShape
@onready var roll_reset_block_hitbox: Area2D = $RollResetBlockHitbox
@onready var projectile_destruction_hitbox: StaticBody2D = $ProjectileDestructionArea

var ragdoll: Node2D = null
var ragdoll_scene := preload("res://scenes/player_ragdoll.tscn")
var flipped_ragdoll_scene := preload("res://scenes/player_ragdoll_flipped.tscn")
var damage_particles_scene := preload("res://scenes/hp_minus.tscn")
var heal_particles_scene := preload("res://scenes/hp_plus.tscn")


@onready var walking_sound: AudioStreamPlayer = $WalkingSound
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var heal_sound: AudioStreamPlayer = $HealSound
var min_sound_pitch := 0.8
var max_sound_pitch := 1.3

signal under_magnet(gun: Node2D)
signal death()

var time_in_air: float = 0.0
var roll_time_left := 0.0
var roll_phase := 0  # When above 0, a roll is in progress. It will only go above 1 when the player is stuck
var jumped := false
var direction: float
var walking_backwards := false
var animation_speed_scale: float
var has_gun := true
var flipped := false

const MAX_HEALTH: float = 100
const HEALTH_BAR_FLASH_THRESHOLD: float = 30
var health := MAX_HEALTH
var health_effect := health
var health_bar_color_1 := Color(0.302, 1.0, 0.494, 1.0)
var health_bar_color_2 := Color(1.0, 0.039, 0.059, 1.0)
var health_bar_flash_timer := 0.0

var sprite_flash_effect := 1.0  # 1.0 is the neutral (disabled) value
var sprite_flash_color := Color.WHITE
const SPRITE_FLASH_REDUCTION := 5.0

var screen_flash_effect := 0.0  # 0.0 is the neutral (disabled) value
const SCREEN_FLASH_STRENGTH := 0.5
const SCREEN_FLASH_REDUCTION = 0.1

var medkit_cooldown_time_left := MEDKIT_COOLDOWN
var roll_cooldown_left := ROLL_COOLDOWN

var movement_locked := false
var go_down_locked := false
var alive := true


func _ready() -> void:
	#has_gun = false
	#change_sprite(true)
	#gun.queue_free()
	
	animation_speed_scale = animated_sprite.speed_scale
	generate_collision_polygons()


func _process(delta: float) -> void:
	update_health_bar(delta)

	# Handle sprite flash effect
	if abs(sprite_flash_effect - 1.0) > 0.02:
		sprite_flash_effect -= (sprite_flash_effect - 1.0) * SPRITE_FLASH_REDUCTION * delta
		var col := Color.WHITE.lerp(sprite_flash_color * sprite_flash_effect, sprite_flash_effect - 1.0)
		animated_sprite.self_modulate = col
		if has_gun:
			front_arm.modulate = col
			back_arm.modulate = col
	else:
		sprite_flash_effect = 1.0
		animated_sprite.self_modulate = Color.WHITE
		if has_gun:
			front_arm.modulate = Color.WHITE
			back_arm.modulate = Color.WHITE
	
	# Handle screen flash effect
	if damage_overlay:
		screen_flash_effect = maxf(0.0, screen_flash_effect - (screen_flash_effect * SCREEN_FLASH_REDUCTION))
		damage_overlay.modulate.a = screen_flash_effect
	
	if alive:
		handle_medkit(delta)
		handle_roll_time(delta)
		
		# Get flip - during roll
		if roll_phase > 0:
			flipped = direction < 0
		elif has_gun:  # get flip - if the player is not rolling and has gun
			flipped = gun.get_flipped()
		# If the player has no gun, flip is handled in physics_process
		
		# set flip
		if has_gun:
			front_arm.set_flipped(flipped)
			back_arm.set_flipped(flipped)
		if (animated_sprite.flip_h != flipped):
			animated_sprite.flip_h = flipped
			_on_sprite_frame_changed()
			for node in rescale_on_flip:
				node.scale.x *= -1
				node.position.x *= -1
		
		# change the speed scale if the player is moving backwards
		if walking_backwards:
			animated_sprite.speed_scale = (BACKWARDS_SPEED / SPEED) * animation_speed_scale
		else:
			animated_sprite.speed_scale = animation_speed_scale
		
		# Handle animations
		var previous_anim := animated_sprite.animation
		if roll_phase > 0:
			animated_sprite.play("roll")
		elif is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			elif walking_backwards:
				animated_sprite.play_backwards("walk")
			else:
				animated_sprite.play("walk")
		else:
			if velocity.y < 0:
				animated_sprite.play("jump_up")
			else:
				animated_sprite.play("jump_down")
		
		# This is called by a signal when the frame is changed, but not when animation changes with the same frame index,
		# so that's why it's here
		if animated_sprite.animation != previous_anim: _on_sprite_frame_changed()

		# Handle walking sound
		if animated_sprite.animation == "walk" && animated_sprite.frame % 4 == 0:
			walking_sound.pitch_scale = randf_range(min_sound_pitch, max_sound_pitch)
			walking_sound.play()
		
		# Handle shooting
		if Input.is_action_pressed("shoot") && !movement_locked && roll_phase == 0 && has_gun:
			gun.fire()
		
	else:
		velocity = Vector2.ZERO
		global_position = ragdoll.get_node("Container/Head").global_position
		if has_gun && gun.visible: gun.visible = false


func _physics_process(delta: float) -> void:
	if !alive:
		direction = 0 
		return
	# check_under_magnet()
	
	var on_floor := is_on_floor()
	if on_floor:
		time_in_air = 0
		jumped = false
		toggle_one_way_platform_collision(true)
	else: 
		# Add the gravity
		time_in_air += delta
		velocity += get_gravity() * delta
		# Reset roll in air, but don't try this when the player is stuck
		# if roll_phase == 1: reset_roll()


	# Handle jump
	if (Input.is_action_pressed("jump") && !movement_locked && time_in_air < LATE_JUMP_TOLERANCE && !jumped &&
	!(roll_reset_block_hitbox.get_overlapping_bodies().size() > 0 && roll_phase > 0)):  # Block jump while rolling with area obstructed
		velocity.y = JUMP_VELOCITY
		jump_sound.pitch_scale = randf_range(min_sound_pitch, max_sound_pitch)
		jump_sound.play()
		jumped = true
		reset_roll()
	# Fall from one way platform
	elif Input.is_action_pressed("go_down") && !movement_locked && !go_down_locked && on_floor:
		toggle_one_way_platform_collision(false)
	# Restore one way platform collision
	elif time_in_air > ONE_WAY_COLLISON_DISABLED_TIME:
		toggle_one_way_platform_collision(true)

	# Get the input direction and handle the movement, flip (if the player has no gun) and roll
	if roll_phase < 1:  # direction isn't overwritten when the player is rolling
		direction = Input.get_axis("move_left", "move_right")
		if movement_locked: direction = 0

		# FLIPPING WITHOUT THE GUN
		if !has_gun && direction > 0.1:  
			flipped = false
		elif !has_gun && direction < -0.1:
			flipped = true
			
		# START ROLL
		if Input.is_action_just_pressed("roll") && !movement_locked && roll_cooldown_left <= 0.0:
			roll_time_left = ROLL_TIME
			roll_cooldown_left = ROLL_COOLDOWN
			roll_phase = 1
			roll_indicator.value = 0.0
			jump_sound.play()
			if abs(direction) >= 0.5:  # if the player is moving in a specified direction, roll in this direction
				direction = clampf(direction, -0.1, 0.1) * 10  # result: -1 or 1
			elif flipped:  # else, roll in the direction the sprite is looking in
				direction = -1
			else:
				direction = 1
	elif roll_phase == 1 && Input.get_axis("move_left", "move_right") * direction < 0:  # reset roll if opposite +- signs (directions)
		reset_roll()
	
	walking_backwards = ((direction < 0 && !flipped)
	|| (direction > 0 && flipped))
	
	# Move
	if (walking_backwards):
		velocity.x += direction * BACKWARDS_SPEED
	elif roll_phase > 0:
		velocity.x += direction * ROLL_SPEED
	else:
		velocity.x += direction * SPEED
	velocity.x *= (1 - FRICTION)

	handle_boss_collision()
	move_and_slide()
	if has_gun: gun.handle_rotation(delta, global_position, direction)


func handle_boss_collision() -> void:
	var touching_boss := false
	var touching_boss_spike := false
	var touching_boss_teeth := false
	for object in (damage_hitbox.get_overlapping_areas() + damage_hitbox.get_overlapping_bodies()):
		if object is Boss:
			touching_boss = true
		elif object is BossTeeth:
			touching_boss_teeth = true
		elif object is BossSpike:
			touching_boss_spike = true
	
	if boss && boss.is_inside_tree() && alive && (touching_boss || touching_boss_teeth || touching_boss_spike) && collision_damage_cooldown.time_left == 0:
		var direction := (self.global_position - boss.global_position).normalized()
		print("adding knockback!")
		velocity.x += direction.x * KNOCKBACK_X
		velocity.y += direction.y * KNOCKBACK_Y
		print("velocity: ", velocity.x, ", ", velocity.y);
		toggle_one_way_platform_collision(false)
		
		if boss.final_chase_phase >= 1:
			boss.body_sprite.play("bite")
			boss.body_sprite.frame = 1
			AudioManager.music_transition("", 1.0)
			die()
		elif boss.dashing:
			var damage: float
			if touching_boss_teeth:
				damage = 50
				boss.body_sprite.play("bite")
				boss.body_sprite.frame = 1
			elif boss.phase == 1:
				damage = 25.0
			elif boss.phase >= 2:
				damage = 35.0
			
			if boss.collided_during_dash:
				damage *= 0.66
			change_health(-damage)
		else:
			var damage: float
			if boss.phase == 1 && !touching_boss_teeth: damage = 5.0
			elif boss.phase == 1 && touching_boss_teeth: damage = 30.0
			elif boss.phase >= 2 && !touching_boss_teeth: damage = 20.0
			elif boss.phase >= 2 && touching_boss_teeth: damage = 35.0
			
			if touching_boss_teeth:
				boss.body_sprite.play("bite")
			
			change_health(-damage)
		
		collision_damage_cooldown.start()


func handle_roll_time(delta: float) -> void:
		roll_time_left = maxf(roll_time_left - delta, 0.0)  # Decrease roll time
		if roll_phase > 0 && roll_time_left == 0.0:  # Reset roll
			reset_roll()
		elif roll_phase == 0:  # Process roll cooldown
			roll_cooldown_left = maxf(roll_cooldown_left - delta, 0.0)
			if roll_indicator: roll_indicator.value = (ROLL_COOLDOWN - roll_cooldown_left) / ROLL_COOLDOWN

# Tries to prevent the player from getting stuck after rolling
func reset_roll() -> void:
	if roll_reset_block_hitbox.get_overlapping_bodies().size() > 0 && roll_phase >= 1 && alive:
		roll_phase += 1
		if roll_phase == 2:
			roll_time_left = ROLL_TIME
		elif roll_phase == 3:
			direction *= -1
			roll_time_left = ROLL_TIME
		elif roll_phase == 4 || roll_phase == 5:
			roll_time_left = ROLL_TIME
		else:
			die()
	else:
		roll_time_left = 0.0
		roll_phase = 0


func update_health_bar(delta: float) -> void:
	if health_effect > health:
		health_effect = clamp(health_effect - MAX_HEALTH * delta * 0.4, health, MAX_HEALTH)
	elif health_effect < health:
		health_effect = clamp(health_effect + MAX_HEALTH * delta * 0.4, 0, health)
	
	if health_bar:
		var color := health_bar_color_1.lerp(health_bar_color_2, 1.0 - health / MAX_HEALTH)
		
		if health <= HEALTH_BAR_FLASH_THRESHOLD:  # Add flash effect
			var sprite_flash_color := color.lerp(Color(0.9, 0.9, 0.9, 1.0), 0.7)
			
			var speed_coeff := clampf(lerpf(3.0, 1.0, (health - 5) / (HEALTH_BAR_FLASH_THRESHOLD - 5)), 0.7, 1.0)
			health_bar_flash_timer += delta * 2 * PI * speed_coeff
			
			var weight := (cos(health_bar_flash_timer) + 1) / 2.0
			color = color.lerp(sprite_flash_color, weight)


		health_bar.self_modulate = color
		health_bar.get_node("Fill").self_modulate = color
		var fill_material = health_bar.get_node("Fill").material
		if fill_material is ShaderMaterial:
			fill_material.set_shader_parameter("white_fill", max(health / MAX_HEALTH, health_effect / MAX_HEALTH))
			fill_material.set_shader_parameter("fill", min(health / MAX_HEALTH, health_effect / MAX_HEALTH))

func handle_medkit(delta: float) -> void:
	if medkit_cooldown_time_left > 0.0:
		medkit_cooldown_time_left -= delta
	elif Input.is_action_just_pressed("heal") && health < MAX_HEALTH:  # USE MEDKIT / HEAL
		medkit_cooldown_time_left = MEDKIT_COOLDOWN
		change_health(MEDKIT_HEAL)
		heal_sound.play()
		var pe := heal_particles_scene.instantiate() as GPUParticles2D
		pe.global_position = self.global_position
		GameManager.game.add_child(pe)
	
	if medkit_indicator:
		medkit_indicator.value = (MEDKIT_COOLDOWN - medkit_cooldown_time_left) / MEDKIT_COOLDOWN

func change_health(amount: float) -> void:
	if amount < 0:
		set_sprite_flash_effect(4.0, Color.RED)
		screen_flash_effect = SCREEN_FLASH_STRENGTH
		for n in DAMAGE_PARTICLES_AMOUNT:
			var particle := damage_particles_scene.instantiate() as GPUParticles2D
			particle.global_position = self.global_position
			particle.global_rotation = randf_range(-PI, PI)
			GameManager.game.add_child.call_deferred(particle)
		if !boss.alive:
			return
	health = min(health + amount, MAX_HEALTH)
	set_low_health_effect(health)
	if health <= 0.0:
		die()
		health = 0.0

func set_low_health_effect(health: float) -> void:
	var value: float
	if health >= 50: value = 0
	elif health > 10: value = lerpf(1.0, 0.0, (health - 10) / 40)
	elif health > 0: value = 1
	else: value = 0
	camera.set_low_hp_effect(value)


func die() -> void:
	if health > 0: 
		change_health(-MAX_HEALTH)
		return  # return, because change_health will call die() again
	
	if alive:
		if flipped:
			ragdoll = flipped_ragdoll_scene.instantiate()
		else:
			ragdoll = ragdoll_scene.instantiate()
		ragdoll.position = position
		ragdoll.rotation = rotation
		GameManager.game.call_deferred("add_child", ragdoll)
		# Ragdoll knockback
		var ragdoll_velocity := self.velocity * RAGDOLL_VELOCITY_COEFFICIENT
		for child in Utils.get_children_recursive(ragdoll, "RigidBody2D") as Array[RigidBody2D]:
			child.linear_velocity = ragdoll_velocity
			child.angular_velocity = ragdoll_velocity.x * RAGDOLL_ANGULAR_VELOCITY_COEFFICIENT
		collision_layer = 0
		collision_mask = 0
		visible = false
		death.emit()
	alive = false
	set_deferred("projectile_destruction_shape.disabled", true)
	set_deferred("damage_shape.disabled", true)
	if death_restart.is_stopped():
		death_restart.start()




func restart_game():
	var scene := load("res://scenes/game.tscn")
	AudioManager.reset()
	get_tree().change_scene_to_packed(scene)


func set_sprite_flash_effect(value: float, color: Color = Color.WHITE) -> void:
	sprite_flash_effect = value
	sprite_flash_color = color


func toggle_one_way_platform_collision(value: bool = false):
	if value:
		self.collision_mask |= 1 << (ONE_WAY_COLLISON_LAYER - 1)
	else:
		self.collision_mask &= ~(1 << (ONE_WAY_COLLISON_LAYER - 1))


func _on_damage_hitbox_area_entered(area: Area2D) -> void:
	if !alive: return
	
	if area is Projectile && !(area is PlayerProjectile || area is BossFume):
		change_health(-area.DAMAGE)
		area.destroy()
	elif area.get_parent() && area.get_parent().get_parent() is SpikeOrb:
		var orb: SpikeOrb = area.get_parent().get_parent()
		if !orb.destroyed:
			change_health(-25)
			orb.destroy()
	elif area is BossSpikeProjectile:
		change_health(-25)
	elif area is BossLaser:
		if laser_damage_cooldown.time_left <= 0 || laser_damage_cooldown.is_stopped():
			change_health(-30)
			laser_damage_cooldown.start()
	elif area is BossFume:
		if fume_damage_cooldown.time_left <= 0 || fume_damage_cooldown.is_stopped():
			change_health(-area.DAMAGE)
			fume_damage_cooldown.start()
			area.destroy()


func _on_damage_hitbox_body_entered(body: Node2D) -> void:
	if body is SpikeOrb:
		change_health(-25)
		body.destroy()


func _on_death_restart_timeout() -> void:
	GameManager.start_game()


func generate_collision_polygons() -> void:
	var sf: SpriteFrames = animated_sprite.sprite_frames
	for anim_name in sf.get_animation_names():
		if anim_name == "roll": continue
		for frame_num in sf.get_frame_count(anim_name):
			var group_name := "player_polygon_" + anim_name + str(frame_num)
			
			var texture := animated_sprite.sprite_frames.get_frame_texture(anim_name, frame_num)
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(texture.get_image())
			var bm_size := bitmap.get_size()
			frame_bitmap_sizes[group_name] = bm_size
			
			var polys = bitmap.opaque_to_polygons(Rect2(Vector2i.ZERO, texture.get_size()), 1.0)
			for poly in polys:
				add_collision_polygon(poly, group_name, damage_hitbox)
				add_collision_polygon(poly, group_name, projectile_destruction_hitbox)


func add_collision_polygon(poly: PackedVector2Array, group_name: String, parent: Node2D) -> void:
	var collision_polygon := CollisionPolygon2D.new()
	collision_polygon.polygon = poly
	collision_polygon.z_index = 1000
	collision_polygon.scale = animated_sprite.scale
	collision_polygon.add_to_group("player_polygon")
	collision_polygon.add_to_group(group_name)
	parent.add_child(collision_polygon)
	collision_polygon.position += animated_sprite.position
	if animated_sprite.centered:
		collision_polygon.position -= (Vector2(frame_bitmap_sizes[group_name]) * animated_sprite.scale / 2)


# Changes collision polygons and positions that are custom for each animation frame
func _on_sprite_frame_changed() -> void:
	if animated_sprite.animation == "roll":
		roll_damage_shape.set_deferred("disabled", false)
		roll_collision_shape.set_deferred("disabled", false)
		base_collision_shape.set_deferred("disabled", true)
		if has_gun:
			gun.visible = false
			front_arm.visible = false
			back_arm.visible = false
	else:
		roll_damage_shape.set_deferred("disabled", true)
		roll_collision_shape.set_deferred("disabled", true)
		base_collision_shape.set_deferred("disabled", false)
		
		if has_gun:
			front_arm.visible = true
			back_arm.visible = true
			# gun pos
			gun.visible = true
			gun.pivot_pos_x = GUN_OFFSETS[animated_sprite.animation][0]
			gun.position.x = GUN_OFFSETS[animated_sprite.animation][1]
			# arms pos
			front_arm.set_local_pos(ARM_POSITIONS[animated_sprite.animation][animated_sprite.frame][0])
			back_arm.set_local_pos(ARM_POSITIONS[animated_sprite.animation][animated_sprite.frame][1])
	
	# walk collision polygon
	walk_collision_shape.set_deferred("disabled", animated_sprite.animation != "walk")
	
	# damage polygons, projectile dectruction polygons for each animation frame
	var group_name := "player_polygon_" + animated_sprite.animation + str(animated_sprite.frame)
	for polygon in get_tree().get_nodes_in_group("player_polygon") as Array[CollisionPolygon2D]:
		polygon.set_deferred("disabled", true)
		polygon.visible = false
	for polygon in get_tree().get_nodes_in_group(group_name) as Array[CollisionPolygon2D]:
		polygon.position = -(Vector2(frame_bitmap_sizes[group_name]) * animated_sprite.scale / 2) + animated_sprite.position
		polygon.set_deferred("disabled", false)
		polygon.visible = true


func change_sprite(new_with_arms: bool):
	var old_sprite: AnimatedSprite2D
	var new_sprite: AnimatedSprite2D
	var moving_arms_mode: ProcessMode
	var moving_arms_visibility: bool
	if new_with_arms:
		old_sprite = animated_sprite_default
		new_sprite = animated_sprite_with_arms
		moving_arms_mode = PROCESS_MODE_DISABLED
		moving_arms_visibility = false
	else:
		old_sprite = animated_sprite_with_arms
		new_sprite = animated_sprite_default
		moving_arms_mode = PROCESS_MODE_INHERIT
		moving_arms_visibility = true
	new_sprite.process_mode = Node.PROCESS_MODE_INHERIT
	new_sprite.animation = old_sprite.animation
	new_sprite.set_frame_and_progress(old_sprite.frame, old_sprite.frame_progress)
	old_sprite.process_mode = Node.PROCESS_MODE_DISABLED
	old_sprite.visible = false
	new_sprite.visible = true
	# Disable the moving arms
	for arm in [front_arm, back_arm] as Array[Node2D]:
		arm.process_mode = moving_arms_mode
		arm.visible = moving_arms_visibility


#func check_under_magnet() -> void:
	#if has_gun && position.x > magenetic_arm_x:
		#reset_roll()
		#gun.visible = true
		#under_magnet.emit(gun)
		#movement_locked = true
		#has_gun = false
		#change_sprite(true)
