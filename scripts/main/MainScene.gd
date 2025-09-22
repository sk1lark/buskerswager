extends Node2D

func _ready():
	print("main scene: loaded successfully!")
	print("main scene: camera position: ", $Camera2D.position)
	print("main scene: checking children...")
	for child in get_children():
		print("main scene: child found: ", child.name, " - ", child.get_class())
		# Only check visibility for nodes that have a visible property (CanvasItems)
		if child is CanvasItem and child.visible == false:
			print("main scene: WARNING - ", child.name, " is not visible!")
	
	# Check if LaneInstance is properly loaded
	var lane = $LaneInstance
	if lane:
		print("main scene: lane found, position: ", lane.position, " scale: ", lane.scale)
		print("main scene: lane children: ", lane.get_child_count())
	else:
		print("main scene: ERROR - lane not found!")
	
	# Check if the busker is there
	var busker = $BuskerInstance
	if busker:
		print("main scene: busker found at: ", busker.position)
	else:
		print("main scene: ERROR - busker not found!")