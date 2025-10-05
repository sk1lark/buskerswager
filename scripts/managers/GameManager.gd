extends Node

class_name GameManager

# Game state
var tips_total = 0
var nightly_goal = 50
var current_night = 1
var max_nights = 5
var total_career_earnings = 0
var night_transition_in_progress = false  # Prevent duplicate night transitions

# Typing challenge state
var falling_words = []  # Array of active FallingWord nodes
var words_completed = 0
var words_required = 7
var is_in_typing_challenge = false
var current_pedestrian: Node = null
var word_spawn_timer: float = 0.0
var word_spawn_interval: float = 4.0  # Spawn a word every 4 seconds (increased from 3.0)
var challenge_duration: float = 30.0  # Challenge lasts 30 seconds (increased from 25.0)
var challenge_timer: float = 0.0
var words_missed = 0  # Count of words that hit the ground
var challenge_tips_earned = 0  # Track actual tips earned during this challenge

# CHAIN MODE: Words must be typed in order!
var chain_index = 0  # Which word in the chain player has completed (0 = none yet)
var chain_counter = 0  # Total words spawned this challenge (for numbering)

# LIFE SYSTEM: 3 strikes per challenge
var lives = 3
var max_lives = 3

# POWER-UP SYSTEM
var active_powerups = []  # Array of active powerup names
var powerup_spawn_timer: float = 0.0
var powerup_spawn_interval: float = 8.0  # Power-up every 8 seconds
var has_shield = false
var slowmo_active = false

# Aiming and shooting system
var aiming_line: Line2D
var currently_locked_word: FallingWord = null  # The word player is currently typing

# Random events system
var event_timer: float = 0.0
var event_interval: float = 5.0  # Random event every 5 seconds
var active_modifier: String = ""  # Current active event
var modifier_duration: float = 0.0

# ORIGINAL MECHANICS - Rhythm combo system
var last_word_time: float = 0.0
var combo_count: int = 0
var combo_window: float = 2.5  # Must complete word within 2.5 seconds to maintain combo
var combo_multiplier: float = 1.0
var max_combo: int = 0

# Crowd mood system (original mechanic)
var crowd_mood: float = 50.0  # 0-100, affects tip amounts
var mood_label: Label

# Risk/Reward betting (original mechanic)
var current_bet: int = 0
var can_place_bet: bool = true

# Advanced word pool - will be shuffled and never repeated
var all_words = [
	# Complex/Advanced words
	"ephemeral", "serendipity", "melancholy", "whimsical", "ethereal", "luminous", "cascading",
	"harmonious", "nostalgic", "eloquent", "resplendent", "magnificent", "spectacular", "enchanting",
	"mysterious", "peculiar", "extraordinary", "exquisite", "breathtaking", "mesmerizing",
	"cacophony", "symphony", "crescendo", "diminuendo", "allegro", "fortissimo", "pianissimo",
	"virtuoso", "repertoire", "improvisation", "accompaniment", "orchestration", "composition",
	"rhapsody", "serenade", "nocturne", "overture", "prelude", "interlude", "finale",
	"troubadour", "minstrel", "wanderer", "vagabond", "storyteller", "entertainer", "performer",
	"labyrinth", "constellation", "kaleidoscope", "silhouette", "renaissance", "cathedral",
	"manuscript", "chronicle", "anthology", "tapestry", "sanctuary", "pilgrimage", "odyssey",
	"paradox", "enigma", "conundrum", "phenomenon", "quintessence", "metamorphosis", "revelation",
	"transcendent", "iridescent", "incandescent", "fluorescent", "phosphorescent", "translucent",
	"magnificent", "grandiose", "spectacular", "stupendous", "phenomenal", "extraordinary",
	"bewildering", "captivating", "enthralling", "fascinating", "intriguing", "mystifying",
	"perplexing", "puzzling", "baffling", "confounding", "astounding", "astonishing",
	"delightful", "wonderful", "marvelous", "glorious", "splendid", "brilliant", "radiant",
	"exuberant", "jubilant", "euphoric", "ecstatic", "elated", "overjoyed", "rapturous",
	"mellifluous", "sonorous", "resonant", "harmonious", "melodious", "euphonious", "dulcet"
]

var used_words = []  # Track words we've already used
var available_words = []  # Pool of words not yet used

# UI References
@onready var performance_label: Label = $"../HUDPanel/TopBar/PerformanceLabel"
@onready var tip_label: Label = $"../HUDPanel/TopBar/TipLabel"
@onready var goal_label: Label = $"../HUDPanel/GoalLabel"
@onready var notification_label: Label = $"../NotificationLayer/NotificationLabel"
@onready var current_word_label: Label = $"../TypingArea/CurrentWordLabel"
@onready var typed_input_label: Label = $"../TypingArea/TypedInputLabel"
@onready var progress_bar_fill: ColorRect = $"../HUDPanel/ProgressBarBackground/ProgressBarFill"
@onready var progress_bar_label: Label = $"../HUDPanel/ProgressBarBackground/ProgressBarLabel"

# NEW UI for lives and power-ups
var lives_container: HBoxContainer
var powerup_container: HBoxContainer
var last_displayed_lives: int = -1  # Track to avoid recreating hearts every frame

# Cutscene UI References
@onready var cutscene_overlay: CanvasLayer = $"../CutsceneOverlay"
@onready var cutscene_background: ColorRect = $"../CutsceneOverlay/CutsceneBackground"
@onready var cutscene_label: Label = $"../CutsceneOverlay/CutsceneLabel"

# Flash Effect References
@onready var flash_overlay: CanvasLayer = $"../FlashOverlay"
@onready var flash_rect: ColorRect = $"../FlashOverlay/FlashRect"

# Dim Overlay References
@onready var dim_overlay: CanvasLayer = $"../DimOverlay"
@onready var dim_rect: ColorRect = $"../DimOverlay/DimRect"

# Game Objects
@onready var performance_timer: Timer = $"../PerformanceTimer"
@onready var lane: Node = $"../LaneInstance"
@onready var busker: Node = $"../BuskerInstance"
@onready var audio_manager: Node = $"../AudioManager"
@onready var camera: Camera2D = $"../Camera2D"
@onready var pedestrian_spawner: Node = $"../LaneInstance/PedestrianSpawner"

# Coin pile system
var coin_pile_position: Vector2
var coin_pile_count: int = 0
var coin_sprites: Array = []

# Screen shake variables
var shake_intensity = 0.0
var shake_duration = 0.0
var original_camera_position: Vector2

# Instruction system
var instructions_showing = false
var instructions_dismissed_once = false  # Track if instructions were dismissed

# Cutscene system
var cutscene_showing = false

# Notification queue system
var notification_queue = []
var notification_playing = false

# Performance music tracks
var performance_tracks = [
	"res://assets/audio/music/performance/123.mp3",
	"res://assets/audio/music/performance/12345.mp3",
	"res://assets/audio/music/performance/123456.mp3",
	"res://assets/audio/music/performance/1234567.mp3"
]
var current_performance_music: AudioStreamPlayer = null

var rng = RandomNumberGenerator.new()

