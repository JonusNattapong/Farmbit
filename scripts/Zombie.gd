extends KinematicBody2D

var ai_behavior = null
var speed = 80
var health = 100
var attack_damage = 20
var velocity = Vector2.ZERO

func _ready():
    # กำหนดกลุ่มให้ศัตรู
    add_to_group("enemy")
    
    # สร้าง AI Behavior
    var ai_system = get_node("/root/AISystem")
    ai_behavior = ai_system.EnemyBehavior.new(self)

func _process(delta):
    if ai_behavior:
        ai_behavior.update(delta)
        move_and_slide(velocity)

func move_toward(target_position):
    velocity = (target_position - global_position).normalized() * speed

func attack():
    # ระบบโจมตีผู้เล่น
    var player = get_tree().get_nodes_in_group("player")[0]
    if global_position.distance_to(player.global_position) < 50:
        player.take_damage(attack_damage)

func take_damage(amount):
    health -= amount
    if health <= 0:
        queue_free()