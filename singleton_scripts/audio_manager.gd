extends Node2D


# const DIRECTORY: String = "/root/Game/GlobalSounds/"
const MUSIC_TRANSITION_TIME := 2.5
const FADE_OUT_MIN_VOLUME := -25.0
var current_music: AudioStreamPlayer

var node: Node

var original_environment_bus_volume: float 
var environment_bus_volume: float = NAN
var environment_bus_index: int

var looping_sounds: Array[AudioStreamPlayer] = []


func set_global_sounds_node(node: Node) -> void:
	if is_instance_valid(node): self.node = node
	environment_bus_volume = NAN
	AudioServer.set_bus_volume_db(environment_bus_index, original_environment_bus_volume)


func _ready() -> void:
	# start_game_music()
	await get_tree().process_frame
	environment_bus_index = AudioServer.get_bus_index("Environment")


func _process(delta: float) -> void:
	looping_sounds.erase(null)
	for i in range(0, looping_sounds.size()):
		var sound := looping_sounds[i]
		if is_instance_valid(sound) && sound.is_inside_tree():
			if !sound.playing: sound.play()
		else:
			looping_sounds[i] = null
	
	if !is_nan(environment_bus_volume):
		AudioServer.set_bus_volume_db(environment_bus_index, environment_bus_volume)


func music_transition(music_name: String, time: float = MUSIC_TRANSITION_TIME) -> void:
	var prev_music := current_music
	if is_instance_valid(prev_music): looping_sounds.erase(prev_music)
	if music_name.length() > 0:
		current_music = get_player(music_name)
	else:
		current_music = null
		
	if time == 0.0 && is_instance_valid(prev_music):
		prev_music.stop()
	elif is_instance_valid(prev_music):
		var tween := get_tree().create_tween().set_parallel(true)
		tween.tween_property(prev_music, "volume_db", FADE_OUT_MIN_VOLUME, time)
		await tween.finished
		if is_instance_valid(prev_music) && prev_music.is_inside_tree(): prev_music.stop()
	
	if is_instance_valid(current_music) && current_music == get_player(music_name):
		current_music.play()
		looping_sounds.append(current_music)


func play(sound_name: String, looped: bool = false) -> void:
	var sound := get_player(sound_name)
	if looped: looping_sounds.append(sound)
	sound.play()

func stop(sound_name: String) -> void:
	var sound := get_player(sound_name)
	sound.stop()
	looping_sounds.erase(sound)
	
func get_player(sound_name: String) -> AudioStreamPlayer:
	if is_instance_valid(node):
		return node.get_node(sound_name)
	else:
		push_warning("AudioManager: Global audio node invalid")
		return AudioStreamPlayer.new()


func fade_out(name: String, time: float) -> void:
	var tween := get_tree().create_tween().tween_property(get_player(name), "volume_db", -25.0, time)
	await tween.finished
	var player := get_player(name)
	player.stop()
	looping_sounds.erase(player)

func fade_in(name: String, time: float, looped: bool = false) -> void:
	var player := get_player(name)
	player.play()
	if looped: looping_sounds.append(player)
	player.volume_db = FADE_OUT_MIN_VOLUME
	get_tree().create_tween().tween_property(player, "volume_db", -25.0, time)



func custom_fade_out(sound_node, time: float) -> void:
	get_tree().create_tween().tween_property(sound_node, "volume_db", -25.0, time)
	await Utils.pausable_timer(time).timeout
	if is_instance_valid(sound_node):
		sound_node.stop()
		looping_sounds.erase(sound_node)


func fade_out_environment_bus(time: float) -> void:
	original_environment_bus_volume = AudioServer.get_bus_volume_db(environment_bus_index)
	environment_bus_volume = original_environment_bus_volume
	get_tree().create_tween().tween_property(self, "environment_bus_volume", -50.0, time)  # The value itself will be set in _process


#func fade_out(audio: AudioStreamPlayer, time: float) -> void:
	#_fade_out = FadeData.new(audio, time)
	#
#func fade_in(audio: AudioStreamPlayer, time: float, volume: float = 1.0) -> void:
	#_fade_in = FadeData.new(audio, time, volume)
	#audio.play()



#func _process(delta) -> void:
	## Fade in
	#if _fade_in != null:
		#_fade_in.time_elapsed += delta
		#var t := _fade_in.time_elapsed / _fade_in.total_time
		#t = clampf(t, 0, 1)
		#_fade_in.audio.volume_db = lerpf(0.0, _fade_in.max_vol, t)
		#if t == 1: _fade_in = null
	#
	## Fade out
	#if _fade_out != null:
		#_fade_out.time_elapsed += delta
		#var t := _fade_out.time_elapsed / _fade_out.total_time
		#t = clampf(t, 0, 1)
		#_fade_out.audio.volume_db = lerpf(_fade_out.max_vol, 0.0, t)
		#if t == 1:
			#_fade_out.audio.stop()
			#_fade_out = null
