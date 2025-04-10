extends KinematicBody2D

var speed = 150
var health = 100
var velocity = Vector2.ZERO

func _ready():
    # กำหนดกลุ่มให้ผู้เล่น
    add_to_group("player")

func _physics_process(delta):
    # การควบคุมผู้เล่น
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    input_vector = input_vector.normalized()
    
    if input_vector != Vector2.ZERO:
        velocity = input_vector * speed
    else:
        velocity = Vector2.ZERO
    
    velocity = move_and_slide(velocity)

func take_damage(amount):
    health -= amount
    if health <= 0:
        game_over()

func game_over():
    # ระบบจบเกม
    print("Game Over!")
    get_tree().reload_current_scene()