func _ready():
	# Allow this node to process inputs even when paused (for instructions/cutscenes)
	process_mode = Node.PROCESS_MODE_ALWAYS

	rng.randomize()
	await get_tree().process_frame

	# Store original camera position for shake effects
	if camera:
		original_camera_position = camera.position

	# Create aiming line
	_setup_aiming_line()

	# Setup new UI elements
	_setup_lives_ui()
	_setup_powerup_ui()

	# Validate critical nodes
	if not busker or not lane or not performance_label:
		push_error("GameManager: Critical nodes missing!")
		return

	# Setup coin pile position (to the right of busker)
	if busker:
		coin_pile_position = busker.global_position + Vector2(80, 30)

	# Performance timer no longer used - typing challenges are triggered by pedestrians

	# Start quiet background music
	if audio_manager and audio_manager.has_method("play_music"):
		audio_manager.play_music("res://assets/audio/music/backgroundmusic.ogg", true)
		if audio_manager.music_player:
			audio_manager.music_player.volume_db = -25.0

	# Initialize night stats
	_initialize_night_stats()

	# Show opening cutscene
	await get_tree().create_timer(1.0).timeout
	_show_cutscene(current_night)

	# Wait for cutscene to be dismissed
	while cutscene_showing:
		await get_tree().create_timer(0.1).timeout

	# Show instructions automatically
	_show_instructions()

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

	# Update aiming line during typing challenge
	if is_in_typing_challenge and aiming_line and is_instance_valid(aiming_line) and busker:
		var mouse_pos = get_viewport().get_mouse_position()
		aiming_line.points[0] = busker.global_position
		aiming_line.points[1] = mouse_pos
		aiming_line.visible = currently_locked_word == null  # Hide when typing

	# Handle typing challenge
	if is_in_typing_challenge:
		# Apply slowmo if active
		var effective_delta = delta
		if slowmo_active:
			effective_delta = delta * 0.5  # Half speed

		challenge_timer += delta
		word_spawn_timer += delta
		event_timer += delta
		powerup_spawn_timer += delta

		# Spawn new words periodically (more words on higher nights)
		var max_words = _get_max_words_for_night()
		if word_spawn_timer >= word_spawn_interval:
			word_spawn_timer = 0.0
			if falling_words.size() < max_words:
				_spawn_falling_word()

		# Spawn power-ups periodically
		if powerup_spawn_timer >= powerup_spawn_interval:
			powerup_spawn_timer = 0.0
			_spawn_powerup()

		# Trigger random events
		if event_timer >= event_interval:
			event_timer = 0.0
			_trigger_random_event()

		# Handle active modifier duration
		if modifier_duration > 0:
			modifier_duration -= delta
			if modifier_duration <= 0:
				_clear_modifier()

		# End challenge after duration
		if challenge_timer >= challenge_duration:
			_end_typing_challenge()

func _input(event):
	# Dismiss cutscene on any key press
	if cutscene_showing:
		if event is InputEventKey and event.pressed:
			_dismiss_cutscene()
		return

	# Dismiss instructions only on I key press
	if instructions_showing:
		if event is InputEventKey and event.pressed and event.keycode == KEY_I:
			_dismiss_instructions()
		return

	if event.is_action_pressed("ui_cancel"):  # ESC key
		get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")

	# Show instructions with I key (only if not dismissed yet and not in typing challenge)
	if not instructions_dismissed_once and not is_in_typing_challenge and event is InputEventKey and event.pressed and event.keycode == KEY_I:
		_show_instructions()

	# Handle mouse click to shoot music note during typing challenge
	if is_in_typing_challenge and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if currently_locked_word == null:  # Only shoot if not currently typing
			_shoot_music_note()

	# Handle typing input during typing challenge (only if word is locked)
	if is_in_typing_challenge and event is InputEventKey and event.pressed and currently_locked_word != null:
		_handle_falling_word_input(event)

# Old typing functions removed - now using falling words system

func _initialize_night_stats():
	tips_total = 0
	nightly_goal = 50 + (current_night - 1) * 25
	_update_ui()

func _start_new_night():
	_initialize_night_stats()
	night_transition_in_progress = false  # Reset flag for new night

	# Stop spawner temporarily
	if pedestrian_spawner and pedestrian_spawner.spawn_timer:
		pedestrian_spawner.spawn_timer.stop()

	# Clear any falling words
	for word in falling_words:
		if is_instance_valid(word):
			word.queue_free()
	falling_words.clear()

	# Show night rules (waits internally and undims when done)
	await _show_night_rules()

	# Show night goal with large text (dims, shows, then undims when done)
	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	await _show_large_notification(night_message, 3.0)

	# Small delay to ensure undim animation is fully complete
	await get_tree().create_timer(0.2).timeout

	# Resume spawner after everything is fully visible
	if pedestrian_spawner and pedestrian_spawner.has_method("start_spawning"):
		pedestrian_spawner.start_spawning()

	# Game now runs passively - pedestrians trigger typing challenges as they walk by
	print("Night started - waiting for pedestrians...")

func _check_win_condition():
	# Prevent duplicate transitions
	if night_transition_in_progress:
		return

	if tips_total >= nightly_goal:
		night_transition_in_progress = true
		total_career_earnings += tips_total
		current_night += 1

		if current_night > max_nights:
			# Game complete!
			screen_shake(15.0, 1.0)
			show_notification("*** LEGENDARY BUSKER! ***\nCareer Total: $%d" % total_career_earnings, 5.0)
			await get_tree().create_timer(6.0).timeout
			get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")
		else:
			# Next night - challenges already ended by celebration
			# Clear any remaining falling words
			for word in falling_words:
				if is_instance_valid(word):
					word.queue_free()
			falling_words.clear()

			# Brief pause before cutscene (celebration already showed)
			await get_tree().create_timer(0.5).timeout

			# Show cutscene before next night
			_show_cutscene(current_night)

			# Wait for player to dismiss cutscene
			while cutscene_showing:
				await get_tree().create_timer(0.1).timeout

			_start_new_night()
	else:
		# Not enough money - reset and keep trying
		show_notification("Need $%d more!\nKeep going..." % [nightly_goal - tips_total], 2.5)
		# Pedestrians will continue to walk by and trigger more challenges

func _update_ui():
	performance_label.text = "Words: %d / %d" % [words_completed, words_required]
	tip_label.text = "Tips: $%d / $%d" % [tips_total, nightly_goal]
	goal_label.text = "Night %d/%d | Career: $%d" % [current_night, max_nights, total_career_earnings]

	# Update lives display (only if lives changed)
	if lives_container and lives != last_displayed_lives:
		last_displayed_lives = lives

		# Clear existing hearts
		for child in lives_container.get_children():
			child.queue_free()

		# Add heart images
		for i in range(max_lives):
			var heart = TextureRect.new()
			heart.texture = load("res://assets/sprites/ui/heart.png")
			heart.custom_minimum_size = Vector2(32, 32)
			heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

			# Dim the heart if it's lost
			if i >= lives:
				heart.modulate = Color(0.3, 0.3, 0.3, 0.5)

			lives_container.add_child(heart)

	# Update progress bar
	if progress_bar_fill and progress_bar_label:
		var progress = clamp(float(tips_total) / float(nightly_goal), 0.0, 1.0)
		var bar_width = 194.0  # Total width minus padding (200 - 6)
		progress_bar_fill.size.x = bar_width * progress
		progress_bar_label.text = "$%d / $%d" % [tips_total, nightly_goal]

		# Change color based on progress
		if progress >= 1.0:
			progress_bar_fill.color = Color(1.0, 0.8, 0.2, 1.0)  # Golden when complete
		elif progress >= 0.75:
			progress_bar_fill.color = Color(0.3, 0.9, 0.3, 1.0)  # Bright green when close
		elif progress >= 0.5:
			progress_bar_fill.color = Color(0.5, 0.8, 0.3, 1.0)  # Yellow-green
		else:
			progress_bar_fill.color = Color(0.2, 0.7, 0.3, 1.0)  # Green

# Notification System
func show_notification(message: String, duration: float = 2.0):
	if instructions_showing or cutscene_showing:
		return

	notification_queue.append({"message": message, "duration": duration})

	if not notification_playing:
		_process_notification_queue()

# Instant notification that bypasses the queue for immediate feedback
func _show_instant_notification(message: String, duration: float = 1.0):
	if instructions_showing or cutscene_showing or not notification_label:
		return

	# Clear queue and stop current notifications for critical instant feedback
	notification_queue.clear()
	notification_playing = false

	# Show immediately
	notification_label.remove_theme_font_size_override("font_size")
	notification_label.text = message
	notification_label.modulate.a = 1.0
	notification_label.scale = Vector2(1.2, 1.2)

	# Quick pop-in animation
	var tween = create_tween()
	tween.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.15)

	# Auto-fade after duration
	await get_tree().create_timer(duration).timeout

	tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.2)
	await tween.finished

