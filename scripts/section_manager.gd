class_name SectionManager
extends Node

@export var preinstantiated_sections: Array[Node2D] = []
@export_file("*.tscn") var section_paths: Array[String] = []
@export var section_parent: Node2D
@export var section_folder: String = "res://scenes/game_sections"

var sections: Array[Section] = []
var loaded_sections: Array[Section] = []
var latest_loaded_index: int

signal section_loaded(name: String)

class Section:
	var node: Node2D = null
	var path: String = ""


func _ready() -> void:
	var pre_size := preinstantiated_sections.size()
	sections.resize(pre_size + section_paths.size())
	loaded_sections.resize(pre_size)
	for i in pre_size:
		var section := Section.new()
		section.node = preinstantiated_sections[i]
		sections[i] = section
		loaded_sections[i] = section
	for i in range(pre_size, pre_size + section_paths.size()):
		sections[i] = Section.new()
		sections[i].path = section_paths[i - pre_size]
	latest_loaded_index = pre_size - 1


func get_section(name: String) -> Node2D:
	var path = _name_to_path(name).to_lower()
	for section in loaded_sections:
		if (is_instance_valid(section.node) &&
		(section.path.to_lower() == path || section.node.name.to_lower() == name.to_lower())):
			return section.node
	push_warning("No loaded section named:", name)
	return null


func load_next(number: int = 1) -> void:
	for i in number:
		latest_loaded_index += 1
		if latest_loaded_index >= sections.size():
			push_warning("Can't load next section - there is no next index in the array")
			return
		_load_section(sections[latest_loaded_index])


func remove_oldest(number: int = 1) -> void:
	for i in number:
		if loaded_sections.size() == 0: return
		_remove_section(loaded_sections[0])
		


func load_by_name(name: String) -> void:
	var path := _name_to_path(name)
	var found := false
	for section in sections:
		if section.path.to_lower() == path.to_lower():
			_load_section(section)
			found = true
	if !found:
		push_error("SectionManager: Section named: ", name, " not found")


func remove_by_name(name: String) -> void:
	var path := _name_to_path(name)
	for section in loaded_sections:
		if section.path.to_lower() == path.to_lower():
			_remove_section(section)
			return
		elif section.node.name.to_lower() == name.to_lower():
			_remove_section(section)




func _name_to_path(name: String) -> String:
	return section_folder + "/" + name + ".tscn"


func _load_section(section: Section) -> void:
	if section.node == null:  # The expected, standard path
		loaded_sections.append(section)
		ResourceLoader.load_threaded_request(section.path)
	else:
		push_warning("Section ", section.path, " already loaded")


func _remove_section(section: Section) -> void:
	var node := section.node
	loaded_sections.erase(section)
	if node == null:
		push_warning("Cannot remove - section ", section.path + " not loaded")
		return;
	node.queue_free()
	section.node = null


func _instantiate_loaded_section(section: Section, resource: Resource) -> void:
	section.node = resource.instantiate()
	section_parent.add_child(section.node)
	section_loaded.emit(section.path.trim_prefix(section_folder).trim_suffix(".tscn"))


func _process(delta: float) -> void:
	# Check if section loading finished and instantiate
	for section in loaded_sections:
		if (section.node == null &&
		ResourceLoader.load_threaded_get_status(section.path) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
			# Pausing the game temporarily
			var audio_players = get_tree().get_root().find_children("*", "AudioStreamPlayer", true, false)
			audio_players.append_array(get_tree().get_root().find_children("*", "AudioStreamPlayer2D", true, false))
			for audio in audio_players:
				audio.process_mode = Node.PROCESS_MODE_ALWAYS
			GameManager.game.pause_ui.lock_pause = true
			get_tree().paused = true
			
			_instantiate_loaded_section(section, ResourceLoader.load_threaded_get(section.path))
			
			# Unpausing
			await get_tree().process_frame
			GameManager.game.pause_ui.lock_pause = false
			get_tree().paused = false
			for audio in audio_players:
				audio.process_mode = Node.PROCESS_MODE_INHERIT
			
	
