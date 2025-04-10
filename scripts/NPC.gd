extends KinematicBody2D

var ai_behavior = null
var speed = 100
var velocity = Vector2.ZERO

func _ready():
    # กำหนดกลุ่มให้ NPC
    add_to_group("npc")
    
    # สร้าง AI Behavior
    var ai_system = get_node("/root/AISystem")
    ai_behavior = ai_system.NPCBehavior.new(self)

func _process(delta):
    if ai_behavior:
        ai_behavior.update(delta)
        move_and_slide(velocity)

func move_toward(target_position):
    velocity = (target_position - global_position).normalized() * speed

func interact():
    # ระบบโต้ตอบกับผู้เล่น
    print("NPC interacted!")