# BIG FLASHY COMBO NOTIFICATION with white outline!
func _show_big_combo_notification(combo: int):
	if instructions_showing or cutscene_showing or not notification_label:
		return

	# Clear queue
	notification_queue.clear()
	notification_playing = false

	# Configure for BIG combo text
	var font_size = 64 + (combo * 8)  # Gets bigger with combo!
	notification_label.add_theme_font_size_override("font_size", font_size)
	notification_label.add_theme_constant_override("outline_size", 12)  # BIG white outline
	notification_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))  # White

	notification_label.text = "%dX COMBO!" % combo
	notification_label.modulate = Color(1.0, 0.6 + (combo * 0.05), 0.0, 1.0)  # Orange that gets brighter
	notification_label.scale = Vector2(0.5, 0.5)

	# MASSIVE pop-in with elastic bounce
	var tween = create_tween()
	tween.tween_property(notification_label, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

	await get_tree().create_timer(0.7).timeout

	# Fade out
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(notification_label, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(notification_label, "scale", Vector2(1.2, 1.2), 0.25)
	await fade_tween.finished

	# Reset overrides
	notification_label.remove_theme_font_size_override("font_size")
	notification_label.remove_theme_constant_override("outline_size")
	notification_label.remove_theme_color_override("font_outline_color")
	notification_label.scale = Vector2(1.0, 1.0)

func _process_notification_queue():
	if notification_queue.is_empty():
		notification_playing = false
		print("Notification queue empty")
		return

	notification_playing = true
	var notification = notification_queue.pop_front()

	if not notification_label:
		push_error("notification_label is null!")
		notification_playing = false
		return

	# Make sure font size is back to default for notifications
	notification_label.remove_theme_font_size_override("font_size")

	print("Displaying notification: ", notification.message, " for ", notification.duration, " seconds")
	notification_label.text = notification.message
	notification_label.modulate.a = 0.0
	notification_label.scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.3)

	print("Waiting for duration...")
	await get_tree().create_timer(notification.duration).timeout
	print("Duration complete, fading out...")

	tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	print("Fade out complete")

	_process_notification_queue()

# Large notification for night goals
func _show_large_notification(message: String, duration: float = 3.0):
	if instructions_showing or cutscene_showing or not notification_label:
		return

	# Clear queue and stop current notifications
	notification_queue.clear()
	notification_playing = false

	# Dim the game
	await _show_dim_overlay()

	# Make text LARGE
	notification_label.add_theme_font_size_override("font_size", 48)
	notification_label.text = message
	notification_label.modulate.a = 0.0
	notification_label.scale = Vector2(0.5, 0.5)

	# Big pop-in animation
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(notification_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	# Settle to normal size
	var settle = create_tween()
	settle.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.2)

	# Wait for duration
	await get_tree().create_timer(duration).timeout

	# Fade out
	var fade = create_tween()
	fade.tween_property(notification_label, "modulate:a", 0.0, 0.4)
	await fade.finished

	# Reset
	notification_label.remove_theme_font_size_override("font_size")
	notification_label.scale = Vector2(1.0, 1.0)

	# Undim the game
	await _hide_dim_overlay()

# Dim overlay functions
func _show_dim_overlay():
	if not dim_rect:
		return
	var tween = create_tween()
	tween.tween_property(dim_rect, "modulate:a", 1.0, 0.3)
	await tween.finished

func _hide_dim_overlay():
	if not dim_rect:
		return
	var tween = create_tween()
	tween.tween_property(dim_rect, "modulate:a", 0.0, 0.3)
	await tween.finished

# Screen shake
func screen_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func _show_instructions():
	var instructions = """~ busker's wager ~

HOW TO PLAY:                                    CONTROLS:
- click to shoot notes                          - i = show/hide instructions
- hit a word to lock it                         - esc = quit to menu
- CHAIN MODE: type (1->2->3)
- NEXT word glows yellow                        GOAL:
- 3 LIVES per challenge                         earn tips each night!
- miss/wrong = lose 1 life                      each night adds NEW challenges!
- power-ups later - click them!                 survive with your lives!
- combos: type fast!

press i to start..."""

	instructions_showing = true
	get_tree().paused = true

	notification_queue.clear()
	notification_playing = false

	# Dim the game
	await _show_dim_overlay()

	if notification_label:
		notification_label.add_theme_font_size_override("font_size", 26)
		notification_label.text = instructions
		notification_label.modulate.a = 1.0
		notification_label.scale = Vector2(1.0, 1.0)

func _dismiss_instructions():
	instructions_showing = false
	instructions_dismissed_once = true  # Mark as dismissed so I key won't open it again
	get_tree().paused = false

	if notification_label:
		notification_label.modulate.a = 0.0
		notification_label.remove_theme_font_size_override("font_size")

	notification_playing = false
	notification_queue.clear()

	# Undim the game
	await _hide_dim_overlay()

	_show_night_intro_and_start()

func _show_night_intro_and_start():
	# Show night rules first (waits internally and undims when done)
	await _show_night_rules()

	# Then show night goal with large text (dims, shows, undims when done)
	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	print("Showing night intro: ", night_message)
	await _show_large_notification(night_message, 3.0)
	print("Night intro complete - pedestrians will spawn and trigger challenges")

	# Start spawning pedestrians now (immediately after undim)
	if pedestrian_spawner and pedestrian_spawner.has_method("start_spawning"):
		pedestrian_spawner.start_spawning()

func _show_cutscene(night: int = 1):
	var cutscene_text = ""

	match night:
		1:
			cutscene_text = """"ugh... another day, another damn dollar."

*yawn*

"guess i'll set up here and pray someone actually stops. my paws are killing me from holding this stupid lute, but rent won't pay itself."

*sigh* "let's get this over with."

press any key to continue..."""
		2:
			cutscene_text = """"okay, not terrible for night one."

*tail wags slightly*

"some of 'em actually looked interested. others just... stared at me like i'm some kind of street decoration. real nice."

"whatever. a dog's gotta eat."

press any key to continue..."""
		3:
			cutscene_text = """"alright, alright. maybe i don't totally suck at this."

*flexes paws*

"folks are starting to recognize me. one guy even threw extra coins! though... probably shouldn't have barked at that grumpy dude."

"yeah, that was dumb."

press any key to continue..."""
		4:
			cutscene_text = """"halfway there... holy crap, this might actually work."

*stretches*

"i'm not just 'that weird dog with a lute' anymore. i'm THE weird dog with a lute."

"the knight gave me a look but still tipped. i'll take it!"

press any key to continue..."""
		5:
			cutscene_text = """"final night. this is it."

*deep breath*

"one more performance and i can finally pay rent. no pressure or anything."

*grips lute tighter*

"alright shiba, let's make this legendary. or at least... not embarrassing."

press any key to continue..."""

	cutscene_showing = true
	get_tree().paused = true

	notification_queue.clear()
	notification_playing = false

	if cutscene_background and cutscene_label:
		# Ensure proper font styling
		cutscene_label.add_theme_font_size_override("font_size", 42)

		# Start invisible
		cutscene_background.modulate.a = 0.0
		cutscene_label.modulate.a = 0.0
		cutscene_label.scale = Vector2(0.9, 0.9)

		cutscene_background.visible = true
		cutscene_label.visible = true
		cutscene_label.text = cutscene_text

		# JUICE: Fade in with scale
		var bg_tween = create_tween()
		bg_tween.tween_property(cutscene_background, "modulate:a", 1.0, 0.4)

		var text_tween = create_tween()
		text_tween.set_parallel(true)
		text_tween.tween_property(cutscene_label, "modulate:a", 1.0, 0.6).set_delay(0.2)
		text_tween.tween_property(cutscene_label, "scale", Vector2(1.0, 1.0), 0.5).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _dismiss_cutscene():
	cutscene_showing = false

	if cutscene_background and cutscene_label:
		# JUICE: Fade out with scale
		var bg_tween = create_tween()
		bg_tween.tween_property(cutscene_background, "modulate:a", 0.0, 0.3)

		var text_tween = create_tween()
		text_tween.set_parallel(true)
		text_tween.tween_property(cutscene_label, "modulate:a", 0.0, 0.3)
		text_tween.tween_property(cutscene_label, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_IN)

		await text_tween.finished

		cutscene_background.visible = false
		cutscene_label.visible = false

	get_tree().paused = false
	# Don't show instructions again - player already knows how to play

# Flash Effect System
func _flash_screen(color: Color = Color(1, 1, 1, 0.3)):
	if flash_rect:
		flash_rect.color = color
		var tween = create_tween()
		tween.tween_property(flash_rect, "color", Color(color.r, color.g, color.b, 0), 0.3)

# PROGRESSIVE NIGHT RULES SYSTEM
func _show_night_rules():
	var rules_text = ""
	match current_night:
		1:
			rules_text = "Night 1 Rules:\n- Type words in chain order (1->2->3)\n- 3 lives per challenge\n- Miss/Wrong letter = lose 1 life"
		2:
			rules_text = "Night 2 Rules:\n- Chain order required\n- 3 lives\n- Power-ups now spawn!\n- Words fall faster"
		3:
			rules_text = "Night 3 Rules:\n- Chain order required\n- 3 lives\n- MORE words on screen\n- Faster spawning"
		4:
			rules_text = "Night 4 Rules:\n- Chain order required\n- 3 lives\n- EVEN MORE words!\n- Speed increased again"
		5:
			rules_text = "FINAL Night Rules:\n- Chain order required\n- 3 lives\n- MAXIMUM chaos!\n- Prove you're legendary!"

	# Dim the game while showing rules
	await _show_dim_overlay()

	# Clear any queued notifications
	notification_queue.clear()
	notification_playing = false

	# Show notification manually with proper timing
	if notification_label:
		notification_label.text = rules_text
		notification_label.modulate.a = 0.0
		notification_label.scale = Vector2(0.8, 0.8)

		var tween = create_tween()
		tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.3)
		await tween.finished

		# Wait for duration
		await get_tree().create_timer(4.0).timeout

		# Fade out
		var fade = create_tween()
		fade.tween_property(notification_label, "modulate:a", 0.0, 0.3)
		await fade.finished

	# Undim after rules are done
	await _hide_dim_overlay()

