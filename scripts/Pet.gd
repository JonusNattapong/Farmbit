extends KinematicBody2D

# Pet properties
var pet_id = ""
var pet_data = null
var current_stats = {}
var mood = 100

# Movement
export var follow_distance = 50
export var move_speed = 100
var target = null  # Player to follow
var velocity = Vector2.ZERO
var path = []
var path_index = 0

# State
var current_action = "idle"  # idle, follow, attack, guard, fetch, etc.
var action_target = null

# References
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var mood_indicator = $MoodIndicator
onready var interaction_area = $InteractionArea

func _ready():
    # Connect signals
    interaction_area.connect("body_entered", self, "_on_interaction_area_entered")
    interaction_area.connect("body_exited", self, "_on_interaction_area_exited")

func initialize(id, data, player_node):
    pet_id = id
    pet_data = data
    current_stats = data["current_stats"]
    mood = data["mood"]
    target = player_node
    move_speed = current_stats["speed"]
    
    # Update appearance based on pet type
    # sprite.texture = load("res://assets/pets/" + pet_id + ".png")
    
    _update_mood_indicator()

func _physics_process(delta):
    if not target:
        return
        
    match current_action:
        "idle":
            _idle_state(delta)
        "follow":
            _follow_state(delta)
        "attack":
            _attack_state(delta)
        "guard":
            _guard_state(delta)
        "fetch":
            _fetch_state(delta)
        _:
            _idle_state(delta)

func _idle_state(delta):
    velocity = Vector2.ZERO
    # Play idle animation
    if animation_player.has_animation("idle"):
        animation_player.play("idle")
    
    # Check distance to player
    if global_position.distance_to(target.global_position) > follow_distance * 1.5:
        current_action = "follow"

func _follow_state(delta):
    var distance = global_position.distance_to(target.global_position)
    
    if distance > follow_distance:
        var direction = (target.global_position - global_position).normalized()
        velocity = direction * move_speed
        velocity = move_and_slide(velocity)
        
        # Update animation
        _update_animation(direction)
    else:
        # Reached player, switch to idle
        current_action = "idle"
        velocity = Vector2.ZERO

func _attack_state(delta):
    if not action_target or not is_instance_valid(action_target):
        current_action = "follow"
        return
        
    var distance = global_position.distance_to(action_target.global_position)
    var attack_range = 30  # Example range
    
    if distance > attack_range:
        # Move towards target
        var direction = (action_target.global_position - global_position).normalized()
        velocity = direction * move_speed
        velocity = move_and_slide(velocity)
        _update_animation(direction)
    else:
        # Attack target
        velocity = Vector2.ZERO
        if animation_player.has_animation("attack"):
            animation_player.play("attack")
        
        # Deal damage (simplified)
        if action_target.has_method("take_damage"):
            action_target.take_damage(current_stats["attack"])
        
        # Cooldown or switch state
        yield(get_tree().create_timer(1.0), "timeout")
        current_action = "follow"

func _guard_state(delta):
    # Stay in place, look for enemies
    velocity = Vector2.ZERO
    if animation_player.has_animation("idle"):
        animation_player.play("idle")
        
    # Find nearby enemies
    var enemies = _find_nearby_enemies(100) # Example range
    if enemies.size() > 0:
        action_target = enemies[0]
        current_action = "attack"

func _fetch_state(delta):
    if not action_target or not is_instance_valid(action_target):
        current_action = "follow"
        return
        
    var distance = global_position.distance_to(action_target.global_position)
    
    if distance > 10:
        # Move towards item
        var direction = (action_target.global_position - global_position).normalized()
        velocity = direction * move_speed
        velocity = move_and_slide(velocity)
        _update_animation(direction)
    else:
        # Collect item
        if action_target.has_method("collect"):
            action_target.collect()
        
        # Return to player or idle
        current_action = "follow"

func _update_animation(direction):
    # Flip sprite based on movement direction
    if direction.x != 0:
        sprite.flip_h = direction.x < 0
    
    # Play walk animation if available
    if animation_player.has_animation("walk"):
        animation_player.play("walk")

func _update_mood_indicator():
    # Update visual indicator based on mood
    if mood > 70:
        mood_indicator.modulate = Color.green
    elif mood > 30:
        mood_indicator.modulate = Color.yellow
    else:
        mood_indicator.modulate = Color.red

func interact():
    # Pet the pet, increase mood
    PetSystem.update_mood(pet_id, 10)
    _update_mood_indicator()
    
    # Play happy animation
    if animation_player.has_animation("happy"):
        animation_player.play("happy")
    
    Events.emit_signal("notification", "You pet " + pet_data["name"], "info")

func command(action, target_node=null):
    current_action = action
    action_target = target_node

func _on_interaction_area_entered(body):
    if body.name == "Player":
        # Show interaction hint
        pass

func _on_interaction_area_exited(body):
    if body.name == "Player":
        # Hide interaction hint
        pass

func _find_nearby_enemies(radius):
    var enemies = []
    var space_state = get_world_2d().direct_space_state
    var query = Physics2DShapeQueryParameters.new()
    query.set_shape(CircleShape2D.new())
    query.shape.radius = radius
    query.transform = global_transform
    query.collision_layer = 4 # Zombie layer
    
    var results = space_state.intersect_shape(query)
    for result in results:
        enemies.append(result.collider)
    return enemies