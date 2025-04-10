extends Node2D

# Constants
const GRID_SIZE = 16  # Size of one grid tile in pixels
const FARM_WIDTH = 30  # Number of tiles horizontally 
const FARM_HEIGHT = 20  # Number of tiles vertically

# Crop and soil management
var soil_states = {}  # Dictionary keyed by Vector2 grid position
var crops = {}  # Dictionary of crop instances keyed by grid position

# Scene references
var crop_scene = preload("res://scenes/Crop.tscn")
var animal_scene = preload("res://scenes/Animal.tscn")

# Farm objects
onready var soil_container = $SoilContainer
onready var crop_container = $CropContainer
onready var animal_container = $AnimalContainer
onready var shipping_bin = $ShippingBin
onready var player_spawn = $PlayerSpawn

# Soil state enum
enum SoilState {NORMAL, TILLED, WATERED}

# Animal counter
var animal_count = 0
var max_animals = 20

func _ready():
    # Connect to relevant events
    Events.connect("till_soil", self, "_on_till_soil")
    Events.connect("water_soil", self, "_on_water_soil")
    Events.connect("plant_seed", self, "_on_plant_seed")
    
    # Initialize farm (could load from save)
    _initialize_farm()

func _initialize_farm():
    # Create initial soil state
    for x in range(FARM_WIDTH):
        for y in range(FARM_HEIGHT):
            # Set default soil state to normal
            var grid_pos = Vector2(x, y)
            soil_states[grid_pos] = SoilState.NORMAL
    
    # Give player some starting items
    _give_starting_items()
    
    # Add some starting animals
    add_animal(0)  # Add a chicken

func _give_starting_items():
    # Give player basic tools
    GameData.add_item_to_inventory("hoe", 1)
    GameData.add_item_to_inventory("watering_can", 1)
    
    # Give some seeds
    GameData.add_item_to_inventory("carrot_seed", 5)
    GameData.add_item_to_inventory("potato_seed", 5)
    
    # Give some feed
    GameData.add_item_to_inventory("chicken_feed", 5)

func grid_to_world(grid_pos):
    # Convert grid position to world coordinates
    return Vector2(grid_pos.x * GRID_SIZE, grid_pos.y * GRID_SIZE)

func world_to_grid(world_pos):
    # Convert world coordinates to grid position
    var grid_x = floor(world_pos.x / GRID_SIZE)
    var grid_y = floor(world_pos.y / GRID_SIZE)
    return Vector2(grid_x, grid_y)

func update_soil_visuals(grid_pos):
    # Here we would update the visual representation of soil
    # This would use a tilemap in a real implementation
    if grid_pos in soil_states:
        var world_pos = grid_to_world(grid_pos)
        
        # Create visual soil representation if not exists
        if not has_node("SoilVisual_" + str(grid_pos.x) + "_" + str(grid_pos.y)):
            var soil_visual = Sprite.new()
            soil_visual.name = "SoilVisual_" + str(grid_pos.x) + "_" + str(grid_pos.y)
            soil_visual.position = world_pos + Vector2(GRID_SIZE/2, GRID_SIZE/2)
            
            # Set sprite based on soil state
            match soil_states[grid_pos]:
                SoilState.NORMAL:
                    # Normal soil might not need a sprite
                    soil_visual.texture = null
                SoilState.TILLED:
                    soil_visual.texture = load("res://assets/images/farm/tilled_soil.png")
                SoilState.WATERED:
                    soil_visual.texture = load("res://assets/images/farm/watered_soil.png")
            
            soil_container.add_child(soil_visual)
        else:
            # Update existing soil visual
            var soil_visual = get_node("SoilVisual_" + str(grid_pos.x) + "_" + str(grid_pos.y))
            
            match soil_states[grid_pos]:
                SoilState.NORMAL:
                    soil_visual.texture = null
                SoilState.TILLED:
                    soil_visual.texture = load("res://assets/images/farm/tilled_soil.png")
                SoilState.WATERED:
                    soil_visual.texture = load("res://assets/images/farm/watered_soil.png")

