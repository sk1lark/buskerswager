extends Node2D

class_name Busker

@onready var sprite = $Sprite

var is_performing = false
var performance_tween: Tween
var float_tween: Tween

func _ready():
	sprite.visible = true  # Force sprite to be visible
	sprite.animation = "idle"
	sprite.stop()  # Keep static - sprite has no frames
	sprite.frame = 0

func start_performance():
	if is_performing:
		return
	is_performing = true
	sprite.visible = true  # Ensure sprite is visible
	sprite.animation = "perform"
	sprite.stop()  # Keep static - sprite has no frames
	sprite.frame = 0
	print("Busker starting performance - sprite visible:", sprite.visible, " position:", position)
	_start_performance_effects()

func stop_performance():
	if not is_performing:
		return
	is_performing = false
	sprite.visible = true  # Keep visible
	sprite.animation = "idle"
	sprite.stop()  # Keep static - sprite has no frames
	sprite.frame = 0
	_stop_performance_effects()

func _start_performance_effects():
	# Kill existing tweens to prevent conflicts
	if performance_tween and performance_tween.is_valid():
		performance_tween.kill()
	if float_tween and float_tween.is_valid():
		float_tween.kill()

	# Glow effect with subtle bounce
	performance_tween = create_tween()
	performance_tween.set_loops()
	performance_tween.tween_property(sprite, "modulate", Color(1.2, 1.15, 1.0, 1.0), 0.6)
	performance_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)

	# Subtle floating/bobbing animation
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(sprite, "position", Vector2(0, -3), 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(sprite, "position", Vector2(0, 0), 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

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
