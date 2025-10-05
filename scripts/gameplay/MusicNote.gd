extends Node2D
class_name MusicNote

var velocity: Vector2 = Vector2.ZERO
var speed: float = 700.0  # Increased from 600
var lifetime: float = 2.0  # Despawn after 2 seconds
var sprite: Sprite2D
var trail_timer: float = 0.0
var trail_interval: float = 0.03  # Spawn trail every 0.03 seconds

signal note_hit_word(word: FallingWord)

func _init():
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/effects/musicnote.png")
	sprite.modulate = Color(1.0, 0.8, 0.2)  # Golden color
	sprite.scale = Vector2(1.2, 1.2)  # Make it slightly bigger

func _ready():
	add_child(sprite)

	# Add stronger glow effect with faster pulsing
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate", Color(1.3, 1.1, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.2), 0.2)

	# Scale pulse for extra juice
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
	scale_tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.2)

func setup(direction: Vector2):
	velocity = direction.normalized() * speed

func _process(delta):
	position += velocity * delta
	lifetime -= delta
	trail_timer += delta

	# Rotate the note as it flies
	rotation += delta * 12.0

	# Spawn trail particles
	if trail_timer >= trail_interval:
		trail_timer = 0.0
		_spawn_trail_particle()

	if lifetime <= 0:
		queue_free()

	# Check collision with falling words
	_check_word_collision()

func _spawn_trail_particle():
	var trail = Label.new()
	trail.text = "♪"
	trail.add_theme_font_size_override("font_size", 20)
	trail.modulate = Color(1.0, 0.8, 0.2, 0.7)
	trail.position = global_position
	trail.rotation = rotation
	trail.z_index = z_index - 1
	get_parent().add_child(trail)

	# Fade out and shrink
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "modulate:a", 0.0, 0.4)
	tween.tween_property(trail, "scale", Vector2(0.5, 0.5), 0.4)
	await tween.finished
	trail.queue_free()

func _check_word_collision():
	var game_manager = get_node("/root/Main/GameManager")
	if not game_manager:
		return

	for word in game_manager.falling_words:
		if is_instance_valid(word) and not word.is_locked:
			# Simple distance-based collision
			var distance = position.distance_to(word.position)
			if distance < 60:  # Hit radius
				# Spawn hit animation!
				_spawn_hit_animation(word.global_position)
				note_hit_word.emit(word)
				queue_free()
				return

func _spawn_hit_animation(hit_pos: Vector2):
	var parent = get_parent()
	if not parent:
		return

	# Create impact flash
	var flash = Sprite2D.new()
	flash.texture = sprite.texture
	flash.modulate = Color(1.5, 1.2, 0.3, 1.0)
	flash.scale = Vector2(2.0, 2.0)
	flash.position = hit_pos
	flash.z_index = 100
	parent.add_child(flash)

	# Flash and fade out using the flash's own tween (not music note's tween)
	var flash_tween = flash.create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector2(3.5, 3.5), 0.3).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free).set_delay(0.3)

	# Spawn burst particles
	for i in range(8):
		var particle = Label.new()
		particle.text = ["♪", "♫", "★"][i % 3]
		particle.add_theme_font_size_override("font_size", 24)
		particle.modulate = Color(1.0, 0.9, 0.4, 1.0)
		particle.position = hit_pos
		particle.z_index = 99
		parent.add_child(particle)

		var angle = (i / 8.0) * TAU
		var direction = Vector2(cos(angle), sin(angle)) * 80

		# Use particle's own tween (not music note's tween)
		var p_tween = particle.create_tween()
		p_tween.set_parallel(true)
		p_tween.tween_property(particle, "position", particle.position + direction, 0.4).set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		p_tween.tween_property(particle, "scale", Vector2(0.5, 0.5), 0.4)
		p_tween.tween_callback(particle.queue_free).set_delay(0.4)
