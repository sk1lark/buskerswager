extends Node
class_name GameManager

enum Mood { HECKLERS = 1, DISTRACTED = 2, GENEROUS = 3, CRITICS = 4, DANCERS = 5, ENCORE = 6 }

# game state stuff
var tips_total = 0
var nightly_goal = 50
var current_night = 1
var max_nights = 5
var rerolls_available = 1
var current_mood = Mood.DISTRACTED
var verse_active = false
var total_career_earnings = 0
var performance_streak = 0
var performance_chain = 0  # Consecutive successful performances (>= base tip)
var chain_multiplier = 1.0  # Bonus multiplier from chains
var max_chain_achieved = 0  # Track best chain for UI

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

# Cutscene UI References
@onready var cutscene_overlay: CanvasLayer = $"../CutsceneOverlay"
@onready var cutscene_background: ColorRect = $"../CutsceneOverlay/CutsceneBackground"
@onready var cutscene_label: Label = $"../CutsceneOverlay/CutsceneLabel"

# Flash Effect References
@onready var flash_overlay: CanvasLayer = $"../FlashOverlay"
@onready var flash_rect: ColorRect = $"../FlashOverlay/FlashRect"

# Audio References
@onready var dice_sound_player: AudioStreamPlayer = $"../DiceSoundPlayer"
@onready var cards_sound_player: AudioStreamPlayer = $"../CardsSoundPlayer"

# Card System
var card_shuffle_scene = preload("res://scenes/ui/CardShuffle.tscn")
var card_shuffle_instance: Control
var current_luck_modifier = 1.0
var current_tip_multiplier = 1.0
var current_pedestrian: Pedestrian  # Store current pedestrian waiting for cards
var card_shuffle_active = false  # Prevent multiple card shuffles
var card_request_timer: Timer  # Timer for card requests

# Timing-based performance system
var timing_active = false
var timing_windows = []  # Array of timing windows during performance
var timing_hits = 0  # How many perfect hits the player got
var timing_total = 0  # Total timing windows in this performance
var timing_bonus = 1.0  # Bonus multiplier from timing performance

# Instruction system
var instructions_showing = false

# Cutscene system
var cutscene_showing = false

# Notification queue system
var notification_queue = []
var notification_playing = false

# Game Objects
@onready var dice: Node2D = $"../Dice2D"
@onready var verse_timer: Timer = $"../VerseTimer"
@onready var lane: Node = $"../LaneInstance"
@onready var busker: Node = $"../BuskerInstance"
@onready var audio_manager: Node = $"../AudioManager"
@onready var camera: Camera2D = $"../Camera2D"
var environmental_effects: Node2D

# Screen shake variables
var shake_intensity = 0.0
var shake_duration = 0.0
var original_camera_position: Vector2

var rng = RandomNumberGenerator.new()

