extends MultiMeshInstance2D


class Star:
	var id: int
	var min_brightness: float
	var max_brightness: float
	var blink_frames: int = 0  # 0 for non-blinking stars (they should be removed)
	var blink_frames_left: int = 0
	var now_on_max_brightness := false
	func _init(id: int, multimesh: MultiMesh, pos: Vector2, min_brightness: float, blink_frames: int) -> void:
		# Blinking star
		if id % 5 == 0:
			self.id = id
			self.blink_frames = blink_frames
			self.blink_frames_left = blink_frames
			self.min_brightness = min_brightness
			self.max_brightness = min_brightness + 0.3
		multimesh.set_instance_transform_2d(id, Transform2D(0.0, pos))
		multimesh.set_instance_color(id, Color(min_brightness, min_brightness, min_brightness))
	func update(multimesh: MultiMesh):
		blink_frames_left -= 1
		if blink_frames_left == 0:
			if now_on_max_brightness: multimesh.set_instance_color(id, Color(min_brightness, min_brightness, min_brightness))
			else: multimesh.set_instance_color(id, Color(max_brightness, max_brightness, max_brightness))
			now_on_max_brightness = !now_on_max_brightness
			blink_frames_left = blink_frames


const AMOUNT := 1000
const DEFAULT_CAMERA_ZOOM := 2.0

var base_resolution := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
ProjectSettings.get_setting("display/window/size/viewport_height"))

var stars: Array[Star] = []


func _ready() -> void:
	# screen_size = get_viewport_rect().size
	get_tree().get_root().size_changed.connect(on_window_resized)
	on_window_resized()
	setup_stars()


func _process(delta: float) -> void:
	for star in stars:
		star.update(multimesh)


func on_window_resized() -> void:
	var current_resolution := Vector2(get_viewport_rect().size)
	var ratio := current_resolution / base_resolution
	var max := maxf(ratio.x, ratio.y)
	scale = Vector2(max, max)
	

#
#func _on_resize_debounce_timer_timeout() -> void:
	#var new_size := get_viewport_rect().size
	#if new_size.x > screen_size.x || new_size.y > screen_size.y:
		#screen_size.x = maxi(new_size.x, screen_size.x)
		#screen_size.y = maxi(new_size.y, screen_size.y)
		#setup_stars()
#
#
#func get_screen_size() -> Vector2i:
	#return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


func setup_stars() -> void:
	stars.clear()
	multimesh.instance_count = AMOUNT
	for id in range(AMOUNT):
		var star := Star.new(id, multimesh, Vector2(randf() * base_resolution.x, randf() * base_resolution.y),
		randf_range(0.2, 0.65), randi_range(10, 30))
		if star.blink_frames > 0: stars.append(star)
