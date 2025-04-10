extends Control

onready var start_button = $MenuPanel/VBoxContainer/StartButton
onready var load_button = $MenuPanel/VBoxContainer/LoadButton
onready var settings_button = $MenuPanel/VBoxContainer/SettingsButton
onready var quit_button = $MenuPanel/VBoxContainer/QuitButton

func _ready():
    # Connect button signals
    start_button.connect("pressed", self, "_on_start_pressed")
    load_button.connect("pressed", self, "_on_load_pressed")
    settings_button.connect("pressed", self, "_on_settings_pressed")
    quit_button.connect("pressed", self, "_on_quit_pressed")
    
    # Play background music if available
    # if $BackgroundMusic:
    #     $BackgroundMusic.play()
    
    # Check for save files
    _check_save_files()

func _check_save_files():
    # Check if there are any save files
    var dir = Directory.new()
    var has_saves = false
    
    for i in range(3):  # Check 3 save slots
        if dir.file_exists("user://save_" + str(i) + ".save"):
            has_saves = true
            break
    
    # Enable/disable load button based on save existence
    load_button.disabled = !has_saves

func _on_start_pressed():
    # Change to character creation / new game scene
    get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_load_pressed():
    # Show load game menu
    var save_slots = load("res://scenes/SaveSlots.tscn").instance()
    add_child(save_slots)
    save_slots.connect("save_selected", self, "_on_save_selected")

func _on_settings_pressed():
    # Show settings menu
    var settings_menu = load("res://scenes/SettingsMenu.tscn").instance()
    add_child(settings_menu)

func _on_quit_pressed():
    # Exit game
    get_tree().quit()

func _on_save_selected(save_index):
    # Load selected save file and start game
    if GameData.load_game(save_index):
        get_tree().change_scene("res://scenes/Main.tscn")
    else:
        # Show error message
        print("Failed to load save file")