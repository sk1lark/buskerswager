extends Node2D
class_name Busker

@onready var sprite = $Sprite
var is_performing = false

func _ready():
    _setup_busker_animations()
    sprite.animation = "idle"
    sprite.play()

func _setup_busker_animations():
    # The busker sprite already has animations set up in the scene file
    # Just ensure the animation is playing
    if sprite.sprite_frames != null:
        sprite.animation = "idle"
        sprite.play()

func start_performance():
    is_performing = true
    sprite.animation = "perform"
    sprite.play()
    # Add glowing effect during performance
    sprite.modulate = Color(1.1, 1.1, 0.9)

func stop_performance():
    is_performing = false
    sprite.animation = "idle"
    sprite.play()
    sprite.modulate = Color.WHITE