# Get max simultaneous words based on night
func _get_max_words_for_night() -> int:
	match current_night:
		1: return 3
		2: return 4
		3: return 5
		4: return 6
		5: return 7
	return 3

# LIVES UI SETUP
func _setup_lives_ui():
	lives_container = HBoxContainer.new()
	lives_container.name = "LivesContainer"
	lives_container.position = Vector2(10, 60)
	lives_container.add_theme_constant_override("separation", 5)

	var hud = get_node("../HUDPanel")
	if hud:
		hud.add_child(lives_container)

	# Initial hearts will be added by _update_ui()

# POWER-UP UI SETUP
func _setup_powerup_ui():
	powerup_container = HBoxContainer.new()
	powerup_container.name = "PowerupContainer"
	powerup_container.position = Vector2(10, 110)
	powerup_container.add_theme_constant_override("separation", 10)

	var hud = get_node("../HUDPanel")
	if hud:
		hud.add_child(powerup_container)

# POWER-UP SYSTEM
func _spawn_powerup():
	# Don't spawn power-ups on night 1
	if current_night < 2:
		return

	var powerup_types = ["slowmo", "autocomplete", "shield"]
	var powerup_type = powerup_types[rng.randi() % powerup_types.size()]

	# Create button-styled power-up
	var powerup_panel = PanelContainer.new()
	powerup_panel.name = "Powerup_" + powerup_type
	powerup_panel.position = Vector2(rng.randf_range(200, 800), 100)
	powerup_panel.z_index = 90

	# Create button-like background
	var style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_all = 3

	var icon = ""
	var bg_color = Color.WHITE
	var border_color = Color.WHITE

	match powerup_type:
		"slowmo":
			icon = "[SLOW]"
			bg_color = Color(0.2, 0.4, 0.6, 0.9)
			border_color = Color(0.5, 0.8, 1.0)
		"autocomplete":
			icon = "[AUTO]"
			bg_color = Color(0.5, 0.4, 0.1, 0.9)
			border_color = Color(1.0, 0.8, 0.2)
		"shield":
			icon = "[SHIELD]"
			bg_color = Color(0.4, 0.4, 0.4, 0.9)
			border_color = Color(0.8, 0.8, 0.8)

	style_box.bg_color = bg_color
	style_box.border_color = border_color
	powerup_panel.add_theme_stylebox_override("panel", style_box)

	# Create label for text
	var powerup_label = Label.new()
	powerup_label.text = icon
	powerup_label.add_theme_font_size_override("font_size", 32)
	powerup_label.add_theme_color_override("font_color", Color.WHITE)
	powerup_label.custom_minimum_size = Vector2(100, 50)
	powerup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	powerup_panel.add_child(powerup_label)

	# Store the powerup type in metadata
	powerup_panel.set_meta("powerup_type", powerup_type)

	get_parent().add_child(powerup_panel)

	# Floating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(powerup_panel, "position:y", powerup_panel.position.y + 15, 1.0).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(powerup_panel, "position:y", powerup_panel.position.y - 15, 1.0).set_ease(Tween.EASE_IN_OUT)

	# Auto-despawn after 6 seconds
	await get_tree().create_timer(6.0).timeout
	if is_instance_valid(powerup_panel):
		var fade_tween = create_tween()
		fade_tween.tween_property(powerup_panel, "modulate:a", 0.0, 0.5)
		await fade_tween.finished
		powerup_panel.queue_free()

func _collect_powerup(powerup_type: String):
	match powerup_type:
		"slowmo":
			_activate_slowmo()
		"autocomplete":
			_activate_autocomplete()
		"shield":
			_activate_shield()

	_update_powerup_display()

func _activate_slowmo():
	slowmo_active = true
	show_notification("[SLOW] SLOW MOTION! [SLOW]", 1.0)
	_flash_screen(Color(0.5, 0.8, 1.0, 0.3))

	# Make all words fall slower
	for word in falling_words:
		if is_instance_valid(word):
			word.fall_speed *= 0.5

	# Lasts 5 seconds
	await get_tree().create_timer(5.0).timeout
	slowmo_active = false

	# Restore speed
	for word in falling_words:
		if is_instance_valid(word):
			word.fall_speed *= 2.0

func _activate_autocomplete():
	show_notification("[AUTO] AUTO-COMPLETE! [AUTO]", 1.0)
	_flash_screen(Color(1.0, 0.8, 0.2, 0.4))

	# Auto-complete the current chain word if one exists
	if chain_index < falling_words.size() and is_instance_valid(falling_words[chain_index]):
		var word = falling_words[chain_index]
		# Trigger completion
		_on_word_completed(word)

func _activate_shield():
	has_shield = true
	show_notification("🛡 SHIELD ACTIVE! 🛡", 1.0)
	_flash_screen(Color(0.8, 0.8, 1.0, 0.3))

	# Visual indicator around busker
	if busker:
		var shield_circle = ColorRect.new()
		shield_circle.name = "ShieldEffect"
		shield_circle.size = Vector2(100, 100)
		shield_circle.position = busker.position - Vector2(50, 50)
		shield_circle.color = Color(0.5, 0.8, 1.0, 0.3)
		shield_circle.z_index = 40
		get_parent().add_child(shield_circle)

		# Pulse animation
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(shield_circle, "modulate:a", 0.5, 0.5)
		pulse_tween.tween_property(shield_circle, "modulate:a", 1.0, 0.5)

func _update_powerup_display():
	# Clear old icons
	for child in powerup_container.get_children():
		child.queue_free()

	# Show active powerups
	if slowmo_active:
		var icon = Label.new()
		icon.text = "⏰"
		icon.add_theme_font_size_override("font_size", 32)
		powerup_container.add_child(icon)

	if has_shield:
		var icon = Label.new()
		icon.text = "🛡"
		icon.add_theme_font_size_override("font_size", 32)
		powerup_container.add_child(icon)

