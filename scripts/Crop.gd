extends Node2D

# Crop properties
var crop_type = ""  # carrot, potato, etc.
var growth_stage = 0  # 0-3 (seed, sprout, grown, harvest)
var growth_days = 0  # Days spent growing
var is_watered = false  # Has been watered today
var is_harvestable = false  # Ready to harvest
var quality = 1  # 1-3 (normal, silver, gold)

# Sprite references
onready var crop_sprite = $CropSprite

# Growth stage sprites (will be overridden based on crop type)
var stage_sprites = []

func _ready():
    # Connect to day changed signal
    Events.connect("day_changed", self, "_on_day_changed")

func initialize(type):
    crop_type = type
    
    # Check if crop exists in GameData
    if not crop_type in GameData.items or not "produces" in GameData.items[crop_type + "_seed"]:
        print("Error: Invalid crop type - " + crop_type)
        return false
    
    # Load textures for growth stages
    _load_growth_sprites()
    
    # Set initial sprite
    _update_sprite()
    
    return true

func _load_growth_sprites():
    # Clear any existing sprites
    stage_sprites.clear()
    
    # Load stage sprites for this crop
    for i in range(4):  # 4 growth stages
        var texture_path = "res://assets/images/crops/" + crop_type + "_" + str(i) + ".png"
        var tex = load(texture_path)
        if tex:
            stage_sprites.append(tex)
        else:
            # Fallback to default crop sprites if specific ones don't exist
            var default_path = "res://assets/images/crops/default_" + str(i) + ".png"
            stage_sprites.append(load(default_path))

func _update_sprite():
    # Update sprite based on current growth stage
    if growth_stage >= 0 and growth_stage < stage_sprites.size():
        crop_sprite.texture = stage_sprites[growth_stage]

func water():
    # Water the crop
    if not is_watered:
        is_watered = true
        
        # Visual indicator for watered state (optional animation or effect)
        var watered_indicator = $WateredIndicator
        if watered_indicator:
            watered_indicator.visible = true

func _on_day_changed(_day):
    # Process daily growth if watered
    if is_watered:
        _grow()
    
    # Reset watered state
    is_watered = false
    var watered_indicator = $WateredIndicator
    if watered_indicator:
        watered_indicator.visible = false

func _grow():
    # Increment growth days
    growth_days += 1
    
    # Check if it's time to advance growth stage
    var seed_data = GameData.items[crop_type + "_seed"]
    var growth_time = seed_data["growth_time"]
    
    # Calculate growth stage based on percentage of growth time
    var growth_percent = float(growth_days) / growth_time
    
    if growth_percent >= 1.0:
        # Fully grown
        growth_stage = 3
        is_harvestable = true
    elif growth_percent >= 0.66:
        # Mature plant
        growth_stage = 2
    elif growth_percent >= 0.33:
        # Young plant
        growth_stage = 1
    else:
        # Seedling
        growth_stage = 0
    
    # Update sprite
    _update_sprite()

func harvest():
    if not is_harvestable:
        return null
    
    var seed_data = GameData.items[crop_type + "_seed"]
    var crop_id = seed_data["produces"]
    
    # Determine harvest quantity (could be random in a range)
    var quantity = 1
    
    # Create harvest result
    var result = {
        "item_id": crop_id,
        "quantity": quantity,
        "quality": quality
    }
    
    # For regrowable crops, reset growth stage but don't destroy
    if "regrows" in seed_data and seed_data["regrows"]:
        growth_stage = 1  # Reset to young plant stage
        growth_days = int(seed_data["growth_time"] * 0.33)  # Reset growth days
        is_harvestable = false
        _update_sprite()
    else:
        # For non-regrowable crops, destroy after harvest
        queue_free()
    
    return result

func set_quality(new_quality):
    if new_quality >= 1 and new_quality <= 3:
        quality = new_quality