extends "res://scripts/Zombie.gd"

# Boss specific properties
export var rage_health_threshold = 50  # Percentage of health to trigger rage mode
export var summon_cooldown = 15.0     # Cooldown for summoning minions
export var minions_per_summon = 3     # Number of minions to summon at once
export var rage_damage_multiplier = 2.0
export var rage_speed_multiplier = 1.5

# Special attack properties
var in_rage_mode = false
var can_summon = true
var special_attack_damage = 30
var special_attack_range = 100
var special_attack_cooldown = 5.0

onready var summon_timer = $SummonTimer
onready var special_attack_timer = $SpecialAttackTimer
onready var rage_particles = $RageParticles

func _ready():
    # Call parent _ready
    ._ready()
    
    # Set boss stats
    max_health = 300
    current_health = max_health
    damage = 20
    move_speed = 40
    
    # Initialize timers
    summon_timer.wait_time = summon_cooldown
    summon_timer.one_shot = true
    
    special_attack_timer.wait_time = special_attack_cooldown
    special_attack_timer.one_shot = true

func _physics_process(delta):
    if !can_move or attacking:
        return
        
    if target:
        # Boss specific behavior
        if can_summon and current_health < max_health * 0.7:
            _summon_minions()
        
        if !attacking and special_attack_timer.is_stopped():
            var distance = global_position.distance_to(target.global_position)
            if distance <= special_attack_range:
                _special_attack()
        
        # Regular movement and attacks
        ._physics_process(delta)

func take_damage(amount, knockback_direction = Vector2.ZERO):
    .take_damage(amount, knockback_direction)
    
    # Check for rage mode
    var health_percentage = (current_health / max_health) * 100
    if !in_rage_mode and health_percentage <= rage_health_threshold:
        _enter_rage_mode()

func _enter_rage_mode():
    in_rage_mode = true
    
    # Increase stats
    damage *= rage_damage_multiplier
    move_speed *= rage_speed_multiplier
    
    # Visual effects
    if rage_particles:
        rage_particles.emitting = true
    
    # Play rage animation if available
    if animation_player.has_animation("rage"):
        animation_player.play("rage")
    
    # Notify player
    Events.emit_signal("notification", "The boss has entered rage mode!", "warning")

func _summon_minions():
    can_summon = false
    
    # Play summon animation if available
    if animation_player.has_animation("summon"):
        animation_player.play("summon")
    
    # Spawn minions around the boss
    for i in range(minions_per_summon):
        var angle = (2 * PI * i) / minions_per_summon
        var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * 50
        Events.emit_signal("spawn_zombie", spawn_pos)
    
    # Start summon cooldown
    summon_timer.start()
    yield(summon_timer, "timeout")
    can_summon = true

func _special_attack():
    attacking = true
    
    # Play special attack animation if available
    if animation_player.has_animation("special_attack"):
        animation_player.play("special_attack")
    
    # Create area of effect damage
    var targets = _get_targets_in_range(special_attack_range)
    for target in targets:
        if target.has_method("take_damage"):
            target.take_damage(special_attack_damage)
    
    # Start special attack cooldown
    special_attack_timer.start()
    yield(special_attack_timer, "timeout")
    attacking = false

func _get_targets_in_range(range_radius):
    var targets = []
    var space_state = get_world_2d().direct_space_state
    var area = CircleShape2D.new()
    area.radius = range_radius
    
    var query = Physics2DShapeQueryParameters.new()
    query.set_shape(area)
    query.transform = global_transform
    query.collision_layer = 2  # Player layer
    
    var results = space_state.intersect_shape(query)
    for result in results:
        targets.append(result.collider)
    
    return targets

func _die():
    # Drop special boss loot
    Events.emit_signal("spawn_item", "boss_trophy", global_position)
    Events.emit_signal("spawn_item", "rare_weapon", global_position)
    Events.emit_signal("boss_defeated")
    
    # Call parent _die
    ._die()