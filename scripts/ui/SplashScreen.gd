extends Control

@onready var play_button = $VBoxContainer/MenuContainer/PlayButton
@onready var quit_button = $VBoxContainer/MenuContainer/QuitButton
@onready var title_label = $VBoxContainer/TitleLabel
@onready var subtitle_label = $VBoxContainer/SubtitleLabel
@onready var audio_player = $AudioStreamPlayer

func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Add button hover effects
	play_button.mouse_entered.connect(_on_button_hover.bind(play_button))
	play_button.mouse_exited.connect(_on_button_unhover.bind(play_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))
	quit_button.mouse_exited.connect(_on_button_unhover.bind(quit_button))

	# Add button press effects
	play_button.button_down.connect(_on_button_press.bind(play_button))
	play_button.button_up.connect(_on_button_release.bind(play_button))
	quit_button.button_down.connect(_on_button_press.bind(quit_button))
	quit_button.button_up.connect(_on_button_release.bind(quit_button))

	# Start background music
	audio_player.play()

	# Start entrance animation
	_animate_entrance()

func _animate_entrance():
	# Start everything invisible/scaled down
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	play_button.scale = Vector2.ZERO
	quit_button.scale = Vector2.ZERO

	# Use await with timers for proper sequencing
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

	await get_tree().create_timer(0.5).timeout

	var tween2 = create_tween()
	tween2.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)

	await get_tree().create_timer(1.0).timeout

	var tween3 = create_tween()
	tween3.tween_property(play_button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.2).timeout

	var tween4 = create_tween()
	tween4.tween_property(quit_button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 0.9), 0.2)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.2)

func _on_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_button_release(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_play_pressed():
	print("splashscreen: play button pressed!")
	# Animate out before changing scene
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished

	# Change to main game scene
	print("splashscreen: changing to main scene...")
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	print("splashscreen: scene change called!")

func _on_quit_pressed():
	# Animate out before quitting
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished

	get_tree().quit()