func _on_till_soil(world_pos):
    # Convert to grid position
    var grid_pos = world_to_grid(world_pos)
    
    # Check if this is a valid position to till
    if is_valid_farm_position(grid_pos) and soil_states[grid_pos] == SoilState.NORMAL:
        # Set soil to tilled state
        soil_states[grid_pos] = SoilState.TILLED
        
        # Update visual representation
        update_soil_visuals(grid_pos)
        
        return true
    
    return false

func _on_water_soil(world_pos):
    # Convert to grid position
    var grid_pos = world_to_grid(world_pos)
    
    # Check if this is tilled soil
    if is_valid_farm_position(grid_pos) and soil_states[grid_pos] == SoilState.TILLED:
        # Set soil to watered state
        soil_states[grid_pos] = SoilState.WATERED
        
        # Update visual representation
        update_soil_visuals(grid_pos)
        
        # If there's a crop here, water it too
        if grid_pos in crops and is_instance_valid(crops[grid_pos]):
            crops[grid_pos].water()
        
        return true
    
    return false

func _on_plant_seed(world_pos, seed_id):
    # Convert to grid position
    var grid_pos = world_to_grid(world_pos)
    
    # Check if this is tilled or watered soil and no crop exists
    if is_valid_farm_position(grid_pos) and \
       (soil_states[grid_pos] == SoilState.TILLED or soil_states[grid_pos] == SoilState.WATERED) and \
       not grid_pos in crops:
        
        # Get the crop type from the seed
        var crop_type = ""
        if seed_id.ends_with("_seed"):
            crop_type = seed_id.replace("_seed", "")
        
        # Instance crop
        var crop_instance = crop_scene.instance()
        crop_container.add_child(crop_instance)
        
        # Set crop position
        crop_instance.position = grid_to_world(grid_pos) + Vector2(GRID_SIZE/2, GRID_SIZE/2)
        
        # Initialize crop
        if crop_instance.initialize(crop_type):
            # Add to crops dictionary
            crops[grid_pos] = crop_instance
            
            # If soil is watered, water the crop
            if soil_states[grid_pos] == SoilState.WATERED:
                crop_instance.water()
                
            return true
        else:
            # Failed to initialize, remove instance
            crop_instance.queue_free()
    
    return false

func harvest_crop(world_pos):
    # Convert to grid position
    var grid_pos = world_to_grid(world_pos)
    
    # Check if crop exists and is harvestable
    if grid_pos in crops and is_instance_valid(crops[grid_pos]):
        var crop = crops[grid_pos]
        var harvest_result = crop.harvest()
        
        if harvest_result != null:
            # Add harvested items to inventory
            GameData.add_item_to_inventory(
                harvest_result["item_id"],
                harvest_result["quantity"],
                harvest_result["quality"]
            )
            
            # If crop is gone (not regrowable), remove from dictionary
            if !is_instance_valid(crops[grid_pos]):
                crops.erase(grid_pos)
                
                # Reset soil state
                soil_states[grid_pos] = SoilState.TILLED
                update_soil_visuals(grid_pos)
            
            return harvest_result
    
    return null

func is_valid_farm_position(grid_pos):
    # Check if position is within farm boundaries
    return grid_pos.x >= 0 and grid_pos.x < FARM_WIDTH and \
           grid_pos.y >= 0 and grid_pos.y < FARM_HEIGHT

func add_animal(animal_type):
    # Check animal limit
    if animal_count >= max_animals:
        Events.emit_signal("notification", "You've reached the maximum number of animals!", 2)
        return null
    
    # Create new animal instance
    var new_animal = animal_scene.instance()
    animal_container.add_child(new_animal)
    
    # Set animal type
    new_animal.type = animal_type
    
    # Position randomly within a designated area
    var spawn_x = rand_range(5, 15) * GRID_SIZE
    var spawn_y = rand_range(12, 18) * GRID_SIZE
    new_animal.position = Vector2(spawn_x, spawn_y)
    
    # Increment animal count
    animal_count += 1
    
    return new_animal

