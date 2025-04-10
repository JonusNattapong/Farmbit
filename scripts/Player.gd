extends KinematicBody2D

# Player attributes
export var move_speed = 100
export var max_health = 100
export var max_energy = 100

# Combat stats
var current_health = 100
var current_energy = 100
var base_damage = 10
var base_defense = 5
var knockback_resistance = 0

# Combat state
var can_attack = true
var attacking = false
var attack_combo = 0
var max_combo = 3
var combo_timer = 0
var combo_timeout = 0.5
var invulnerable = false
var invulnerable_time = 0.5

# Weather effects
var weather_damage_multiplier = 1.0
var weather_speed_multiplier = 1.0
var weather_protection = 0.0  # From equipment
var in_shelter = false

# Equipment
var equipped_weapon = null
var equipped_armor = null

# Tool variables
var current_tool = "hoe"
var current_seed = "carrot_seed"
var tools = ["hoe", "watering_can", "axe", "hammer", "fishing_rod"]

# Movement
var velocity = Vector2.ZERO
var direction = Vector2.DOWN
var knockback = Vector2.ZERO

# References
onready var sprite = $Sprite
onready var anim_player = $AnimationPlayer
onready var weapon_pivot = $WeaponPivot
onready var weapon_sprite = $WeaponPivot/WeaponSprite
onready var hit_area = $WeaponPivot/HitArea
onready var attack_timer = $AttackTimer
onready var invulnerability_timer = $InvulnerabilityTimer
onready var combo_reset_timer = $ComboResetTimer
onready var health_bar = $HealthBar

func _ready():
    # Initialize timers
    attack_timer.one_shot = true
    invulnerability_timer.one_shot = true
    combo_reset_timer.one_shot = true
    
    # Connect signals
    Events.connect("health_changed", self, "_on_health_changed")
    Events.connect("energy_changed", self, "_on_energy_changed")
    Events.connect("weather_effect_started", self, "_on_weather_effect_started")
    Events.connect("weather_effect_ended", self, "_on_weather_effect_ended")
    Events.connect("natural_disaster_started", self, "_on_natural_disaster_started")
    Events.connect("natural_disaster_ended", self, "_on_natural_disaster_ended")
    Events.connect("lightning_strike", self, "_on_lightning_strike")
    
    # Initial updates
    _update_stats()

func _physics_process(delta):
    if knockback != Vector2.ZERO:
        knockback = knockback.move_toward(Vector2.ZERO, delta * 500)
        knockback = move_and_slide(knockback)
        return
        
    var input_vector = get_input_vector()
    
    if input_vector != Vector2.ZERO and not attacking:
        direction = input_vector
        velocity = input_vector * get_modified_speed()
        update_animation("walk")
    else:
        velocity = Vector2.ZERO
        if not attacking:
            update_animation("idle")
    
    velocity = move_and_slide(velocity)
    
    # Apply weather effects
    if not in_shelter:
        _apply_weather_effects(delta)
    
    # Handle attacks
    if Input.is_action_just_pressed("attack") and can_attack and not attacking:
        attack()

func _apply_weather_effects(delta):
    var weather_effects = WeatherManager.get_current_effects()
    
    # Apply energy drain from weather
    if "energy_drain" in weather_effects:
        var drain = weather_effects["energy_drain"] * (1 - weather_protection)
        consume_energy(drain * delta)
    
    # Apply damage from weather (like extreme cold or heat)
    if "damage" in weather_effects:
        var damage = weather_effects["damage"] * (1 - weather_protection)
        take_weather_damage(damage * delta)

func take_weather_damage(amount):
    if invulnerable:
        return
        
    current_health = max(0, current_health - amount)
    Events.emit_signal("health_changed", current_health, max_health)
    
    if current_health <= 0:
        die()

func get_modified_speed():
    var modified_speed = move_speed
    
    # Apply weather effects
    modified_speed *= weather_speed_multiplier
    
    # Apply skills
    modified_speed *= (1 + Skills.get_skill_effect("farming", "harvesting", "speed_bonus"))
    
    return modified_speed

func _on_weather_effect_started(effect_type):
    match effect_type:
        "storm":
            weather_speed_multiplier = 0.7
            weather_damage_multiplier = 1.5
        "blizzard":
            weather_speed_multiplier = 0.5
            weather_damage_multiplier = 2.0
        "heat_wave":
            weather_speed_multiplier = 0.8
            weather_damage_multiplier = 1.3
        _:
            weather_speed_multiplier = 1.0
            weather_damage_multiplier = 1.0

func _on_weather_effect_ended(effect_type):
    weather_speed_multiplier = 1.0
    weather_damage_multiplier = 1.0

func _on_natural_disaster_started(disaster_type):
    match disaster_type:
        "tornado":
            weather_speed_multiplier = 0.3
            take_damage(30)
        "flood":
            weather_speed_multiplier = 0.5
            take_damage(20)
        "drought":
            weather_damage_multiplier = 1.5
            consume_energy(20)

func _on_natural_disaster_ended(disaster_type):
    weather_speed_multiplier = 1.0
    weather_damage_multiplier = 1.0

func _on_lightning_strike():
    if not in_shelter and randf() < 0.1:  # 10% chance to be struck
        take_damage(50)  # Lightning deals massive damage
        Events.emit_signal("notification", "You were struck by lightning!", "danger")

func enter_shelter():
    in_shelter = true
    weather_protection = 1.0

func exit_shelter():
    in_shelter = false
    weather_protection = equipped_armor.get("weather_protection", 0.0) if equipped_armor else 0.0

# Rest of the existing player functions...
[Previous combat and farming related functions]