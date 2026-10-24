extends Node

var game: Game = null
var menu: Control = null
var loaded_path: String = ""

const MIN_ASPECT := 1.0
const MAX_ASPECT := 2.0

# used to display instructions on the game start
var display_menu_instructions := true


func _ready() -> void:
	await get_tree().process_frame
	get_tree().get_root().size_changed.connect(_on_window_resized)
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_game_node(game_node: Game):
	game = game_node

func enter_menu(display_menu_instructions: bool = false) -> void:
	self.display_menu_instructions = display_menu_instructions
	loaded_path = "res://scenes/game_sections/menu.tscn"
	ResourceLoader.load_threaded_request(loaded_path)
	#get_tree().paused = false
	#menu = get_tree().current_scene
	#set_deferred("game", null)


func start_game() -> void:
	loaded_path = "res://scenes/game_sections/game.tscn"
	ResourceLoader.load_threaded_request(loaded_path)
	#get_tree().paused = false
	#game = get_tree().current_scene
	#set_deferred("menu", null)




func _process(delta: float) -> void:
	if loaded_path.length() > 0:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(loaded_path, progress)
		if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			for label in get_tree().get_nodes_in_group("loading_labels"):
				if label is Label: label.text = "LOADING (" + str(roundi(progress[0] * 100)) + "/100)" 
		else:
			await get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(loaded_path))
			var scene := get_tree().current_scene
			if scene is Menu:
				menu = get_tree().current_scene
				set_deferred("game", null)
			elif scene is Game:
				game = get_tree().current_scene
				set_deferred("menu", null)
			
			get_tree().paused = false
			loaded_path = ""
	

# TODO: DISABLE IN WEB EXPORT
# TODO: IN WEB EXPORT: ALSO DISABLE THE EXIT BUTTON
func _on_window_resized() -> void:
	pass
	force_window_aspect.call_deferred()

func force_window_aspect() -> void:
	var size := Vector2(DisplayServer.window_get_size())
	var aspect := size.x / size.y
	if aspect > MAX_ASPECT:
		size.x = size.y * MAX_ASPECT
	elif aspect < MIN_ASPECT:
		size.y = size.x / MIN_ASPECT
	else:
		return
	DisplayServer.window_set_size(size)
