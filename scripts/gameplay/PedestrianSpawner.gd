extends Node2D
class_name PedestrianSpawner

@onready var spawn_timer = $SpawnTimer
@export var pedestrian_scene: PackedScene
var base_spawn_rate = 4.0  # Slower spawning
var mood_multiplier = 1.0

func _ready():
	spawn_timer.timeout.connect(_spawn_pedestrian)
	pedestrian_scene = preload("res://scenes/characters/Pedestrian.tscn")
	spawn_timer.wait_time = base_spawn_rate
	spawn_timer.start()

func set_mood_spawn_rate(multiplier: float):
	mood_multiplier = multiplier
	spawn_timer.wait_time = base_spawn_rate / mood_multiplier

func _spawn_pedestrian():
	var pedestrian = pedestrian_scene.instantiate()
	pedestrian.z_index = 10  # Put pedestrians in front of busker
	get_parent().add_child(pedestrian)

func get_random_pedestrian() -> Pedestrian:
	var pedestrians = []
	for child in get_parent().get_children():
		if child is Pedestrian and not child.is_performing_event:
			pedestrians.append(child)
	
	if pedestrians.size() > 0:
		return pedestrians[randi() % pedestrians.size()]
	return null
