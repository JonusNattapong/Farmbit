extends Node

signal building_placed(building_type, position)
signal building_removed(position)
signal furniture_placed(furniture_type, position)
signal furniture_removed(position)
signal decoration_placed(decoration_type, position)
signal comfort_level_changed(new_level)

# Building types and costs
const BUILDINGS = {
    "small_house": {
        "name": "Small House",
        "size": Vector2(3, 2),
        "cost": {
            "wood": 30,
            "stone": 20
        },
        "comfort_bonus": 5,
        "unlocked": true
    },
    "medium_house": {
        "name": "Medium House",
        "size": Vector2(4, 3),
        "cost": {
            "wood": 50,
            "stone": 40,
            "iron": 10
        },
        "comfort_bonus": 10,
        "requirements": {
            "small_house": true,
            "player_level": 5
        }
    },
    "large_house": {
        "name": "Large House",
        "size": Vector2(5, 4),
        "cost": {
            "wood": 100,
            "stone": 80,
            "iron": 30,
            "gold": 5
        },
        "comfort_bonus": 20,
        "requirements": {
            "medium_house": true,
            "player_level": 10
        }
    },
    "greenhouse": {
        "name": "Greenhouse",
        "size": Vector2(4, 3),
        "cost": {
            "wood": 40,
            "stone": 20,
            "glass": 30
        },
        "effects": {
            "crop_growth": 1.5,
            "season_immunity": true
        }
    },
    "barn": {
        "name": "Barn",
        "size": Vector2(4, 3),
        "cost": {
            "wood": 50,
            "stone": 30
        },
        "capacity": {
            "animals": 5,
            "storage": 100
        }
    }
}

# Furniture types and effects
const FURNITURE = {
    "bed": {
        "name": "Basic Bed",
        "cost": {"wood": 10},
        "comfort": 5,
        "energy_restore": 1.1
    },
    "luxury_bed": {
        "name": "Luxury Bed",
        "cost": {
            "wood": 20,
            "cloth": 10,
            "gold": 1
        },
        "comfort": 15,
        "energy_restore": 1.3
    },
    "bookshelf": {
        "name": "Bookshelf",
        "cost": {"wood": 15},
        "comfort": 3,
        "skill_exp_bonus": 0.1
    },
    "table": {
        "name": "Dining Table",
        "cost": {"wood": 12},
        "comfort": 2,
        "food_effect_bonus": 0.1
    },
    "kitchen": {
        "name": "Kitchen Counter",
        "cost": {
            "wood": 15,
            "stone": 10
        },
        "cooking_speed": 1.2,
        "food_quality": 1.1
    }
}

# Decoration types
const DECORATIONS = {
    "plant": {
        "name": "House Plant",
        "cost": {"wood": 5},
        "comfort": 2
    },
    "painting": {
        "name": "Painting",
        "cost": {
            "wood": 5,
            "cloth": 2
        },
        "comfort": 3
    },
    "carpet": {
        "name": "Carpet",
        "cost": {"cloth": 5},
        "comfort": 2
    }
}

var placed_buildings = {}
var placed_furniture = {}
var placed_decorations = {}
var current_comfort_level = 0

func can_place_building(building_type, position):
    if not building_type in BUILDINGS:
        return false
        
    var building = BUILDINGS[building_type]
    
    # Check requirements
    if "requirements" in building:
        for req in building["requirements"]:
            if req == "player_level":
                if GameData.player_level < building["requirements"][req]:
                    return false
            elif not has_building(req):
                return false
    
    # Check resources
    for resource in building["cost"]:
        if not GameData.has_item(resource, building["cost"][resource]):
            return false
    
    # Check space
    var size = building["size"]
    for x in range(size.x):
        for y in range(size.y):
            var check_pos = position + Vector2(x, y)
            if check_pos in placed_buildings:
                return false
    
    return true

func place_building(building_type, position):
    if not can_place_building(building_type, position):
        return false
    
    var building = BUILDINGS[building_type]
    
    # Deduct resources
    for resource in building["cost"]:
        GameData.remove_item_from_inventory(resource, building["cost"][resource])
    
    # Place building
    placed_buildings[position] = {
        "type": building_type,
        "size": building["size"],
        "furniture": {},
        "decorations": {}
    }
    
    # Add comfort bonus
    if "comfort_bonus" in building:
        update_comfort_level(building["comfort_bonus"])
    
    emit_signal("building_placed", building_type, position)
    return true

func place_furniture(furniture_type, position, building_position):
    if not furniture_type in FURNITURE:
        return false
        
    var furniture = FURNITURE[furniture_type]
    
    # Check if position is in a building
    if not building_position in placed_buildings:
        return false
    
    # Check if spot is available
    if position in placed_buildings[building_position]["furniture"]:
        return false
    
    # Check resources
    for resource in furniture["cost"]:
        if not GameData.has_item(resource, furniture["cost"][resource]):
            return false
    
    # Deduct resources
    for resource in furniture["cost"]:
        GameData.remove_item_from_inventory(resource, furniture["cost"][resource])
    
    # Place furniture
    placed_buildings[building_position]["furniture"][position] = furniture_type
    
    # Add comfort bonus
    update_comfort_level(furniture["comfort"])
    
    emit_signal("furniture_placed", furniture_type, position)
    return true

func update_comfort_level(delta):
    current_comfort_level += delta
    emit_signal("comfort_level_changed", current_comfort_level)
    
    # Apply comfort bonuses
    var bonuses = calculate_comfort_bonuses()
    GameData.apply_comfort_bonuses(bonuses)

func calculate_comfort_bonuses():
    var bonuses = {
        "energy_restore": 1.0,
        "skill_exp": 1.0,
        "food_effects": 1.0
    }
    
    # Calculate based on comfort level
    bonuses["energy_restore"] += current_comfort_level * 0.01  # +1% per comfort level
    bonuses["skill_exp"] += current_comfort_level * 0.005     # +0.5% per comfort level
    bonuses["food_effects"] += current_comfort_level * 0.008  # +0.8% per comfort level
    
    return bonuses

func has_building(building_type):
    for pos in placed_buildings:
        if placed_buildings[pos]["type"] == building_type:
            return true
    return false