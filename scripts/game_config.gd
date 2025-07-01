extends Resource

class_name GameConfig

# Configuration for betting system
@export_group("Betting")
@export var initial_balance: float = 100.0
@export var ticket_values: Array[float] = [10.0, 20.0, 30.0]
@export var max_bet: float = 50.0
@export var min_bet: float = 1.0
@export var default_bet: float = 10.0

# Configuration for randomization system
@export_group("Randomization")
@export var seed: int = 0
@export var outcomes: Dictionary = {
	"sample_outcome": {"multiplier": 2.0}
}
