class_name EndingUI
extends CanvasLayer

@onready var black_rect: ColorRect = $Control/BlackRect
@onready var title: Label = $Control/Title
@onready var thank_you: Label = $Control/ThankYou


func _ready() -> void:
	visible = false

func show_ending_text() -> void:
	GameManager.game.pause_ui.lock_pause = true
	visible = true
	title.modulate.a = 0.0
	thank_you.modulate.a = 0.0
	await Utils.fade_in_object(title, 4.0)
	await Utils.fade_in_object(thank_you, 3.0)
	await Utils.pausable_timer(3.0).timeout
	await Utils.fade_in_object(black_rect, 5.0, Color.WHITE)
	AudioManager.music_transition("", 6.0)
	await Utils.pausable_timer(5.0).timeout
	GameManager.enter_menu()


func _on_game_ending_text_start() -> void:
	show_ending_text()
