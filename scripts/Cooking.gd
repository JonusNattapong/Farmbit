extends Node

signal cooking_started(recipe)
signal cooking_completed(recipe)
signal cooking_failed(reason)

var recipes = {
    "vegetable_soup": {
        "name": "Vegetable Soup",
        "ingredients": {
            "carrot": 2,
            "potato": 1,
            "tomato": 1
        },
        "result": {
            "item_id": "vegetable_soup",
            "amount": 1
        },
        "energy_restore": 50,
        "health_restore": 30,
        "bonus_effects": ["defense_up"]
    },
    "zombie_repellent": {
        "name": "Zombie Repellent",
        "ingredients": {
            "zombie_flesh": 3,
            "rare_gem": 1
        },
        "result": {
            "item_id": "zombie_repellent",
            "amount": 1
        },
        "effects": ["repel_zombies"],
        "duration": 300  # 5 minutes
    },
    "power_stew": {
        "name": "Power Stew",
        "ingredients": {
            "carrot": 1,
            "potato": 1,
            "milk": 1
        },
        "result": {
            "item_id": "power_stew",
            "amount": 1
        },
        "energy_restore": 80,
        "health_restore": 50,
        "bonus_effects": ["attack_up", "defense_up"]
    },
    "healing_salad": {
        "name": "Healing Salad",
        "ingredients": {
            "carrot": 1,
            "tomato": 2
        },
        "result": {
            "item_id": "healing_salad",
            "amount": 1
        },
        "energy_restore": 30,
        "health_restore": 70,
        "bonus_effects": ["regen"]
    }
}

func can_cook_recipe(recipe_id):
    if not recipe_id in recipes:
        return false
        
    var recipe = recipes[recipe_id]
    
    # Check if player has all required ingredients
    for ingredient in recipe["ingredients"]:
        var required_amount = recipe["ingredients"][ingredient]
        if not GameData.has_item(ingredient, required_amount):
            return false
    
    return true

func start_cooking(recipe_id):
    if not can_cook_recipe(recipe_id):
        emit_signal("cooking_failed", "Missing ingredients")
        return false
    
    var recipe = recipes[recipe_id]
    emit_signal("cooking_started", recipe)
    
    # Remove ingredients
    for ingredient in recipe["ingredients"]:
        var amount = recipe["ingredients"][ingredient]
        GameData.remove_item_from_inventory(ingredient, amount)
    
    # Add result item
    var result = recipe["result"]
    GameData.add_item_to_inventory(result["item_id"], result["amount"])
    
    emit_signal("cooking_completed", recipe)
    return true

func get_available_recipes():
    var available = {}
    
    for recipe_id in recipes:
        if can_cook_recipe(recipe_id):
            available[recipe_id] = recipes[recipe_id]
    
    return available

func get_recipe_info(recipe_id):
    if recipe_id in recipes:
        return recipes[recipe_id]
    return null