extends CanvasLayer

# Manages UI rendering and player inputs
var ticket_buttons: Array = []
var selected_ticket_button: TextureButton = null
var main_menu_panel: Panel = null
var bet_panel: Panel = null

func initialize(config_resource: Resource) -> void:
	# Get and validate panels
	main_menu_panel = get_node_or_null("MainMenuPanel")
	bet_panel = get_node_or_null("BetPanel")
	if not main_menu_panel:
		push_error("MainMenuPanel not found in scene tree")
	if not bet_panel:
		push_error("BetPanel not found in scene tree")
	else:
		bet_panel.hide()
	
	# Clear existing ticket buttons
	for button in ticket_buttons:
		if is_instance_valid(button):
			button.queue_free()
	ticket_buttons.clear()
	
	# Instance ticket buttons
	var ticket_values: Array = config_resource.ticket_values
	var x_offset: float = 50.0
	for value in ticket_values:
		var button_scene: PackedScene = load("res://scenes/TicketButton.tscn")
		var button: TextureButton = button_scene.instantiate()
		# Normalize float to integer string for name (e.g., 10.0 -> "10")
		var value_str: String = str(int(value)) if value == int(value) else str(value)
		button.name = "TicketButton_" + value_str
		button.position = Vector2(x_offset, 400)
		var value_label: Label = button.get_node("ValueLabel")
		value_label.text = "$" + value_str
		if not button.pressed.is_connected(_on_ticket_button_pressed.bind(value)):
			button.pressed.connect(_on_ticket_button_pressed.bind(value))
		add_child(button)
		ticket_buttons.append(button)
		x_offset += 200.0
	
	# Ensure UI nodes exist
	var balance_label: Label = get_node_or_null("BetPanel/BalanceLabel")
	var bet_button: Button = get_node_or_null("BetPanel/BetButton")
	if not balance_label:
		push_error("BalanceLabel not found in scene tree")
	if not bet_button:
		push_error("BetButton not found in scene tree")
	else:
		if not bet_button.pressed.is_connected(_on_bet_button_pressed):
			bet_button.pressed.connect(_on_bet_button_pressed)
	
	# Set initial balance
	balance_label.text = "Balance: $%.2f" % config_resource.initial_balance
	
	# Connect to SignalBus
	SignalBus.balance_updated.connect(_on_balance_updated)
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	SignalBus.payout_calculated.connect(_on_payout_calculated)

func _on_balance_updated(balance: float) -> void:
	var label: Label = get_node_or_null("BetPanel/BalanceLabel")
	if label:
		label.text = "Balance: $%.2f" % balance

func _on_ticket_button_pressed(amount: float) -> void:
	# Debug: Print all button names and amount
	print("Ticket button pressed with amount: ", amount)
	for button in ticket_buttons:
		print("Button name: ", button.name)
		# Normalize float to integer string for comparison
		var amount_str: String = str(int(amount)) if amount == int(amount) else str(amount)
		if button.name == "TicketButton_" + amount_str:
			# Deselect previous ticket
			if selected_ticket_button:
				selected_ticket_button.scale = Vector2(1.0, 1.0)  # Reset scale
			selected_ticket_button = button
			button.scale = Vector2(1.2, 1.2)  # Highlight with scale
			print("Button click: ", button.name)
			break
		else:
			print("No match for: TicketButton_", amount_str)
	SignalBus.bet_requested.emit(amount)

func _on_bet_button_pressed() -> void:
	var betting = get_parent().get_node_or_null("Betting")
	if betting and betting.current_bet > 0:
		SignalBus.bet_confirmed.emit()
	else:
		show_error("No valid bet selected")

func _on_game_state_changed(new_state: int) -> void:
	match new_state:
		GameManager.GameState.INIT:
			show_menu_screen()
		GameManager.GameState.BETTING:
			show_betting_screen()
		GameManager.GameState.PLAYING:
			update_game({})
		GameManager.GameState.OUTCOME:
			pass
		GameManager.GameState.END:
			print("game over")

func _on_payout_calculated(payout: float) -> void:
	show_outcome(payout)

func show_menu_screen() -> void:
	if main_menu_panel:
		main_menu_panel.show()
	if bet_panel:
		bet_panel.hide()
	var balance_label: Label = get_node_or_null("BetPanel/BalanceLabel")
	var bet_button: Button = get_node_or_null("BetPanel/BetButton")
	if balance_label:
		balance_label.hide()
	if bet_button:
		bet_button.hide()
	for button in ticket_buttons:
		if is_instance_valid(button):
			button.hide()

func _on_play_button_clicked() -> void:
	main_menu_panel = get_node_or_null("MainMenuPanel")
	bet_panel = get_node_or_null("BetPanel")
	if main_menu_panel:
		main_menu_panel.hide()
	if bet_panel:
		bet_panel.show()
	GameManager.change_state(GameManager.GameState.BETTING)

func show_betting_screen() -> void:
	# Show betting UI
	if main_menu_panel:
		main_menu_panel.hide()
	if bet_panel:
		bet_panel.show()
	var balance_label: Label = get_node_or_null("BetPanel/BalanceLabel")
	var bet_button: Button = get_node_or_null("BetPanel/BetButton")
	if balance_label:
		balance_label.show()
	if bet_button:
		bet_button.show()
	for button in ticket_buttons:
		if is_instance_valid(button):
			button.show()
	if selected_ticket_button:
		selected_ticket_button.scale = Vector2(1.0, 1.0)  # Reset selection
		selected_ticket_button = null

func update_game(_outcome: Dictionary) -> void:
	# Extend: Update blackjack visuals
	pass

func show_outcome(_payout: float) -> void:
	# Extend: Show blackjack outcome
	var label: Label = get_node_or_null("BetPanel/BalanceLabel")
	if label:
		var betting = get_parent().get_node_or_null("Betting")
		if betting:
			label.text = "Balance: $%.2f" % betting.balance

func _on_replay_button_pressed() -> void:
	SignalBus.play_sound.emit("click")
	SignalBus.restart_game.emit()

func show_error(message: String) -> void:
	var error_label: Label = get_node_or_null("BetPanel/ErrorLabel")
	if error_label:
		error_label.text = message
		error_label.show()
		await get_tree().create_timer(2.0).timeout
		error_label.hide()
	else:
		push_error("ErrorLabel not found for error: " + message)
