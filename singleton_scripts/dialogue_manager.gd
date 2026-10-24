extends Node

# const LABEL_PATH: String = "/root/Game/UI/Control/DialogueLabel"
const DIALOGUE_TIME: float = 9.0
const ADD_CHARS_PER_SECOND := 20
const REMOVE_CHARS_PER_SECOND := 60
const MAX_DIALOGUES := 3

var dialogues: Array[Dialogue] = []
var label: Label


class Dialogue:
	var full_text: String
	var displayed_text: String = ""
	var time_elapsed: float = 0.0
	var deletion_time: float
	func _init(text: String, time: float = DIALOGUE_TIME):
		self.full_text = text
		self.deletion_time = time
	func update_time(delta: float) -> void:
		time_elapsed += delta
		var chars_to_display: int
		if time_elapsed <= deletion_time:
			chars_to_display = clampi(ADD_CHARS_PER_SECOND * time_elapsed, 0, full_text.length())
		else:
			chars_to_display = clampi(full_text.length() - REMOVE_CHARS_PER_SECOND * (time_elapsed - deletion_time), 0, full_text.length())
		displayed_text = full_text.substr(0, chars_to_display)
	func check_deletion() -> bool:
		return time_elapsed > deletion_time && displayed_text.length() == 0



func display(text: String):
	var new_dialogue := Dialogue.new(text)
	dialogues.append(new_dialogue)
	if dialogues.size() > MAX_DIALOGUES:
		dialogues.pop_front()


func setup(label: Label) -> void:
	dialogues.clear()
	self.label = label


func _process(delta: float) -> void:
	for i in dialogues.size():
		dialogues[i].update_time(delta)
		if dialogues[i].check_deletion():
			dialogues.remove_at.call_deferred(i)
	
	var new_text := ""
	for dialogue in self.dialogues:
		new_text += dialogue.displayed_text
		new_text += "\n"
	
	if is_instance_valid(label) && label.is_inside_tree():
		label.text = new_text