func _ready():
	print("gamemanager: starting up...")
	rng.randomize()
	# Wait for all nodes to be ready
	await get_tree().process_frame

	# Store original camera position for shake effects
	if camera:
		original_camera_position = camera.position
		print("gamemanager: camera found at: ", camera.position)
	else:
		print("gamemanager: ERROR - camera not found!")

	# Check if lane has background
	if lane:
		var background = lane.get_node("Background")
		if background:
			print("gamemanager: background found, texture: ", background.texture, " position: ", background.position)
		else:
			print("gamemanager: ERROR - background not found in lane!")
	else:
		print("gamemanager: ERROR - lane not found for background check!")

	# Notification label should already have correct font size from scene
	
	# Debug - check if all nodes exist
	print("gamemanager: checking nodes...")
	if not dice:
		print("ERROR: dice node not found!")
		return
	if not busker:
		print("ERROR: busker node not found!")
		return
	if not lane:
		print("ERROR: lane node not found!")
		return
	if not mood_label:
		print("ERROR: mood_label not found!")
		return
	print("gamemanager: all nodes found!")

	# Connect signals with error checking
	if dice.has_signal("dice_rolled"):
		dice.dice_rolled.connect(_on_dice_roll_complete)
		print("gamemanager: dice signal connected")
	else:
		print("Warning: Dice node doesn't have dice_rolled signal")

	verse_timer.timeout.connect(_on_verse_complete)
	reroll_button.pressed.connect(_on_reroll_pressed)

	# Setup card shuffle system
	_setup_card_shuffle()

	# Make this GameManager easily findable for pedestrian connections
	print("gamemanager: registering for pedestrian card requests")

	# Setup environmental effects
	_setup_environmental_effects()

	# Setup card request timer
	card_request_timer = Timer.new()
	card_request_timer.wait_time = 5.0  # 5 second window to play cards
	card_request_timer.one_shot = true
	card_request_timer.timeout.connect(_on_card_request_timeout)
	add_child(card_request_timer)

	# Start quiet background music
	if audio_manager and audio_manager.has_method("play_music"):
		audio_manager.play_music("res://assets/audio/music/backgroundmusic.ogg", true)
		# Make it really quiet
		if audio_manager.music_player:
			audio_manager.music_player.volume_db = -25.0
		print("gamemanager: started quiet background music")

	# Initialize night without showing message yet
	_initialize_night_stats()
	print("gamemanager: initialization complete!")

	# Make sure all UI elements are properly initialized
	if cutscene_background and cutscene_label:
		print("gamemanager: cutscene elements found")
	else:
		print("gamemanager: ERROR - cutscene elements not found!")
		print("gamemanager: cutscene_background: ", cutscene_background)
		print("gamemanager: cutscene_label: ", cutscene_label)

	# Show cutscene first, then instructions
	await get_tree().create_timer(1.0).timeout
	_show_cutscene()

func _process(delta):
	# Handle screen shake
	if shake_duration > 0:
		shake_duration -= delta
		if camera and shake_intensity > 0:
			var offset = Vector2(
				rng.randf_range(-shake_intensity, shake_intensity),
				rng.randf_range(-shake_intensity, shake_intensity)
			)
			camera.position = original_camera_position + offset
	elif camera:
		camera.position = original_camera_position

func _input(event):
	# Dismiss cutscene on any key press
	if cutscene_showing:
		if event is InputEventKey and event.pressed:
			_dismiss_cutscene()
		return  # Don't process any other inputs while cutscene is showing

	# Dismiss instructions only on I key press
	if instructions_showing:
		if event is InputEventKey and event.pressed and event.keycode == KEY_I:
			_dismiss_instructions()
		return  # Don't process any other inputs while instructions are showing

	if event.is_action_pressed("ui_cancel"):  # ESC key
		get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")

	# Manual dice rolling with R key or Enter
	if (event is InputEventKey and event.pressed and event.keycode == KEY_R) or event.is_action_pressed("ui_accept"):
		print("GameManager: R key detected!")
		if not verse_active and not dice.is_rolling:
			print("GameManager: Rolling dice...")
			screen_shake(3.0, 0.15)  # Tactile feedback for dice roll
			_roll_dice()
		else:
			print("GameManager: Cannot roll - verse_active:", verse_active, " dice.is_rolling:", dice.is_rolling)

	# Timing performance input during verses with Spacebar
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if timing_active:
			_check_timing_input()

	# Manual card playing with P key
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		print("GameManager: P key detected!")
		screen_shake(2.0, 0.1)  # Tactile feedback for card play
		_play_cards()

	# Show instructions with I key
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		_show_instructions()

func _initialize_night_stats():
	# Initialize night stats without showing message (for first night after cutscene)
	tips_total = 0
	rerolls_available = 1 + (current_night - 1) / 2  # More rerolls on later nights
	nightly_goal = 50 + (current_night - 1) * 25  # Goals get harder
	performance_streak = 0
	performance_chain = 0  # Reset chain each night for fresh challenge
	chain_multiplier = 1.0
	_update_ui()

func _start_new_night():
	# Initialize stats
	_initialize_night_stats()

	# Show night intro with dramatic pause
	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	if max_chain_achieved > 1:
		night_message += "\nBest Chain: %d" % max_chain_achieved
	show_notification(night_message, 3.0)
	await get_tree().create_timer(3.5).timeout

	_prepare_verse()

