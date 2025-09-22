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
    var drawn_cards = _draw_random_cards(3)
    var luck_modifier = _calculate_luck_modifier(drawn_cards)
    var tip_multiplier = _calculate_tip_multiplier(drawn_cards)
    
    print("CardShuffle: Starting card reveal animation...")
    
    # Animate card reveals
    var card_nodes = card_container.get_children()
    for i in range(min(3, card_nodes.size())):
        if card_nodes[i] is TextureRect and i < drawn_cards.size():
            await get_tree().create_timer(0.3).timeout
            
            # Flip animation
            var card = card_nodes[i]
            var tween = create_tween()
            tween.tween_property(card, "scale:x", 0, 0.15)
            await tween.finished
            
            # Change texture when card is "flipped"
            card.texture = drawn_cards[i]
            
            # Flip back
            tween = create_tween()
            tween.tween_property(card, "scale:x", 1, 0.15)
    
    # Wait a moment then emit result
    await get_tree().create_timer(2.0).timeout
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
    for card in cards:
        var value = _get_card_value(card)
        
        if value == 14:  # Ace
            multiplier += 0.5
        elif value >= 11:  # Face cards (J, Q, K)
            multiplier += 0.3
        elif value >= 8:  # High cards
            multiplier += 0.1
    
    return multiplier
