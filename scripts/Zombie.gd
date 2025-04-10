extends KinematicBody2D

# Zombie properties
export var max_health = 100
export var current_health = 100
export var damage = 10
export var move_speed = 50
export var detection_range = 200
export var attack_range = 30
export var attack_cooldown = 1.0

# Movement
var velocity = Vector2.ZERO
var path = []
var path_index = 0
var can_move = true

# Combat
var can_attack = true
var attacking = false
var target = null

# Drops
var possible_drops = {
    "zombie_flesh": 80,  # 80% chance
    "rare_gem": 5,      # 5% chance
    "weapon_part": 10   # 10% chance
}

onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var health_bar = $HealthBar
onready var detection_area = $DetectionArea
onready var attack_timer = $AttackTimer
onready var hit_area = $HitArea

func _ready():
    # Initialize timers
    attack_timer.wait_time = attack_cooldown
    attack_timer.one_shot = true
    
    # Connect signals
    detection_area.connect("body_entered", self, "_on_detection_area_entered")
    detection_area.connect("body_exited", self, "_on_detection_area_exited")
    hit_area.connect("area_entered", self, "_on_hit_area_entered")

func _physics_process(delta):
    if !can_move or attacking:
        return
        
    if target:
        # Move towards target
        var direction = (target.global_position - global_position).normalized()
        velocity = direction * move_speed
        velocity = move_and_slide(velocity)
        
        # Update animation
        _update_animation(direction)
        
        # Check attack range
        if global_position.distance_to(target.global_position) <= attack_range:
            _attack()

func take_damage(amount, knockback_direction = Vector2.ZERO):
    current_health -= amount
    health_bar.value = (current_health / max_health) * 100
    
    # Apply knockback
    if knockback_direction != Vector2.ZERO:
        velocity = knockback_direction * 100
        move_and_slide(velocity)
    
    # Play hit animation
    if animation_player.has_animation("hit"):
        animation_player.play("hit")
    
    # Check death
    if current_health <= 0:
        _die()

func _attack():
    if !can_attack:
        return
        
    attacking = true
    can_attack = false
    
    # Play attack animation
    if animation_player.has_animation("attack"):
        animation_player.play("attack")
    
    # Deal damage to target if in range
    if target and global_position.distance_to(target.global_position) <= attack_range:
        if target.has_method("take_damage"):
            target.take_damage(damage)
    
    # Start attack cooldown
    attack_timer.start()
    yield(attack_timer, "timeout")
    
    attacking = false
    can_attack = true

func _die():
    # Drop items
    for item in possible_drops.keys():
        if randf() * 100 <= possible_drops[item]:
            # Spawn item at zombie position
            Events.emit_signal("spawn_item", item, global_position)
    
    # Play death animation if available
    if animation_player.has_animation("death"):
        animation_player.play("death")
        yield(animation_player, "animation_finished")
    
    # Remove zombie
    queue_free()

func _update_animation(direction):
    # Flip sprite based on movement direction
    if direction.x != 0:
        sprite.flip_h = direction.x < 0
    
    # Play walk animation if available
    if animation_player.has_animation("walk"):
        animation_player.play("walk")

func _on_detection_area_entered(body):
    if body.name == "Player":
        target = body

func _on_detection_area_exited(body):
    if body.name == "Player":
        target = null

func _on_hit_area_entered(area):
    if area.is_in_group("player_weapons"):
        var damage = area.get_damage()
        var knockback = (global_position - area.global_position).normalized()
        take_damage(damage, knockback)