func _prepare_verse():
	verse_active = false
	reroll_button.disabled = (rerolls_available <= 0)
	busker.stop_performance()

	# Make sure performance music is stopped during preparation
	if audio_manager:
		audio_manager.stop_performance_music()

	_update_ui()

	# Wait a moment, then make the dice glow to indicate it's ready to roll
	await get_tree().create_timer(0.5).timeout
	if dice and dice.has_method("start_glow"):
		dice.start_glow()
		print("gamemanager: dice should now be glowing")
	else:
		print("gamemanager: ERROR - dice not found or missing glow method")

func _roll_dice():
	reroll_button.disabled = true

	# Stop dice glow since we're rolling
	if dice and dice.has_method("stop_glow"):
		dice.stop_glow()

	# Add dramatic pause and build-up
	show_notification("Rolling dice... 🎲", 1.0)
	screen_shake(2.0, 0.3)  # Shake for dice roll anticipation

	# Play dice sound effect
	if dice_sound_player:
		dice_sound_player.play()

	dice.roll()

func _on_dice_roll_complete(value: int):
	current_mood = value as Mood

	# Show mood result with flair
	var mood_info = mood_data[current_mood]
	var mood_message = "🎲 %s! (×%.1f)" % [mood_info["name"].capitalize(), mood_info["mult"]]
	show_notification(mood_message, 2.0)

	_update_ui()
	verse_active = true
	busker.start_performance()

	# Start performance music
	if audio_manager:
		audio_manager.start_performance_music()

	# Start environmental effects
	if environmental_effects:
		environmental_effects.start_performance_effects(busker.global_position)

	# Start timing-based performance system
	_start_timing_performance()

	verse_timer.start()
	var spawner = lane.get_node("PedestrianSpawner")
	spawner.set_mood_spawn_rate(1.0 + mood_info["event_odds"])

func _on_verse_complete():
	verse_active = false
	busker.stop_performance()

	# Stop timing performance system
	_stop_timing_performance()

	# Stop performance music
	if audio_manager:
		audio_manager.stop_performance_music()

	# Stop environmental effects
	if environmental_effects:
		environmental_effects.stop_performance_effects()

	var mood_info = mood_data[current_mood]
	var event_fired = rng.randf() * current_luck_modifier < mood_info["event_odds"]
	var tip_change = 0
	var effect_type = "none"
	if event_fired:
		var event = _roll_weighted_event(event_tables[current_mood])
		tip_change = event["tip_delta"]
		effect_type = event["effect"]
		_trigger_crowd_effect(effect_type)
		show_notification("Event: " + event["name"], 2.0)

	var base_tip = 3
	var streak_bonus = 1.0 + (performance_streak * 0.1)  # 10% per streak

	# Performance Chain System - rewards consistent good performances
	var base_performance_value = int((base_tip + tip_change) * mood_info["mult"])
	if base_performance_value >= base_tip:  # Successful performance
		performance_chain += 1
		max_chain_achieved = max(max_chain_achieved, performance_chain)
		# Chain multiplier: 1.0, 1.2, 1.5, 1.8, 2.2, 2.6, 3.0+ (caps at 3.0)
		chain_multiplier = 1.0 + min(performance_chain * 0.4, 2.0)
	else:  # Failed performance breaks the chain
		if performance_chain > 0:
			show_notification("💔 Chain Broken! Was at %dx" % performance_chain, 2.0)
		performance_chain = 0
		chain_multiplier = 1.0

	var total_gain = int(base_performance_value * current_tip_multiplier * streak_bonus * chain_multiplier * timing_bonus)

	# Update streak
	if total_gain > 0:
		performance_streak += 1
	else:
		performance_streak = 0
	tips_total += max(total_gain, 0)

	# Show tip gain with MAXIMUM JUICE and emoji variety!
	var tip_message = "+$%d" % max(total_gain, 0)

	# Add emoji based on tip amount
	if total_gain >= 20:
		tip_message += " 💰💰💰"
	elif total_gain >= 15:
		tip_message += " 💰💰"
	elif total_gain >= 8:
		tip_message += " 💰"
	elif total_gain > 0:
		tip_message += " 🪙"

	if current_tip_multiplier > 1.0:
		tip_message += " (×%.1f cards!)" % current_tip_multiplier
	if performance_streak > 1:
		tip_message += " (🔥%dx streak!)" % performance_streak
	if performance_chain > 1:
		tip_message += " (⛓️%dx chain!)" % performance_chain
	if timing_bonus > 1.0:
		tip_message += " (🎵%.1fx timing!)" % timing_bonus

	# Screen shake based on tip amount - more money = more shake!
	var shake_amount = min(total_gain * 0.5, 8.0)
	if shake_amount > 0:
		screen_shake(shake_amount, 0.3)

	# Make busker celebrate big tips!
	if total_gain >= 8 and busker and busker.has_method("celebrate"):
		busker.celebrate()

	# Enhanced audio feedback based on tip amount
	if audio_manager and total_gain > 0:
		if total_gain >= 15:  # Big tip
			audio_manager.play_yippee_sound()
			_flash_screen()  # Extra flash for big tips
		elif total_gain >= 8:  # Good tip
			audio_manager.play_yippee_sound()
		# Small tips get no special sound to make bigger ones feel better

	show_notification(tip_message, 2.5)

	# Reset modifiers after use
	current_luck_modifier = 1.0
	current_tip_multiplier = 1.0

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

		# Add environmental effect for the event
		if environmental_effects:
			environmental_effects.trigger_event_effect(effect_type, target.global_position)

