extends Node

# Generates random outcomes for casino games
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var outcomes: Dictionary = {}

func initialize(config_resource: Resource) -> void:
	rng.seed = config_resource.seed
	outcomes = config_resource.outcomes
	SignalBus.game_state_changed.connect(_on_game_state_changed)

func generate_outcome() -> Dictionary:
	if outcomes.is_empty():
		return {"multiplier": 2.0}
	var outcome_id: String = outcomes.keys()[rng.randi() % outcomes.size()]
	return outcomes[outcome_id]

func _on_game_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.PLAYING:
		var outcome = generate_outcome()
		SignalBus.outcome_generated.emit(outcome)


func _on_play_button_pressed():
	pass # Replace with function body.
