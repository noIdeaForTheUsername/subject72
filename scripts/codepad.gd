class_name Codepad
extends Control


@onready var code_display: Label = $CodeDisplay
@onready var code_note: Label = $StickyNote/CodeLabel
@onready var accepted_sound: AudioStreamPlayer = $AcceptedSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound
@onready var status_light: StatusLight = $StatusLight
@onready var highlight_animation: AnimationPlayer = $HighlightAnimation

var entered_code: String = "":
	set (value):
		entered_code = value
		if value == "":
			code_display.text = "ENTER CODE"
		else:
			code_display.text = entered_code

var correct_code: String = "123456"

var accepted := false
signal code_accepted()


func _ready() -> void:
	correct_code = str(randi_range(100000, 999999))
	code_note.text = correct_code
	highlight_animation.play("highlight")


func _on_number_button_activated(number: int) -> void:
	if accepted: return
	highlight_animation.play("RESET")
	entered_code += str(number)
	if entered_code.length() >= correct_code.length():
		verify_code()


func _on_erase_button_activated(number: int) -> void:
	if accepted: return
	if entered_code.length() > 0: entered_code = entered_code.erase(entered_code.length() - 1, 1)


func toggle_buttons(enabled: bool):
	for node in get_children():
		if node is CodepadNumber:
			node.disabled = !enabled


func verify_code():
	if entered_code == correct_code:
		accepted = true
		status_light.status = StatusLight.Status.OFF
		accepted_sound.play()
		code_accepted.emit()
	else:
		entered_code = ""
		error_sound.play()
