extends Node2D
class_name EnvironmentalEffects

# Environmental lighting and particle effects for the game
@onready var street_light_glow: Node2D
@onready var ambient_particles: GPUParticles2D
@onready var performance_sparkles: GPUParticles2D

var rng = RandomNumberGenerator.new()
var is_performing = false

func _ready():
	rng.randomize()
	_setup_lighting()
	_setup_particles()

func _setup_lighting():
	# Create atmospheric street light glow
	street_light_glow = Node2D.new()
	street_light_glow.name = "StreetLightGlow"
	add_child(street_light_glow)

	# Add multiple light sources for depth
	for i in range(3):
		var light = _create_light_source(
			Vector2(rng.randf_range(-400, 400), rng.randf_range(-50, -30)),
			rng.randf_range(0.8, 1.2),
			Color(1.0, 0.9, 0.7, rng.randf_range(0.1, 0.3))
		)
		street_light_glow.add_child(light)

func _create_light_source(pos: Vector2, scale_factor: float, color: Color) -> Sprite2D:
	var light = Sprite2D.new()

	# Create a simple circular light texture programmatically
	var light_texture = ImageTexture.new()
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center = Vector2(64, 64)

	for x in range(128):
		for y in range(128):
			var dist = center.distance_to(Vector2(x, y))
			var alpha = max(0, 1.0 - (dist / 64.0))
			alpha = pow(alpha, 2)  # Smoother falloff
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha * color.a))

	light_texture.set_image(image)
	light.texture = light_texture
	light.position = pos
	light.scale = Vector2(scale_factor, scale_factor)
	light.modulate = color

	# Add gentle pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(light, "modulate:a", color.a * 0.7, rng.randf_range(2.0, 4.0))
	tween.tween_property(light, "modulate:a", color.a, rng.randf_range(2.0, 4.0))

	return light

func _setup_particles():
	# Ambient dust particles
	ambient_particles = GPUParticles2D.new()
	ambient_particles.name = "AmbientParticles"
	add_child(ambient_particles)

	var ambient_material = ParticleProcessMaterial.new()
	ambient_material.direction = Vector3(0, -1, 0)
	ambient_material.initial_velocity_min = 10.0
	ambient_material.initial_velocity_max = 30.0
	ambient_material.gravity = Vector3(0, 20, 0)
	ambient_material.scale_min = 0.1
	ambient_material.scale_max = 0.3
	ambient_material.color = Color(0.9, 0.9, 0.8, 0.3)

	ambient_particles.process_material = ambient_material
	ambient_particles.amount = 25
	ambient_particles.emission_rect_extents = Vector2(500, 10)
	ambient_particles.position = Vector2(0, -200)
	ambient_particles.emitting = true

	# Performance sparkles (initially disabled)
	performance_sparkles = GPUParticles2D.new()
	performance_sparkles.name = "PerformanceSparkles"
	add_child(performance_sparkles)

	var sparkle_material = ParticleProcessMaterial.new()
	sparkle_material.direction = Vector3(0, -1, 0)
	sparkle_material.initial_velocity_min = 20.0
	sparkle_material.initial_velocity_max = 60.0
	sparkle_material.gravity = Vector3(0, -30, 0)
	sparkle_material.scale_min = 0.2
	sparkle_material.scale_max = 0.8
	sparkle_material.color = Color(1.0, 0.9, 0.6, 0.8)
	sparkle_material.hue_variation_min = -0.1
	sparkle_material.hue_variation_max = 0.1

	performance_sparkles.process_material = sparkle_material
	performance_sparkles.amount = 15
	performance_sparkles.emission_rect_extents = Vector2(30, 30)
	performance_sparkles.emitting = false

func start_performance_effects(busker_position: Vector2):
	is_performing = true

	# Position sparkles around the busker
	performance_sparkles.position = busker_position + Vector2(0, -20)
	performance_sparkles.emitting = true

	# Enhance lighting during performance
	var enhance_tween = create_tween()
	for light in street_light_glow.get_children():
		enhance_tween.parallel().tween_property(light, "modulate:a", light.modulate.a * 1.5, 1.0)

func stop_performance_effects():
	is_performing = false

	# Stop sparkles
	performance_sparkles.emitting = false

	# Restore normal lighting
	var restore_tween = create_tween()
	for light in street_light_glow.get_children():
		var original_alpha = light.modulate.a / 1.5  # Assuming we enhanced by 1.5x
		restore_tween.parallel().tween_property(light, "modulate:a", original_alpha, 1.0)

# Call this for dramatic events
func trigger_event_effect(effect_type: String, position: Vector2):
	match effect_type:
		"generous":
			_create_coin_sparkle(position)
		"dance":
			_create_dance_confetti(position)
		"heckle":
			_create_angry_smoke(position)

func _create_coin_sparkle(pos: Vector2):
	var coin_particles = GPUParticles2D.new()
	add_child(coin_particles)

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 40.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 0.3
	material.scale_max = 0.6
	material.color = Color(1.0, 0.8, 0.2, 1.0)

	coin_particles.process_material = material
	coin_particles.amount = 8
	coin_particles.position = pos
	coin_particles.emitting = true
	coin_particles.one_shot = true

	# Clean up after particles finish
	await get_tree().create_timer(3.0).timeout
	coin_particles.queue_free()

func _create_dance_confetti(pos: Vector2):
	var confetti = GPUParticles2D.new()
	add_child(confetti)

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 0.2
	material.scale_max = 0.5
	material.color = Color(rng.randf(), rng.randf(), rng.randf(), 0.9)
	material.hue_variation_min = -0.5
	material.hue_variation_max = 0.5

	confetti.process_material = material
	confetti.amount = 20
	confetti.position = pos + Vector2(0, -30)
	confetti.emitting = true
	confetti.one_shot = true

	await get_tree().create_timer(4.0).timeout
	confetti.queue_free()

func _create_angry_smoke(pos: Vector2):
	var smoke = GPUParticles2D.new()
	add_child(smoke)

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 50.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.4
	material.scale_max = 1.0
	material.color = Color(0.3, 0.1, 0.1, 0.6)

	smoke.process_material = material
	smoke.amount = 12
	smoke.position = pos + Vector2(0, -10)
	smoke.emitting = true
	smoke.one_shot = true

	await get_tree().create_timer(2.5).timeout
	smoke.queue_free()