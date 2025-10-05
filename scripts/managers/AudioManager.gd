extends Node

# audio players for different sound types
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var performance_player: AudioStreamPlayer

# lute tracks that play during busker performances
var performance_tracks = [
    "res://assets/audio/music/performance/lute1.ogg",
    "res://assets/audio/music/performance/lute2.ogg", 
    "res://assets/audio/music/performance/lute3.ogg"
]

var is_performing = false

func _ready():
    # Create audio players
    music_player = AudioStreamPlayer.new()
    music_player.volume_db = -12.0
    add_child(music_player)

    sfx_player = AudioStreamPlayer.new()
    sfx_player.volume_db = 5.0  # Much louder for dice and card sounds
    add_child(sfx_player)

    ambient_player = AudioStreamPlayer.new()
    ambient_player.volume_db = -20.0
    add_child(ambient_player)

    # Create performance player for busker music
    performance_player = AudioStreamPlayer.new()
    performance_player.volume_db = -8.0
    add_child(performance_player)

    # Connect signal for when performance track finishes
    performance_player.finished.connect(_on_performance_finished)

func play_music(path: String, loop: bool = true):
    var stream = load(path)
    if stream:
        music_player.stream = stream
        if stream is AudioStreamOggVorbis:
            stream.loop = loop
        music_player.play()

func stop_music():
    music_player.stop()

func play_sfx(path: String):
    var stream = load(path)
    if stream:
        sfx_player.stream = stream
        sfx_player.play()
    else:
        push_error("AudioManager: Failed to load SFX: " + path)

# Play the yippee sound when earning money!
func play_yippee_sound():
    play_sfx("res://assets/audio/sfx/yippee.ogg")

# Play dice roll sound
func play_dice_sound():
    play_sfx("res://assets/audio/sfx/dice.ogg")

# Play card flip/deal sound
func play_cards_sound():
    play_sfx("res://assets/audio/sfx/cards.ogg")

func play_ambient_loop(path: String):
    var stream = load(path)
    if stream:
        ambient_player.stream = stream
        if stream is AudioStreamOggVorbis:
            stream.loop = true
        ambient_player.play()

# Performance music functions
func start_performance_music():
    if not is_performing:
        is_performing = true
        _play_random_performance_track()

func stop_performance_music():
    if is_performing:
        is_performing = false
        performance_player.stop()

func _play_random_performance_track():
    if performance_tracks.size() > 0:
        var random_track = performance_tracks[randi() % performance_tracks.size()]
        if ResourceLoader.exists(random_track):
            var stream = load(random_track)
            if stream:
                performance_player.stream = stream
                # Don't loop individual tracks - let them play naturally
                if stream is AudioStreamOggVorbis:
                    stream.loop = false
                performance_player.play()
        else:
            push_error("AudioManager: Track file not found: " + random_track)

func _on_performance_finished():
    # When a performance track finishes naturally, play another random one if still performing
    if is_performing:
        _play_random_performance_track()