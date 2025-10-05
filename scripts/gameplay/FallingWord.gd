extends Node2D
class_name FallingWord

var word_text: String = ""
var typed_progress: int = 0  # How many letters have been typed correctly
var fall_speed: float = 50.0
var label: RichTextLabel
var is_setup_complete: bool = false

signal word_completed(word: FallingWord)
signal word_hit_ground(word: FallingWord)

func _init():
	# Create the label immediately in _init so it's ready
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", 32)
	label.add_theme_color_override("default_color", Color.WHITE)
	label.position = Vector2(-100, -20)
	label.size = Vector2(200, 40)

func _ready():
	# Add label to scene tree
	add_child(label)

	print("FallingWord _ready with text: ", word_text)

	# Update display if setup was already called
	if is_setup_complete:
		_update_display()

func setup(text: String, speed: float):
	print("FallingWord setup called with: ", text)
	word_text = text
	fall_speed = speed
	typed_progress = 0
	is_setup_complete = true

	# Update display now if label exists
	_update_display()

func _process(delta):
	# Fall down
	position.y += fall_speed * delta

	# Check if hit ground (y > 700 approximately)
	if position.y > 700:
		word_hit_ground.emit(self)
		queue_free()

func type_letter(letter: String) -> bool:
	# Check if this letter matches the next expected letter
	if typed_progress < word_text.length():
		if word_text[typed_progress].to_lower() == letter.to_lower():
			typed_progress += 1
			_update_display()

			# Check if word is complete
			if typed_progress >= word_text.length():
				word_completed.emit(self)
				return true
			return true
	return false

func _update_display():
	if not label or word_text == "":
		return

	# Build BBCode string with colored letters
	# Green for typed, white for untyped
	var display_text = "[center]"
	for i in range(word_text.length()):
		if i < typed_progress:
			display_text += "[color=#00ff00]" + word_text[i] + "[/color]"
		else:
			display_text += "[color=#ffffff]" + word_text[i] + "[/color]"
	display_text += "[/center]"

	label.text = display_text
	print("FallingWord display updated: ", display_text)

func get_next_expected_letter() -> String:
	if typed_progress < word_text.length():
		return word_text[typed_progress].to_lower()
	return ""

func is_complete() -> bool:
	return typed_progress >= word_text.length()