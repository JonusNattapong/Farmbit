extends Node

class_name AntiCheatSystem

# ระบบตรวจจับและป้องกันการโกงขั้นสูง
var player_profiles = {}
var cheat_patterns = {}
var detection_system_active = true
var real_time_validation = true
var encryption_key = "farmbit_secure_2025"

# Machine Learning สำหรับตรวจจับรูปแบบการโกง
var ml_detector = null
var training_data = []

const NORMAL_THRESHOLD = 2.5 # ค่าเบี่ยงเบนมาตรฐานที่ยอมรับได้

func _ready():
    init_advanced_anti_cheat()
    load_cheat_patterns()
    start_real_time_protection()

func init_advanced_anti_cheat():
    # เริ่มต้นระบบ Machine Learning
    ml_detector = MachineLearning.new()
    ml_detector.init_model(10, [20, 15], 3) # 10 inputs, 2 hidden layers (20, 15), 3 outputs
    
    # โหลดข้อมูลการฝึก
    load_training_data("user://anti_cheat_training.json")

func load_cheat_patterns():
    # โหลดรูปแบบการโกงที่รู้จัก
    var file = File.new()
    if file.file_exists("res://data/cheat_patterns.json"):
        file.open("res://data/cheat_patterns.json", File.READ)
        cheat_patterns = parse_json(file.get_as_text())
        file.close()

func start_real_time_protection():
    # เริ่มระบบตรวจสอบแบบเรียลไทม์
    $ProtectionTimer.start(1.0) # ตรวจสอบทุก 1 วินาที
    
    # เชื่อมต่อสัญญาณต่างๆ
    Events.connect("player_stat_changed", self, "_on_player_stat_changed_advanced")
    Events.connect("inventory_updated", self, "_on_inventory_updated_advanced")
    Events.connect("skill_used", self, "_on_skill_used_advanced")
    Events.connect("game_saved", self, "_validate_save_data")

func _on_player_stat_changed_advanced(stat, old_value, new_value):
    if !detection_system_active: return
    
    var player = get_tree().get_nodes_in_group("player")[0]
    var player_id = player.get_instance_id()
    
    # สร้างโปรไฟล์ผู้เล่นถ้ายังไม่มี
    if !player_profiles.has(player_id):
        init_player_profile(player_id)
    
    # วิเคราะห์การเปลี่ยนแปลงด้วย ML
    var input = [
        float(old_value),
        float(new_value),
        player_profiles[player_id]["stats"][stat]["avg"],
        player_profiles[player_id]["stats"][stat]["std_dev"],
        OS.get_unix_time() - player_profiles[player_id]["last_update"],
        player.speed,
        player.health,
        player_profiles[player_id]["cheat_score"],
        player_profiles[player_id]["action_count"],
        player_profiles[player_id]["session_time"]
    ]
    
    var prediction = ml_detector.predict(input)
    update_cheat_score(player_id, prediction[0])
    
    # อัพเดทสถิติผู้เล่น
    update_player_stats(player_id, stat, new_value)
    
    # ถ้าคะแนนโกงเกินเกณฑ์
    if player_profiles[player_id]["cheat_score"] > 0.85:
        handle_cheat_detection(player_id, "stat_anomaly", 
            "Suspicious stat change: %s from %s to %s" % [stat, old_value, new_value])

func _on_inventory_updated_advanced(item_id, count_change):
    if !detection_system_active: return
    
    var player = get_tree().get_nodes_in_group("player")[0]
    var player_id = player.get_instance_id()
    
    # ตรวจสอบกับรูปแบบการโกงที่รู้จัก
    for pattern in cheat_patterns.get("inventory", []):
        if pattern.match(item_id, count_change):
            handle_cheat_detection(player_id, "known_inventory_hack", 
                "Matched known cheat pattern for item: %s" % item_id)
            return
    
    # ตรวจสอบด้วยระบบ ML
    var input = [
        float(count_change),
        player_profiles[player_id]["inventory_changes"],
        player_profiles[player_id]["cheat_score"],
        player_profiles[player_id]["session_time"],
        player.speed,
        player.health
    ]
    
    var prediction = ml_detector.predict(input)
    update_cheat_score(player_id, prediction[1])
    
    # อัพเดทสถิติ Inventory
    player_profiles[player_id]["inventory_changes"] += 1
    
    if player_profiles[player_id]["cheat_score"] > 0.8:
        handle_cheat_detection(player_id, "inventory_anomaly",
            "Suspicious inventory change: %s x%d" % [item_id, count_change])

