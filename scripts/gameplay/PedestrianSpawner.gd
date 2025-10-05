extends Node2D
class_name PedestrianSpawner

@onready var spawn_timer = $SpawnTimer
@export var pedestrian_scene: PackedScene
var base_spawn_rate = 4.0  # Slower spawning
var mood_multiplier = 1.0
var active_character_types = []  # Track which character sprites are currently on screen

func _ready():
	spawn_timer.timeout.connect(_spawn_pedestrian)
	pedestrian_scene = preload("res://scenes/characters/Pedestrian.tscn")
	spawn_timer.wait_time = base_spawn_rate
	# Don't start automatically - wait for game to start it

func start_spawning():
	spawn_timer.start()

func set_mood_spawn_rate(multiplier: float):
	mood_multiplier = multiplier
	spawn_timer.wait_time = base_spawn_rate / mood_multiplier

func _spawn_pedestrian():
	# Clean up the active list - remove any invalid pedestrians
	active_character_types = active_character_types.filter(func(p): return is_instance_valid(p))

	# Get list of currently used character types
	var used_types = []
	for ped in active_character_types:
		used_types.append(ped.character_type)

	# Find available character types (0-8 for 9 characters)
	var available_types = []
	for i in range(9):
		if i not in used_types:
			available_types.append(i)

	# If all types are in use, just pick a random one anyway
	if available_types.is_empty():
		available_types = range(9)

	var pedestrian = pedestrian_scene.instantiate()

	# Override the character selection with an available type
	var selected_type = available_types[randi() % available_types.size()]
	pedestrian.character_type = selected_type

	pedestrian.z_index = 10  # Put pedestrians in front of busker
	get_parent().add_child(pedestrian)

	# Track this pedestrian
	active_character_types.append(pedestrian)

	# Connect to removal signal to clean up tracking
	pedestrian.tree_exited.connect(func(): _on_pedestrian_removed(pedestrian))

func _on_pedestrian_removed(pedestrian):
	active_character_types.erase(pedestrian)

func get_random_pedestrian() -> Pedestrian:
	var pedestrians = []
	for child in get_parent().get_children():
		if child is Pedestrian and not child.is_performing_event:
			pedestrians.append(child)
	
	if pedestrians.size() > 0:
		return pedestrians[randi() % pedestrians.size()]
	return null
