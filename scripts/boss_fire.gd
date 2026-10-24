class_name BossFire
extends BossFume

const FIRE_SPAWN_CHANCE: float = 1.0 / (60.0 * 2.0 * 6.0)  # Physics frames * ~lifetime * one per how many shards?
const FIRE_SCENE := preload("res://scenes/fire_emitter.tscn")

var start_fire := false
var fire_started := false

func _init() -> void:
	super._init()

func custom_physics_process(delta: float) -> void:
	super.custom_physics_process(delta)
	if randf() <= FIRE_SPAWN_CHANCE:  # Mark for fire placement
		start_fire = true

	if start_fire && !fire_started && has_overlapping_areas():  # Spawn fire particle emitter
		fire_started = true
		var fire_emitter := FIRE_SCENE.instantiate()
		fire_emitter.global_position = self.global_position
		get_node("/root/Game").add_child.call_deferred(fire_emitter)
		fire_emitter.add_to_group("fire_emitters", true)
	
