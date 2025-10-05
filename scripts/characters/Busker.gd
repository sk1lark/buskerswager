extends Node2D

class_name Busker

@onready var sprite = $Sprite

var shadow: Sprite2D
var is_performing = false
var performance_tween: Tween
var float_tween: Tween

func _ready():
	_setup_busker_visuals()
	sprite.visible = true  # Force sprite to be visible
	sprite.animation = "idle"
	sprite.stop()  # Don't play animation to prevent blinking
	sprite.frame = 0  # Set to first frame

func _setup_busker_visuals():
	# Create shadow if it doesn't exist
	if not shadow:
		shadow = Sprite2D.new()
		shadow.name = "Shadow"
		add_child(shadow)
		move_child(shadow, 0)  # Put shadow behind sprite

	# Setup shadow properties
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		shadow.texture = sprite.sprite_frames.get_frame_texture("idle", 0)
		shadow.modulate = Color(0, 0, 0, 0.5)  # Semi-transparent black
		shadow.scale = Vector2(0.26, 0.12)  # Flattened shadow
		shadow.position = Vector2(0, 6)  # Slightly below character
		shadow.skew = 0.08  # Slight skew for perspective

func start_performance():
	if is_performing:
		return
	is_performing = true
	sprite.visible = true  # Ensure sprite is visible
	sprite.animation = "perform"
	sprite.stop()  # Keep static to prevent blinking
	sprite.frame = 0  # Use first frame
	print("Busker starting performance - sprite visible:", sprite.visible, " position:", position)
	_start_performance_effects()

func stop_performance():
	if not is_performing:
		return
	is_performing = false
	sprite.visible = true  # Keep visible
	sprite.animation = "idle"
	sprite.stop()  # Keep static
	sprite.frame = 0
	_stop_performance_effects()

func _start_performance_effects():
	# Kill existing tweens to prevent conflicts
	if performance_tween and performance_tween.is_valid():
		performance_tween.kill()
	if float_tween and float_tween.is_valid():
		float_tween.kill()

	# Simple glow effect only - no movement to avoid flickering
	performance_tween = create_tween()
	performance_tween.set_loops()
	performance_tween.tween_property(sprite, "modulate", Color(1.2, 1.15, 1.0, 1.0), 1.0)
	performance_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)

func _stop_performance_effects():
	# Stop all tweens
	if performance_tween and performance_tween.is_valid():
		performance_tween.kill()
	if float_tween and float_tween.is_valid():
		float_tween.kill()

	# Reset to normal appearance
	sprite.modulate = Color.WHITE
	sprite.position = Vector2.ZERO
	sprite.rotation = 0.0
