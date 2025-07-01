extends Node

# Manages editor-assigned sound effects
var players: Dictionary = {}

func initialize() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			players[child.name] = child
	SignalBus.play_sound.connect(_on_play_sound)

func _on_play_sound(sound_id: String) -> void:
	if players.has(sound_id):
		players[sound_id].play()
	else:
		push_error("AudioStreamPlayer for sound_id " + sound_id + " not found")
