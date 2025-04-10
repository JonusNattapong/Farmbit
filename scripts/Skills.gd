extends Node

signal skill_leveled_up(skill_id, new_level)
signal skill_exp_gained(skill_id, amount)
signal skill_point_gained
signal skill_unlocked(skill_id)

# Skill categories
var combat_skills = {
    "sword_mastery": {
        "name": "Sword Mastery",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "damage_bonus": 0.05,  # 5% per level
            "critical_chance": 0.01  # 1% per level
        },
        "description": "Increases sword damage and critical chance"
    },
    "defense_mastery": {
        "name": "Defense Mastery",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "defense_bonus": 0.05,  # 5% per level
            "damage_reduction": 0.01  # 1% per level
        },
        "description": "Improves defense and damage reduction"
    },
    "combat_technique": {
        "name": "Combat Technique",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "attack_speed": 0.02,  # 2% per level
            "dodge_chance": 0.01  # 1% per level
        },
        "description": "Increases attack speed and dodge chance"
    }
}

var farming_skills = {
    "crop_mastery": {
        "name": "Crop Mastery",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "growth_speed": 0.05,  # 5% per level
            "quality_chance": 0.02  # 2% per level
        },
        "description": "Improves crop growth and quality"
    },
    "water_conservation": {
        "name": "Water Conservation",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "water_duration": 0.1,  # 10% per level
            "watering_range": 0.5  # +0.5 tiles per level
        },
        "description": "Improves watering efficiency"
    },
    "harvesting": {
        "name": "Harvesting",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "double_harvest": 0.02,  # 2% per level
            "exp_bonus": 0.05  # 5% per level
        },
        "description": "Chance for extra crops and bonus exp"
    }
}

var cooking_skills = {
    "cooking_mastery": {
        "name": "Cooking Mastery",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "effect_duration": 0.1,  # 10% per level
            "effect_potency": 0.05  # 5% per level
        },
        "description": "Improves food effects duration and potency"
    },
    "recipe_innovation": {
        "name": "Recipe Innovation",
        "level": 1,
        "exp": 0,
        "next_level_exp": 100,
        "effects": {
            "new_recipe_chance": 0.05,  # 5% per level
            "quality_bonus": 0.1  # 10% per level
        },
        "description": "Chance to discover new recipes and improve quality"
    }
}

# Player skill points
var skill_points = 0

func _ready():
    print("Skills system initialized")

func gain_exp(skill_category, skill_id, amount):
    var skills = _get_skill_category(skill_category)
    if not skills or not skill_id in skills:
        return
        
    var skill = skills[skill_id]
    skill["exp"] += amount
    
    emit_signal("skill_exp_gained", skill_id, amount)
    
    # Check for level up
    while skill["exp"] >= skill["next_level_exp"]:
        _level_up(skill_category, skill_id)

func _level_up(skill_category, skill_id):
    var skills = _get_skill_category(skill_category)
    if not skills or not skill_id in skills:
        return
        
    var skill = skills[skill_id]
    skill["level"] += 1
    skill["exp"] -= skill["next_level_exp"]
    
    # Increase exp required for next level
    skill["next_level_exp"] = int(skill["next_level_exp"] * 1.5)
    
    # Grant skill point every 5 levels
    if skill["level"] % 5 == 0:
        skill_points += 1
        emit_signal("skill_point_gained")
    
    emit_signal("skill_leveled_up", skill_id, skill["level"])

func get_skill_effect(skill_category, skill_id, effect):
    var skills = _get_skill_category(skill_category)
    if not skills or not skill_id in skills:
        return 0
        
    var skill = skills[skill_id]
    if effect in skill["effects"]:
        return skill["effects"][effect] * skill["level"]
    return 0

func _get_skill_category(category):
    match category:
        "combat":
            return combat_skills
        "farming":
            return farming_skills
        "cooking":
            return cooking_skills
    return null

func get_all_effects(skill_category):
    var total_effects = {}
    var skills = _get_skill_category(skill_category)
    
    if not skills:
        return total_effects
        
    for skill_id in skills:
        var skill = skills[skill_id]
        for effect in skill["effects"]:
            var value = skill["effects"][effect] * skill["level"]
            if effect in total_effects:
                total_effects[effect] += value
            else:
                total_effects[effect] = value
    
    return total_effects