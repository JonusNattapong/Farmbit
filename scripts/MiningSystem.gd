extends Node

class_name MiningSystem

# ประเภทแร่และหิน
var mineral_types = {
    "stone": {
        "health": 50,
        "tool": "pickaxe",
        "drops": ["stone", "flint"],
        "drop_chances": [0.8, 0.2],
        "exp": 10
    },
    "copper_ore": {
        "health": 100,
        "tool": "pickaxe",
        "drops": ["copper_ore"],
        "drop_chances": [1.0],
        "exp": 25
    },
    "iron_ore": {
        "health": 150,
        "tool": "steel_pickaxe", 
        "drops": ["iron_ore"],
        "drop_chances": [1.0],
        "exp": 40
    }
}

# ระบบขุดแร่
func mine(mineral_type, tool_used):
    if mineral_types.has(mineral_type):
        var mineral = mineral_types[mineral_type]
        
        # ตรวจสอบเครื่องมือ
        if tool_used != mineral["tool"]:
            return {"success": false, "message": "Wrong tool for this mineral"}
        
        # คำนวณความเสียหาย
        var damage = calculate_damage(tool_used)
        mineral["health"] -= damage
        
        # ตรวจสอบว่าแตกหรือยัง
        if mineral["health"] <= 0:
            var drops = get_drops(mineral)
            var exp = mineral["exp"]
            return {
                "success": true,
                "drops": drops,
                "exp": exp,
                "message": "Mining successful"
            }
        else:
            return {
                "success": true,
                "drops": [],
                "exp": mineral["exp"] * 0.1, # ได้ exp นิดหน่อยแม้ยังไม่แตก
                "message": "Keep mining!"
            }
    else:
        return {"success": false, "message": "Unknown mineral type"}

# คำนวณความเสียหายจากเครื่องมือ
func calculate_damage(tool):
    match tool:
        "pickaxe":
            return 20
        "steel_pickaxe":
            return 35
        "gold_pickaxe":
            return 50
        _:
            return 10

# สุ่มของที่ได้จากการขุด
func get_drops(mineral):
    var drops = []
    for i in range(mineral["drops"].size()):
        if randf() <= mineral["drop_chances"][i]:
            drops.append({
                "item": mineral["drops"][i],
                "quantity": int(rand_range(1, 3)) + 1
            })
    return drops

# ระบบอัพเกรดเครื่องมือ
func upgrade_tool(current_tool):
    match current_tool:
        "pickaxe":
            return "steel_pickaxe"
        "steel_pickaxe":
            return "gold_pickaxe"
        _:
            return current_tool

# ระบบค้นหาแหล่งแร่
func find_mineral_deposit(region):
    var deposits = []
    for mineral in mineral_types:
        if randf() > 0.7: # 30% โอกาสพบแหล่งแร่
            deposits.append({
                "type": mineral,
                "position": Vector2(
                    rand_range(0, 1000),
                    rand_range(0, 800)
                ),
                "amount": int(rand_range(3, 10))
            })
    return deposits