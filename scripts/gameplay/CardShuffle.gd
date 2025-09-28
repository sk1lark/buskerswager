extends Control
class_name CardShuffle

signal cards_drawn(luck_modifier: float, tip_multiplier: float)
signal shuffle_skipped

@onready var card_container = $CardContainer
@onready var draw_button = $DrawButton
@onready var skip_button = $SkipButton

var card_atlas: Texture2D
var card_textures: Array[AtlasTexture] = []
var card_back_texture: AtlasTexture

# Card dimensions and layout
const CARD_WIDTH = 56
const CARD_HEIGHT = 80
const CARDS_PER_ROW = 13
const TOTAL_ROWS = 6

# Card values for luck calculation
const CARD_VALUES = {
    # Row 0 - Hearts: A,2,3,4,5,6,7,8,9,10,J,Q,K
    0: [14,2,3,4,5,6,7,8,9,10,11,12,13],
    # Row 1 - Spades: A,2,3,4,5,6,7,8,9,10,J,Q,K  
    1: [14,2,3,4,5,6,7,8,9,10,11,12,13],
    # Row 2 - Diamonds: A,2,3,4,5,6,7,8,9,10,J,Q,K
    2: [14,2,3,4,5,6,7,8,9,10,11,12,13],
    # Row 3 - Clubs: A,2,3,4,5,6,7,8,9,10,J,Q,K
    3: [14,2,3,4,5,6,7,8,9,10,11,12,13],
    # Row 4 - Card backs and jokers
    4: [0,0,0,0,0,0,0,0,0,0,0,0,0],
    # Row 5 - More card backs/jokers
    5: [0,0,0,0,0,0,0,0,0,0,0,0,0]
}

func _ready():
    card_atlas = preload("res://assets/sprites/ui/cards/card_atlas.png")
    _setup_card_textures()
    
    print("CardShuffle: Setting up button connections...")
    print("CardShuffle: draw_button = ", draw_button)
    print("CardShuffle: skip_button = ", skip_button)
    
    if draw_button:
        draw_button.pressed.connect(_on_draw_pressed)
        print("CardShuffle: Draw button connected!")
    else:
        print("ERROR: Draw button not found!")
        
    if skip_button:
        skip_button.pressed.connect(_on_skip_pressed)
        print("CardShuffle: Skip button connected!")
    else:
        print("ERROR: Skip button not found!")
    
    visible = false

func _setup_card_textures():
    # Create card back first (top-left of row 4)
    card_back_texture = AtlasTexture.new()
    card_back_texture.atlas = card_atlas
    card_back_texture.region = Rect2(0, 4 * CARD_HEIGHT, CARD_WIDTH, CARD_HEIGHT)
    
    # Create AtlasTexture for each playing card (skip card backs/jokers)
    for row in range(4):  # Only first 4 rows (the actual cards)
        for col in range(CARDS_PER_ROW):
            var atlas_texture = AtlasTexture.new()
            atlas_texture.atlas = card_atlas
            atlas_texture.region = Rect2(
                col * CARD_WIDTH, 
                row * CARD_HEIGHT, 
                CARD_WIDTH, 
                CARD_HEIGHT
            )
            card_textures.append(atlas_texture)

func show_card_shuffle():
    print("CardShuffle: show_card_shuffle() called")
    visible = true
    # Reset cards to back and start shuffle animation
    var card_nodes = card_container.get_children()
    for card in card_nodes:
        if card is TextureRect:
            card.texture = card_back_texture
    
    print("CardShuffle: Starting shuffle animation")
    # Shuffle animation
    _animate_shuffle()

func _animate_shuffle():
    var card_nodes = card_container.get_children()
    
    # Quick shuffle effect - cards flip and move slightly
    for i in range(card_nodes.size()):
        if card_nodes[i] is TextureRect:
            var card = card_nodes[i]
            
            # Create a simple immediate animation without await inside the loop
            var tween = create_tween()
            tween.set_parallel(false)  # Sequential animations
            
            # Scale down and rotate
            tween.tween_property(card, "scale", Vector2(0.8, 0.8), 0.2)
            tween.parallel().tween_property(card, "rotation", PI/6, 0.2)
            # Scale back up and rotate back
            tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
            tween.parallel().tween_property(card, "rotation", 0, 0.2)
            
            # Small delay between cards
            await get_tree().create_timer(0.1).timeout
    
    # Wait for all animations to complete
    await get_tree().create_timer(0.5).timeout