func _on_day_changed(_day):
    # Daily farm update
    _reset_soil_water()

func _reset_soil_water():
    # Reset all watered soil to tilled
    for grid_pos in soil_states:
        if soil_states[grid_pos] == SoilState.WATERED:
            soil_states[grid_pos] = SoilState.TILLED
            update_soil_visuals(grid_pos)

func save_farm_state():
    # Store current farm state
    var save_data = {
        "soil_states": {},
        "crops": {},
        "animals": []
    }
    
    # Save soil states (convert Vector2 keys to strings)
    for grid_pos in soil_states:
        var key = str(grid_pos.x) + "," + str(grid_pos.y)
        save_data["soil_states"][key] = soil_states[grid_pos]
    
    # Save crops
    for grid_pos in crops:
        if is_instance_valid(crops[grid_pos]):
            var key = str(grid_pos.x) + "," + str(grid_pos.y)
            var crop = crops[grid_pos]
            save_data["crops"][key] = {
                "crop_type": crop.crop_type,
                "growth_stage": crop.growth_stage,
                "growth_days": crop.growth_days,
                "is_watered": crop.is_watered,
                "is_harvestable": crop.is_harvestable,
                "quality": crop.quality
            }
    
    # Save animals
    for animal in animal_container.get_children():
        if animal.has_method("get_animal_type_string"):
            save_data["animals"].append({
                "type": animal.type,
                "position_x": animal.position.x,
                "position_y": animal.position.y,
                "happiness": animal.happiness,
                "fed_today": animal.fed_today,
                "petted_today": animal.petted_today,
                "has_product_ready": animal.has_product_ready,
                "days_since_harvest": animal.days_since_harvest
            })
    
    return save_data

func load_farm_state(save_data):
    # Clear existing farm
    _clear_farm()
    
    # Load soil states
    for key in save_data["soil_states"]:
        var coords = key.split(",")
        var grid_pos = Vector2(int(coords[0]), int(coords[1]))
        soil_states[grid_pos] = save_data["soil_states"][key]
        update_soil_visuals(grid_pos)
    
    # Load crops
    for key in save_data["crops"]:
        var coords = key.split(",")
        var grid_pos = Vector2(int(coords[0]), int(coords[1]))
        var crop_data = save_data["crops"][key]
        
        # Create crop instance
        var crop_instance = crop_scene.instance()
        crop_container.add_child(crop_instance)
        crop_instance.position = grid_to_world(grid_pos) + Vector2(GRID_SIZE/2, GRID_SIZE/2)
        
        # Set properties
        crop_instance.initialize(crop_data["crop_type"])
        crop_instance.growth_stage = crop_data["growth_stage"]
        crop_instance.growth_days = crop_data["growth_days"]
        crop_instance.is_watered = crop_data["is_watered"]
        crop_instance.is_harvestable = crop_data["is_harvestable"]
        crop_instance.quality = crop_data["quality"]
        
        # Add to crops dictionary
        crops[grid_pos] = crop_instance
    
    # Load animals
    for animal_data in save_data["animals"]:
        var new_animal = animal_scene.instance()
        animal_container.add_child(new_animal)
        
        # Set properties
        new_animal.type = animal_data["type"]
        new_animal.position = Vector2(animal_data["position_x"], animal_data["position_y"])
        new_animal.happiness = animal_data["happiness"]
        new_animal.fed_today = animal_data["fed_today"]
        new_animal.petted_today = animal_data["petted_today"]
        new_animal.has_product_ready = animal_data["has_product_ready"]
        new_animal.days_since_harvest = animal_data["days_since_harvest"]
        
        # Increment animal count
        animal_count += 1

func _clear_farm():
    # Clear crops
    for crop in crop_container.get_children():
        crop.queue_free()
    crops.clear()
    
    # Clear animals
    for animal in animal_container.get_children():
        animal.queue_free()
    animal_count = 0
    
    # Reset soil visuals
    for child in soil_container.get_children():
        child.queue_free()