extends Node

# Manages bets and balance for casino games
var balance: float = 0.0
var current_bet: float = 0.0
var ticket_values: Array = []
var config: Resource = null

func initialize(config_resource: Resource) -> void:
	config = config_resource
	balance = config.initial_balance
	ticket_values = config.ticket_values
	current_bet = 0.0
	SignalBus.balance_updated.emit(balance)
	
	SignalBus.bet_placed.connect(_on_bet_placed)
	SignalBus.outcome_generated.connect(_on_outcome_generated)

func place_bet(amount: float) -> bool:
	# Revert previous bet
	if current_bet > 0:
		balance += current_bet
		current_bet = 0.0
	
	# Apply new bet
	if ticket_values.has(amount) and amount >= config.min_bet and amount <= config.max_bet and amount <= balance:
		current_bet = amount
		balance -= amount
		SignalBus.balance_updated.emit(balance)
		return true
	else:
		# Restore balance if bet is invalid
		SignalBus.balance_updated.emit(balance)
		return false

func calculate_payout(outcome: Dictionary) -> float:
	var multiplier: float = outcome.get("multiplier", 0.0)
	var payout: float = current_bet * multiplier
	balance += payout
	SignalBus.balance_updated.emit(balance)
	current_bet = 0.0  # Reset bet after payout
	return payout

func _on_bet_placed(amount: float) -> void:
	pass  # Placeholder for future extensions

func _on_outcome_generated(outcome: Dictionary) -> void:
	if GameManager.current_state == GameManager.GameState.OUTCOME:
		var payout = calculate_payout(outcome)
		SignalBus.payout_calculated.emit(payout)