func _on_draw_pressed():
    print("CardShuffle: Draw button pressed!")

    # Disable buttons during animation
    draw_button.disabled = true
    skip_button.disabled = true

    var drawn_cards = _draw_random_cards(3)
    var luck_modifier = _calculate_luck_modifier(drawn_cards)
    var tip_multiplier = _calculate_tip_multiplier(drawn_cards)

    print("CardShuffle: Starting card reveal animation...")

    # Dramatic pause before reveals
    await get_tree().create_timer(0.5).timeout

    # Animate card reveals with more juice
    var card_nodes = card_container.get_children()
    for i in range(min(3, card_nodes.size())):
        if card_nodes[i] is TextureRect and i < drawn_cards.size():
            var card = card_nodes[i]

            # Highlight the card being revealed
            var glow_tween = create_tween()
            glow_tween.tween_property(card, "modulate", Color.YELLOW, 0.2)

            await get_tree().create_timer(0.4).timeout

            # Dramatic flip with bounce
            var flip_tween = create_tween()
            flip_tween.set_parallel(true)
            flip_tween.tween_property(card, "scale:x", 0, 0.2).set_ease(Tween.EASE_IN)
            flip_tween.tween_property(card, "rotation", PI/4, 0.2).set_ease(Tween.EASE_IN)
            await flip_tween.finished

            # Play card flip sound
            print("CardShuffle: Attempting to play card sound...")
            var audio_manager = get_node("../../AudioManager")
            print("CardShuffle: AudioManager found: ", audio_manager)
            if audio_manager and audio_manager.has_method("play_cards_sound"):
                print("CardShuffle: Calling play_cards_sound()...")
                audio_manager.play_cards_sound()
            else:
                print("CardShuffle: ERROR - AudioManager not found or missing method!")

            # Change texture when card is "flipped"
            card.texture = drawn_cards[i]

            # Flip back with bounce
            flip_tween = create_tween()
            flip_tween.set_parallel(true)
            flip_tween.tween_property(card, "scale:x", 1.1, 0.15).set_ease(Tween.EASE_OUT)
            flip_tween.tween_property(card, "rotation", 0, 0.15).set_ease(Tween.EASE_OUT)
            flip_tween.tween_property(card, "scale:x", 1.0, 0.1).set_ease(Tween.EASE_IN).set_delay(0.15)
            flip_tween.tween_property(card, "modulate", Color.WHITE, 0.3).set_delay(0.2)

    # Show preview of results
    var preview_text = "Luck: %.2f | Tips: ×%.2f" % [luck_modifier, tip_multiplier]
    print("Card results: ", preview_text)

    # Wait a moment then emit result
    await get_tree().create_timer(1.5).timeout
    print("CardShuffle: Emitting cards_drawn signal with luck=%.2f, tip=%.2f" % [luck_modifier, tip_multiplier])
    cards_drawn.emit(luck_modifier, tip_multiplier)
    visible = false

func _on_skip_pressed():
    print("CardShuffle: Skip button pressed!")
    shuffle_skipped.emit()
    visible = false
    visible = false

func _draw_random_cards(count: int) -> Array[AtlasTexture]:
    var drawn: Array[AtlasTexture] = []
    for i in range(count):
        var random_index = randi_range(0, card_textures.size() - 1)
        drawn.append(card_textures[random_index])
    return drawn

func _get_card_value(card: AtlasTexture) -> int:
    var card_index = card_textures.find(card)
    if card_index == -1:
        return 0
    
    var row = int(card_index / CARDS_PER_ROW)  # Use explicit int conversion
    var col = card_index % CARDS_PER_ROW
    
    return CARD_VALUES.get(row, [0])[col]

func _calculate_luck_modifier(cards: Array[AtlasTexture]) -> float:
    var total_value = 0
    for card in cards:
        var value = _get_card_value(card)
        total_value += value
    
    # Convert to luck modifier (0.5 to 2.0)
    # Face cards and aces give better luck
    return 0.5 + (total_value / 42.0) * 1.5  # Max possible is 3 aces = 42

func _calculate_tip_multiplier(cards: Array[AtlasTexture]) -> float:
    var multiplier = 1.0
    var card_values = []
    var card_suits = []

    # Get values and suits for synergy checking
    for card in cards:
        var value = _get_card_value(card)
        var suit = _get_card_suit(card)
        card_values.append(value)
        card_suits.append(suit)

        # Base card bonuses
        if value == 14:  # Ace
            multiplier += 0.5
        elif value >= 11:  # Face cards (J, Q, K)
            multiplier += 0.3
        elif value >= 8:  # High cards
            multiplier += 0.1

    # Check for synergies
    var synergy_bonus = _calculate_synergy_bonus(card_values, card_suits)
    return multiplier + synergy_bonus

func _get_card_suit(card: AtlasTexture) -> int:
    var card_index = card_textures.find(card)
    if card_index == -1:
        return 0
    return int(card_index / CARDS_PER_ROW)  # 0=Hearts, 1=Spades, 2=Diamonds, 3=Clubs

func _calculate_synergy_bonus(values: Array, suits: Array) -> float:
    var bonus = 0.0

    # Synergy 1: Three of a Kind (same value) = +1.0 multiplier
    var value_counts = {}
    for value in values:
        value_counts[value] = value_counts.get(value, 0) + 1
    for count in value_counts.values():
        if count == 3:
            bonus += 1.0
            print("CardShuffle: THREE OF A KIND! +1.0 bonus")

    # Synergy 2: All Same Suit (flush) = +0.8 multiplier
    var unique_suits = {}
    for suit in suits:
        unique_suits[suit] = true
    if unique_suits.size() == 1:
        bonus += 0.8
        print("CardShuffle: FLUSH! +0.8 bonus")

    # Synergy 3: Straight (consecutive values) = +0.6 multiplier
    if _is_straight(values):
        bonus += 0.6
        print("CardShuffle: STRAIGHT! +0.6 bonus")

    # Synergy 4: All Face Cards (J, Q, K) = +0.7 multiplier
    var all_face_cards = true
    for value in values:
        if value < 11 or value > 13:
            all_face_cards = false
            break
    if all_face_cards:
        bonus += 0.7
        print("CardShuffle: ROYAL COURT! +0.7 bonus")

    # Synergy 5: All Aces = +1.5 multiplier (rare but powerful)
    var all_aces = true
    for value in values:
        if value != 14:
            all_aces = false
            break
    if all_aces:
        bonus += 1.5
        print("CardShuffle: TRIPLE ACES! +1.5 bonus")

    return bonus

func _is_straight(values: Array) -> bool:
    var sorted_values = values.duplicate()
    sorted_values.sort()

    # Check for consecutive values
    for i in range(1, sorted_values.size()):
        if sorted_values[i] != sorted_values[i-1] + 1:
            return false
    return true
