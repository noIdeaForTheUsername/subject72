class_name TerminalLabel
extends Label

var lines: Array[String] = [""]
var remaining_letters := ""

var excess_time: float = 0.0
var time_per_letter: float = 0.1

var time_elapsed := 0.0
var show_cursor: bool = true
const CURSOR_BLINKS_PER_SECOND := 2.0

signal line_written()


func _process(delta: float) -> void:
	var prev_time_elapsed := time_elapsed
	time_elapsed += delta
	if remaining_letters.length() > 0:
		excess_time += delta
		var letters := floori(excess_time / time_per_letter)
		if letters > 0:
			excess_time -= letters * time_per_letter
			lines[lines.size() - 1] += remaining_letters.substr(0, letters)
			remaining_letters = remaining_letters.erase(0, letters)
			update_text()
			AudioManager.play("Tick")
		if remaining_letters.length() == 0:
			line_written.emit()
			excess_time = 0.0
	elif floori(prev_time_elapsed * CURSOR_BLINKS_PER_SECOND) < floori(time_elapsed * CURSOR_BLINKS_PER_SECOND):
		update_text()

func update_text():
	text = lines.reduce(func(accum, line): return accum + "\n" + line)
	if show_cursor && floori(time_elapsed * CURSOR_BLINKS_PER_SECOND) % 2 == 0: text += "_"


# if new_line is true, adds a 0.5 second delay
func write_gradually(text: String, new_line: bool = false, time_per_letter: float = 0.05) -> void:
	if new_line:
		await Utils.pausable_timer(0.5).timeout
		next_line()
	if lines[lines.size() - 1] == "": AudioManager.play("Beep")
	remaining_letters = text
	self.time_per_letter = time_per_letter
	await line_written


func write_instantly(text: String, new_line: bool = false) -> void:
	if new_line: next_line()
	lines[lines.size() - 1] += text
	update_text()

func replace_instantly(text: String) -> void:
	lines[lines.size() - 1] = text
	update_text()

func next_line() -> void:
	lines.append("")
	update_text()

func toggle_cursor(visible: bool):
	show_cursor = visible

func set_font_color(color: Color):
	label_settings.font_color = color
