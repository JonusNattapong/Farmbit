extends Control

var cooking_system
var selected_recipe = null

onready var recipe_list = $RecipeList
onready var ingredient_list = $IngredientList
onready var recipe_info = $RecipeInfo
onready var cook_button = $CookButton
onready var animation_player = $AnimationPlayer
onready var result_label = $ResultLabel

func _ready():
    cooking_system = get_node("/root/Cooking")
    
    # Connect signals
    cooking_system.connect("cooking_started", self, "_on_cooking_started")
    cooking_system.connect("cooking_completed", self, "_on_cooking_completed")
    cooking_system.connect("cooking_failed", self, "_on_cooking_failed")
    
    cook_button.connect("pressed", self, "_on_cook_button_pressed")
    
    # Hide result label initially
    result_label.hide()
    
    # Update recipe list
    _update_recipe_list()

func _update_recipe_list():
    recipe_list.clear()
    
    var available_recipes = cooking_system.get_available_recipes()
    for recipe_id in available_recipes:
        var recipe = available_recipes[recipe_id]
        recipe_list.add_item(recipe["name"], recipe_id)
        
        # Gray out recipes that can't be cooked
        if not cooking_system.can_cook_recipe(recipe_id):
            var idx = recipe_list.get_item_count() - 1
            recipe_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))

func _on_recipe_selected(recipe_id):
    selected_recipe = recipe_id
    var recipe = cooking_system.get_recipe_info(recipe_id)
    
    if recipe:
        # Update ingredient list
        ingredient_list.clear()
        for ingredient in recipe["ingredients"]:
            var required = recipe["ingredients"][ingredient]
            var owned = GameData.get_item_count(ingredient)
            var item_name = GameData.get_item_name(ingredient)
            ingredient_list.add_item("%s (%d/%d)" % [item_name, owned, required])
        
        # Update recipe info
        var info_text = "Results in: %s\n" % recipe["name"]
        if "energy_restore" in recipe:
            info_text += "Energy: +%d\n" % recipe["energy_restore"]
        if "health_restore" in recipe:
            info_text += "Health: +%d\n" % recipe["health_restore"]
        if "bonus_effects" in recipe:
            info_text += "Effects: %s\n" % ", ".join(recipe["bonus_effects"])
        recipe_info.text = info_text
        
        # Enable cook button if recipe can be cooked
        cook_button.disabled = not cooking_system.can_cook_recipe(recipe_id)
    else:
        # Clear lists if no recipe selected
        ingredient_list.clear()
        recipe_info.text = ""
        cook_button.disabled = true

func _on_cook_button_pressed():
    if selected_recipe:
        cooking_system.start_cooking(selected_recipe)

func _on_cooking_started(recipe):
    # Play cooking animation
    if animation_player.has_animation("cooking"):
        animation_player.play("cooking")
    
    # Disable interaction during cooking
    cook_button.disabled = true
    recipe_list.disabled = true

func _on_cooking_completed(recipe):
    # Show success message
    result_label.text = "Successfully cooked %s!" % recipe["name"]
    result_label.modulate = Color(0, 1, 0)  # Green
    result_label.show()
    
    # Play completion sound if available
    # if $SuccessSound:
    #     $SuccessSound.play()
    
    # Reset UI
    _reset_after_cooking()

func _on_cooking_failed(reason):
    # Show error message
    result_label.text = "Cooking failed: %s" % reason
    result_label.modulate = Color(1, 0, 0)  # Red
    result_label.show()
    
    # Reset UI
    _reset_after_cooking()

func _reset_after_cooking():
    # Re-enable interaction
    cook_button.disabled = false
    recipe_list.disabled = false
    
    # Update recipe list with new inventory state
    _update_recipe_list()
    
    # Hide result label after delay
    yield(get_tree().create_timer(2.0), "timeout")
    result_label.hide()

func _on_close_button_pressed():
    hide()  # Hide cooking UI