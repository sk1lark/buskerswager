extends Node2D
class_name MusicNote

var velocity: Vector2 = Vector2.ZERO
var speed: float = 600.0
var lifetime: float = 2.0  # Despawn after 2 seconds
var sprite: Sprite2D

signal note_hit_word(word: FallingWord)

func _init():
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/effects/musicnote.png")
	sprite.modulate = Color(1.0, 0.8, 0.2)  # Golden color

func _ready():
	add_child(sprite)

	# Add glow effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate", Color(1.2, 1.0, 0.5), 0.3)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.2), 0.3)

func setup(direction: Vector2):
	velocity = direction.normalized() * speed

func _process(delta):
	position += velocity * delta
	lifetime -= delta

	# Rotate the note as it flies
	rotation += delta * 10.0

	if lifetime <= 0:
		queue_free()

	# Check collision with falling words
	_check_word_collision()

func _check_word_collision():
	var game_manager = get_node("/root/Main/GameManager")
	if not game_manager:
		return

	for word in game_manager.falling_words:
		if is_instance_valid(word) and not word.is_locked:
			# Simple distance-based collision
			var distance = position.distance_to(word.position)
			if distance < 60:  # Hit radius
				note_hit_word.emit(word)
				queue_free()
				return