func _lose_life():
	if has_shield:
		# Shield absorbs the hit
		has_shield = false
		show_notification("🛡 SHIELD ABSORBED HIT!", 1.0)
		_flash_screen(Color(0.5, 0.8, 1.0, 0.5))

		# Remove shield visual
		var shield = get_parent().get_node_or_null("ShieldEffect")
		if shield:
			shield.queue_free()

		_update_powerup_display()
		return

	lives -= 1
	_update_ui()

	# Visual feedback
	_flash_screen(Color(1.0, 0.2, 0.2, 0.5))
	screen_shake(8.0, 0.3)

	if lives <= 0:
		# Challenge failed!
		show_notification("💔 OUT OF LIVES!\nCHALLENGE FAILED!", 2.0)
		_play_game_over_sound()
		await get_tree().create_timer(2.5).timeout
		_end_typing_challenge()
	else:
		show_notification("[X] LIFE LOST! %d REMAINING" % lives, 1.0)

# COIN PILE SYSTEM
func _add_coin_to_pile(coin: TextureRect):
	coin_pile_count += 1
	coin_sprites.append(coin)

	# Position coin in pile with slight randomness - smaller spacing
	coin.position = coin_pile_position + Vector2(randf_range(-8, 8), -coin_pile_count * 1.5)
	coin.z_index = 35 + coin_pile_count  # Stack on top of each other

	# Little bounce when landing - smaller final size
	var bounce_tween = create_tween()
	bounce_tween.tween_property(coin, "scale", Vector2(0.5, 0.5), 0.1)
	bounce_tween.tween_property(coin, "scale", Vector2(0.4, 0.4), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

func _clear_coin_pile():
	# Clear all coins from the pile
	for coin in coin_sprites:
		if is_instance_valid(coin):
			coin.queue_free()
	coin_sprites.clear()
	coin_pile_count = 0

# PERFORMANCE MUSIC SYSTEM
func _start_performance_music():
	# Stop current performance music if playing
	_stop_performance_music()

	# Fade out background music
	if audio_manager and audio_manager.music_player:
		var fade_out = create_tween()
		fade_out.tween_property(audio_manager.music_player, "volume_db", -60.0, 0.5)
		await fade_out.finished
		audio_manager.music_player.stop()

	# Pick a random track
	var random_track = performance_tracks[rng.randi() % performance_tracks.size()]

	# Create new audio player
	current_performance_music = AudioStreamPlayer.new()
	current_performance_music.stream = load(random_track)
	current_performance_music.volume_db = -60.0
	add_child(current_performance_music)
	current_performance_music.play()

	# Fade in performance music
	var fade_in = create_tween()
	fade_in.tween_property(current_performance_music, "volume_db", -10.0, 0.5)

	print("Started performance music: ", random_track)

func _stop_performance_music():
	if current_performance_music and is_instance_valid(current_performance_music):
		# Fade out performance music
		var fade_out = create_tween()
		fade_out.tween_property(current_performance_music, "volume_db", -60.0, 0.5)
		await fade_out.finished

		# Check again if still valid after await
		if current_performance_music and is_instance_valid(current_performance_music):
			current_performance_music.stop()
			current_performance_music.queue_free()
		current_performance_music = null

	# Fade in background music
	if audio_manager and audio_manager.music_player:
		audio_manager.music_player.volume_db = -60.0
		audio_manager.music_player.play()
		var fade_in = create_tween()
		fade_in.tween_property(audio_manager.music_player, "volume_db", -12.0, 0.5)
		print("Stopped performance music")

# Falling Words Typing Challenge System
func start_typing_challenge(pedestrian: Node):
	if is_in_typing_challenge:
		return  # Already in a challenge

	# NEVER start a challenge while screen is dimmed
	if dim_rect and dim_rect.modulate.a > 0.0:
		return  # Screen is dimmed, don't start challenge

	current_pedestrian = pedestrian
	is_in_typing_challenge = true
	challenge_timer = 0.0
	word_spawn_timer = 0.0
	event_timer = 0.0
	powerup_spawn_timer = 0.0
	words_completed = 0
	words_missed = 0
	challenge_tips_earned = 0
	currently_locked_word = null
	active_modifier = ""
	modifier_duration = 0.0

	# Reset CHAIN MODE
	chain_index = 0
	chain_counter = 0  # Reset word numbering

	# Reset LIVES
	lives = max_lives
	has_shield = false
	slowmo_active = false

	# Reset combo system
	combo_count = 0
	combo_multiplier = 1.0
	last_word_time = 0.0

	# Clear coin pile from previous challenge
	_clear_coin_pile()

	# Clear any existing falling words
	for word in falling_words:
		if is_instance_valid(word):
			word.queue_free()
	falling_words.clear()

	# Show aiming line and restart its pulsing animation
	if aiming_line:
		aiming_line.visible = true
		# Restart pulsing animation
		var line_tween = create_tween()
		line_tween.set_loops()
		line_tween.tween_property(aiming_line, "modulate:a", 0.6, 0.5)
		line_tween.tween_property(aiming_line, "modulate:a", 1.0, 0.5)

	# Start busker performance
	busker.start_performance()

	# Hide old typing UI
	if current_word_label:
		current_word_label.visible = false
	if typed_input_label:
		typed_input_label.visible = false

	# Start random performance music (delayed slightly to avoid overlapping with notifications)
	await get_tree().create_timer(0.3).timeout
	_start_performance_music()

	print("Typing challenge started!")

func _spawn_falling_word():
	# Refill available words if we've used them all
	if available_words.is_empty():
		available_words = all_words.duplicate()
		available_words.shuffle()

	# Get a unique word
	var word_text = available_words.pop_front()
	used_words.append(word_text)

	# Create falling word
	var falling_word = preload("res://scripts/gameplay/FallingWord.gd").new()

	# Random x position across the screen
	var spawn_x = rng.randf_range(150, 850)
	falling_word.position = Vector2(spawn_x, 50)  # Start near top of screen
	falling_word.z_index = 100  # Make sure it's on top of everything

	# Setup the word AFTER positioning - speed increases with night
	var base_speed = 40.0 + (current_night * 7.0)
	falling_word.setup(word_text, base_speed)

	# CHAIN MODE: Assign chain number using counter (increments each spawn)
	chain_counter += 1
	falling_word.set_meta("chain_number", chain_counter)

	# Connect signals
	falling_word.word_completed.connect(_on_word_completed)
	falling_word.word_hit_ground.connect(_on_word_hit_ground)
	falling_word.wrong_letter_typed.connect(_on_wrong_letter)
	falling_word.word_collision.connect(_on_word_collision)

	# Add to scene
	get_parent().add_child(falling_word)
	falling_words.append(falling_word)

	# Update chain display
	_update_chain_indicators()

	print("Spawned falling word: ", word_text, " (#", chain_counter, ") at position:", falling_word.position)

func _setup_aiming_line():
	aiming_line = Line2D.new()
	aiming_line.width = 5.0
	aiming_line.default_color = Color(1.0, 0.8, 0.2, 0.8)  # More opaque golden
	aiming_line.points = [Vector2.ZERO, Vector2.ZERO]
	aiming_line.z_index = 50
	aiming_line.visible = false
	aiming_line.antialiased = true

	# Make line taper from thick to thin
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1.2))
	curve.add_point(Vector2(0.5, 0.9))
	curve.add_point(Vector2(1, 0.3))
	aiming_line.width_curve = curve

	get_parent().add_child(aiming_line)

	# Add pulsing animation to aiming line
	var line_tween = create_tween()
	line_tween.set_loops()
	line_tween.tween_property(aiming_line, "modulate:a", 0.6, 0.5)
	line_tween.tween_property(aiming_line, "modulate:a", 1.0, 0.5)

