extends Node

class_name GameManager

# Game state
var tips_total = 0
var nightly_goal = 50
var current_night = 1
var max_nights = 5
var total_career_earnings = 0

# Typing challenge state
var falling_words = []  # Array of active FallingWord nodes
var words_completed = 0
var words_required = 7
var is_in_typing_challenge = false
var current_pedestrian: Node = null
var word_spawn_timer: float = 0.0
var word_spawn_interval: float = 3.0  # Spawn a word every 3 seconds
var challenge_duration: float = 25.0  # Challenge lasts 25 seconds
var challenge_timer: float = 0.0
var words_missed = 0  # Count of words that hit the ground

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

# Cutscene UI References
@onready var cutscene_overlay: CanvasLayer = $"../CutsceneOverlay"
@onready var cutscene_background: ColorRect = $"../CutsceneOverlay/CutsceneBackground"
@onready var cutscene_label: Label = $"../CutsceneOverlay/CutsceneLabel"

# Flash Effect References
@onready var flash_overlay: CanvasLayer = $"../FlashOverlay"
@onready var flash_rect: ColorRect = $"../FlashOverlay/FlashRect"

# Game Objects
@onready var performance_timer: Timer = $"../PerformanceTimer"
@onready var lane: Node = $"../LaneInstance"
@onready var busker: Node = $"../BuskerInstance"
@onready var audio_manager: Node = $"../AudioManager"
@onready var camera: Camera2D = $"../Camera2D"

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

	# Validate critical nodes
	if not busker or not lane or not performance_label:
		push_error("GameManager: Critical nodes missing!")
		return

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
	if is_in_typing_challenge and aiming_line and busker:
		var mouse_pos = get_viewport().get_mouse_position()
		aiming_line.points[0] = busker.global_position
		aiming_line.points[1] = mouse_pos
		aiming_line.visible = currently_locked_word == null  # Hide when typing

	# Handle typing challenge
	if is_in_typing_challenge:
		challenge_timer += delta
		word_spawn_timer += delta
		event_timer += delta

		# Spawn new words periodically (max 3 words at once)
		if word_spawn_timer >= word_spawn_interval:
			word_spawn_timer = 0.0
			if falling_words.size() < 3:  # Limit to 3 words max
				_spawn_falling_word()

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

	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	show_notification(night_message, 3.0)
	await get_tree().create_timer(3.5).timeout

	# Game now runs passively - pedestrians trigger typing challenges as they walk by
	print("Night started - waiting for pedestrians...")

func _check_win_condition():
	if tips_total >= nightly_goal:
		total_career_earnings += tips_total
		current_night += 1

		if current_night > max_nights:
			# Game complete!
			screen_shake(15.0, 1.0)
			show_notification("*** LEGENDARY BUSKER! ***\nCareer Total: $%d" % total_career_earnings, 5.0)
			await get_tree().create_timer(6.0).timeout
			get_tree().change_scene_to_file("res://scenes/ui/SplashScreen.tscn")
		else:
			# Next night
			screen_shake(8.0, 0.6)
			show_notification("Night %d Complete!\nEarned: $%d" % [current_night - 1, tips_total], 3.0)
			await get_tree().create_timer(4.0).timeout

			# Show cutscene before next night
			_show_cutscene(current_night)
			await get_tree().create_timer(0.5).timeout

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

# Notification System
func show_notification(message: String, duration: float = 2.0):
	if instructions_showing or cutscene_showing:
		return

	notification_queue.append({"message": message, "duration": duration})

	if not notification_playing:
		_process_notification_queue()

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

# Screen shake
func screen_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func _show_instructions():
	var instructions = """~ busker's wager ~

how to play:
- click to shoot music notes at falling words
- hit a word to lock it for typing
- type the locked word letter by letter
- chain reactions: your word collides with others = bonus!
- combos: type words quickly in succession for multipliers
- i = show/hide instructions
- esc = quit to menu

goal:
earn enough tips each night to progress!
higher combos + crowd mood = more money
wrong letter or missed word = instant fail!

press i to start..."""

	instructions_showing = true
	get_tree().paused = true

	notification_queue.clear()
	notification_playing = false

	if notification_label:
		notification_label.add_theme_font_size_override("font_size", 36)
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

	_show_night_intro_and_start()

func _show_night_intro_and_start():
	var night_message = "NIGHT %d - Goal: $%d" % [current_night, nightly_goal]
	print("Showing night intro: ", night_message)
	show_notification(night_message, 3.0)
	print("Waiting 3.5 seconds...")
	await get_tree().create_timer(3.5).timeout
	print("Night intro complete - pedestrians will spawn and trigger challenges")

