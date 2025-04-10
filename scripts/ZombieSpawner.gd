extends Node2D

# Spawning properties
export var spawn_radius = 300  # Spawn distance from player
export var min_zombies = 3    # Minimum zombies at night
export var max_zombies = 10   # Maximum zombies at night
export var spawn_interval = 30.0  # Seconds between spawn attempts
export var boss_night_interval = 7  # Boss appears every X nights

# Spawn chances (percentage)
var zombie_spawn_chances = {
    "normal": 70,
    "special": 25,
    "boss": 5
}

# References
var zombie_scene = preload("res://scenes/Zombie.tscn")
var boss_zombie_scene = preload("res://scenes/BossZombie.tscn")
var active_zombies = []
var current_night = 0
var can_spawn = false

onready var spawn_timer = $SpawnTimer
onready var player = get_node("../Player")  # Assuming player is sibling node

func _ready():
    # Connect to time signals
    Events.connect("night_started", self, "_on_night_started")
    Events.connect("day_started", self, "_on_day_started")
    Events.connect("enemy_died", self, "_on_enemy_died")
    
    # Setup spawn timer
    spawn_timer.wait_time = spawn_interval
    spawn_timer.connect("timeout", self, "_on_spawn_timer_timeout")

func _on_night_started():
    current_night += 1
    can_spawn = true
    spawn_timer.start()
    
    # Initial spawn wave
    var initial_count = min_zombies + (current_night - 1)
    initial_count = min(initial_count, max_zombies)
    
    for i in range(initial_count):
        spawn_zombie()
    
    # Check for boss night
    if current_night % boss_night_interval == 0:
        spawn_boss_zombie()

func _on_day_started():
    can_spawn = false
    spawn_timer.stop()
    
    # Remove all zombies
    for zombie in active_zombies:
        if is_instance_valid(zombie):
            zombie.queue_free()
    active_zombies.clear()

func _on_spawn_timer_timeout():
    if can_spawn and active_zombies.size() < max_zombies:
        spawn_zombie()

func spawn_zombie():
    # Get random position around player
    var spawn_pos = get_random_spawn_position()
    
    # Determine zombie type
    var rand = randf() * 100
    var zombie_type = "normal"
    var cumulative = 0
    
    for type in zombie_spawn_chances:
        cumulative += zombie_spawn_chances[type]
        if rand <= cumulative:
            zombie_type = type
            break
    
    # Create zombie instance
    var zombie
    match zombie_type:
        "boss":
            zombie = boss_zombie_scene.instance()
        _:
            zombie = zombie_scene.instance()
            if zombie_type == "special":
                # Enhance zombie properties for special type
                zombie.max_health *= 1.5
                zombie.current_health = zombie.max_health
                zombie.damage *= 1.2
                zombie.move_speed *= 1.2
    
    # Add zombie to scene
    get_parent().add_child(zombie)
    zombie.global_position = spawn_pos
    active_zombies.append(zombie)
    
    # Emit spawn signal
    Events.emit_signal("enemy_spawned", zombie_type, spawn_pos)

func spawn_boss_zombie():
    var spawn_pos = get_random_spawn_position()
    var boss = boss_zombie_scene.instance()
    
    get_parent().add_child(boss)
    boss.global_position = spawn_pos
    active_zombies.append(boss)
    
    Events.emit_signal("boss_spawned", "zombie_boss", spawn_pos)
    Events.emit_signal("notification", "A powerful zombie boss has appeared!", "warning")

func get_random_spawn_position():
    var angle = randf() * 2 * PI
    var distance = spawn_radius
    var offset = Vector2(cos(angle), sin(angle)) * distance
    return player.global_position + offset

func _on_enemy_died(enemy_type, position):
    # Remove from active zombies list
    var index = active_zombies.find(position)
    if index != -1:
        active_zombies.remove(index)
    
    # Spawn new zombie after delay if still night
    if can_spawn:
        spawn_timer.start()