func _check_win_condition():
	if tips_total >= nightly_goal:
		total_career_earnings += tips_total
		current_night += 1

		# Stop all performance activities and music when winning
		verse_active = false
		busker.stop_performance()
		if audio_manager:
			audio_manager.stop_performance_music()

		# Stop environmental effects
		if environmental_effects:
			environmental_effects.stop_performance_effects()

		# Stop the verse timer if it's running
		if verse_timer:
			verse_timer.stop()

		if current_night > max_nights:
			# Game complete! MASSIVE SHAKE!
			screen_shake(15.0, 1.0)
			show_notification("🎉 LEGENDARY BUSKER! 🎉\nCareer Total: $%d" % total_career_earnings, 5.0)
			await get_tree().create_timer(6.0).timeout
			get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")
		else:
			# Next night - celebrate with shake
			screen_shake(8.0, 0.6)
			show_notification("Night %d Complete!\nEarned: $%d" % [current_night - 1, tips_total], 3.0)
			await get_tree().create_timer(4.0).timeout
			_start_new_night()
	else:
		await get_tree().create_timer(3.0).timeout
		_prepare_verse()

func _on_reroll_pressed():
	if rerolls_available > 0 and not verse_active:
		rerolls_available -= 1
		_roll_dice()

func _update_ui():
	var mood_info = mood_data.get(current_mood, {"name": "Unknown", "mult": 1.0, "event_odds": 0.0})
	mood_label.text = "Mood: %s (×%.1f)" % [mood_info["name"], mood_info["mult"]]

	var tip_text = "Tips: $%d / $%d" % [tips_total, nightly_goal]
	if performance_streak > 1:
		tip_text += " 🔥%d" % performance_streak
	if performance_chain > 1:
		tip_text += " ⛓️%d" % performance_chain
	tip_label.text = tip_text

	var goal_text = "Night %d/%d | Career: $%d" % [current_night, max_nights, total_career_earnings]
	if max_chain_achieved > 1:
		goal_text += " | Best Chain: %d" % max_chain_achieved
	goal_label.text = goal_text
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

		# Play card shuffle sound effect
		if cards_sound_player:
			cards_sound_player.play()

		card_shuffle_instance.show_card_shuffle()

