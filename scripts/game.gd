class_name Game
extends Node2D

# MAIN
@export var global_sounds_node: Node
@export var dialogue_label: Node
@export var camera: Camera
@export var player: Player
@export var boss: Boss
@export var section_manager: SectionManager
@export var pause_ui: PauseUI
@export var boss_ending_animation: BossEndingAnimation

# BIODOME
@export var fire_sprinklers_parent: Node
@export var entrance_door: Door
@export var exit_door: Door
@export var player_exit_block: PhysicsBody2D
@export var exit_indicator: Node2D

# TESLA ROOM
@export var hide_on_player_at_control_panel: Array[CanvasItem]
@export var glass_crack_sound: AudioStreamPlayer2D
@export var glass_break_sound: AudioStreamPlayer
@export var glass_hitting_anim: AnimationPlayer
@export var glass_break_particles: GPUParticles2D
@export var glass_body: Node2D
var color_overwrite_shader := preload("res://scripts/shaders/color_overwrite.gdshader")

# BIODOME
var lockdown_deactivated := false
var exit_blocked := true

# CHASE + ENDING
var player_won_chase := false
var boss_won_chase := false
var tesla_activated := false
var glass_destroyed := false
var glass_durability := 7
@export var boss_touching_glass := false
var environment_bus_index: int
var environment_bus_volume: float = NAN

# TESLA ROOM
signal player_at_control_panel()
signal tesla_minigame_failed()
signal ending_sequence_start()
signal tesla_shutdown()
signal ending_text_start()


func _enter_tree() -> void:
	GameManager.set_game_node(self)


func _ready() -> void:
	AudioManager.set_global_sounds_node(global_sounds_node)
	AudioManager.music_transition("Music", 0.0)
	DialogueManager.setup(dialogue_label)
	await Utils.pausable_timer(3.0).timeout
	activate_lockdown()


func _process(delta: float) -> void:
	# BIODOME
	if lockdown_deactivated && exit_blocked && (player.global_position - boss.global_position).x < -800.0:
		disable_exit_block()


func _on_pause_button_pressed() -> void:
	if pause_ui.lock_pause: return
	AudioManager.play("MenuButton")
	pause_ui.paused = true


# ------------------------------------------------------------------------------------------------------------------------------------------------------
# BIODOME EVENTS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func activate_fire_sprinklers(time: float = 7.0) -> void:
	if !fire_sprinklers_parent: return
	AudioManager.play("FireSprinklers")
	for child in fire_sprinklers_parent.get_children(): 
		var emitter = child.get_node_or_null("ParticleEmitter")
		if emitter:
			emitter.emitting = true
	await Utils.pausable_timer(2.0).timeout # 2 seconds before the fadeout begins (subtracted in the next wait times)
	var fadeout_tween := get_tree().create_tween().set_parallel(true)
	for emitter in get_tree().get_nodes_in_group("fire_emitters") as Array[Node2D]:
		var col := emitter.modulate
		col.a = 0.0
		fadeout_tween.tween_property(emitter, "modulate", col, maxf(time - 2.0, 0.0))
	await Utils.pausable_timer(maxf(time - 2.0, 0.0)).timeout
	for child in fire_sprinklers_parent.get_children(): 
		var emitter = child.get_node_or_null("ParticleEmitter")
		if emitter:
			emitter.emitting = false
	for node in get_tree().get_nodes_in_group("fire_emitters"):
		node.queue_free()
	await Utils.pausable_timer(3.0).timeout
	for child in fire_sprinklers_parent.get_children(): 
		var emitter = child.get_node_or_null("ParticleEmitter")
		if emitter:
			emitter.visible = false

# At the begin of the fight
func activate_lockdown() -> void:
	entrance_door.close()
	exit_door.close()
	AudioManager.play("LockdownActivatedAnn")
	DialogueManager.display("[ANNOUNCER]: Biodome lockdown activated.")

# At the end of the fight
func deactivate_lockdown() -> void:
	AudioManager.play("LockdownDeactivatedAnn")
	DialogueManager.display("[ANNOUNCER]: Lockdown deactivated.")
	AudioManager.music_transition("ChaseMusic1", 4.0)
	entrance_door.open()
	exit_door.open()
	lockdown_deactivated = true
	await Utils.pausable_timer(5.0).timeout
	DialogueManager.display("[YOU]: I need to get him!")

