extends Node

# Global signal bus for casino game events
signal bet_requested(amount: float)
signal bet_placed(amount: float)
signal bet_confirmed()
signal balance_updated(new_balance: float)
signal game_state_changed(new_state: int)
signal outcome_generated(outcome: Dictionary)
signal payout_calculated(payout: float)
signal play_sound(sound_id: String)
signal restart_game()
