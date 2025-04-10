extends Node

var music_volume = 0.5
var sfx_volume = 0.5

func _ready():
    # Load music and sound effects
    load_music()
    load_sfx()

func load_music():
    # Load background music
    var music = AudioStreamPlayer.new()
    music.stream = load("res://assets/music/background_music.ogg")
    music.volume_db = linear2db(music_volume)
    music.play()
    add_child(music)

func load_sfx():
    # Load sound effects
    var sfx = {
        "attack": load("res://assets/sfx/attack_sound.ogg"),
        "hit": load("res://assets/sfx/hit_sound.ogg"),
        "harvest": load("res://assets/sfx/harvest_sound.ogg"),
        "build": load("res://assets/sfx/build_sound.ogg"),
        "collect": load("res://assets/sfx/collect_sound.ogg")
    }

func play_music(music_type):
    match music_type:
        "background":
            $Music.stream = load("res://assets/music/background_music.ogg")
            $Music.play()

func play_sfx(sfx_type):
    var sfx = AudioStreamPlayer.new()
    sfx.stream = load("res://assets/sfx/" + sfx_type + ".ogg")
    sfx.volume_db = linear2db(sfx_volume)
    sfx.play()
    add_child(sfx)