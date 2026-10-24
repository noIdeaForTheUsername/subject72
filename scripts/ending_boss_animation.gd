class_name BossEndingAnimation
extends Node

@export var boss: Boss
const FINAL_BOSS_MODULATE := Color(0.1, 0.1, 0.1)
const ANIMATION_TIME := 10.0

var flash_color: Color
var flash_intensity: float
var finished := false

var modulate_tween: Tween

func _ready() -> void:
	GameManager.game.tesla_shutdown.connect(finish_anim)

func start_anim():
	process_mode = Node.PROCESS_MODE_INHERIT
	modulate_tween = get_tree().create_tween()
	modulate_tween.tween_property(boss, "modulate", FINAL_BOSS_MODULATE, ANIMATION_TIME)
	for mat in get_boss_shader_mats():
		mat.set_shader_parameter("overwrite_color", Vector4(0.77, 0.976, 1, 1.0))

func finish_anim():
	finished = true
	boss.falling = true
	for sprite in get_tree().get_nodes_in_group("boss_sprites") as Array[Node2D]:
		if sprite.material is ShaderMaterial:
			sprite.material = null
	
	modulate_tween.kill()
	boss.set_deferred("modulate", FINAL_BOSS_MODULATE)
	await Utils.pausable_timer(1.5).timeout
	boss.toggle_ground_collision(true)

# CALLED FROM ENDAREA> TESLA COIL > BOLT CONTROLLER
func flash(time: float):
	flash_intensity = 1.0
	get_tree().create_tween().set_ease(Tween.EASE_OUT).tween_property(self, "flash_intensity", 0.0, time)
	boss.rotation *= -1

func _process(delta: float) -> void:
	for mat in get_boss_shader_mats():
		mat.set_shader_parameter("overwrite_intensity", flash_intensity)


# INTERNAL UTILS

func get_boss_shader_mats() -> Array[ShaderMaterial]:
	var array: Array[ShaderMaterial] = []
	for sprite in get_tree().get_nodes_in_group("boss_sprites") as Array[Node2D]:
		var mat := sprite.material
		if mat is ShaderMaterial: array.append(mat)
	return array