func _on_cards_drawn(luck_modifier: float, tip_multiplier: float):
	current_luck_modifier = luck_modifier
	current_tip_multiplier = tip_multiplier
	card_shuffle_active = false
	print("Cards drawn! Luck: %.2f, Tips: %.2f" % [luck_modifier, tip_multiplier])

	# Show notification with card results
	var message = "Cards drawn! Luck: %.2f, Tips: ×%.2f" % [luck_modifier, tip_multiplier]
	if tip_multiplier >= 2.0:  # High multiplier suggests synergies
		message += "\n🎰 SYNERGY BONUS!"
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

# Notification System - Fixed to prevent overlapping
func show_notification(message: String, duration: float = 2.0):
	# Don't queue if instructions or cutscene are showing
	if instructions_showing or cutscene_showing:
		return

	# Add to queue instead of showing immediately
	notification_queue.append({"message": message, "duration": duration})

	# Start processing queue if not already running
	if not notification_playing:
		_process_notification_queue()

func _process_notification_queue():
	if notification_queue.is_empty():
		notification_playing = false
		return

	notification_playing = true
	var notification = notification_queue.pop_front()

	# Show this notification
	notification_label.text = notification.message
	notification_label.modulate.a = 0.0
	notification_label.scale = Vector2(0.8, 0.8)

	# Simple fade in
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.3)

	# Wait
	await get_tree().create_timer(notification.duration).timeout

	# Simple fade out
	tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Process next notification
	_process_notification_queue()

# Screen shake system for maximum juice!
func screen_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

# Environmental Effects Setup
func _setup_environmental_effects():
	# Create and setup environmental effects
	var EnvironmentalEffectsScene = preload("res://scripts/effects/EnvironmentalEffects.gd")
	environmental_effects = Node2D.new()
	environmental_effects.name = "EnvironmentalEffects"
	environmental_effects.set_script(EnvironmentalEffectsScene)
	get_parent().add_child(environmental_effects)
	print("Environmental effects system ready!")

# Pedestrian card request handler
func _on_pedestrian_card_request(pedestrian: Pedestrian):
	print("gamemanager: received card request from pedestrian!")

	# Only allow one card shuffle at a time
	if card_shuffle_active or current_pedestrian:
		print("gamemanager: card shuffle busy, letting pedestrian walk away")
		pedestrian.continue_after_cards()  # Let them walk away
		return

	print("gamemanager: pedestrian stopped for cards!")
	show_notification("Pedestrian wants cards! Press P to play!", 5.0)
	current_pedestrian = pedestrian  # Store reference to release later
	card_request_timer.start()  # Start 5-second timer
	# Don't auto-trigger cards - wait for P key!

func _on_card_request_timeout():
	# Pedestrian got tired of waiting
	if current_pedestrian:
		show_notification("Pedestrian walked away...", 1.5)
		current_pedestrian.continue_after_cards()
		current_pedestrian = null

# Timing-based Performance System - Simplified
func _start_timing_performance():
	timing_active = true
	timing_hits = 0
	timing_total = 2  # Just 2 timing windows to reduce spam
	timing_bonus = 1.0

	# Don't show initial message - just wait for first window

	# Create timing windows with lots of space
	for i in range(timing_total):
		var delay = 4.0 + (i * 3.0)  # Windows at 4s and 7s - very spaced out
		await get_tree().create_timer(delay).timeout
		if timing_active:  # Only if performance is still active
			_create_timing_window()

func _create_timing_window():
	show_notification("HIT SPACEBAR NOW!", 1.5)  # Clear, single message
	_flash_screen()  # Add screen flash when timing window appears
	timing_windows.append(get_tree().create_timer(1.5))  # 1.5 second window - very forgiving

func _check_timing_input():
	# Check if there's an active timing window
	for i in range(timing_windows.size() - 1, -1, -1):  # Check backwards
		var window = timing_windows[i]
		if window.time_left > 0:
			# Perfect hit!
			timing_hits += 1
			timing_windows.remove_at(i)

			# Varied feedback based on timing accuracy
			var accuracy = window.time_left / 1.5  # How much time was left (higher = better timing)
			if accuracy > 0.8:
				show_notification("PERFECT! 🎵", 1.0)
				screen_shake(3.0, 0.25)
				_flash_screen()  # Flash for perfect timing
			elif accuracy > 0.5:
				show_notification("Great! ♪", 1.0)
				screen_shake(2.0, 0.2)
			else:
				show_notification("Good! ♫", 1.0)
				screen_shake(1.5, 0.15)
			return

	# No active window - don't show miss message to reduce spam

