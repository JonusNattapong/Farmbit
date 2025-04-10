extends Node

signal pet_obtained(pet_id)
signal pet_leveled_up(pet_id, new_level)
signal pet_skill_unlocked(pet_id, skill_id)
signal pet_mood_changed(pet_id, new_mood)
signal pet_stats_updated(pet_id, stats)

# Pet types and their base stats
const PETS = {
    "farm_dog": {
        "name": "Farm Dog",
        "description": "A loyal companion that helps with farming and fighting",
        "base_stats": {
            "health": 100,
            "attack": 15,
            "defense": 10,
            "speed": 120,
            "stamina": 100
        },
        "skills": {
            "fetch": {
                "name": "Fetch Items",
                "level_required": 1,
                "description": "Automatically collects dropped items"
            },
            "guard": {
                "name": "Guard Area",
                "level_required": 3,
                "description": "Protects an area from zombies"
            },
            "herd": {
                "name": "Herd Animals",
                "level_required": 5,
                "description": "Helps manage farm animals"
            }
        }
    },
    "battle_cat": {
        "name": "Battle Cat",
        "description": "A fierce feline that excels in combat",
        "base_stats": {
            "health": 80,
            "attack": 25,
            "defense": 8,
            "speed": 150,
            "stamina": 90
        },
        "skills": {
            "swift_strike": {
                "name": "Swift Strike",
                "level_required": 1,
                "description": "Quick attack that can hit multiple enemies"
            },
            "night_vision": {
                "name": "Night Vision",
                "level_required": 3,
                "description": "Helps spot enemies in the dark"
            },
            "assassinate": {
                "name": "Assassinate",
                "level_required": 5,
                "description": "Powerful sneak attack"
            }
        }
    },
    "helper_bird": {
        "name": "Helper Bird",
        "description": "A smart bird that assists with various tasks",
        "base_stats": {
            "health": 50,
            "attack": 5,
            "defense": 5,
            "speed": 200,
            "stamina": 80
        },
        "skills": {
            "scout": {
                "name": "Scout Area",
                "level_required": 1,
                "description": "Reveals nearby resources and dangers"
            },
            "harvest_help": {
                "name": "Harvest Helper",
                "level_required": 3,
                "description": "Helps harvest crops faster"
            },
            "message": {
                "name": "Message Delivery",
                "level_required": 5,
                "description": "Can deliver items to NPCs"
            }
        }
    }
}

# Active pets
var active_pets = {}

# Current following pet
var current_pet = null

func _ready():
    # Connect to relevant signals
    Events.connect("combat_ended", self, "_on_combat_ended")
    Events.connect("item_collected", self, "_on_item_collected")
    Events.connect("day_started", self, "_on_day_started")

func obtain_pet(pet_id):
    if pet_id in PETS and not pet_id in active_pets:
        var pet_data = PETS[pet_id].duplicate(true)
        pet_data["level"] = 1
        pet_data["exp"] = 0
        pet_data["exp_needed"] = 100
        pet_data["mood"] = 100
        pet_data["current_stats"] = pet_data["base_stats"].duplicate()
        pet_data["unlocked_skills"] = ["fetch" if pet_id == "farm_dog" else "swift_strike" if pet_id == "battle_cat" else "scout"]
        
        active_pets[pet_id] = pet_data
        emit_signal("pet_obtained", pet_id)
        
        return true
    return false

func set_active_pet(pet_id):
    if pet_id in active_pets:
        current_pet = pet_id
        return true
    return false

func gain_exp(pet_id, amount):
    if not pet_id in active_pets:
        return
        
    var pet = active_pets[pet_id]
    pet["exp"] += amount
    
    # Check for level up
    while pet["exp"] >= pet["exp_needed"]:
        _level_up(pet_id)

func _level_up(pet_id):
    var pet = active_pets[pet_id]
    pet["level"] += 1
    pet["exp"] -= pet["exp_needed"]
    pet["exp_needed"] = int(pet["exp_needed"] * 1.5)
    
    # Improve stats
    for stat in pet["current_stats"]:
        pet["current_stats"][stat] = int(pet["base_stats"][stat] * (1 + pet["level"] * 0.1))
    
    # Check for new skills
    for skill_id in PETS[pet_id]["skills"]:
        if PETS[pet_id]["skills"][skill_id]["level_required"] == pet["level"]:
            pet["unlocked_skills"].append(skill_id)
            emit_signal("pet_skill_unlocked", pet_id, skill_id)
    
    emit_signal("pet_leveled_up", pet_id, pet["level"])
    emit_signal("pet_stats_updated", pet_id, pet["current_stats"])

func update_mood(pet_id, amount):
    if not pet_id in active_pets:
        return
        
    var pet = active_pets[pet_id]
    pet["mood"] = clamp(pet["mood"] + amount, 0, 100)
    emit_signal("pet_mood_changed", pet_id, pet["mood"])
    
    # Apply mood effects to stats
    var mood_multiplier = 0.5 + (pet["mood"] / 100.0)
    for stat in pet["current_stats"]:
        var base = pet["base_stats"][stat] * (1 + pet["level"] * 0.1)
        pet["current_stats"][stat] = int(base * mood_multiplier)
    
    emit_signal("pet_stats_updated", pet_id, pet["current_stats"])

func use_pet_skill(pet_id, skill_id):
    if not pet_id in active_pets:
        return false
        
    var pet = active_pets[pet_id]
    if not skill_id in pet["unlocked_skills"]:
        return false
        
    # Apply skill effects based on type
    match skill_id:
        "fetch", "scout":
            # These are passive skills
            pass
        "guard":
            # Start guarding current area
            Events.emit_signal("pet_guarding_area", pet_id)
        "herd":
            # Help with animal management
            Events.emit_signal("pet_herding_started", pet_id)
        "swift_strike", "assassinate":
            # Combat skills
            var damage = pet["current_stats"]["attack"] * (2 if skill_id == "assassinate" else 1)
            Events.emit_signal("pet_attack", pet_id, damage)
        "harvest_help":
            # Speed up current harvest
            Events.emit_signal("pet_harvest_boost", pet_id)
        "message":
            # Start message delivery UI
            Events.emit_signal("pet_message_delivery", pet_id)
    
    return true

func get_pet_info(pet_id):
    if pet_id in active_pets:
        return active_pets[pet_id]
    return null

func _on_combat_ended(victory):
    # Give combat exp to pets that participated
    if victory and current_pet:
        gain_exp(current_pet, 20)
        update_mood(current_pet, 5)

func _on_item_collected(item_id):
    # Give exp for fetch ability
    if current_pet and "fetch" in active_pets[current_pet]["unlocked_skills"]:
        gain_exp(current_pet, 1)

func _on_day_started():
    # Reset pet moods and give daily bonus
    for pet_id in active_pets:
        update_mood(pet_id, 10)  # Daily mood boost