func _on_skill_used_advanced(skill_id, cooldown):
    if !detection_system_active: return
    
    var player = get_tree().get_nodes_in_group("player")[0]
    var player_id = player.get_instance_id()
    
    # ตรวจสอบ cooldown ที่ผิดปกติ
    if cooldown < 0:
        handle_cheat_detection(player_id, "skill_cooldown_hack",
            "Negative cooldown detected for skill: %s" % skill_id)
        return
    
    # ตรวจสอบการใช้สกิลถี่เกินไป
    var current_time = OS.get_unix_time()
    if player_profiles[player_id].has("last_skill_used"):
        var time_diff = current_time - player_profiles[player_id]["last_skill_used"]
        if time_diff < cooldown * 0.5: # ใช้สกิลเร็วกว่า cooldown ถึงครึ่งหนึ่ง
            handle_cheat_detection(player_id, "rapid_skill_use",
                "Skill used too frequently: %s (%.2fs after last use)" % [skill_id, time_diff])
    
    player_profiles[player_id]["last_skill_used"] = current_time

func _validate_save_data():
    # ตรวจสอบความถูกต้องของข้อมูลเซฟ
    var save_data = GameData.get_save_data()
    var validation_hash = _calculate_validation_hash(save_data)
    
    if save_data["validation_hash"] != validation_hash:
        handle_cheat_detection(save_data["player_id"], "save_data_tampering",
            "Game save data has been modified!")
        GameData.restore_from_backup()

func _calculate_validation_hash(data) -> String:
    # คำนวณ hash สำหรับตรวจสอบความถูกต้อง
    var json = JSON.print(data)
    return (json + encryption_key).sha256_text()

func init_player_profile(player_id):
    # เริ่มต้นโปรไฟล์ผู้เล่น
    player_profiles[player_id] = {
        "stats": {},
        "inventory_changes": 0,
        "cheat_score": 0.0,
        "action_count": 0,
        "session_time": 0.0,
        "last_update": OS.get_unix_time(),
        "warnings": 0
    }

func update_player_stats(player_id, stat, new_value):
    # อัพเดทสถิติผู้เล่น
    if !player_profiles[player_id]["stats"].has(stat):
        player_profiles[player_id]["stats"][stat] = {
            "values": [],
            "avg": 0.0,
            "std_dev": 0.0
        }
    
    var stat_data = player_profiles[player_id]["stats"][stat]
    stat_data["values"].append(float(new_value))
    
    # คำนวณค่าเฉลี่ยและค่าเบี่ยงเบนมาตรฐาน
    var sum = 0.0
    for val in stat_data["values"]:
        sum += val
    
    stat_data["avg"] = sum / stat_data["values"].size()
    
    var variance = 0.0
    for val in stat_data["values"]:
        variance += pow(val - stat_data["avg"], 2)
    
    stat_data["std_dev"] = sqrt(variance / stat_data["values"].size())

func update_cheat_score(player_id, score):
    # อัพเดทคะแนนโกงด้วย exponential moving average
    var alpha = 0.2 # smoothing factor
    player_profiles[player_id]["cheat_score"] = \
        alpha * score + (1 - alpha) * player_profiles[player_id]["cheat_score"]

func handle_cheat_detection(player_id, cheat_type, message):
    # จัดการเมื่อพบการโกง
    player_profiles[player_id]["warnings"] += 1
    
    # บันทึกเหตุการณ์
    log_cheat_attempt(player_id, cheat_type, message)
    
    # ดำเนินการตามระดับความรุนแรง
    match player_profiles[player_id]["warnings"]:
        1:
            Events.emit_signal("cheat_warning", "Suspicious activity detected")
        2:
            Events.emit_signal("cheat_penalty", "Minor penalty applied")
            apply_minor_penalty(player_id)
        3:
            Events.emit_signal("cheat_major_penalty", "Major penalty applied")
            apply_major_penalty(player_id)
        _:
            Events.emit_signal("cheat_ban", "Account suspended due to cheating")
            ban_player(player_id)

func apply_minor_penalty(player_id):
    # โทษระดับเบา
    var player = instance_from_id(player_id)
    if player:
        player.speed *= 0.9 # ลดความเร็ว 10%
        player.damage *= 0.9 # ลดความเสียหาย 10%

func apply_major_penalty(player_id):
    # โทษระดับกลาง
    var player = instance_from_id(player_id)
    if player:
        player.reset_stats() # รีเซ็ตค่าสถานะ
        player.clear_inventory() # ล้าง Inventory

