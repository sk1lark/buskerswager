extends Node2D
class_name Pedestrian

# Character node names as they appear in the scene
const CHARACTER_NODES = [
	"chef",
	"knight",
	"wizard"
]

@onready var current_sprite: Sprite2D
@onready var shadow: Sprite2D
var rng = RandomNumberGenerator.new()
var character_type: int
var direction = Vector2.LEFT
var speed = 80.0
var is_performing_event = false
var street_y = 155  # Ground level position (lowered to prevent spawning too high)
var base_scale = 1.0  # Store original scale for depth effects
var has_stopped = false
var stop_chance = 0.15  # 15% chance to stop

# Wiggle animation variables
var wiggle_time: float = 0.0
var wiggle_speed: float = 8.0  # How fast the wiggle
var wiggle_amount: float = 5.0  # How much rotation in degrees

func _ready():
	rng.randomize()
	character_type = rng.randi_range(0, CHARACTER_NODES.size() - 1)

	_setup_character()
	_setup_movement()

func _setup_character():
	# Hide all character sprites first
	for node_name in CHARACTER_NODES:
		var sprite_node = get_node(node_name) as Sprite2D
		sprite_node.visible = false

	# Show and set up the selected character
	var selected_character = CHARACTER_NODES[character_type]
	current_sprite = get_node(selected_character) as Sprite2D
	current_sprite.visible = true

	# Create shadow for depth
	_create_shadow()

	# Add slight random scale variation for visual diversity
	base_scale = rng.randf_range(0.9, 1.1)
	current_sprite.scale = Vector2(base_scale, base_scale)

func _setup_movement():
	# Keep pedestrians at consistent height (no random y_offset)
	position.y = street_y

	# No depth scaling - keep them all the same size
	current_sprite.scale = Vector2(base_scale, base_scale)

	if rng.randi() % 2 == 0:
		direction = Vector2.RIGHT
		position.x = -100  # Closer spawn so they stay on screen
		current_sprite.flip_h = false
	else:
		direction = Vector2.LEFT
		position.x = 100   # Closer spawn so they stay on screen
		current_sprite.flip_h = true

	# Vary walking speed slightly
	speed = rng.randf_range(70.0, 90.0)

func _process(delta):
	if not is_performing_event:
		position += direction * speed * delta

		# Wiggle animation - rotate back and forth like a sticker
		wiggle_time += delta * wiggle_speed
		var wiggle_rotation = sin(wiggle_time) * deg_to_rad(wiggle_amount)
		current_sprite.rotation = wiggle_rotation

		# Check if pedestrian should stop (only once, near center)
		if not has_stopped and abs(position.x) < 50:
			if rng.randf() < stop_chance:
				stop_for_typing_challenge()

		# Delete when further off-screen (increased range to keep visible longer)
		if position.x < -150 or position.x > 150:
			queue_free()

func stop_for_typing_challenge():
	# Check if a challenge is already active
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager and game_manager.is_in_typing_challenge:
		# Don't stop - another challenge is already active
		return

	has_stopped = true
	is_performing_event = true
	speed = 0
	# Stop wiggling when stopped
	current_sprite.rotation = 0

	print("Pedestrian stopped for typing challenge!")

	# Notify GameManager to start typing challenge
	if game_manager:
		print("Found GameManager, starting challenge...")
		game_manager.start_typing_challenge(self)
	else:
		print("ERROR: Could not find GameManager!")

func perform_event(event_type: String):
	is_performing_event = true
	speed = 0

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
	# Resume wiggling
	wiggle_time = 0.0

func _give_money_and_pass():
	# Random villager just tosses money and keeps walking!
	var game_manager = get_node("/root/Main/GameManager")
	if not game_manager:
		return

	var tip_amount = rng.randi_range(3, 8)
	game_manager.tips_total += tip_amount
	game_manager._update_ui()

	# Show floating text
	var money_label = Label.new()
	money_label.text = "+$%d" % tip_amount
	money_label.add_theme_font_size_override("font_size", 28)
	money_label.modulate = Color(0.2, 1.0, 0.2, 1.0)  # Bright green
	money_label.position = position + Vector2(0, -40)
	money_label.z_index = 200
	get_parent().add_child(money_label)

	# Animate money floating up
	var money_tween = create_tween()
	money_tween.set_parallel(true)
	money_tween.tween_property(money_label, "position:y", money_label.position.y - 60, 1.5)
	money_tween.tween_property(money_label, "modulate:a", 0.0, 1.5)

	await money_tween.finished
	money_label.queue_free()

	print("Generous villager gave $%d!" % tip_amount)

func _create_shadow():
	# Create shadow sprite
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	add_child(shadow)
	move_child(shadow, 0)  # Put shadow behind character

	# Use the same texture as the character for the shadow
	if current_sprite and current_sprite.texture:
		shadow.texture = current_sprite.texture

	# Setup shadow properties
	shadow.modulate = Color(0, 0, 0, 0.35)  # Semi-transparent black
	shadow.scale = Vector2(base_scale * 1.0, base_scale * 0.3)  # Flattened shadow
	shadow.position = Vector2(0, 6)  # Below character
	shadow.skew = 0.05  # Slight perspective skew
