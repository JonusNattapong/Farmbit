extends Node

signal quest_accepted(quest_id)
signal quest_updated(quest_id, status)
signal quest_completed(quest_id)
signal quest_reward_received(quest_id, rewards)

var quests = {
    # Main story quests
    "tutorial": {
        "title": "Welcome to Farmbit",
        "description": "Learn the basics of farming and survival",
        "objectives": [
            {"type": "till", "amount": 3, "progress": 0},
            {"type": "plant", "amount": 2, "progress": 0},
            {"type": "talk_to", "target": "farmer", "progress": 0}
        ],
        "rewards": {
            "gold": 100,
            "items": {"carrot_seed": 5},
            "exp": {"farming": 50}
        },
        "next_quest": "first_zombie"
    },
    
    "first_zombie": {
        "title": "First Night",
        "description": "Survive your first zombie encounter",
        "objectives": [
            {"type": "kill_zombies", "amount": 3, "progress": 0},
            {"type": "survive_night", "amount": 1, "progress": 0}
        ],
        "rewards": {
            "gold": 200,
            "items": {"rusty_sword": 1},
            "exp": {"combat": 100}
        },
        "next_quest": "farm_upgrade"
    },
    
    # Daily quests
    "daily_harvest": {
        "title": "Daily Harvest",
        "description": "Harvest crops for the village",
        "objectives": [
            {"type": "harvest", "amount": 10, "progress": 0}
        ],
        "rewards": {
            "gold": 150,
            "exp": {"farming": 30}
        },
        "repeatable": true,
        "reset": "daily"
    },
    
    "zombie_hunter": {
        "title": "Zombie Hunter",
        "description": "Clear zombies from the area",
        "objectives": [
            {"type": "kill_zombies", "amount": 15, "progress": 0}
        ],
        "rewards": {
            "gold": 200,
            "exp": {"combat": 50},
            "items": {"zombie_flesh": 5}
        },
        "repeatable": true,
        "reset": "daily"
    },
    
    # Special event quests
    "blood_moon": {
        "title": "Blood Moon",
        "description": "Survive the blood moon zombie invasion",
        "objectives": [
            {"type": "survive_blood_moon", "amount": 1, "progress": 0},
            {"type": "kill_zombies", "amount": 50, "progress": 0},
            {"type": "kill_boss", "target": "blood_moon_boss", "progress": 0}
        ],
        "rewards": {
            "gold": 1000,
            "items": {"rare_weapon": 1, "boss_trophy": 1},
            "exp": {"combat": 500}
        },
        "event_quest": true
    }
}

var active_quests = {}
var completed_quests = []

func _ready():
    # Connect to relevant signals
    Events.connect("crop_harvested", self, "_on_crop_harvested")
    Events.connect("enemy_killed", self, "_on_enemy_killed")
    Events.connect("night_survived", self, "_on_night_survived")
    Events.connect("blood_moon_survived", self, "_on_blood_moon_survived")
    Events.connect("npc_talked", self, "_on_npc_talked")

func accept_quest(quest_id):
    if quest_id in quests and not quest_id in active_quests:
        var quest = quests[quest_id].duplicate(true)
        active_quests[quest_id] = quest
        emit_signal("quest_accepted", quest_id)
        Events.emit_signal("notification", "New quest: " + quest["title"], "quest")
        return true
    return false

func update_quest_progress(quest_id, objective_type, amount=1, target=null):
    if not quest_id in active_quests:
        return
    
    var quest = active_quests[quest_id]
    for objective in quest["objectives"]:
        if objective["type"] == objective_type:
            if target and "target" in objective and objective["target"] != target:
                continue
            
            objective["progress"] += amount
            if objective["progress"] >= objective["amount"]:
                objective["progress"] = objective["amount"]
            
            emit_signal("quest_updated", quest_id, quest)
            
            # Check if all objectives are complete
            var all_complete = true
            for obj in quest["objectives"]:
                if obj["progress"] < obj["amount"]:
                    all_complete = false
                    break
            
            if all_complete:
                complete_quest(quest_id)

func complete_quest(quest_id):
    if not quest_id in active_quests:
        return
    
    var quest = active_quests[quest_id]
    
    # Give rewards
    if "rewards" in quest:
        if "gold" in quest["rewards"]:
            GameData.add_money(quest["rewards"]["gold"])
        
        if "items" in quest["rewards"]:
            for item_id in quest["rewards"]["items"]:
                GameData.add_item_to_inventory(item_id, quest["rewards"]["items"][item_id])
        
        if "exp" in quest["rewards"]:
            for skill_type in quest["rewards"]["exp"]:
                Skills.gain_exp(skill_type, "exp", quest["rewards"]["exp"][skill_type])
        
        emit_signal("quest_reward_received", quest_id, quest["rewards"])
    
    # Handle quest completion
    if not quest.get("repeatable", false):
        completed_quests.append(quest_id)
        active_quests.erase(quest_id)
        
        # Start next quest if available
        if "next_quest" in quest and not quest["next_quest"] in completed_quests:
            accept_quest(quest["next_quest"])
    else:
        # Reset repeatable quest
        _reset_quest(quest_id)
    
    emit_signal("quest_completed", quest_id)
    Events.emit_signal("notification", "Quest completed: " + quest["title"], "success")

func _reset_quest(quest_id):
    if quest_id in active_quests:
        var quest = active_quests[quest_id]
        for objective in quest["objectives"]:
            objective["progress"] = 0

func _on_crop_harvested(_crop_type):
    for quest_id in active_quests:
        update_quest_progress(quest_id, "harvest")

func _on_enemy_killed(enemy_type):
    for quest_id in active_quests:
        if enemy_type == "zombie":
            update_quest_progress(quest_id, "kill_zombies")
        elif enemy_type == "boss":
            update_quest_progress(quest_id, "kill_boss", 1, enemy_type)

func _on_night_survived():
    for quest_id in active_quests:
        update_quest_progress(quest_id, "survive_night")

func _on_blood_moon_survived():
    for quest_id in active_quests:
        update_quest_progress(quest_id, "survive_blood_moon")

func _on_npc_talked(npc_id):
    for quest_id in active_quests:
        update_quest_progress(quest_id, "talk_to", 1, npc_id)

func get_available_quests():
    var available = []
    for quest_id in quests:
        if not quest_id in active_quests and not quest_id in completed_quests:
            available.append(quest_id)
    return available

func get_quest_info(quest_id):
    if quest_id in quests:
        return quests[quest_id]
    return null