func _shoot_music_note():
	if not busker:
		return

	var mouse_pos = get_viewport().get_mouse_position()

	# Check if clicking on a power-up first
	for child in get_parent().get_children():
		if child.name.begins_with("Powerup_"):
			var powerup_rect = Rect2(child.global_position - Vector2(24, 24), Vector2(48, 48))
			if powerup_rect.has_point(mouse_pos):
				# Collect power-up
				var powerup_type = child.get_meta("powerup_type", "")
				if powerup_type != "":
					_collect_powerup(powerup_type)
					child.queue_free()
					return

	var direction = (mouse_pos - busker.global_position).normalized()

	# Recoil effect on busker
	var recoil_tween = create_tween()
	recoil_tween.tween_property(busker, "position", busker.position - direction * 5, 0.08)
	recoil_tween.tween_property(busker, "position", busker.position, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Small screen shake
	screen_shake(2.0, 0.1)

	# Flash at busker position
	_spawn_muzzle_flash(busker.global_position, direction)

	var note = preload("res://scripts/gameplay/MusicNote.gd").new()
	note.position = busker.global_position
	note.setup(direction)
	note.note_hit_word.connect(_on_note_hit_word)
	get_parent().add_child(note)

	# Audio feedback
	if audio_manager:
		audio_manager.play_sfx("res://assets/audio/sfx/yippee.wav")

	print("Shot music note towards ", mouse_pos)

func _spawn_muzzle_flash(pos: Vector2, direction: Vector2):
	# Create a quick burst/flash effect
	for i in range(5):
		var particle = Label.new()
		particle.text = "♪"
		particle.add_theme_font_size_override("font_size", rng.randi_range(16, 28))
		particle.modulate = Color(1.0, 0.8 + randf() * 0.2, 0.2, 1.0)
		particle.position = pos + direction * randf_range(10, 30)
		particle.rotation = randf_range(-PI, PI)
		particle.z_index = 45
		get_parent().add_child(particle)

		var angle = direction.angle() + randf_range(-PI/4, PI/4)
		var spread = Vector2(cos(angle), sin(angle)) * randf_range(30, 60)

		var p_tween = create_tween()
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", particle.position + spread, 0.3)
		p_tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		p_tween.tween_property(particle, "rotation", particle.rotation + randf_range(-PI, PI), 0.3)
		await p_tween.finished
		particle.queue_free()

func _update_chain_indicators():
	# Update all words to show their chain number and highlight the next one
	for word in falling_words:
		if not is_instance_valid(word):
			continue

		var chain_num = word.get_meta("chain_number", -1)
		if chain_num == -1:
			continue

		# Calculate if this is the next word (chain_num - 1 because we already incremented chain_index)
		var is_next = (chain_num == chain_index + 1)

		# Highlight the NEXT word in chain
		if is_next:
			word.modulate = Color(1.0, 1.0, 0.3, 1.0)  # Bright yellow = NEXT
		else:
			word.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Grey = not your turn

		# Update or create chain number label
		var chain_label = word.get_node_or_null("ChainNumber")
		if chain_label == null:
			chain_label = Label.new()
			chain_label.name = "ChainNumber"
			chain_label.add_theme_font_size_override("font_size", 56)
			chain_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0, 1.0))
			chain_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
			chain_label.add_theme_constant_override("outline_size", 6)
			chain_label.position = Vector2(-35, -70)
			chain_label.z_index = 105
			word.add_child(chain_label)

		# Update the text
		chain_label.text = str(chain_num)

func _on_note_hit_word(word: FallingWord):
	# Check if hit a power-up
	if word.has_method("get_meta") and word.has_meta("powerup_type"):
		var powerup_type = word.get_meta("powerup_type")
		_collect_powerup(powerup_type)
		word.queue_free()
		return

	# CHAIN MODE: Only allow hitting the NEXT word in chain
	var word_chain_number = word.get_meta("chain_number", -1)
	var expected_chain_number = chain_index + 1

	if word_chain_number != expected_chain_number:
		# Wrong word in chain!
		show_notification("[X] WRONG ORDER!\nType word #%d first!" % expected_chain_number, 1.0)
		_flash_screen(Color(1.0, 0.5, 0.0, 0.3))
		screen_shake(3.0, 0.1)
		return

	if currently_locked_word == null and is_instance_valid(word):
		# JUICE: Hit effects!
		_spawn_hit_explosion(word.global_position)
		screen_shake(4.0, 0.15)
		_flash_screen(Color(1.0, 1.0, 0.5, 0.3))

		# Show hit marker
		_spawn_hit_marker(word.global_position)

		currently_locked_word = word
		word.lock_for_typing()

		# Update chain indicators
		_update_chain_indicators()

		print("Word locked for typing: ", word.word_text, " (chain #", word_chain_number, ")")

func _spawn_hit_explosion(pos: Vector2):
	# Create impact explosion with notes
	for i in range(12):
		var particle = Label.new()
		particle.text = ["♪", "♫", "~", "*"][rng.randi() % 4]
		particle.add_theme_font_size_override("font_size", rng.randi_range(20, 36))
		particle.modulate = Color(1.0, 0.9, 0.3, 1.0)
		particle.position = pos
		particle.rotation = randf_range(-PI, PI)
		particle.z_index = 120
		get_parent().add_child(particle)

		var angle = (i / 12.0) * TAU
		var direction = Vector2(cos(angle), sin(angle)) * randf_range(80, 140)

		var p_tween = create_tween()
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", particle.position + direction, 0.5).set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		p_tween.tween_property(particle, "rotation", particle.rotation + randf_range(-PI*2, PI*2), 0.5)
		p_tween.tween_property(particle, "scale", Vector2(0.3, 0.3), 0.5)
		await p_tween.finished
		particle.queue_free()

func _spawn_hit_marker(pos: Vector2):
	# Show a "HIT!" marker
	var marker = Label.new()
	marker.text = "HIT!"
	marker.add_theme_font_size_override("font_size", 28)
	marker.modulate = Color(1.0, 1.0, 0.3, 1.0)
	marker.position = pos + Vector2(-30, -40)
	marker.z_index = 125
	get_parent().add_child(marker)

	var m_tween = create_tween()
	m_tween.set_parallel(true)
	m_tween.tween_property(marker, "position:y", marker.position.y - 50, 0.6).set_ease(Tween.EASE_OUT)
	m_tween.tween_property(marker, "modulate:a", 0.0, 0.6)
	m_tween.tween_property(marker, "scale", Vector2(1.5, 1.5), 0.3).set_ease(Tween.EASE_OUT)
	await m_tween.finished
	marker.queue_free()

func _handle_falling_word_input(event: InputEventKey):
	var key = event.as_text_key_label().to_lower()

	# Only accept single letter keys
	if key.length() != 1:
		return
	if not (key >= "a" and key <= "z"):
		return

	# Play typing sound effect (quieter)
	_play_typing_sound()

	# Only type on the currently locked word
	if currently_locked_word and is_instance_valid(currently_locked_word):
		currently_locked_word.type_letter(key)

func _play_typing_sound():
	# Play quieter typing sound
	var typing_sound = AudioStreamPlayer.new()
	typing_sound.stream = load("res://assets/audio/sfx/press.wav")
	typing_sound.volume_db = -20  # Much quieter
	add_child(typing_sound)
	typing_sound.play()
	# Clean up after playing
	await typing_sound.finished
	typing_sound.queue_free()

func _on_word_completed(word: FallingWord):
	words_completed += 1

	# CHAIN MODE: Update chain index to the completed word's number
	var completed_chain_num = word.get_meta("chain_number", -1)
	if completed_chain_num != -1:
		chain_index = completed_chain_num

	# JUICE: Spawn completion particles at word position BEFORE removing it
	_spawn_word_completion_particles(word.global_position)

	falling_words.erase(word)
	word.queue_free()

	# Unlock the word so player can target another
	if currently_locked_word == word:
		currently_locked_word = null

	# Update chain indicators for remaining words
	_update_chain_indicators()