func disable_exit_block() -> void:
	player_exit_block.process_mode = Node.PROCESS_MODE_DISABLED
	exit_blocked = false
	# Exit indicator
	exit_indicator.visible = true
	exit_indicator.modulate = Color(1, 1, 1, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(exit_indicator, "modulate", Color.WHITE, 1.0)

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# CHASE EVENTS
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func _on_magnet_area_body_entered(body: Node2D) -> void:
	if body is not Player || !player.has_gun: return
	# player setup
	var gun := player.gun
	player.reset_roll()
	player.gun.visible = true
	player.movement_locked = true
	player.has_gun = false
	player.change_sprite(true)
	
	# gun reparent
	var prev_global_transform := gun.global_transform
	gun.set_script(null)
	gun.get_parent().remove_child(gun)
	var storage := section_manager.get_section("STORAGE")
	if (storage): storage.add_child(gun)
	gun.global_transform = prev_global_transform
	# gun animation
	var tween := get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_IN)
	tween.tween_property(gun, "global_position", Vector2(3677, -1577), 0.8)
	tween.tween_property(gun, "global_rotation_degrees", -168.6, 0.8)
	if (camera): camera.fly_to_pos(Vector2(3647, -1498), 1.0)
	await Utils.pausable_timer(0.8).timeout
	AudioManager.play("MetalHit")
	AudioManager.music_transition("", 0.0)
	AudioManager.stop("FireAlarm")
	await Utils.pausable_timer(2.5).timeout
	# boss animation and setup
	if (camera): camera.fly_to_pos(Vector2(3231, -1305), 1.5)
	await Utils.pausable_timer(3.0).timeout
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	boss.start_final_chase(40.0)
	boss.play_phase_roar()
	await Utils.pausable_timer(1.0).timeout
	AudioManager.music_transition("ChaseMusic2", 0.0)
	DialogueManager.display("[YOU]: Run!")
	await Utils.pausable_timer(1.5).timeout
	get_tree().create_tween().tween_property(boss, "final_chase_min_speed", boss.DEFAULT_FINAL_CHASE_MIN_SPEED, 1.0)
	if (camera): camera.fly_to_follow_node(0.5)
	await Utils.pausable_timer(0.5).timeout
	if player:
		player.movement_locked = false
		player.ROLL_COOLDOWN = 0.5
		player.ROLL_SPEED = player.SPEED
	section_manager.remove_oldest()

# ------------------------------------------------------------------------------------------------------------------------------------------------------
# ENDING EVENTS (ordered by the expected time of the first call during gameplay)
# ------------------------------------------------------------------------------------------------------------------------------------------------------

func on_player_won_chase() -> void:
	player_won_chase = true
	AudioManager.music_transition("EndingMusic1", 8.0)

func _on_player_at_control_panel_area() -> void:
	if boss_won_chase: return
	section_manager.remove_oldest()
	player_at_control_panel.emit()
	player.movement_locked = true
	for node in hide_on_player_at_control_panel:
		Utils.fade_out_object(node, 1.0)

func play_glass_hitting_animation() -> void:
	if glass_hitting_anim:
		glass_hitting_anim.process_mode = Node.PROCESS_MODE_INHERIT
		glass_hitting_anim.play.call_deferred("hit_glass")
	else: push_warning("No glass hitting animation!")

func _on_tesla_activated() -> void:
	tesla_activated = true
	AudioManager.play("TeslaActivationAlarm", true)
	player.movement_locked = false
	if boss_touching_glass:
		ending_sequence()

func crack_glass() -> void:
	glass_durability -= 1
	if tesla_activated && !glass_destroyed:  # player won the game
		ending_sequence()
		camera.set_low_hp_effect(0.0)
	elif glass_durability == 0:  # player lost on the final minigame
		break_glass()
		camera.set_low_hp_effect(0.0)
	else:  # when minigame is still in progress
		glass_crack_sound.volume_db += 1.5
		glass_crack_sound.pitch_scale += 0.15
		glass_crack_sound.play()
		if (glass_durability <= 3):  # blur for extra intensity
			camera.set_low_hp_effect(2.0 / glass_durability)
		camera.shake_effect(
			pow(8.0 - min(glass_durability, 5.5), 2.0) / 5.0,
			1.0)

func break_glass() -> void:
	glass_destroyed = true
	glass_break_sound.play()
	player.movement_locked = false
	glass_hitting_anim.stop(true)
	boss.append_failed_tesla_kill_action_1()
	glass_break_particles.emitting = true
	glass_body.queue_free()
	tesla_minigame_failed.emit()

func ending_sequence() -> void:
	glass_hitting_anim.stop(true)
	AudioManager.fade_out("TeslaActivationAlarm", 3.0)
	AudioManager.music_transition("EndingMusic2", 0.0)
	for sound in [AudioManager.get_player("TeslaWorking1"), AudioManager.get_player("TeslaWorking2")]:
		if sound: get_tree().create_tween().tween_property(sound, "volume_db", 10.0, 3.0)
	
	# Create boss sprites group and add shader param
	for node in Utils.get_children_recursive(boss) as Array[Node]:
		if node is Sprite2D or node is AnimatedSprite2D:
			node.material = ShaderMaterial.new()
			node.material.shader = color_overwrite_shader
			node.add_to_group("boss_sprites")
	
	ending_sequence_start.emit()
	
	await Utils.pausable_timer(12.0).timeout
	tesla_shutdown.emit()
	for sound in [AudioManager.get_player("TeslaWorking1"), AudioManager.get_player("TeslaWorking2")]:
		get_tree().create_tween().tween_property(sound, "pitch_scale", 0.5, 10.0)
		AudioManager.custom_fade_out(sound, 10.0)
		
	await Utils.pausable_timer(6.0).timeout
	AudioManager.fade_out_environment_bus(4.0)
	ending_text_start.emit()
