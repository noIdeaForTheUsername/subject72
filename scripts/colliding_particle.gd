class_name CollidingParticle
extends RigidBody2D


var time_alive := 0.0
var despawn_time := 10.0
var initial_alpha: float
var fade_away_time := 8.0
var fade_in_time := 0.0
var set_size := 1.0


func _init():
	pass

func setup(global_position: Vector2, color: Color = Color(1, 1, 1, 1),
size: float = 100.0, initial_velocity: Vector2 = Vector2(0, 0), despawn_time: float = 10.0,
fade_away_time: float = despawn_time * 0.8, gravity_scale = 1.0):
	self.position = global_position
	get_node("Sprite2D").modulate = color
	self.set_size = size
	self.linear_velocity = initial_velocity
	self.despawn_time = despawn_time
	self.fade_away_time = fade_away_time
	self.initial_alpha = color.a
	self.gravity_scale = gravity_scale


func set_fade_in(time: float):
	if time > 0:
		get_node("Sprite2D").modulate.a
		self.fade_in_time = time


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_alive = 0.0
	get_node("Sprite2D").visible = true
	get_node("Sprite2D").scale = Vector2(set_size, set_size)
	get_node("CollisionShape2D").scale = Vector2(set_size / 100.0, set_size / 100.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_alive += delta
	
	if time_alive >= despawn_time:
		queue_free()
	elif time_alive >= fade_away_time:
		get_node("Sprite2D").modulate.a = initial_alpha - ((time_alive - fade_away_time) / (despawn_time - fade_away_time)) * initial_alpha
	elif fade_in_time > 0.0:
		if time_alive <= fade_in_time:
			get_node("Sprite2D").modulate.a = (time_alive / fade_in_time) * initial_alpha
		else:
			get_node("Sprite2D").modulate.a = initial_alpha