func _stop_timing_performance():
	timing_active = false
	timing_windows.clear()

	# Calculate timing bonus based on accuracy
	var accuracy = float(timing_hits) / float(timing_total) if timing_total > 0 else 0.0
	timing_bonus = 1.0 + (accuracy * 0.5)  # Up to 1.5x multiplier for perfect timing

	var timing_message = "Timing: %d/%d" % [timing_hits, timing_total]
	if accuracy >= 0.75:
		timing_message += " 🌟 EXCELLENT!"
	elif accuracy >= 0.5:
		timing_message += " 👍 Good!"
	elif accuracy > 0:
		timing_message += " 📈 Keep trying!"
	else:
		timing_message += " 💥 Try again!"

	print("Timing performance: ", timing_message)

func _show_instructions():
	var instructions = """BUSKER'S WAGER CONTROLS

DICE: Press R/ENTER or click dice to roll
TIMING: Hit SPACEBAR on the beat during performances
CARDS: Press P to play cards when available
ESC: Return to menu
I: Show/hide these instructions

GOAL: Master timing and card synergies to maximize tips!
Build performance chains and hit perfect timing for huge bonuses!

Press I to continue..."""

	instructions_showing = true

	# Clear the notification queue and stop processing
	notification_queue.clear()
	notification_playing = false

	# Show instructions directly without queue
	if notification_label:
		notification_label.add_theme_font_size_override("font_size", 36)  # Smaller for instructions
		notification_label.text = instructions
		notification_label.modulate.a = 1.0
		notification_label.scale = Vector2(1.0, 1.0)

func _dismiss_instructions():
	instructions_showing = false

	# Hide instructions immediately
	if notification_label:
		notification_label.modulate.a = 0.0
		notification_label.remove_theme_font_size_override("font_size")  # Reset to default 72px

	# Resume normal notification processing
	notification_playing = false

	# Show night intro and start the game
	_show_night_intro_and_start()

func _show_night_intro_and_start():
	# Show night intro with dramatic pause
	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	if max_chain_achieved > 1:
		night_message += "\nBest Chain: %d" % max_chain_achieved
	show_notification(night_message, 3.0)
	await get_tree().create_timer(3.5).timeout

	_prepare_verse()

func _play_cards():
	# Only allow card playing when there's a waiting pedestrian
	if current_pedestrian and not card_shuffle_active:
		print("Player pressed P - starting card shuffle!")
		card_request_timer.stop()  # Stop the timeout timer
		trigger_card_shuffle()
	else:
		show_notification("No cards available to play!", 1.5)

# Cutscene system
func _show_cutscene():
	print("gamemanager: showing cutscene...")
	var cutscene_text = """I guess this should do. I hope the townsfolk appreciate my music today. I need the money.

Press any key to continue..."""

	cutscene_showing = true

	# Clear the notification queue and stop processing
	notification_queue.clear()
	notification_playing = false

	# Show cutscene background with white text
	if cutscene_background and cutscene_label:
		print("gamemanager: setting cutscene visible")
		cutscene_background.visible = true
		cutscene_label.visible = true
		cutscene_label.text = cutscene_text
		print("gamemanager: cutscene should now be visible")
	else:
		print("gamemanager: ERROR - cutscene elements are null!")

func _dismiss_cutscene():
	cutscene_showing = false

	# Hide cutscene overlay
	if cutscene_background and cutscene_label:
		cutscene_background.visible = false
		cutscene_label.visible = false

	# Show instructions after cutscene
	_show_instructions()

# Flash Effect System
func _flash_screen():
	if flash_rect:
		# Quick white flash
		flash_rect.color = Color(1, 1, 1, 0.3)  # Semi-transparent white
		var tween = create_tween()
		tween.tween_property(flash_rect, "color", Color(1, 1, 1, 0), 0.2)  # Fade out quickly
