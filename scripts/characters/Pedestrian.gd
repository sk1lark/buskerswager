extends Node2D
class_name Pedestrian

signal card_shuffle_requested(pedestrian: Pedestrian)

# Character node names as they appear in the scene
const CHARACTER_NODES = [
	"bearded",
	"old man",
	"woman",
    "hat man"
]

@onready var current_sprite: AnimatedSprite2D
@onready var shadow: Sprite2D
var rng = RandomNumberGenerator.new()
var character_type: int
var direction = Vector2.LEFT
var speed = 80.0
var is_performing_event = false
var street_y = 130  # Ground level position matching where busker stands
var has_stopped_for_cards = false
var stop_chance = 0.6  # 60% chance to stop for cards (increased for testing)
var base_scale = 1.0  # Store original scale for depth effects

func _ready():
	rng.randomize()
	character_type = rng.randi_range(0, CHARACTER_NODES.size() - 1)
	
	_setup_character()
	_setup_movement()
	
	# Connect to GameManager for card shuffles
	print("pedestrian: attempting to connect to GameManager...")
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		card_shuffle_requested.connect(game_manager._on_pedestrian_card_request)
		print("pedestrian: successfully connected to GameManager for cards")
	else:
		print("pedestrian: ERROR - Could not find GameManager at /root/Main/GameManager")
		# Try alternate path
		game_manager = get_node("../../GameManager")
		if game_manager:
			card_shuffle_requested.connect(game_manager._on_pedestrian_card_request)
			print("pedestrian: found GameManager at alternate path")
		else:
			print("pedestrian: ERROR - GameManager not found at alternate path either")

func _setup_character():
	# Hide all character sprites first
	for node_name in CHARACTER_NODES:
		var sprite_node = get_node(node_name)
		sprite_node.visible = false

	# Show and set up the selected character
	var selected_character = CHARACTER_NODES[character_type]
	current_sprite = get_node(selected_character)
	current_sprite.visible = true
	current_sprite.animation = "walk"
	current_sprite.play()

	# Create shadow for depth
	_create_shadow()

	# Add slight random scale variation for visual diversity
	base_scale = rng.randf_range(0.9, 1.1)
	current_sprite.scale = Vector2(base_scale, base_scale)

func _setup_movement():
	# Lane's local coordinate system - spawn off the sides of the lane area
	var y_offset = rng.randi_range(-30, 30)
	position.y = street_y + y_offset

	# Scale based on y position for depth effect (closer = bigger)
	var depth_scale = 1.0 + (y_offset * 0.004)  # Subtle depth scaling
	base_scale *= depth_scale
	current_sprite.scale = Vector2(base_scale, base_scale)

	if rng.randi() % 2 == 0:
		direction = Vector2.RIGHT
		position.x = -200  # Left side of lane area
		current_sprite.flip_h = false
	else:
		direction = Vector2.LEFT
		position.x = 200   # Right side of lane area
		current_sprite.flip_h = true

	# Vary walking speed slightly
	speed = rng.randf_range(70.0, 90.0)

func _process(delta):
	if not is_performing_event:
		position += direction * speed * delta
		
		# Check if pedestrian should stop for cards (only once, near center)
		if not has_stopped_for_cards and abs(position.x) < 50:
			if rng.randf() < stop_chance:
				_stop_for_cards()
				return
		
		# Delete when off-screen in lane coordinate space
		if position.x < -250 or position.x > 250:
			queue_free()

func perform_event(event_type: String):
	is_performing_event = true
	speed = 0
	current_sprite.animation = "idle"
	current_sprite.play()
	
	match event_type:
		"generous":
			_perform_generous()
		"dance":
			_perform_dance()
		"heckle":
			_perform_heckle()