func _spawn_word_completion_particles(pos: Vector2):
	# COIN EXPLOSION when word is completed!
	var num_coins = rng.randi_range(5, 8)
	for i in range(num_coins):
		var coin = TextureRect.new()
		coin.texture = load("res://assets/sprites/ui/coins.png")
		coin.custom_minimum_size = Vector2(24, 24)
		coin.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		coin.position = pos
		coin.rotation = randf_range(-PI, PI)
		coin.z_index = 150
		get_parent().add_child(coin)

		# Initial upward velocity and horizontal spread
		var horizontal_vel = randf_range(-150, 150)
		var upward_vel = randf_range(-200, -300)

		# Simulate parabolic arc with gravity
		var gravity = 800.0
		var duration = 0.8
		var time_step = 0.016  # ~60fps

		var current_pos = pos
		var vel_x = horizontal_vel
		var vel_y = upward_vel

		# Animate parabolic motion
		for t in range(int(duration / time_step)):
			vel_y += gravity * time_step  # Apply gravity
			current_pos.x += vel_x * time_step
			current_pos.y += vel_y * time_step

			var move_tween = create_tween()
			move_tween.set_parallel(true)
			move_tween.tween_property(coin, "position", current_pos, time_step)
			move_tween.tween_property(coin, "rotation", coin.rotation + 0.3, time_step)
			await move_tween.finished

			# Check if reached coin pile height
			if current_pos.y >= coin_pile_position.y - 20:
				break

		# Final snap to pile position
		var snap_tween = create_tween()
		snap_tween.tween_property(coin, "position", coin_pile_position + Vector2(randf_range(-8, 8), randf_range(-5, 5)), 0.1)
		await snap_tween.finished

		# Add to pile
		_add_coin_to_pile(coin)

	# ORIGINAL MECHANIC: Rhythm combo system
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last = current_time - last_word_time

	if last_word_time > 0 and time_since_last <= combo_window:
		# Maintained combo!
		combo_count += 1
		combo_multiplier = 1.0 + (combo_count * 0.2)  # +20% per combo
		if combo_count > max_combo:
			max_combo = combo_count

		# JUICE: Intense visual feedback for combo - IMMEDIATE FEEDBACK
		_flash_screen(Color(1.0, 0.5 + (combo_count * 0.1), 0.0, 0.4 + (combo_count * 0.05)))
		screen_shake(3.0 + (combo_count * 1.5), 0.2 + (combo_count * 0.02))
		_show_big_combo_notification(combo_count)

		# JUICE: Camera zoom punch on high combos
		if combo_count >= 3:
			_camera_zoom_punch(1.0 + (combo_count * 0.02))

		# Spawn musical note trail
		_spawn_combo_trail(combo_count)

		# JUICE: Time freeze effect on high combos
		if combo_count >= 5:
			_time_freeze(0.05)
	else:
		# Combo broken or first word
		combo_count = 0
		combo_multiplier = 1.0
		_flash_screen()
		screen_shake(3.0, 0.2)

	last_word_time = current_time

	# Award tips with combo multiplier and mood
	var base_points = 5
	if active_modifier == "double_points":
		base_points *= 2

	# Ensure at least minimum points with mood multiplier (0.5 to 2.0)
	var mood_multiplier = clamp(crowd_mood / 50.0, 0.5, 2.0)
	var points = max(int(base_points * combo_multiplier * mood_multiplier), 2)
	tips_total += points
	challenge_tips_earned += points

	# Update crowd mood based on performance
	crowd_mood = clamp(crowd_mood + 2 + combo_count, 0, 100)

	# Random chance for bonus particle effects
	if rng.randf() < 0.3:  # 30% chance
		_spawn_bonus_particles()

	_update_ui()
	_update_crowd_mood_display()

	# CHECK IF NIGHT GOAL REACHED - TRIGGER INSTANT CELEBRATION!
	if tips_total >= nightly_goal and not night_transition_in_progress:
		_trigger_night_complete_celebration()

	print("Word completed! Combo: %dx | Points: +$%d | Mood: %.1f" % [combo_count, points, crowd_mood])

func _on_word_hit_ground(word: FallingWord):
	words_missed += 1
	falling_words.erase(word)
	# word already queues itself for deletion

	# Play game over sound
	_play_game_over_sound()

	# Break combo and reduce mood
	combo_count = 0
	combo_multiplier = 1.0
	crowd_mood = clamp(crowd_mood - 20, 0, 100)

	# LOSE A LIFE instead of instant fail
	_lose_life()

	print("Word missed! Total missed: ", words_missed)

func _on_wrong_letter(word: FallingWord):
	# Play game over sound
	_play_game_over_sound()

	# Red screen flash
	_flash_screen(Color(1, 0, 0, 0.5))
	screen_shake(10.0, 0.4)

	# Break combo and tank mood
	combo_count = 0
	combo_multiplier = 1.0
	crowd_mood = clamp(crowd_mood - 25, 0, 100)

	# LOSE A LIFE instead of instant fail
	_lose_life()

	print("Wrong letter typed!")

func _trigger_random_event():
	if active_modifier != "":
		return  # Don't stack modifiers

	# Removed "bonus_word" event - was causing random money increases
	var events = ["speed_boost", "double_points", "falling_faster"]
	var event = events[rng.randi() % events.size()]
	active_modifier = event
	modifier_duration = 4.0  # Events last 4 seconds

	match event:
		"speed_boost":
			show_notification(">> SPEED BOOST! Words spawn faster! <<", 1.5)
			word_spawn_interval = 2.0  # Faster word spawning (changed from 1.0)
			screen_shake(5.0, 0.3)
			_flash_screen(Color(1, 1, 0, 0.3))  # Yellow flash

		"double_points":
			show_notification("$$ DOUBLE POINTS! $$", 1.5)
			screen_shake(3.0, 0.2)
			_flash_screen(Color(0, 1, 0, 0.3))  # Green flash

		"falling_faster":
			show_notification("!! GRAVITY INCREASE! !!", 1.5)
			_flash_screen(Color(1, 0, 1, 0.3))  # Purple flash
			# Make all active words fall faster
			for word in falling_words:
				if is_instance_valid(word):
					word.fall_acceleration *= 2.0

	print("Random event triggered: ", event)

func _clear_modifier():
	match active_modifier:
		"speed_boost":
			word_spawn_interval = 4.0  # Reset to normal (changed from 2.0)

	active_modifier = ""
	print("Modifier cleared")

func _spawn_bonus_particles():
	# Create sparkle particle effects around the screen
	for i in range(10):
		var particle = Label.new()
		particle.text = ["*", "+", "x", "o"][rng.randi() % 4]
		particle.add_theme_font_size_override("font_size", 32)
		particle.modulate = Color(randf_range(0.8, 1.0), randf_range(0.8, 1.0), randf_range(0.8, 1.0))
		particle.position = Vector2(rng.randf_range(100, 900), rng.randf_range(50, 500))
		get_parent().add_child(particle)

		# Animate particle
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y - 100, 1.0)
		tween.tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_property(particle, "rotation", randf_range(-PI, PI), 1.0)

		# Clean up
		await tween.finished
		particle.queue_free()

func _spawn_combo_trail(combo_level: int):
	# ORIGINAL: Musical note trail that follows the busker
	var num_notes = min(combo_level, 8)
	for i in range(num_notes):
		var note = Label.new()
		note.text = ["~", "^", "v", ">"][rng.randi() % 4]
		note.add_theme_font_size_override("font_size", 24 + (combo_level * 2))
		note.modulate = Color(1.0, 0.5 + (combo_level * 0.05), 0.0)
		note.position = busker.global_position + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		note.z_index = 200
		get_parent().add_child(note)

		# Spiral upward animation
		var tween = create_tween()
		tween.set_parallel(true)
		var angle = (i / float(num_notes)) * TAU
		var radius = 100
		tween.tween_property(note, "position", note.position + Vector2(cos(angle) * radius, sin(angle) * radius - 150), 1.5)
		tween.tween_property(note, "modulate:a", 0.0, 1.5)
		tween.tween_property(note, "rotation", randf_range(-PI*3, PI*3), 1.5)
		tween.tween_property(note, "scale", Vector2(2, 2), 1.5)

		await tween.finished
		note.queue_free()

func _update_crowd_mood_display():
	# Update UI to show crowd mood (text changes based on mood)
	var mood_text = ""
	if crowd_mood < 20:
		mood_text = "ANGRY"
	elif crowd_mood < 40:
		mood_text = "MEH"
	elif crowd_mood < 60:
		mood_text = "OK"
	elif crowd_mood < 80:
		mood_text = "HAPPY"
	else:
		mood_text = "HYPED"

	# Show mood in performance label
	if performance_label:
		performance_label.text = "Words: %d / %d | %s %.0f%%" % [words_completed, words_required, mood_text, crowd_mood]

func _camera_zoom_punch(target_zoom: float):
	# JUICE: Quick zoom in/out for impact
	if not camera:
		return

	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), 0.08)
	zoom_tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.12)

