extends KinematicBody2D

# Constants
enum AnimalType {CHICKEN, COW, SHEEP, PIG}

# Basic animal properties
export(AnimalType) var type = AnimalType.CHICKEN
var happiness = 50.0  # 0-100 scale
var fed_today = false
var petted_today = false
var has_product_ready = false
var days_to_produce = 1  # Default for chickens
var days_since_harvest = 0

# Movement properties
var move_speed = 30
var move_direction = Vector2.ZERO
var idle_timer = 0.0
var idle_time = 3.0  # Time to stay idle
var move_timer = 0.0
var move_time = 2.0  # Time to keep moving
var is_moving = false

# References
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var product_icon = $ProductIcon

# Product data by animal type
var product_data = {
    AnimalType.CHICKEN: {
        "item_id": "egg",
        "days_to_produce": 1,
        "product_icon": "res://assets/images/items/egg.png"
    },
    AnimalType.COW: {
        "item_id": "milk",
        "days_to_produce": 2,
        "product_icon": "res://assets/images/items/milk.png"
    },
    AnimalType.SHEEP: {
        "item_id": "wool",
        "days_to_produce": 3,
        "product_icon": "res://assets/images/items/wool.png"
    },
    AnimalType.PIG: {
        "item_id": "truffle", 
        "days_to_produce": 3,
        "product_icon": "res://assets/images/items/truffle.png"
    }
}

func _ready():
    # Set animal-specific properties
    _set_animal_properties()
    
    # Subscribe to day changed event
    Events.connect("day_changed", self, "_on_day_changed")
    
    # Start idle
    _start_idle()
    
    # Hide product icon initially
    product_icon.visible = false

func _set_animal_properties():
    # Set sprite based on animal type
    match type:
        AnimalType.CHICKEN:
            sprite.texture = load("res://assets/images/animals/chicken.png")
            move_speed = 25
        AnimalType.COW:
            sprite.texture = load("res://assets/images/animals/cow.png")
            move_speed = 15
        AnimalType.SHEEP:
            sprite.texture = load("res://assets/images/animals/sheep.png")
            move_speed = 20
        AnimalType.PIG:
            sprite.texture = load("res://assets/images/animals/pig.png")
            move_speed = 18
    
    # Set production time
    days_to_produce = product_data[type]["days_to_produce"]
    
    # Set product icon
    if "product_icon" in product_data[type]:
        var icon_texture = load(product_data[type]["product_icon"])
        if icon_texture:
            product_icon.texture = icon_texture

func _physics_process(delta):
    # Handle movement
    if is_moving:
        move_timer -= delta
        var collision = move_and_collide(move_direction * move_speed * delta)
        
        # If collided or timer expired, start idle
        if collision or move_timer <= 0:
            _start_idle()
    else:
        idle_timer -= delta
        if idle_timer <= 0:
            _start_moving()

func _start_idle():
    is_moving = false
    idle_timer = idle_time + randf() * 2.0  # Random idle time
    move_direction = Vector2.ZERO
    _update_animation()

func _start_moving():
    is_moving = true
    move_timer = move_time + randf() * 1.0  # Random move time
    
    # Pick a random direction
    var angle = randf() * 2.0 * PI
    move_direction = Vector2(cos(angle), sin(angle)).normalized()
    
    _update_animation()

func _update_animation():
    # If we had animations, we would play them here based on direction and movement state
    if is_moving:
        # Flip sprite based on direction
        if move_direction.x < 0:
            sprite.flip_h = true
        elif move_direction.x > 0:
            sprite.flip_h = false
    
    # Show product icon if product is ready
    product_icon.visible = has_product_ready

func _on_day_changed(_day):
    # Reset daily flags
    fed_today = false
    petted_today = false
    
    # Process production
    if happiness > 20:  # Only produce if somewhat happy
        days_since_harvest += 1
        
        # Check if it's time to produce
        if days_since_harvest >= days_to_produce:
            has_product_ready = true
            product_icon.visible = true
    
    # Decrease happiness if not fed or petted
    if !fed_today:
        happiness -= 10
    if !petted_today:
        happiness -= 5
    
    # Clamp happiness
    happiness = clamp(happiness, 0, 100)

func feed(feed_item = null):
    # Check if correct feed type
    var correct_feed = false
    
    # In a complete implementation, check feed_item matches animal type
    if feed_item == null:
        # For now, assume it's correct feed
        correct_feed = true
    else:
        # Check if feed type matches animal
        match type:
            AnimalType.CHICKEN:
                correct_feed = feed_item == "chicken_feed"
            AnimalType.COW:
                correct_feed = feed_item == "cow_feed"
            AnimalType.SHEEP:
                correct_feed = feed_item == "sheep_feed"
            AnimalType.PIG:
                correct_feed = feed_item == "pig_feed"
    
    if correct_feed and !fed_today:
        fed_today = true
        happiness += 15
        happiness = clamp(happiness, 0, 100)
        Events.emit_signal("animal_fed", self)
        return true
    
    return false

func pet():
    if !petted_today:
        petted_today = true
        happiness += 10
        happiness = clamp(happiness, 0, 100)
        Events.emit_signal("animal_petted", self)
        return true
    
    return false

func collect_product():
    if has_product_ready:
        # Get product data
        var item_id = product_data[type]["item_id"]
        
        # Quality based on happiness
        var quality = 1  # Default quality
        if happiness > 80:
            quality = 3  # Gold quality
        elif happiness > 50:
            quality = 2  # Silver quality
        
        # Reset product state
        has_product_ready = false
        days_since_harvest = 0
        product_icon.visible = false
        
        # Build result
        var result = {
            "item_id": item_id,
            "quantity": 1,
            "quality": quality
        }
        
        # Special case: chickens can produce multiple eggs
        if type == AnimalType.CHICKEN and happiness > 70:
            # Chance for 2 eggs
            if randf() > 0.7:
                result["quantity"] = 2
        
        # Emit signal
        Events.emit_signal("animal_product_collected", self, result)
        
        return result
    
    return null

func get_animal_type_string():
    match type:
        AnimalType.CHICKEN: return "Chicken"
        AnimalType.COW: return "Cow"
        AnimalType.SHEEP: return "Sheep"
        AnimalType.PIG: return "Pig"
    return "Unknown"