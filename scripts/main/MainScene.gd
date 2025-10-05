extends Node2D

func _ready():
	# Validate critical scene nodes
	if not $LaneInstance:
		push_error("MainScene: Lane not found!")
	if not $BuskerInstance:
		push_error("MainScene: Busker not found!")