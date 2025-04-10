extends Node

class_name AISystem

# สถานะต่างๆ ของ AI
enum AIState {
    IDLE,
    WANDER,
    CHASE,
    ATTACK,
    FLEE
}

# คลาสพื้นฐานสำหรับ AI
class AIBehavior:
    var character
    var current_state = AIState.IDLE
    
    func _init(character_node):
        character = character_node
    
    func update(delta):
        match current_state:
            AIState.IDLE:
                idle_behavior(delta)
            AIState.WANDER:
                wander_behavior(delta)
            AIState.CHASE:
                chase_behavior(delta)
            AIState.ATTACK:
                attack_behavior(delta)
            AIState.FLEE:
                flee_behavior(delta)
    
    # พฤติกรรมพื้นฐาน
    func idle_behavior(delta):
        pass
    
    func wander_behavior(delta):
        pass
    
    func chase_behavior(delta):
        pass
    
    func attack_behavior(delta):
        pass
    
    func flee_behavior(delta):
        pass

# AI สำหรับ NPC ธรรมดา
class NPCBehavior extends AIBehavior:
    var dialogue_options = []
    var schedule = {}
    
    func _init(character_node).(character_node):
        pass
    
    func idle_behavior(delta):
        # พฤติกรรมเมื่ออยู่นิ่ง
        if randf() < 0.01: # 1% โอกาสที่จะเริ่มเดินสุ่ม
            current_state = AIState.WANDER
    
    func wander_behavior(delta):
        # พฤติกรรมการเดินสุ่ม
        if randf() < 0.02: # 2% โอกาสที่จะหยุดเดิน
            current_state = AIState.IDLE

# AI สำหรับศัตรู
class EnemyBehavior extends AIBehavior:
    var detection_range = 300
    var attack_range = 50
    
    func _init(character_node).(character_node):
        pass
    
    func update(delta):
        var player = get_tree().get_nodes_in_group("player")[0]
        var distance_to_player = character.global_position.distance_to(player.global_position)
        
        if distance_to_player < attack_range:
            current_state = AIState.ATTACK
        elif distance_to_player < detection_range:
            current_state = AIState.CHASE
        else:
            current_state = AIState.WANDER
        
        .update(delta)
    
    func chase_behavior(delta):
        # พฤติกรรมการไล่ล่า
        var player = get_tree().get_nodes_in_group("player")[0]
        character.move_toward(player.global_position)

    func attack_behavior(delta):
        # พฤติกรรมการโจมตี
        character.attack()

# ระบบหลักของ AI
var npc_behaviors = []
var enemy_behaviors = []

func _ready():
    # เริ่มต้นระบบ AI
    init_ai_system()

func init_ai_system():
    # ค้นหาและสร้าง AI ให้กับ NPC และศัตรูทั้งหมด
    var npcs = get_tree().get_nodes_in_group("npc")
    for npc in npcs:
        npc_behaviors.append(NPCBehavior.new(npc))
    
    var enemies = get_tree().get_nodes_in_group("enemy")
    for enemy in enemies:
        enemy_behaviors.append(EnemyBehavior.new(enemy))

func _process(delta):
    # อัพเดท AI ทุกเฟรม
    for behavior in npc_behaviors:
        behavior.update(delta)
    
    for behavior in enemy_behaviors:
        behavior.update(delta)