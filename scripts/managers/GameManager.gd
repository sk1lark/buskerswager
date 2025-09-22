extends Node
class_name GameManager

enum Mood { HECKLERS = 1, DISTRACTED = 2, GENEROUS = 3, CRITICS = 4, DANCERS = 5, ENCORE = 6 }

# game state stuff
var tips_total = 0
var nightly_goal = 30
var rerolls_available = 1
var current_mood = Mood.DISTRACTED
var verse_active = false

# different crowd moods and their vibes
var mood_data = {
	Mood.HECKLERS: {"name": "hostile crowd", "mult": 0.6, "event_odds": 0.45},
	Mood.DISTRACTED: {"name": "distracted walkers", "mult": 0.8, "event_odds": 0.30},
	Mood.GENEROUS: {"name": "generous tourists", "mult": 1.6, "event_odds": 0.40},
	Mood.CRITICS: {"name": "art critics", "mult": 1.1, "event_odds": 0.55},
	Mood.DANCERS: {"name": "festival dancers", "mult": 1.3, "event_odds": 0.65},
	Mood.ENCORE: {"name": "encore fever!", "mult": 1.8, "event_odds": 0.50}
}

# random events that can happen
var event_tables = {
	Mood.HECKLERS: [
		{"name": "Angry Shouts", "tip_delta": -3, "weight": 4, "effect": "heckle"},
		{"name": "Sarcastic Coin", "tip_delta": 1, "weight": 3, "effect": "none"},
		{"name": "Cold Shoulder", "tip_delta": 0, "weight": 5, "effect": "none"}
	],
	Mood.DISTRACTED: [
		{"name": "Phone Scrolling", "tip_delta": 0, "weight": 6, "effect": "none"},
		{"name": "Child's Coin", "tip_delta": 2, "weight": 2, "effect": "generous"},
		{"name": "Traffic Noise", "tip_delta": -1, "weight": 4, "effect": "none"}
	],
	Mood.GENEROUS: [
		{"name": "Large Bill", "tip_delta": 8, "weight": 2, "effect": "generous"},
		{"name": "Group Applause", "tip_delta": 5, "weight": 3, "effect": "generous"},
		{"name": "Photo & Tip", "tip_delta": 3, "weight": 4, "effect": "generous"}
	],
	Mood.CRITICS: [
		{"name": "Thoughtful Nod", "tip_delta": 2, "weight": 4, "effect": "none"},
		{"name": "Harsh Review", "tip_delta": -4, "weight": 2, "effect": "heckle"},
		{"name": "Professional Tip", "tip_delta": 4, "weight": 3, "effect": "generous"}
	],
	Mood.DANCERS: [
		{"name": "Dance Circle", "tip_delta": 6, "weight": 3, "effect": "dance"},
		{"name": "Knocked Over", "tip_delta": -2, "weight": 1, "effect": "heckle"},
		{"name": "Rhythmic Claps", "tip_delta": 3, "weight": 4, "effect": "dance"}
	],
	Mood.ENCORE: [
		{"name": "Encore Chant", "tip_delta": 7, "weight": 3, "effect": "dance"},
		{"name": "Crowd Gathering", "tip_delta": 4, "weight": 4, "effect": "generous"},
		{"name": "Security Warning", "tip_delta": -2, "weight": 2, "effect": "heckle"}
	]
}

# UI References
@onready var mood_label: Label = $"../HUDPanel/TopBar/MoodLabel"
@onready var tip_label: Label = $"../HUDPanel/TopBar/TipLabel"
@onready var reroll_button: Button = $"../HUDPanel/TopBar/RerollButton"
@onready var odds_bar: ProgressBar = $"../HUDPanel/EventOddsBar"
@onready var odds_label: Label = $"../HUDPanel/EventOddsLabel"
@onready var goal_label: Label = $"../HUDPanel/GoalLabel"
@onready var notification_label: Label = $"../NotificationLabel"

# Card System
var card_shuffle_scene = preload("res://scenes/ui/CardShuffle.tscn")
var card_shuffle_instance: Control
var current_luck_modifier = 1.0
var current_tip_multiplier = 1.0
var current_pedestrian: Pedestrian  # Store current pedestrian waiting for cards
var card_shuffle_active = false  # Prevent multiple card shuffles

# Game Objects
@onready var dice: Node2D = $"../Dice2D"
@onready var verse_timer: Timer = $"../VerseTimer"
@onready var lane: Node = $"../LaneInstance"
@onready var busker: Node = $"../BuskerInstance"
@onready var audio_manager: Node = $"../AudioManager"

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	# Wait for all nodes to be ready
	await get_tree().process_frame

	# Connect signals with error checking
	if dice.has_signal("dice_rolled"):
		dice.dice_rolled.connect(_on_dice_roll_complete)
	else:
		print("Warning: Dice node doesn't have dice_rolled signal")

	verse_timer.timeout.connect(_on_verse_complete)
	reroll_button.pressed.connect(_on_reroll_pressed)
	
	# Setup card shuffle system
	_setup_card_shuffle()
	
	_start_new_night()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")

func _start_new_night():
	tips_total = 0
	rerolls_available = 1
	_update_ui()
	_prepare_verse()

