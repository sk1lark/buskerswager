extends Node2D
class_name Busker

@onready var sprite = $Sprite
@onready var shadow = $Shadow
var is_performing = false
var performance_tween: Tween
var lighting_shader: Shader
var material: ShaderMaterial

func _ready():
	_setup_busker_visuals()
	sprite.animation = "idle"
	sprite.play()

func _setup_busker_visuals():
	# Setup lighting shader
	if ResourceLoader.exists("res://assets/shaders/character_lighting.gdshader"):
		lighting_shader = load("res://assets/shaders/character_lighting.gdshader")
		if lighting_shader:
			material = ShaderMaterial.new()
			material.shader = lighting_shader
			sprite.material = material
			print("Busker: Lighting shader loaded successfully")
	else:
		print("Busker: Lighting shader not found, using default rendering")

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
	shadow.scale = Vector2(0.26, 0.12)  # Flattened shadow (matching new sprite scale)
	shadow.position = Vector2(0, 6)  # Slightly below character
	shadow.skew = 0.08  # Slight skew for perspective

	# The busker sprite already has animations set up in the scene file
	if sprite.sprite_frames != null:
		sprite.animation = "idle"
		sprite.play()

func start_performance():
	is_performing = true
	sprite.animation = "perform"
	sprite.play()

	# Enhanced performance effects
	_start_performance_effects()

func stop_performance():
	is_performing = false
	sprite.animation = "idle"
	sprite.play()

	# Stop performance effects
	_stop_performance_effects()

func _start_performance_effects():
	# Kill existing tween
	if performance_tween:
		performance_tween.kill()

	# Enable shader glow effect
	if material:
		material.set_shader_parameter("glow_strength", 0.8)

	performance_tween = create_tween()
	performance_tween.set_loops()

	# Enhanced visual effects for performance
	performance_tween.tween_property(sprite, "modulate", Color(1.15, 1.1, 1.0, 1.0), 1.2)
	performance_tween.tween_property(sprite, "modulate", Color(1.05, 1.05, 1.05, 1.0), 1.2)

	# Subtle floating animation with rotation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.parallel().tween_property(sprite, "position", Vector2(0, -3), 2.5)
	float_tween.parallel().tween_property(sprite, "rotation", deg_to_rad(2), 2.5)
	float_tween.parallel().tween_property(sprite, "position", Vector2(0, 3), 2.5)
	float_tween.parallel().tween_property(sprite, "rotation", deg_to_rad(-2), 2.5)

func _stop_performance_effects():
	# Stop all tweens
	if performance_tween:
		performance_tween.kill()

	# Disable shader glow effect
	if material:
		material.set_shader_parameter("glow_strength", 0.0)

	# Reset to normal appearance
	var reset_tween = create_tween()
	reset_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.8)
	reset_tween.parallel().tween_property(sprite, "position", Vector2.ZERO, 0.8)
	reset_tween.parallel().tween_property(sprite, "rotation", 0.0, 0.8)
