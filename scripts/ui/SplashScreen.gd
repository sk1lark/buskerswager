extends Control

@onready var play_label = $VBoxContainer/MenuContainer/PlayContainer/PlayLabel
@onready var quit_label = $VBoxContainer/MenuContainer/QuitContainer/QuitLabel
@onready var play_arrow = $VBoxContainer/MenuContainer/PlayContainer/PlayArrow
@onready var quit_arrow = $VBoxContainer/MenuContainer/QuitContainer/QuitArrow
@onready var title_label = $VBoxContainer/TitleLabel
@onready var subtitle_label = $VBoxContainer/SubtitleLabel
@onready var audio_player = $AudioStreamPlayer

var play_hovered = false
var quit_hovered = false

func _ready():
	# Start background music and loop it continuously
	if audio_player.stream:
		audio_player.stream.loop = true
	audio_player.play()

	# Start entrance animation
	_animate_entrance()

func _process(_delta):
	# Check hover for play button
	var play_rect = Rect2(play_label.global_position, play_label.size)
	var mouse_pos = get_viewport().get_mouse_position()

	if play_rect.has_point(mouse_pos):
		if not play_hovered:
			play_hovered = true
			_on_play_hover()
	else:
		if play_hovered:
			play_hovered = false
			_on_play_unhover()

	# Check hover for quit button
	var quit_rect = Rect2(quit_label.global_position, quit_label.size)
	if quit_rect.has_point(mouse_pos):
		if not quit_hovered:
			quit_hovered = true
			_on_quit_hover()
	else:
		if quit_hovered:
			quit_hovered = false
			_on_quit_unhover()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position

		# Check click on play
		var play_rect = Rect2(play_label.global_position, play_label.size)
		if play_rect.has_point(mouse_pos):
			_on_play_pressed()

		# Check click on quit
		var quit_rect = Rect2(quit_label.global_position, quit_label.size)
		if quit_rect.has_point(mouse_pos):
			_on_quit_pressed()

func _animate_entrance():
	# Start everything invisible/scaled down
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	play_label.modulate.a = 0.0
	quit_label.modulate.a = 0.0

	# Arrows start invisible (already set in scene)
	if play_arrow:
		play_arrow.modulate.a = 0.0
	if quit_arrow:
		quit_arrow.modulate.a = 0.0

	# Use await with timers for proper sequencing
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

	await get_tree().create_timer(0.5).timeout

	var tween2 = create_tween()
	tween2.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)

	await get_tree().create_timer(1.0).timeout

	var tween3 = create_tween()
	tween3.tween_property(play_label, "modulate:a", 1.0, 0.6)

	await get_tree().create_timer(0.2).timeout

	var tween4 = create_tween()
	tween4.tween_property(quit_label, "modulate:a", 1.0, 0.6)

func _on_play_hover():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(play_label, "position:x", play_label.position.x + 25, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(play_arrow, "modulate:a", 1.0, 0.2)

func _on_play_unhover():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(play_label, "position:x", play_label.position.x - 25, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(play_arrow, "modulate:a", 0.0, 0.2)

func _on_quit_hover():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(quit_label, "position:x", quit_label.position.x + 25, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_arrow, "modulate:a", 1.0, 0.2)

func _on_quit_unhover():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(quit_label, "position:x", quit_label.position.x - 25, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_arrow, "modulate:a", 0.0, 0.2)

func _on_play_pressed():
	print("splashscreen: play button pressed!")

	# Stop the looping music before leaving
	audio_player.stop()

	# Fade out quit button and other elements
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(quit_label, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(quit_arrow, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(title_label, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.3)

	# Typing animation - light up each letter
	await _animate_typing_effect()

	# Explode the letters
	await _explode_letters()

	# Change to main game scene
	print("splashscreen: changing to main scene...")
	var result = get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	if result != OK:
		print("ERROR: Failed to load main scene, error code: ", result)
	else:
		print("splashscreen: scene change initiated successfully!")

func _animate_typing_effect():
	var text = "start adventure"
	var bbcode = ""

	# Type each letter with color change
	for i in range(text.length()):
		bbcode = ""
		for j in range(text.length()):
			if j <= i:
				# Typed letters are bright golden
				bbcode += "[color=#FFE680]" + text[j] + "[/color]"
			else:
				# Untyped letters are dim
				bbcode += "[color=#665544]" + text[j] + "[/color]"

		play_label.text = bbcode

		# Play typing sound
		var typing_sound = AudioStreamPlayer.new()
		typing_sound.stream = load("res://assets/audio/sfx/press.wav")
		typing_sound.volume_db = -10
		add_child(typing_sound)
		typing_sound.play()

		# Screen shake on each letter
		var shake_offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		play_label.position += shake_offset

		await get_tree().create_timer(0.04).timeout  # Faster typing (was 0.08)

		# Reset position
		play_label.position -= shake_offset

		# Clean up sound
		typing_sound.queue_free()

	# Brief pause with all letters lit
	await get_tree().create_timer(0.15).timeout  # Shorter pause

func _explode_letters():
	var text = "start adventure"

	# MASSIVE screen shake before explosion
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position", position + Vector2(5, 5), 0.05)
	shake_tween.tween_property(self, "position", position - Vector2(5, 5), 0.05)
	shake_tween.tween_property(self, "position", position + Vector2(3, -3), 0.05)
	shake_tween.tween_property(self, "position", position, 0.05)

	await get_tree().create_timer(0.1).timeout

	# Create individual letter labels that explode
	for i in range(text.length()):
		if text[i] == " ":
			continue

		var letter = Label.new()
		letter.text = text[i]
		letter.add_theme_font_override("font", load("res://assets/fonts/Jersey20-Regular.ttf"))
		letter.add_theme_font_size_override("font_size", 56)
		letter.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
		letter.position = play_label.global_position + Vector2(i * 25, 0)
		letter.z_index = 100
		get_parent().add_child(letter)

		# Random explosion direction - MORE DRAMATIC
		var angle = randf_range(0, TAU)
		var distance = randf_range(300, 600)  # Further explosion (was 200-400)
		var target_pos = letter.position + Vector2(cos(angle), sin(angle)) * distance

		# Explode FASTER with MORE rotation and scale
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(letter, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)  # Faster and snappier (was 0.8)
		tween.tween_property(letter, "rotation", randf_range(-PI*5, PI*5), 0.5)  # More rotation (was PI*3)
		tween.tween_property(letter, "modulate:a", 0.0, 0.5)
		tween.tween_property(letter, "scale", Vector2(3, 3), 0.5)  # Bigger scale (was 2)

	# Hide original text
	play_label.modulate.a = 0

	# Continuous screen shake during explosion
	for shake_i in range(8):
		self.position += Vector2(randf_range(-4, 4), randf_range(-4, 4))
		await get_tree().create_timer(0.06).timeout
		self.position = Vector2.ZERO

	# Wait for explosion to finish (shorter wait)
	await get_tree().create_timer(0.2).timeout

func _on_quit_pressed():
	# Animate out before quitting
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished

	get_tree().quit()