func _prepare_verse():
	verse_active = false
	reroll_button.disabled = (rerolls_available <= 0)
	busker.stop_performance()

	# Make sure performance music is stopped during preparation
	if audio_manager:
		audio_manager.stop_performance_music()

	_update_ui()
	await get_tree().create_timer(2.0).timeout
	if not verse_active:
		_roll_dice()

func _roll_dice():
	reroll_button.disabled = true
	dice.roll()

func _on_dice_roll_complete(value: int):
	current_mood = value as Mood
	_update_ui()
	verse_active = true
	busker.start_performance()

	# Start performance music
	if audio_manager:
		audio_manager.start_performance_music()

	verse_timer.start()
	var spawner = lane.get_node("PedestrianSpawner")
	var mood_info = mood_data[current_mood]
	spawner.set_mood_spawn_rate(1.0 + mood_info["event_odds"])

func _on_verse_complete():
	verse_active = false
	busker.stop_performance()

	# Stop performance music
	if audio_manager:
		audio_manager.stop_performance_music()

	var mood_info = mood_data[current_mood]
	var event_fired = rng.randf() < mood_info["event_odds"]
	var tip_change = 0
	var effect_type = "none"
	if event_fired:
		var event = _roll_weighted_event(event_tables[current_mood])
		tip_change = event["tip_delta"]
		effect_type = event["effect"]
		_trigger_crowd_effect(effect_type)
	var base_tip = 3
	var total_gain = int((base_tip + tip_change) * mood_info["mult"])
	tips_total += max(total_gain, 0)
	_update_ui()
	_check_win_condition()

func _roll_weighted_event(events: Array) -> Dictionary:
	var total_weight = 0
	for event in events:
		total_weight += event["weight"]
	var roll = rng.randi_range(1, total_weight)
	var current_weight = 0
	for event in events:
		current_weight += event["weight"]
		if roll <= current_weight:
			return event
	return events[0]

func _trigger_crowd_effect(effect_type: String):
	var spawner = lane.get_node("PedestrianSpawner")
	var target = spawner.get_random_pedestrian()
	if target:
		target.perform_event(effect_type)

func _check_win_condition():
	if tips_total >= nightly_goal:
		mood_label.text = "SUCCESS! New strings acquired!"
		reroll_button.disabled = true
	else:
		await get_tree().create_timer(2.0).timeout
		_prepare_verse()

func _on_reroll_pressed():
	if rerolls_available > 0 and not verse_active:
		rerolls_available -= 1
		_roll_dice()

func _update_ui():
	var mood_info = mood_data.get(current_mood, {"name": "Unknown", "mult": 1.0, "event_odds": 0.0})
	mood_label.text = "Mood: %s (×%.1f)" % [mood_info["name"], mood_info["mult"]]
	tip_label.text = "Tips: $%d" % tips_total
	goal_label.text = "Goal: $%d" % nightly_goal
	reroll_button.text = "Reroll (%d)" % rerolls_available

# Card Shuffle System
func _setup_card_shuffle():
	print("Setting up card shuffle system...")
	# Find the existing CardShuffle instance in the scene
	card_shuffle_instance = get_parent().get_node("CardShuffle")
	if card_shuffle_instance:
		card_shuffle_instance.cards_drawn.connect(_on_cards_drawn)
		card_shuffle_instance.shuffle_skipped.connect(_on_shuffle_skipped)
		print("Card shuffle system ready!")
	else:
		print("ERROR: CardShuffle node not found!")

func trigger_card_shuffle():
	if card_shuffle_instance and not card_shuffle_active:
		card_shuffle_active = true
		current_luck_modifier = 1.0
		current_tip_multiplier = 1.0
		card_shuffle_instance.show_card_shuffle()

func _on_cards_drawn(luck_modifier: float, tip_multiplier: float):
	current_luck_modifier = luck_modifier
	current_tip_multiplier = tip_multiplier
	card_shuffle_active = false
	print("Cards drawn! Luck: %.2f, Tips: %.2f" % [luck_modifier, tip_multiplier])

	# Show notification with card results
	var message = "Cards drawn! Luck: %.2f, Tips: %.2f" % [luck_modifier, tip_multiplier]
	show_notification(message, 2.5)

	# Release the waiting pedestrian
	if current_pedestrian:
		current_pedestrian.continue_after_cards()
		current_pedestrian = null

func _on_shuffle_skipped():
	current_luck_modifier = 1.0
	current_tip_multiplier = 1.0
	card_shuffle_active = false
	print("Card shuffle skipped")

	# Show notification for skipped shuffle
	show_notification("Card shuffle skipped!", 1.5)

	# Release the waiting pedestrian
	if current_pedestrian:
		current_pedestrian.continue_after_cards()
		current_pedestrian = null

# Notification System
func show_notification(message: String, duration: float = 2.0):
	notification_label.text = message

	# Fade in
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)

	# Wait
	await get_tree().create_timer(duration).timeout

	# Fade out
	tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)

# Pedestrian card request handler
func _on_pedestrian_card_request(pedestrian: Pedestrian):
	# Only allow one card shuffle at a time
	if card_shuffle_active:
		pedestrian.continue_after_cards()  # Let them walk away
		return

	print("Pedestrian stopped for cards!")
	show_notification("Pedestrian stopping for cards!", 1.5)
	current_pedestrian = pedestrian  # Store reference to release later
	trigger_card_shuffle()
