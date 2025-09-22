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
var rng = RandomNumberGenerator.new()
var character_type: int
var direction = Vector2.LEFT
var speed = 80.0
var is_performing_event = false
var street_y = 130  # Ground level position matching where busker stands
var has_stopped_for_cards = false
var stop_chance = 0.3  # 30% chance to stop for cards

func _ready():
	rng.randomize()
	character_type = rng.randi_range(0, CHARACTER_NODES.size() - 1)
	
	_setup_character()
	_setup_movement()
	
	# Connect to GameManager for card shuffles
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		card_shuffle_requested.connect(game_manager._on_pedestrian_card_request)
		print("Pedestrian connected to GameManager for cards")
	else:
		print("ERROR: Could not find GameManager for card shuffle!")

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

func _setup_movement():
	# Lane's local coordinate system - spawn off the sides of the lane area
	position.y = street_y + rng.randi_range(-20, 20)
	
	if rng.randi() % 2 == 0:
		direction = Vector2.RIGHT
		position.x = -200  # Left side of lane area
		current_sprite.flip_h = false
	else:
		direction = Vector2.LEFT
		position.x = 200   # Right side of lane area
		current_sprite.flip_h = true

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
	# Glow effect for generous tip
	current_sprite.modulate = Color(1.2, 1.2, 0.8)
	
	# Create floating coin effect
	var _coin_pos = position + Vector2(0, -30)
	# Add particle effect here if desired
	
	await get_tree().create_timer(2.5).timeout
	current_sprite.modulate = Color.WHITE
	_resume_walking()

func _perform_dance():
	# Bounce and sway animation
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(self, "position:y", position.y - 20, 0.4)
	tween.tween_property(self, "position:y", position.y, 0.4)
	
	await get_tree().create_timer(3.0).timeout
	_resume_walking()

func _perform_heckle():
	# Red angry tint
	current_sprite.modulate = Color.RED
	# Shake effect
	var original_pos = position
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.1)
	tween.tween_property(self, "position", original_pos + Vector2(-5, 0), 0.1)
	
	await get_tree().create_timer(1.8).timeout
	position = original_pos
	current_sprite.modulate = Color.WHITE
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
	
	print("Pedestrian stopping for cards!")
	# Signal to GameManager that this pedestrian wants to see cards
	card_shuffle_requested.emit(self)

func continue_after_cards():
	# Called by GameManager after card shuffle is complete
	_resume_walking()