func _time_freeze(duration: float):
	# JUICE: Brief time freeze for impact on high combos
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration * 0.1).timeout  # Account for slow time
	Engine.time_scale = 1.0

func _on_word_collision(colliding_word: FallingWord):
	# STRATEGIC MECHANIC: Chain reaction when typing word collides with another
	if not is_instance_valid(colliding_word):
		return

	# Remove colliding word from list
	falling_words.erase(colliding_word)

	# Auto-complete the colliding word with bonus points!
	var bonus_points = 10
	tips_total += bonus_points
	words_completed += 1

	# Update crowd mood positively
	crowd_mood = clamp(crowd_mood + 5, 0, 100)

	# Visual feedback
	show_notification(">> CHAIN REACTION! +$%d <<" % bonus_points, 1.0)
	_flash_screen(Color(0, 1.0, 1.0, 0.5))  # Cyan flash
	screen_shake(6.0, 0.25)

	# Create explosion on the colliding word
	if colliding_word.label:
		var explosion_pos = colliding_word.global_position
		# Spawn particles at collision point
		for i in range(8):
			var particle = Label.new()
			particle.text = ["*", "+", "x"][rng.randi() % 3]
			particle.add_theme_font_size_override("font_size", 32)
			particle.modulate = Color(0, 1.0, 1.0, 1.0)
			particle.position = explosion_pos
			particle.z_index = 150
			get_parent().add_child(particle)

			var angle = (i / 8.0) * TAU
			var direction = Vector2(cos(angle), sin(angle)) * 100
			var p_tween = create_tween()
			p_tween.set_parallel(true)
			p_tween.tween_property(particle, "position", particle.position + direction, 0.5)
			p_tween.tween_property(particle, "modulate:a", 0.0, 0.5)

	colliding_word.queue_free()

	_update_ui()
	_update_crowd_mood_display()

	print("Chain reaction! Collision destroyed word, bonus: +$", bonus_points)

func _spawn_confetti():
	# Spawn 40 colorful square confetti pieces
	for i in range(40):
		var confetti = ColorRect.new()
		var size = rng.randi_range(8, 20)
		confetti.size = Vector2(size, size)

		# Random bright colors
		var colors = [
			Color(1.0, 0.2, 0.2),  # Red
			Color(0.2, 0.5, 1.0),  # Blue
			Color(1.0, 0.8, 0.2),  # Yellow
			Color(0.3, 1.0, 0.3),  # Green
			Color(1.0, 0.4, 0.8),  # Pink
			Color(0.8, 0.3, 1.0),  # Purple
			Color(1.0, 0.5, 0.2),  # Orange
		]
		confetti.color = colors[rng.randi() % colors.size()]

		# Start from top of screen at random x position
		confetti.position = Vector2(rng.randf_range(0, 1024), rng.randf_range(-100, -50))
		confetti.rotation = randf_range(0, TAU)
		confetti.z_index = 200
		get_parent().add_child(confetti)

		# Fall down with rotation and slight side-to-side drift
		var fall_duration = randf_range(2.0, 3.5)
		var drift = randf_range(-100, 100)

		var c_tween = create_tween()
		c_tween.set_parallel(true)
		c_tween.tween_property(confetti, "position:y", 800, fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		c_tween.tween_property(confetti, "position:x", confetti.position.x + drift, fall_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		c_tween.tween_property(confetti, "rotation", confetti.rotation + randf_range(-PI*3, PI*3), fall_duration)
		c_tween.tween_property(confetti, "modulate:a", 0.0, 0.5).set_delay(fall_duration - 0.5)

		# Clean up when finished (in parallel, not sequential)
		c_tween.finished.connect(func(): confetti.queue_free())

func _trigger_night_complete_celebration():
	# Immediately end the typing challenge
	if is_in_typing_challenge:
		_end_typing_challenge()

	# Freeze everything
	get_tree().paused = true

	# MASSIVE celebration notification with white outline
	var celebration_label = Label.new()
	celebration_label.text = "NIGHT COMPLETE!"
	celebration_label.add_theme_font_size_override("font_size", 96)
	celebration_label.add_theme_constant_override("outline_size", 16)
	celebration_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
	celebration_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Golden
	celebration_label.position = Vector2(512, 384) - Vector2(400, 50)
	celebration_label.size = Vector2(800, 100)
	celebration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celebration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	celebration_label.z_index = 500
	celebration_label.scale = Vector2(0.3, 0.3)
	get_parent().add_child(celebration_label)

	# HUGE screen shake and flash
	screen_shake(20.0, 1.0)
	_flash_screen(Color(1.0, 0.9, 0.3, 0.6))

	# Elastic pop-in animation
	var cel_tween = create_tween()
	cel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # Keep animating while paused
	cel_tween.tween_property(celebration_label, "scale", Vector2(1.3, 1.3), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	cel_tween.tween_property(celebration_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Spawn MASSIVE particle explosion - 60 particles!
	for i in range(60):
		var particle = Label.new()
		particle.text = ["*", "+", "o", "O", "x", ".", "#"][rng.randi() % 7]
		particle.add_theme_font_size_override("font_size", rng.randi_range(32, 72))
		particle.modulate = Color(randf_range(0.9, 1.0), randf_range(0.7, 1.0), randf_range(0.2, 0.6), 1.0)
		particle.position = Vector2(512, 384)
		particle.rotation = randf_range(-PI, PI)
		particle.z_index = 499
		get_parent().add_child(particle)

		var angle = (i / 60.0) * TAU + randf_range(-0.3, 0.3)
		var distance = randf_range(150, 400)
		var direction = Vector2(cos(angle), sin(angle)) * distance

		var p_tween = create_tween()
		p_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", particle.position + direction, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		p_tween.tween_property(particle, "modulate:a", 0.0, 1.2).set_delay(0.3)
		p_tween.tween_property(particle, "rotation", particle.rotation + randf_range(-PI*4, PI*4), 1.5)
		p_tween.tween_property(particle, "scale", Vector2(0.3, 0.3), 1.5)

	await get_tree().create_timer(2.5).timeout

	# Fade out celebration
	var fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.set_parallel(true)
	fade_tween.tween_property(celebration_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_property(celebration_label, "scale", Vector2(1.5, 1.5), 0.5)
	await fade_tween.finished
	celebration_label.queue_free()

	# Unpause and trigger night transition
	get_tree().paused = false
	_check_win_condition()

func _play_game_over_sound():
	# Play game over sound effect
	var game_over_sound = AudioStreamPlayer.new()
	game_over_sound.stream = load("res://assets/audio/sfx/game_over.wav")
	game_over_sound.volume_db = -15  # Reduce volume
	add_child(game_over_sound)
	game_over_sound.play()
	# Clean up after playing
	await game_over_sound.finished
	game_over_sound.queue_free()

	# Penalty for missing
	if words_missed >= 3:
		show_notification("Too many words missed!", 2.0)
		_end_typing_challenge()

func _end_typing_challenge():
	is_in_typing_challenge = false
	challenge_timer = 0.0
	currently_locked_word = null

	# Stop performance music
	_stop_performance_music()

	# Hide aiming line
	if aiming_line:
		aiming_line.visible = false

	# Clear remaining falling words
	for word in falling_words:
		if is_instance_valid(word):
			word.queue_free()
	falling_words.clear()

	# Stop busker performance
	busker.stop_performance()

	# Show old typing UI again
	if current_word_label:
		current_word_label.visible = true
	if typed_input_label:
		typed_input_label.visible = true

	# Resume pedestrian walking
	if current_pedestrian and is_instance_valid(current_pedestrian):
		current_pedestrian._resume_walking()

	# Spawn confetti celebration!
	_spawn_confetti()

	# Show result
	var result_message = "Challenge complete!\nWords typed: %d\nWords missed: %d\n+$%d" % [words_completed, words_missed, challenge_tips_earned]
	show_notification(result_message, 2.5)

	# Check win condition to progress to next night
	await get_tree().create_timer(2.0).timeout
	_check_win_condition()

	_update_ui()

	print("Typing challenge ended!")
