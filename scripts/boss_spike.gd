class_name BossSpike
extends Area2D

const EJECT_DELAY := 0.2
const EJECT_VELOCITY := 40.0


@onready var sprite: Sprite2D = $Sprite2D
@onready var eject_warn: Line2D = $EjectWarn
@onready var collision_shape: CollisionPolygon2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var default_position := Vector2.INF
var hidden_position: Vector2
var slide_out_vector: Vector2

var slide_out_time := 0.5
var slide_out_timer := 0.5
var movement := 0


var projectile_scene := preload("res://scenes/boss_spike_projectile.tscn")


func _ready() -> void:
	if default_position == Vector2.INF:
		default_position = position
		self.apply_scale(Vector2(1.25, 1.25))
		self.add_to_group("boss_spikes")
		slide_out_vector = Vector2(sprite.get_rect().size.x * self.scale.x, 0).rotated(self.rotation)
	visible = false
	monitorable = false
	monitoring = false
	# eject_warn.visible = false
	
	hidden_position = default_position - slide_out_vector
	position = hidden_position
	

func _process(delta: float) -> void:
	if movement != 0:
		slide_out_timer += delta * movement
		if (movement < 0 && slide_out_timer < 0) || (movement > 0 && slide_out_timer > slide_out_time):
			slide_out_timer = clampf(slide_out_timer, 0, slide_out_time)
			movement = 0
		position = hidden_position.lerp(default_position, slide_out_timer / slide_out_time)


func slide_out(time: float = 0.5) -> void:
	visible = true
	monitorable = true
	monitoring = true
	if time == 0.0:
		position = default_position
	else:
		slide_out_time = time
		slide_out_timer = 0.0
		movement = 1


func show_eject_warn() -> void:
	eject_warn.visible = true
	if animation_player:
		animation_player.play("eject_warn_blinking")


# Call show_eject_warn earlier
func eject(regen_time: float = 1.0, delay: float = EJECT_DELAY) -> void:
	visible = true
	monitorable = true
	monitoring = true
	movement = -1
	slide_out_time = delay
	slide_out_timer = delay
	await Utils.pausable_timer(delay).timeout
	
	eject_warn.visible = false
	if animation_player:
		animation_player.stop()
	
	var projectile: BossSpikeProjectile = projectile_scene.instantiate()
	get_node("/root/Game").add_child(projectile)
	projectile.setup(global_position, global_rotation, false)
	var new_sprite: Sprite2D = Sprite2D.new()
	new_sprite.texture = self.sprite.texture
	new_sprite.position = self.sprite.position
	projectile.set_sprite(new_sprite)
	var col_poly: CollisionPolygon2D = CollisionPolygon2D.new()
	col_poly.polygon = collision_shape.polygon
	col_poly.position = collision_shape.position
	projectile.set_collision_polygon(col_poly)
	projectile.scale = scale
	
	await Utils.pausable_timer(regen_time).timeout
	
	_ready()
	slide_out(slide_out_time)
	