func _show_cutscene(night: int = 1):
	var cutscene_text = ""

	match night:
		1:
			cutscene_text = """*yawn* another day, another dollar... or lack thereof.

guess i'll set up here and see if anyone actually stops today. my paws are getting sore from holding this lute, but rent won't pay itself.

*sighs* let's do this.

press any key to continue..."""
		2:
			cutscene_text = """whew! not bad for night one. my tail's wagging a bit.

the crowd seems... okay? some of them looked genuinely interested. others just stared at me like i was a weird street decoration.

can't blame them though. a shiba busker isn't exactly... normal.

press any key to continue..."""
		3:
			cutscene_text = """okay, okay. i'm getting the hang of this!

my paw technique is improving. the townsfolk are starting to recognize me. one person even threw an extra coin!

...maybe i shouldn't have barked at that one grumpy guy though.

press any key to continue..."""
		4:
			cutscene_text = """*stretches* halfway there! my musician career is... actually happening?

i'm not just a dog with a lute anymore. i'm THE dog with a lute.

the knight gave me a weird look today but still tipped. success is success!

press any key to continue..."""
		5:
			cutscene_text = """final night. this is it. one more good performance and i can finally...

*deep breath*

no pressure, shiba. just you, your lute, and the hopes of not being evicted.

let's make this legendary.

press any key to continue..."""

	cutscene_showing = true
	get_tree().paused = true

	notification_queue.clear()
	notification_playing = false

	if cutscene_background and cutscene_label:
		cutscene_background.visible = true
		cutscene_label.visible = true
		cutscene_label.text = cutscene_text

func _dismiss_cutscene():
	cutscene_showing = false

	if cutscene_background and cutscene_label:
		cutscene_background.visible = false
		cutscene_label.visible = false

	_show_instructions()

# Flash Effect System
func _flash_screen(color: Color = Color(1, 1, 1, 0.3)):
	if flash_rect:
		flash_rect.color = color
		var tween = create_tween()
		tween.tween_property(flash_rect, "color", Color(color.r, color.g, color.b, 0), 0.3)

# Falling Words Typing Challenge System
func start_typing_challenge(pedestrian: Node):
	if is_in_typing_challenge:
		return  # Already in a challenge

	current_pedestrian = pedestrian
	is_in_typing_challenge = true
	challenge_timer = 0.0
	word_spawn_timer = 0.0
	event_timer = 0.0
	words_completed = 0
	words_missed = 0
	currently_locked_word = null
	active_modifier = ""
	modifier_duration = 0.0

	# Reset combo system
	combo_count = 0
	combo_multiplier = 1.0
	last_word_time = 0.0

	# Clear any existing falling words
	for word in falling_words:
		if is_instance_valid(word):
			word.queue_free()
	falling_words.clear()

	# Show aiming line
	if aiming_line:
		aiming_line.visible = true

	# Start busker performance
	busker.start_performance()

	# Hide old typing UI
	if current_word_label:
		current_word_label.visible = false
	if typed_input_label:
		typed_input_label.visible = false

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

	# Setup the word AFTER positioning
	falling_word.setup(word_text, 50.0 + (current_night * 10.0))  # Speed increases with night

	# Connect signals
	falling_word.word_completed.connect(_on_word_completed)
	falling_word.word_hit_ground.connect(_on_word_hit_ground)
	falling_word.wrong_letter_typed.connect(_on_wrong_letter)
	falling_word.word_collision.connect(_on_word_collision)

	# Add to scene
	get_parent().add_child(falling_word)
	falling_words.append(falling_word)

	print("Spawned falling word: ", word_text, " at position:", falling_word.position, " z_index:", falling_word.z_index)

func _setup_aiming_line():
	aiming_line = Line2D.new()
	aiming_line.width = 3.0
	aiming_line.default_color = Color(1.0, 0.8, 0.2, 0.6)  # Golden semi-transparent
	aiming_line.points = [Vector2.ZERO, Vector2.ZERO]
	aiming_line.z_index = 50
	aiming_line.visible = false
	get_parent().add_child(aiming_line)

func _shoot_music_note():
	if not busker:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var direction = (mouse_pos - busker.global_position).normalized()

	var note = preload("res://scripts/gameplay/MusicNote.gd").new()
	note.position = busker.global_position
	note.setup(direction)
	note.note_hit_word.connect(_on_note_hit_word)
	get_parent().add_child(note)

	print("Shot music note towards ", mouse_pos)

