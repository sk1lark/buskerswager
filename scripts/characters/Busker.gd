extends Node2D
class_name Busker

@onready var sprite = $Sprite
var shadow: Sprite2D
var is_performing = false
var performance_tween: Tween

func _ready():
	sprite.animation = "idle"
	sprite.play()

func start_performance():
	is_performing = true
	sprite.animation = "perform"
	sprite.play()

func stop_performance():
	is_performing = false
	sprite.animation = "idle"
	sprite.play()