func ban_player(player_id):
    # แบนผู้เล่น
    var player = instance_from_id(player_id)
    if player:
        player.queue_free() # ลบผู้เล่นออกจากเกม
        GameData.ban_account(player_id)

func log_cheat_attempt(player_id, cheat_type, message):
    # บันทึกประวัติการโกง
    var log_entry = {
        "timestamp": OS.get_datetime(),
        "player_id": player_id,
        "cheat_type": cheat_type,
        "message": message,
        "cheat_score": player_profiles[player_id]["cheat_score"]
    }
    
    # บันทึกลงไฟล์
    var file = File.new()
    file.open("user://cheat_logs.json", File.WRITE_READ)
    var logs = []
    if file.get_len() > 0:
        logs = parse_json(file.get_as_text())
    logs.append(log_entry)
    file.store_string(to_json(logs))
    file.close()

func _on_ProtectionTimer_timeout():
    # ตรวจสอบเป็นระยะ
    if real_time_validation:
        validate_game_state()
        validate_player_behavior()

func validate_game_state():
    # ตรวจสอบสถานะเกม
    var player = get_tree().get_nodes_in_group("player")[0]
    if player:
        # ตรวจสอบค่าสถานะที่เกินขีดจำกัด
        if player.health > player.max_health * 1.5:
            handle_cheat_detection(player.get_instance_id(), "health_hack",
                "Health exceeds maximum limit: %d/%d" % [player.health, player.max_health])
        
        # ตรวจสอบตำแหน่งที่ผิดปกติ
        if player.global_position.x < 0 or player.global_position.y < 0:
            handle_cheat_detection(player.get_instance_id(), "position_hack",
                "Invalid player position: %s" % str(player.global_position))

func validate_player_behavior():
    # ตรวจสอบพฤติกรรมผู้เล่น
    var player = get_tree().get_nodes_in_group("player")[0]
    if player:
        var player_id = player.get_instance_id()
        
        # ตรวจสอบการกระทำที่มากเกินไป
        if player_profiles[player_id]["action_count"] > 1000: # มากกว่า 1000 ครั้งต่อนาที
            handle_cheat_detection(player_id, "action_spam",
                "Excessive actions detected: %d" % player_profiles[player_id]["action_count"])
        
        # รีเซ็ตตัวนับ
        player_profiles[player_id]["action_count"] = 0

# Machine Learning Helper Class
class MachineLearning:
    var model_weights = []
    var model_biases = []
    
    func init_model(input_size: int, hidden_layers: Array, output_size: int):
        # เริ่มต้นโมเดล Neural Network
        randomize()
        
        # ชั้น Input -> Hidden แรก
        model_weights.append(_create_matrix(hidden_layers[0], input_size))
        model_biases.append(_create_array(hidden_layers[0]))
        
        # ชั้น Hidden -> Hidden
        for i in range(1, hidden_layers.size()):
            model_weights.append(_create_matrix(hidden_layers[i], hidden_layers[i-1]))
            model_biases.append(_create_array(hidden_layers[i]))
        
        # ชั้น Hidden สุดท้าย -> Output
        model_weights.append(_create_matrix(output_size, hidden_layers[-1]))
        model_biases.append(_create_array(output_size))
    
    func predict(inputs: Array) -> Array:
        # ทำนายผลลัพธ์
        var current = inputs
        
        for i in range(model_weights.size()):
            current = _matrix_vector_multiply(model_weights[i], current)
            current = _vector_add(current, model_biases[i])
            current = _sigmoid(current)
        
        return current
    
    func _sigmoid(x: Array) -> Array:
        var result = []
        for val in x:
            result.append(1.0 / (1.0 + exp(-val)))
        return result
    
    func _create_matrix(rows: int, cols: int) -> Array:
        var matrix = []
        for i in range(rows):
            var row = []
            for j in range(cols):
                row.append(randf() * 2 - 1) # Random between -1 and 1
            matrix.append(row)
        return matrix
    
    func _create_array(size: int) -> Array:
        var arr = []
        for i in range(size):
            arr.append(randf() * 2 - 1) # Random between -1 and 1
        return arr
    
    func _matrix_vector_multiply(matrix: Array, vector: Array) -> Array:
        var result = []
        for i in range(matrix.size()):
            var sum = 0.0
            for j in range(vector.size()):
                sum += matrix[i][j] * vector[j]
            result.append(sum)
        return result
    
    func _vector_add(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            result.append(a[i] + b[i])
        return result