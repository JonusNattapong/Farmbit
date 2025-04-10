extends Control

onready var pet_list = $Background/PetList
onready var pet_info_panel = $Background/PetInfoPanel
onready var pet_name_label = $Background/PetInfoPanel/PetName
onready var pet_level_label = $Background/PetInfoPanel/Level
onready var pet_exp_bar = $Background/PetInfoPanel/ExpBar
onready var pet_mood_bar = $Background/PetInfoPanel/MoodBar
onready var pet_stats_label = $Background/PetInfoPanel/Stats
onready var pet_skills_list = $Background/PetInfoPanel/SkillsList
onready var set_active_button = $Background/PetInfoPanel/SetActiveButton
onready var command_button = $Background/PetInfoPanel/CommandButton

var selected_pet = null

func _ready():
    # Connect signals
    PetSystem.connect("pet_obtained", self, "_on_pet_obtained")
    PetSystem.connect("pet_leveled_up", self, "_on_pet_leveled_up")
    PetSystem.connect("pet_mood_changed", self, "_on_pet_mood_changed")
    PetSystem.connect("pet_stats_updated", self, "_on_pet_stats_updated")
    
    set_active_button.connect("pressed", self, "_on_set_active_pressed")
    command_button.connect("pressed", self, "_on_command_pressed")
    
    # Initialize UI
    _update_pet_list()
    pet_info_panel.hide()

func _update_pet_list():
    pet_list.clear()
    
    for pet_id in PetSystem.active_pets:
        var pet = PetSystem.active_pets[pet_id]
        pet_list.add_item(pet["name"])
        pet_list.set_item_metadata(pet_list.get_item_count() - 1, pet_id)
        
        # Highlight active pet
        if pet_id == PetSystem.current_pet:
            pet_list.set_item_custom_bg_color(pet_list.get_item_count() - 1, Color.lightgray)

func _on_pet_list_item_selected(index):
    selected_pet = pet_list.get_item_metadata(index)
    _update_pet_info()

func _update_pet_info():
    if not selected_pet:
        pet_info_panel.hide()
        return
        
    pet_info_panel.show()
    var pet = PetSystem.get_pet_info(selected_pet)
    
    pet_name_label.text = pet["name"]
    pet_level_label.text = "Level " + str(pet["level"])
    pet_exp_bar.max_value = pet["exp_needed"]
    pet_exp_bar.value = pet["exp"]
    pet_exp_bar.hint_tooltip = str(pet["exp"]) + "/" + str(pet["exp_needed"])
    pet_mood_bar.value = pet["mood"]
    pet_mood_bar.hint_tooltip = "Mood: " + str(pet["mood"]) + "%"
    
    # Update stats
    var stats_text = "Stats:\n"
    for stat in pet["current_stats"]:
        stats_text += "- " + stat.capitalize() + ": " + str(pet["current_stats"][stat]) + "\n"
    pet_stats_label.text = stats_text
    
    # Update skills
    pet_skills_list.clear()
    for skill_id in pet["unlocked_skills"]:
        var skill_name = PetSystem.PETS[selected_pet]["skills"][skill_id]["name"]
        pet_skills_list.add_item(skill_name)
    
    # Update buttons
    set_active_button.disabled = (selected_pet == PetSystem.current_pet)

func _on_set_active_pressed():
    if selected_pet:
        PetSystem.set_active_pet(selected_pet)
        _update_pet_list()
        _update_pet_info()

func _on_command_pressed():
    if selected_pet:
        # Open command menu (to be implemented)
        Events.emit_signal("pet_command_menu_opened", selected_pet)

func _on_pet_obtained(pet_id):
    _update_pet_list()

func _on_pet_leveled_up(pet_id, new_level):
    if pet_id == selected_pet:
        _update_pet_info()

func _on_pet_mood_changed(pet_id, new_mood):
    if pet_id == selected_pet:
        _update_pet_info()

func _on_pet_stats_updated(pet_id, stats):
    if pet_id == selected_pet:
        _update_pet_info()

func _on_close_button_pressed():
    hide()