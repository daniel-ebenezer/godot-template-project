extends Node

# Autoload singleton to manage game loop and state
enum GameState { INIT, BETTING, PLAYING, OUTCOME, END }

const BETTING_GROUP = "BettingSystem"
const UI_GROUP = "UISystem"
const RANDOMIZATION_GROUP = "RandomizationSystem"
const AUDIO_GROUP = "AudioSystem"

var current_state: GameState = GameState.INIT
var config: Resource = null
var outcome: Dictionary = {}
var betting_node: Node = null
var ui_node: Node = null
var randomization_node: Node = null
#var audio_node: Node = null

func _ready() -> void:
	# Load GameConfig
	config = load("res://config/GameConfig.tres")
	if not config:
		push_error("Failed to load GameConfig.tres")
	
	# Initialize systems using node groups
	var betting_nodes = get_tree().get_nodes_in_group(BETTING_GROUP)
	var ui_nodes = get_tree().get_nodes_in_group(UI_GROUP)
	
	var randomization_nodes = get_tree().get_nodes_in_group(RANDOMIZATION_GROUP)
	var audio_nodes = get_tree().get_nodes_in_group(AUDIO_GROUP)
	
	if betting_nodes.size() != 1:
		push_error("Expected one node in " + BETTING_GROUP + ", found " + str(betting_nodes.size()))
	else:
		betting_node = betting_nodes[0]
		betting_node.initialize(config)
	
	if ui_nodes.size() != 1:
		push_error("Expected one node in " + UI_GROUP + ", found " + str(ui_nodes.size()))
	else:
		ui_node = ui_nodes[0]
		ui_node.initialize(config)
	
	if randomization_nodes.size() != 1:
		push_error("Expected one node in " + RANDOMIZATION_GROUP + ", found " + str(randomization_nodes.size()))
	else:
		randomization_node = randomization_nodes[0]
		randomization_node.initialize(config)
	
	#if audio_nodes.size() != 1:
		#push_error("Expected one node in " + AUDIO_GROUP + ", found " + str(audio_nodes.size()))
	#else:
		#audio_node = audio_nodes[0]
		#audio_node.initialize()
	
	# Connect to SignalBus
	SignalBus.bet_requested.connect(_on_bet_requested)
	SignalBus.bet_confirmed.connect(_on_bet_confirmed)
	SignalBus.restart_game.connect(_on_restart_game)
	
	# Emit initial state
	SignalBus.game_state_changed.emit(current_state)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	SignalBus.game_state_changed.emit(new_state)
	print(new_state)
	match current_state:
		GameState.INIT:
			pass
		GameState.BETTING:
			SignalBus.play_sound.emit("click")
		GameState.PLAYING:
			SignalBus.outcome_generated.connect(_on_outcome_generated, CONNECT_ONE_SHOT)
		GameState.OUTCOME:
			SignalBus.payout_calculated.connect(_on_payout_calculated, CONNECT_ONE_SHOT)
		GameState.END:
			pass

func _on_bet_requested(amount: float) -> void:
	if current_state == GameState.BETTING:
		if betting_node and betting_node.place_bet(amount):
			SignalBus.bet_placed.emit(amount)
		elif ui_node:
			ui_node.show_error("Insufficient balance or invalid ticket")

func _on_bet_confirmed() -> void:
	if current_state == GameState.BETTING:
		if betting_node and betting_node.current_bet > 0:
			change_state(GameState.PLAYING)
		elif ui_node:
			ui_node.show_error("No valid bet selected")

func _on_outcome_generated(outcome: Dictionary) -> void:
	if current_state == GameState.PLAYING:
		self.outcome = outcome
		change_state(GameState.OUTCOME)

func _on_payout_calculated(payout: float) -> void:
	if current_state == GameState.OUTCOME:
		SignalBus.play_sound.emit("win" if payout > 0 else "loss")
		change_state(GameState.END)

func _on_restart_game() -> void:
	if betting_node:
		betting_node.initialize(config)  # Reset balance
	change_state(GameState.BETTING)
