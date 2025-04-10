extends Control

# Menu UI references
onready var new_game_button = $VBoxContainer/NewGameButton
onready var load_game_button = $VBoxContainer/LoadGameButton
onready var settings_button = $VBoxContainer/SettingsButton
onready var quit_button = $VBoxContainer/QuitButton
onready var save_slots = $SaveSlots
onready var settings_panel = $SettingsPanel
onready var new_game_panel = $NewGamePanel
onready var farm_name_input = $NewGamePanel/VBoxContainer/FarmNameInput
onready var character_customization = $NewGamePanel/VBoxContainer/CharacterCustomization
onready var start_game_button = $NewGamePanel/VBoxContainer/StartGameButton
onready var back_button = $NewGamePanel/VBoxContainer/BackButton

# Menu state
var current_panel = null
var is_game_starting = false

func _ready():
	# Connect button signals
	new_game_button.connect("pressed", self, "_on_new_game_pressed")
	load_game_button.connect("pressed", self, "_on_load_game_pressed")
	settings_button.connect("pressed", self, "_on_settings_pressed")
	quit_button.connect("pressed", self, "_on_quit_pressed")
	
	# Connect new game panel buttons
	start_game_button.connect("pressed", self, "_on_start_game_pressed")
	back_button.connect("pressed", self, "_on_back_pressed")
	
	# Hide auxiliary panels
	save_slots.visible = false
	settings_panel.visible = false
	new_game_panel.visible = false
	
	# Connect save slot signals (assuming they're children of SaveSlots)
	for slot in save_slots.get_children():
		if slot.has_method("connect") and slot.has_signal("pressed"):
			slot.connect("pressed", self, "_on_save_slot_pressed", [slot.name])
	
	# Play menu music if available
	# if $MenuMusic and !$MenuMusic.playing:
	#     $MenuMusic.play()

func _on_new_game_pressed():
	# Show new game panel
	_show_panel(new_game_panel)
	
	# Initialize character customization if needed
	_init_character_customization()

func _on_load_game_pressed():
	# Show save slots for loading
	_show_panel(save_slots)
	
	# Populate save slots
	_populate_save_slots()

func _on_settings_pressed():
	# Show settings panel
	_show_panel(settings_panel)

func _on_quit_pressed():
	# Exit the game
	get_tree().quit()

func _on_back_pressed():
	# Return to main menu
	_hide_current_panel()

func _on_start_game_pressed():
	# Check for valid farm name
	var farm_name = farm_name_input.text.strip_edges()
	if farm_name.empty():
		# Show error message
		print("Please enter a farm name!")
		return
		
	# Initialize new game data
	_initialize_new_game(farm_name)
	
	# Start game
	_start_game()

func _on_save_slot_pressed(slot_name):
	# Load the selected save
	var save_index = slot_name.split("_")[-1]
	
	# Check if save exists
	if _does_save_exist(save_index):
		# Load game data
		if GameData.load_game(save_index):
			# Start game with loaded data
			_start_game()
		else:
			# Show error message
			print("Failed to load game save!")
	else:
		# Create new save in this slot
		_on_new_game_pressed()

func _show_panel(panel):
	# Hide current panel if exists
	_hide_current_panel()
	
	# Show new panel
	panel.visible = true
	current_panel = panel

func _hide_current_panel():
	if current_panel != null:
		current_panel.visible = false
		current_panel = null

func _populate_save_slots():
	# Iterate through save slots and update their display
	for i in range(3):  # Assuming 3 save slots
		var slot = save_slots.get_node("SaveSlot_" + str(i))
		if slot:
			var save_data = _get_save_data(i)
			
			# Update slot display based on data
			if save_data:
				# Show farm name and days played
				slot.get_node("FarmName").text = save_data.farm_name
				slot.get_node("DaysPlayed").text = "Day " + str(save_data.day)
				slot.get_node("MoneyLabel").text = str(save_data.money) + "g"
				slot.get_node("SaveTime").text = save_data.save_time
				
				# Show farm image if available
				if "farm_image" in save_data:
					var texture = load(save_data.farm_image)
					if texture:
						slot.get_node("FarmImage").texture = texture
						
				# Mark as used slot
				slot.get_node("NewGameLabel").visible = false
			else:
				# Reset to empty slot
				slot.get_node("FarmName").text = "Empty Slot"
				slot.get_node("DaysPlayed").text = ""
				slot.get_node("MoneyLabel").text = ""
				slot.get_node("SaveTime").text = ""
				slot.get_node("FarmImage").texture = null
				
				# Show new game label
				slot.get_node("NewGameLabel").visible = true

func _get_save_data(save_index):
	# Check if save exists and return basic save info
	var save_path = "user://save_" + str(save_index) + ".save"
	var file = File.new()
	
	if file.file_exists(save_path):
		file.open(save_path, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		
		if data:
			# Add timestamp to data
			var timestamp = OS.get_datetime()
			var datetime_str = "%d-%02d-%02d %02d:%02d" % [
				timestamp["year"], 
				timestamp["month"], 
				timestamp["day"],
				timestamp["hour"],
				timestamp["minute"]
			]
			data["save_time"] = datetime_str
			return data
			
	return null

func _does_save_exist(save_index):
	var save_path = "user://save_" + str(save_index) + ".save"
	var file = File.new()
	return file.file_exists(save_path)

func _initialize_new_game(farm_name):
	# Reset game data to defaults
	GameData.reset_game()
	
	# Set initial values
	GameData.farm_name = farm_name
	GameData.player_name = farm_name + " Farmer"  # Default, can be changed later
	GameData.day = 1
	GameData.season = "spring"
	GameData.year = 1
	GameData.player_money = 1000  # Starting money
	
	# Add initial inventory items (basic tools)
	GameData.add_item_to_inventory("basic_hoe", 1)
	GameData.add_item_to_inventory("basic_watering_can", 1)
	GameData.add_item_to_inventory("basic_axe", 1)
	GameData.add_item_to_inventory("basic_hammer", 1)
	
	# Add some initial seeds
	GameData.add_item_to_inventory("parsnip_seeds", 15)

func _init_character_customization():
	# Initialize character customization UI components
	# This would be more complex in a real implementation
	pass

func _start_game():
	# Set flag to prevent multiple starts
	if is_game_starting:
		return
	is_game_starting = true
	
	# Play transition animation if available
	# if $TransitionAnimation:
	#     $TransitionAnimation.play("fade_out")
	#     yield($TransitionAnimation, "animation_finished")
	
	# Change to farm scene
	get_tree().change_scene("res://scenes/Main.tscn")
	
	# Reset flag (in case scene change fails)
	is_game_starting = false