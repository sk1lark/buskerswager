extends Node2D
class_name Busker

@onready var sprite = $Sprite
var shadow: Sprite2D
var is_performing = false
var performance_tween: Tween
var base_position: Vector2
var base_scale: Vector2

func _ready():
	# Since sprite is now single frame, no need to set animation or play
	base_position = position
	base_scale = scale

func start_performance():
	is_performing = true
	# No animation changes needed since sprite is single frame

	# Add subtle performance movement for life
	performance_tween = create_tween()
	performance_tween.set_loops()
	performance_tween.set_parallel(true)

	# Gentle sway while performing
	performance_tween.tween_property(self, "position:x", base_position.x + 3, 1.5).set_ease(Tween.EASE_IN_OUT)
	performance_tween.tween_property(self, "position:x", base_position.x - 3, 1.5).set_ease(Tween.EASE_IN_OUT).set_delay(1.5)

	# Slight scale breathing effect
	performance_tween.tween_property(self, "scale", base_scale * 1.05, 2.0).set_ease(Tween.EASE_IN_OUT)
	performance_tween.tween_property(self, "scale", base_scale * 0.98, 2.0).set_ease(Tween.EASE_IN_OUT).set_delay(2.0)

func stop_performance():
	is_performing = false
	# No animation changes needed since sprite is single frame

	# Stop performance animation and return to base
	if performance_tween:
		performance_tween.kill()

	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(self, "position", base_position, 0.5).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "scale", base_scale, 0.5).set_ease(Tween.EASE_OUT)

# Add a special celebration animation for big tips
func celebrate():
	if not is_performing:
		var celebrate_tween = create_tween()
		celebrate_tween.set_parallel(true)

		# Jump for joy
		celebrate_tween.tween_property(self, "position:y", base_position.y - 20, 0.3).set_ease(Tween.EASE_OUT)
		celebrate_tween.tween_property(self, "position:y", base_position.y, 0.3).set_ease(Tween.EASE_IN).set_delay(0.3)

		# Spin slightly
		celebrate_tween.tween_property(self, "rotation", 0.2, 0.3).set_ease(Tween.EASE_OUT)
		celebrate_tween.tween_property(self, "rotation", 0, 0.3).set_ease(Tween.EASE_IN).set_delay(0.3)