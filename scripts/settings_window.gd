class_name SettingsWindow
extends MenuWindow


@export var music_slider: Slider
@export var sfx_slider: Slider

var music_bus_index: int
var sfx_bus_index: int

# amplitude = 10^(volume_db/20)
const MUSIC_AMP_MIN := pow(10.0, -25.0 / 20.0)
const MUSIC_AMP_MAX := pow(10.0, -2.5 / 20.0)
const SFX_AMP_MIN := pow(10.0, -25.0 / 20.0)
const SFX_AMP_MAX := pow(10.0, 4.0 / 20.0)


func _ready() -> void:
	super._ready()
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_value_changed)
		music_bus_index = AudioServer.get_bus_index("Music")
		var db := AudioServer.get_bus_volume_db(music_bus_index)
		var amp := pow(10.0, db / 20.0)
		music_slider.value = inverse_lerp(MUSIC_AMP_MIN, MUSIC_AMP_MAX, amp)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
		sfx_bus_index = AudioServer.get_bus_index("SFX")
		var db := AudioServer.get_bus_volume_db(sfx_bus_index)
		var amp := pow(10.0, db / 20.0)
		sfx_slider.value = inverse_lerp(SFX_AMP_MIN, SFX_AMP_MAX, amp)


func _on_music_slider_value_changed(value: float) -> void:
	var amp := lerpf(MUSIC_AMP_MIN, MUSIC_AMP_MAX, value)
	var db := 20.0 * log(amp) / log(10)
	AudioServer.set_bus_volume_db(music_bus_index, db)
	AudioServer.set_bus_mute(music_bus_index, value == 0.0)


func _on_sfx_slider_value_changed(value: float) -> void:
	var amp := lerpf(SFX_AMP_MIN, SFX_AMP_MAX, value)
	var db := 20.0 * log(amp) / log(10)
	AudioServer.set_bus_volume_db(sfx_bus_index, db)
	AudioServer.set_bus_mute(sfx_bus_index, value == 0.0)


func _on_slider_drag_ended(value_changed: bool) -> void:
	AudioManager.play("MenuButton")
