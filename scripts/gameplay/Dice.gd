extends Node2D

signal dice_rolled(value: int)
signal dice_clicked
@onready var sprite = $DiceSprite

var rng = RandomNumberGenerator.new()
var last_face = 1
var is_rolling = false
var is_glowing = false
var glow_tween: Tween

func _ready():
	rng.randomize()
	show_face(1)  # Show default face at start

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_rolling:
			emit_signal("dice_clicked")
			roll()

func roll():
	if is_rolling:
		return  # Prevent multiple rolls

	# Stop glowing when rolling starts
	stop_glow()
	is_rolling = true

	# Play dice sound effect
	print("Dice: Attempting to play dice sound...")
	var audio_manager = get_node("../../AudioManager")
	print("Dice: AudioManager found: ", audio_manager)
	if audio_manager and audio_manager.has_method("play_dice_sound"):
		print("Dice: Calling play_dice_sound()...")
		audio_manager.play_dice_sound()
	else:
		print("Dice: ERROR - AudioManager not found or missing method!")

	# Anticipation - slight pause and scale up
	var anticipation_tween = create_tween()
	anticipation_tween.set_parallel(true)
	anticipation_tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	anticipation_tween.tween_property(sprite, "rotation", 0.2, 0.3).set_ease(Tween.EASE_OUT)
	await anticipation_tween.finished

	# Play roll animation for verisimilitude!
	sprite.animation = "roll"
	sprite.play()

	# Add some bounce during roll
	var roll_tween = create_tween()
	roll_tween.set_loops()
	roll_tween.tween_property(sprite, "position:y", sprite.position.y - 5, 0.1)
	roll_tween.tween_property(sprite, "position:y", sprite.position.y, 0.1)

	# Wait for dramatic effect
	await get_tree().create_timer(1.2).timeout

	# Stop animations
	sprite.stop()
	roll_tween.kill()

	# Pick random face 1-6 (corresponds to frame 0-5 in idle)
	var face = rng.randi_range(1, 6)

	# Dramatic reveal with scale and rotate back
	var reveal_tween = create_tween()
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), 0.1)
	reveal_tween.tween_property(sprite, "rotation", 0, 0.1)
	await reveal_tween.finished

	show_face(face)

	# Bounce back to normal with satisfying pop
	var final_tween = create_tween()
	final_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await final_tween.finished

	is_rolling = false
	last_face = face
	emit_signal("dice_rolled", face)

func show_face(face: int):
	sprite.animation = "idle"
	sprite.frame = face - 1  # face 1 is frame 0. Face 6 is frame 5.

func start_glow():
	if is_glowing or is_rolling:
		return

	is_glowing = true
	print("dice: starting glow effect")

	# Create pulsing glow effect
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.8, 1.0), 0.8)  # Warm glow
	glow_tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.8)  # Softer glow

func stop_glow():
	if not is_glowing:
		return

	is_glowing = false
	print("dice: stopping glow effect")

	if glow_tween:
		glow_tween.kill()

	# Reset to normal color
	var reset_tween = create_tween()
	reset_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
