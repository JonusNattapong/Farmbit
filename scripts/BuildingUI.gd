extends Control

onready var building_list = $Background/BuildingList
onready var furniture_list = $Background/FurnitureList
onready var decoration_list = $Background/DecorationList
onready var info_panel = $Background/InfoPanel
onready var preview = $Background/Preview
onready var place_button = $Background/InfoPanel/PlaceButton
onready var requirements_label = $Background/InfoPanel/Requirements
onready var cost_label = $Background/InfoPanel/Cost
onready var effects_label = $Background/InfoPanel/Effects
onready var comfort_label = $Background/ComfortLevel

var selected_type = null
var selected_category = null  # "building", "furniture", "decoration"
var can_place = false

func _ready():
    # Connect signals
    BuildingSystem.connect("building_placed", self, "_on_building_placed")
    BuildingSystem.connect("furniture_placed", self, "_on_furniture_placed")
    BuildingSystem.connect("comfort_level_changed", self, "_update_comfort_level")
    
    place_button.connect("pressed", self, "_on_place_button_pressed")
    
    # Populate lists
    _populate_building_list()
    _populate_furniture_list()
    _populate_decoration_list()
    
    # Initial updates
    _update_comfort_level(BuildingSystem.current_comfort_level)

func _populate_building_list():
    building_list.clear()
    
    for building_id in BuildingSystem.BUILDINGS:
        var building = BuildingSystem.BUILDINGS[building_id]
        if "unlocked" in building and building["unlocked"]:
            building_list.add_item(building["name"])
            building_list.set_item_metadata(building_list.get_item_count() - 1, building_id)

func _populate_furniture_list():
    furniture_list.clear()
    
    for furniture_id in BuildingSystem.FURNITURE:
        var furniture = BuildingSystem.FURNITURE[furniture_id]
        furniture_list.add_item(furniture["name"])
        furniture_list.set_item_metadata(furniture_list.get_item_count() - 1, furniture_id)

func _populate_decoration_list():
    decoration_list.clear()
    
    for decoration_id in BuildingSystem.DECORATIONS:
        var decoration = BuildingSystem.DECORATIONS[decoration_id]
        decoration_list.add_item(decoration["name"])
        decoration_list.set_item_metadata(decoration_list.get_item_count() - 1, decoration_id)

func _on_building_selected(index):
    selected_category = "building"
    selected_type = building_list.get_item_metadata(index)
    _update_info_panel()

func _on_furniture_selected(index):
    selected_category = "furniture"
    selected_type = furniture_list.get_item_metadata(index)
    _update_info_panel()

func _on_decoration_selected(index):
    selected_category = "decoration"
    selected_type = decoration_list.get_item_metadata(index)
    _update_info_panel()

func _update_info_panel():
    if not selected_type:
        info_panel.hide()
        return
        
    info_panel.show()
    
    match selected_category:
        "building":
            _show_building_info(BuildingSystem.BUILDINGS[selected_type])
        "furniture":
            _show_furniture_info(BuildingSystem.FURNITURE[selected_type])
        "decoration":
            _show_decoration_info(BuildingSystem.DECORATIONS[selected_type])

func _show_building_info(building):
    # Show requirements
    var req_text = "Requirements:\n"
    if "requirements" in building:
        for req in building["requirements"]:
            if req == "player_level":
                req_text += "- Player Level " + str(building["requirements"][req]) + "\n"
            else:
                req_text += "- " + BuildingSystem.BUILDINGS[req]["name"] + "\n"
    else:
        req_text += "None\n"
    requirements_label.text = req_text
    
    # Show costs
    var cost_text = "Cost:\n"
    for resource in building["cost"]:
        var amount = building["cost"][resource]
        var owned = GameData.get_item_count(resource)
        cost_text += "- %s: %d/%d\n" % [resource.capitalize(), owned, amount]
    cost_label.text = cost_text
    
    # Show effects
    var effects_text = "Effects:\n"
    if "comfort_bonus" in building:
        effects_text += "- Comfort: +" + str(building["comfort_bonus"]) + "\n"
    if "effects" in building:
        for effect in building["effects"]:
            effects_text += "- " + effect.capitalize() + ": +" + str(building["effects"][effect]) + "\n"
    effects_label.text = effects_text
    
    # Update preview
    preview.texture = load("res://assets/buildings/" + selected_type + ".png")
    
    # Update place button
    place_button.disabled = not BuildingSystem.can_place_building(selected_type, Vector2.ZERO)

func _show_furniture_info(furniture):
    # Show costs
    var cost_text = "Cost:\n"
    for resource in furniture["cost"]:
        var amount = furniture["cost"][resource]
        var owned = GameData.get_item_count(resource)
        cost_text += "- %s: %d/%d\n" % [resource.capitalize(), owned, amount]
    cost_label.text = cost_text
    
    # Show effects
    var effects_text = "Effects:\n"
    if "comfort" in furniture:
        effects_text += "- Comfort: +" + str(furniture["comfort"]) + "\n"
    for effect in furniture:
        if effect not in ["name", "cost", "comfort"]:
            effects_text += "- " + effect.capitalize() + ": +" + str(furniture[effect]) + "\n"
    effects_label.text = effects_text
    
    # Update preview
    preview.texture = load("res://assets/furniture/" + selected_type + ".png")
    
    # Update place button
    place_button.disabled = not GameData.has_resources_for_cost(furniture["cost"])

func _show_decoration_info(decoration):
    # Show costs
    var cost_text = "Cost:\n"
    for resource in decoration["cost"]:
        var amount = decoration["cost"][resource]
        var owned = GameData.get_item_count(resource)
        cost_text += "- %s: %d/%d\n" % [resource.capitalize(), owned, amount]
    cost_label.text = cost_text
    
    # Show effects
    var effects_text = "Effects:\n"
    if "comfort" in decoration:
        effects_text += "- Comfort: +" + str(decoration["comfort"]) + "\n"
    effects_label.text = effects_text
    
    # Update preview
    preview.texture = load("res://assets/decorations/" + selected_type + ".png")
    
    # Update place button
    place_button.disabled = not GameData.has_resources_for_cost(decoration["cost"])

func _update_comfort_level(new_level):
    comfort_label.text = "Comfort Level: " + str(new_level)
    
    # Show bonuses
    var bonuses = BuildingSystem.calculate_comfort_bonuses()
    var bonus_text = "\nBonuses:"
    for bonus_type in bonuses:
        bonus_text += "\n" + bonus_type.capitalize() + ": +" + str((bonuses[bonus_type] - 1) * 100) + "%"
    comfort_label.text += bonus_text

func _on_place_button_pressed():
    # Handle placement based on category
    match selected_category:
        "building":
            Events.emit_signal("building_placement_started", selected_type)
        "furniture":
            Events.emit_signal("furniture_placement_started", selected_type)
        "decoration":
            Events.emit_signal("decoration_placement_started", selected_type)
    
    # Hide UI while placing
    hide()

func _on_close_button_pressed():
    hide()
    Events.emit_signal("building_mode_ended")