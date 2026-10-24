class_name Cutscene
extends Control

@export var global_sounds_node: Node
@export var shader_rect: ColorRect
@export var background_rect: ColorRect
@export var epilepsy_screen: Control
@export var terminal: Control
@export var terminal_label: TerminalLabel
@export var image_1: TextureRect
@export var image_2: TextureRect
@export var skip_label: Label

func _ready() -> void:
	AudioManager.set_global_sounds_node(global_sounds_node)
	background_rect.visible = true
	epilepsy_screen.visible = false
	shader_rect.visible = false
	terminal.visible = false
	image_1.visible = false
	image_2.visible = false


	await Utils.fade_in_object(epilepsy_screen, 1.0)
	await Utils.pausable_timer(5.0).timeout
	await Utils.fade_out_object(epilepsy_screen, 1.0)
	await Utils.pausable_timer(1.0).timeout
	AudioManager.fade_in("Noise", 1.0, true)
	Utils.fade_in_object(shader_rect, 1.0)
	await Utils.fade_in_object(terminal, 1.0)
	Utils.fade_in_object(skip_label, 1.0)
	
	await terminal_label.write_gradually("User: Security Operations Commander", false)
	await terminal_label.write_gradually("Password: ", true)
	await terminal_label.write_gradually("##############", false, 0.25)
	terminal_label.next_line()
	terminal_label.toggle_cursor(false)
	for i in range(5):
		for char in ['|', '/', '-', '\\']:
			terminal_label.replace_instantly(char)
			await Utils.pausable_timer(0.2).timeout
	terminal_label.toggle_cursor(true)
	terminal_label.replace_instantly("")
	Utils.fade_out_object(skip_label, 1.0)
	await terminal_label.write_gradually("Login successful. Welcome!", false)
	await terminal_label.write_gradually("-----------------------------------", true, 0.025)
	await terminal_label.write_gradually("[01:18:31] Facility status: OK", true)
	await terminal_label.write_gradually("Monitoring", true)
	terminal_label.toggle_cursor(false)
	for i in range(3):
		for dots in ["", ".", "..", "..."]:
			terminal_label.replace_instantly("Monitoring" + dots)
			await Utils.pausable_timer(0.5).timeout
	terminal_label.replace_instantly("")
	terminal_label.toggle_cursor(true)
	AudioManager.play("ConsoleAlarm2", true)
	terminal_label.set_font_color(Color.YELLOW)
	await terminal_label.write_gradually("[01:21:19] Warning! Abnormal motion at: Subject-72 cell", false)
	await Utils.pausable_timer(6.0).timeout
	AudioManager.play("ConsoleAlarm1", true)
	terminal_label.set_font_color(Color.RED)
	await terminal_label.write_gradually("[01:23:14] DANGER! SUBJECT-72 CELL INTEGRITY CRITICAL", true)
	await Utils.pausable_timer(4.0).timeout
	await terminal_label.write_gradually("[01:23:58] SUBJECT-72 OUT OF ITS CELL", true)
	await Utils.pausable_timer(4.0).timeout
	await terminal_label.write_gradually("[01:26:22] EPSILON PROTOCOL INITIATED", true)
	await Utils.pausable_timer(4.0).timeout
	
	await Utils.fade_out_object(terminal, 1.0)
	terminal_label.process_mode = Node.PROCESS_MODE_DISABLED
	AudioManager.fade_out("Noise", 1.0)
	AudioManager.fade_out("ConsoleAlarm1", 1.0)
	AudioManager.fade_out("ConsoleAlarm2", 1.0)
	Utils.fade_out_object(shader_rect, 1.0)
	await Utils.pausable_timer(4.0).timeout
	
	AudioManager.play("ShortNoise")
	AudioManager.fade_in("Noise", 1.0, true)
	background_rect.color = Color.WHITE
	Utils.fade_in_object(shader_rect, 0.5)
	await Utils.fade_in_object(image_1, 0.5)
	await Utils.pausable_timer(6.0).timeout
	await Utils.fade_out_object(image_1, 0.5)
	
	AudioManager.play("ShortNoise")
	await Utils.fade_in_object(image_2, 0.5)
	await Utils.pausable_timer(6.0).timeout
	await Utils.fade_out_object(image_2, 0.5)
	background_rect.color = Color.BLACK
	AudioManager.play("ShortNoise")
	await AudioManager.fade_out("Noise", 1.0)
	shader_rect.visible = false
	await Utils.pausable_timer(4.0).timeout
	
	end_cutscene(true)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("skip"):
		end_cutscene()

func end_cutscene(display_menu_instructions = false) -> void:
	GameManager.enter_menu(display_menu_instructions)
