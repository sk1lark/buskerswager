extends Node2D

signal dice_rolled(value: int)
@onready var sprite = $DiceSprite

var rng = RandomNumberGenerator.new()
var last_face = 1

func _ready():
    rng.randomize()
    show_face(1)  # Show default face at start

func roll():
    # Play roll animation for verisimilitude!
    sprite.animation = "roll"
    sprite.play()
    # Wait 0.5 seconds (adjust for your taste)
    await get_tree().create_timer(0.5).timeout
    sprite.stop()
    # Pick random face 1-6 (corresponds to frame 0-5 in idle)
    var face = rng.randi_range(1, 6)
    show_face(face)
    last_face = face
    emit_signal("dice_rolled", face)

func show_face(face: int):
    sprite.animation = "idle"
    sprite.frame = face - 1  # face 1 is frame 0. Face 6 is frame 5.