func _on_note_hit_word(word: FallingWord):
	if currently_locked_word == null and is_instance_valid(word):
		currently_locked_word = word
		word.lock_for_typing()

		# Grey out all other words
		for other_word in falling_words:
			if is_instance_valid(other_word) and other_word != word:
				other_word.is_targeted = false
				other_word._update_display()

		print("Word locked for typing: ", word.word_text)

func _handle_falling_word_input(event: InputEventKey):
	var key = event.as_text_key_label().to_lower()

	# Only accept single letter keys
	if key.length() != 1:
		return
	if not (key >= "a" and key <= "z"):
		return

	# Only type on the currently locked word
	if currently_locked_word and is_instance_valid(currently_locked_word):
		currently_locked_word.type_letter(key)

func _on_word_completed(word: FallingWord):
	words_completed += 1
	falling_words.erase(word)
	word.queue_free()

	# Unlock the word so player can target another
	if currently_locked_word == word:
		currently_locked_word = null

		# Restore all other words to normal
		for other_word in falling_words:
			if is_instance_valid(other_word):
				other_word.is_targeted = false
				other_word._update_display()

	# ORIGINAL MECHANIC: Rhythm combo system
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last = current_time - last_word_time

	if last_word_time > 0 and time_since_last <= combo_window:
		# Maintained combo!
		combo_count += 1
		combo_multiplier = 1.0 + (combo_count * 0.2)  # +20% per combo
		if combo_count > max_combo:
			max_combo = combo_count

		# JUICE: Intense visual feedback for combo
		_flash_screen(Color(1.0, 0.5 + (combo_count * 0.1), 0.0, 0.4 + (combo_count * 0.05)))
		screen_shake(3.0 + (combo_count * 1.5), 0.2 + (combo_count * 0.02))
		show_notification("*** %dX COMBO! ***" % combo_count, 0.8)

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
		if combo_count > 0:
			show_notification("Combo broken...", 1.0)
		combo_count = 0
		combo_multiplier = 1.0
		_flash_screen()
		screen_shake(3.0, 0.2)

	last_word_time = current_time

	# Award tips with combo multiplier and mood
	var base_points = 5
	if active_modifier == "double_points":
		base_points *= 2

	var points = int(base_points * combo_multiplier * (crowd_mood / 50.0))
	tips_total += points

	# Update crowd mood based on performance
	crowd_mood = clamp(crowd_mood + 2 + combo_count, 0, 100)

	# Random chance for bonus particle effects
	if rng.randf() < 0.3:  # 30% chance
		_spawn_bonus_particles()

	_update_ui()
	_update_crowd_mood_display()

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

	# INSTANT FAIL if word hits ground (HIGH STAKES!)
	_flash_screen(Color(1, 0, 0, 0.5))
	screen_shake(15.0, 0.5)
	show_notification("WORD HIT THE GROUND!\nCHALLENGE FAILED!", 2.0)
	_end_typing_challenge()

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

	# LOSE MONEY on wrong letter (high stakes!)
	var penalty = 5
	tips_total = max(0, tips_total - penalty)

	# End the challenge immediately
	show_notification("Wrong letter!\n-$%d penalty!\nChallenge failed!" % penalty, 2.0)
	_end_typing_challenge()

	print("Wrong letter typed! Challenge ended.")

func _trigger_random_event():
	if active_modifier != "":
		return  # Don't stack modifiers

	var events = ["speed_boost", "double_points", "falling_faster", "bonus_word"]
	var event = events[rng.randi() % events.size()]
	active_modifier = event
	modifier_duration = 4.0  # Events last 4 seconds

	match event:
		"speed_boost":
			show_notification(">> SPEED BOOST! Words spawn faster! <<", 1.5)
			word_spawn_interval = 1.0  # Faster word spawning
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

		"bonus_word":
			show_notification("** BONUS WORD! +$20! **", 1.5)
			_flash_screen(Color(1, 1, 1, 0.5))  # White flash
			tips_total += 20
			_update_ui()

	print("Random event triggered: ", event)

func _clear_modifier():
	match active_modifier:
		"speed_boost":
			word_spawn_interval = 2.0  # Reset to normal

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

	# Show result
	var result_message = "Challenge complete!\nWords typed: %d\nWords missed: %d\n+$%d" % [words_completed, words_missed, words_completed * 5]
	show_notification(result_message, 3.0)

	# Check win condition to progress to next night
	await get_tree().create_timer(3.5).timeout
	_check_win_condition()

	_update_ui()

	print("Typing challenge ended!")
