extends Sprite2D

@onready var circle: Sprite2D = $DisplayedContent/Circle
@onready var markers: Sprite2D = $DisplayedContent/Markers
@onready var breach_text: Sprite2D = $DisplayedContent/BreachText
@onready var epsilon_text: Sprite2D = $DisplayedContent/EpsilonText

var bar_scene = preload("res://scenes/epsilon_monitor_bar.tscn")

var markers_transparency_change: float = 1.0
var text_transparency_change: float = 1.0
var circle_rotation_speed := PI / 4
var text_swap_time: float = 6

var markers_appearing := false
var display_breach_text := false
var time_since_text_swap: float = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if markers: handle_markers(delta)
	if circle: handle_circle(delta)
	if breach_text && epsilon_text: handle_text(delta)


func handle_markers(delta: float):
	if (markers.modulate.a >= 1.0 && markers_appearing) || (markers.modulate.a <= 0.0 && !markers_appearing):
		markers_appearing = !markers_appearing
	
	if markers_appearing:
		markers.modulate.a = clamp(markers.modulate.a + markers_transparency_change * delta, 0.0, 1.0)
	else:
		markers.modulate.a = clamp(markers.modulate.a - markers_transparency_change * delta, 0.0, 1.0)


func handle_circle(delta: float):
	circle.rotate(circle_rotation_speed * delta)
	

func handle_text(delta: float):
	time_since_text_swap += delta;
	
	if (time_since_text_swap > text_swap_time):
		display_breach_text = !display_breach_text
		time_since_text_swap = 0.0
	
	if (display_breach_text):
		breach_text.modulate.a = clamp(breach_text.modulate.a + text_transparency_change * delta, 0.0, 1.0)
		epsilon_text.modulate.a = clamp(epsilon_text.modulate.a - text_transparency_change * delta, 0.0, 1.0)
	else:
		breach_text.modulate.a = clamp(breach_text.modulate.a - text_transparency_change * delta, 0.0, 1.0)
		epsilon_text.modulate.a = clamp(epsilon_text.modulate.a + text_transparency_change * delta, 0.0, 1.0)
