extends Node2D

signal entered_shelter
signal exited_shelter

onready var bed = $Bed
onready var storage = $Storage
onready var cooking_station = $CookingStation
onready var cooking_ui = $CanvasLayer/CookingUI
onready var door = $Door
onready var player = null

# Interaction state
var can_cook = false

func _ready():
    # Connect bed interaction
    if bed:
        bed.connect("interact", self, "_on_bed_interact")
    
    # Connect storage interaction
    if storage:
        storage.connect("interact", self, "_on_storage_interact")
    
    # Connect door interaction
    if door:
        door.connect("interact", self, "_on_door_interact")
    
    # Connect cooking station
    if cooking_station:
        cooking_station.connect("body_entered", self, "_on_cooking_station_body_entered")
        cooking_station.connect("body_exited", self, "_on_cooking_station_body_exited")
    
    # Get player reference
    player = get_node_or_null("Player")
    if player:
        player.enter_shelter()
        emit_signal("entered_shelter")
        Events.emit_signal("notification", "You are now sheltered from the weather.", "info")

func _input(event):
    if event.is_action_pressed("use_tool"):
        if can_cook:
            _show_cooking_ui()

func _on_bed_interact():
    # Show sleep confirmation dialog
    Events.emit_signal("dialog_open", "Would you like to sleep until morning?", "Bed", ["Yes", "No"])
    var dialog_handler = funcref(self, "_handle_sleep_dialog")
    Events.connect("dialog_closed", dialog_handler, "handle_dialog_response")

func _on_storage_interact():
    # Open storage chest UI
    Events.emit_signal("storage_opened")

func _on_door_interact():
    # Check weather conditions
    var current_effects = WeatherManager.get_current_effects()
    var current_disaster = WeatherManager.current_disaster
    
    if current_disaster:
        # Warn player about leaving during disaster
        Events.emit_signal("dialog_open", 
            "Warning: There is a " + current_disaster + " outside. Are you sure you want to leave?",
            "Warning",
            ["Yes", "No"])
        var dialog_handler = funcref(self, "_handle_exit_dialog")
        Events.connect("dialog_closed", dialog_handler, "handle_dialog_response")
    else:
        _exit_home()

func _handle_exit_dialog(response):
    if response == 0:  # "Yes" selected
        _exit_home()

func _exit_home():
    if player:
        player.exit_shelter()
        emit_signal("exited_shelter")
    get_tree().change_scene("res://scenes/Main.tscn")

func _on_cooking_station_body_entered(body):
    if body.name == "Player":
        can_cook = true
        cooking_station.get_node("HintLabel").show()

func _on_cooking_station_body_exited(body):
    if body.name == "Player":
        can_cook = false
        cooking_station.get_node("HintLabel").hide()
        _hide_cooking_ui()

func _show_cooking_ui():
    cooking_ui.show()
    Events.emit_signal("notification", "Let's cook something!", "info")
    get_tree().paused = true

func _hide_cooking_ui():
    cooking_ui.hide()
    get_tree().paused = false

func _handle_sleep_dialog(response):
    if response == 0:  # "Yes" selected
        # Check for active disasters
        if WeatherManager.current_disaster:
            Events.emit_signal("notification", "You sleep through the " + WeatherManager.current_disaster, "info")
        
        # Restore energy
        GameData.update_energy(GameConstants.ENERGY_RESTORE_SLEEP)
        
        # Advance time to next morning (6:00)
        while TimeManager.current_hour < 6:
            TimeManager.advance_time(60)  # Advance by 1 hour
        
        # If it's past 6:00, advance to next day at 6:00
        if TimeManager.current_hour >= 6:
            TimeManager.advance_time((24 - TimeManager.current_hour + 6) * 60)
        
        # Show morning notification
        Events.emit_signal("notification", "You feel well rested!", "info")
        
        # Check weather for new day
        WeatherManager._update_weather()
    
    # Disconnect dialog handler
    Events.disconnect("dialog_closed", self, "_handle_sleep_dialog")