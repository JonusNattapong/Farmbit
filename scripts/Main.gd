extends Node2D

onready var time_label = $CanvasLayer/TimeDisplay

func _ready():
    # Initialize audio manager
    var audio_manager = AudioManager.new()
    add_child(audio_manager)
    audio_manager.play_music("background")