func _perform_generous():
	# Enhanced glow effect for generous tip
	var glow_tween = create_tween()
	glow_tween.set_loops(3)
	glow_tween.tween_property(current_sprite, "modulate", Color(1.3, 1.2, 0.7), 0.4)
	glow_tween.tween_property(current_sprite, "modulate", Color(1.1, 1.1, 0.9), 0.4)

	# Floating animation with sparkle effect
	var float_tween = create_tween()
	float_tween.tween_property(current_sprite, "position", Vector2(0, -8), 0.8)
	float_tween.tween_property(current_sprite, "position", Vector2.ZERO, 0.8)

	await get_tree().create_timer(2.5).timeout
	current_sprite.modulate = Color.WHITE
	_resume_walking()

func _perform_dance():
	# Enhanced dancing with rotation and scaling
	var dance_tween = create_tween()
	dance_tween.set_loops(4)

	# Bouncy dance with slight rotation and scale
	dance_tween.parallel().tween_property(self, "position:y", position.y - 25, 0.3)
	dance_tween.parallel().tween_property(current_sprite, "rotation", deg_to_rad(10), 0.3)
	dance_tween.parallel().tween_property(current_sprite, "scale", Vector2(base_scale * 1.1, base_scale * 1.1), 0.3)

	dance_tween.parallel().tween_property(self, "position:y", position.y, 0.3)
	dance_tween.parallel().tween_property(current_sprite, "rotation", deg_to_rad(-10), 0.3)
	dance_tween.parallel().tween_property(current_sprite, "scale", Vector2(base_scale * 0.95, base_scale * 1.05), 0.3)

	await get_tree().create_timer(3.2).timeout

	# Reset properties
	current_sprite.rotation = 0
	current_sprite.scale = Vector2(base_scale, base_scale)
	_resume_walking()

func _perform_heckle():
	# Enhanced angry effect with color cycling and aggressive shaking
	var angry_tween = create_tween()
	angry_tween.set_loops(4)
	angry_tween.tween_property(current_sprite, "modulate", Color(1.4, 0.3, 0.3), 0.2)
	angry_tween.tween_property(current_sprite, "modulate", Color(1.0, 0.5, 0.5), 0.2)

	# More aggressive shake with rotation
	var original_pos = position
	var shake_tween = create_tween()
	shake_tween.set_loops(8)
	shake_tween.parallel().tween_property(self, "position", original_pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-3, 3)), 0.08)
	shake_tween.parallel().tween_property(current_sprite, "rotation", deg_to_rad(rng.randf_range(-15, 15)), 0.08)

	await get_tree().create_timer(2.0).timeout

	# Reset properties
	position = original_pos
	current_sprite.modulate = Color.WHITE
	current_sprite.rotation = 0
	_resume_walking()

func _resume_walking():
	is_performing_event = false
	speed = 80.0
	current_sprite.animation = "walk"
	current_sprite.play()

func _stop_for_cards():
	has_stopped_for_cards = true
	is_performing_event = true
	speed = 0
	current_sprite.animation = "idle"
	current_sprite.play()

	print("pedestrian: stopping for cards and emitting signal!")
	# Signal to GameManager that this pedestrian wants to see cards
	card_shuffle_requested.emit(self)
	print("pedestrian: card_shuffle_requested signal emitted")

func continue_after_cards():
	# Called by GameManager after card shuffle is complete
	_resume_walking()

func _create_shadow():
	# Create shadow sprite
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	add_child(shadow)
	move_child(shadow, 0)  # Put shadow behind character

	# Get current frame for shadow texture
	if current_sprite and current_sprite.sprite_frames:
		shadow.texture = current_sprite.sprite_frames.get_frame_texture("walk", 0)

	# Setup shadow properties
	shadow.modulate = Color(0, 0, 0, 0.35)  # Semi-transparent black
	shadow.scale = Vector2(base_scale * 1.0, base_scale * 0.3)  # Flattened shadow
	shadow.position = Vector2(0, 6)  # Below character
	shadow.skew = 0.05  # Slight perspective skew
