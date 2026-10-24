class_name BoltController
extends Node2D

@onready var bolt_timer: Timer = $BoltSpawningTimer
@onready var glow: PointLight2D = $BlueGlow
var glow_tween: Tween = null

var last_bolt_index: int = 0
var last_sound_index: int = 0

var bolts: Array[Bolt] = []
var arcs: Array[GPUParticles2D] = []
var sounds: Array[AudioStreamPlayer2D] = []

const BOLT_DISAPPEAR_TIME := 0.6

func _ready() -> void:
	GameManager.game.ending_sequence_start.connect(start_animation)
	GameManager.game.tesla_shutdown.connect(stop_animation)
	for node in get_children():
		if node is Bolt: bolts.append(node)
		elif node is GPUParticles2D: arcs.append(node)
		elif node is AudioStreamPlayer2D: sounds.append(node)


func start_animation():
	glow.visible = true
	toggle_arcs(true)
	spawn_bolt()
	bolt_timer.start()


func stop_animation():
	bolt_timer.stop()
	toggle_arcs(false)


func _on_timer_timeout() -> void:
	spawn_bolt()



func toggle_arcs(emitting: bool):
	for arc in arcs:
		if emitting: arc.visible = true
		arc.emitting = emitting

func spawn_bolt():
	if bolts.size() < 2: return
	var index := randi_range(0, bolts.size() - 1)
	while index == last_bolt_index:
		index = randi_range(0, bolts.size() - 1)
	bolts[index].spawn(BOLT_DISAPPEAR_TIME)
	last_bolt_index = index
	
	if sounds.size() >= 2:
		index = randi_range(0, sounds.size() - 1)
		while index == last_bolt_index:
			index = randi_range(0, sounds.size() - 1)
		sounds[index].play()
		last_sound_index = index
	
	if glow_tween: glow_tween.kill()
	glow_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT)
	glow.energy = 1.5
	glow_tween.tween_property(glow, "energy", 0.0, 0.5)
	
	GameManager.game.camera.shake_effect(3.5, 0.35)
	if GameManager.game.boss_ending_animation: GameManager.game.boss_ending_animation.flash(bolt_timer.wait_time * 0.9)
