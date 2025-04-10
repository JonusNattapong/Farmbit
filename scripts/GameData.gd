extends Node

# Player data
var player_name = "Farmer"
var player_money = 500
var player_max_energy = 100
var player_energy = 100

# Inventory data
var inventory = {}
var inventory_capacity = 20
var selected_item = ""
var selected_tool = ""

# Farm data
var farm_level = 1
var farm_upgrade_cost = 5000

# Relationship data
var npc_relationships = {}

# Item definitions
var items = {
    # Tools
    "hoe": {
        "type": "tool",
        "name": "Hoe",
        "description": "Used to till soil for planting.",
        "icon": "res://assets/images/items/tools/hoe.png",
        "energy_cost": 2,
        "stackable": false,
    },
    "watering_can": {
        "type": "tool",
        "name": "Watering Can",
        "description": "Used to water crops.",
        "icon": "res://assets/images/items/tools/watering_can.png",
        "energy_cost": 1,
        "stackable": false,
    },
    
    # Weapons
    "rusty_sword": {
        "type": "weapon",
        "name": "Rusty Sword",
        "description": "An old but functional sword.",
        "icon": "res://assets/images/items/weapons/rusty_sword.png",
        "damage": 10,
        "attack_speed": 1.0,
        "durability": 100,
        "stackable": false,
    },
    "fire_sword": {
        "type": "weapon",
        "name": "Fire Sword",
        "description": "A sword imbued with fire magic.",
        "icon": "res://assets/images/items/weapons/fire_sword.png",
        "damage": 20,
        "attack_speed": 1.2,
        "durability": 200,
        "element": "fire",
        "stackable": false,
        "rarity": "rare",
    },
    "boss_slayer": {
        "type": "weapon",
        "name": "Boss Slayer",
        "description": "A legendary sword for slaying powerful zombies.",
        "icon": "res://assets/images/items/weapons/boss_slayer.png",
        "damage": 50,
        "attack_speed": 1.5,
        "durability": 500,
        "bonus_vs_boss": 2.0,
        "stackable": false,
        "rarity": "legendary",
    },
    
    # Armor
    "leather_armor": {
        "type": "armor",
        "name": "Leather Armor",
        "description": "Basic protection against zombies.",
        "icon": "res://assets/images/items/armor/leather_armor.png",
        "defense": 5,
        "durability": 100,
        "stackable": false,
    },
    "iron_armor": {
        "type": "armor",
        "name": "Iron Armor",
        "description": "Sturdy protection for serious battles.",
        "icon": "res://assets/images/items/armor/iron_armor.png",
        "defense": 10,
        "durability": 200,
        "stackable": false,
        "rarity": "rare",
    },
    
    # Zombie Drops
    "zombie_flesh": {
        "type": "material",
        "name": "Zombie Flesh",
        "description": "Rotting flesh from a zombie.",
        "icon": "res://assets/images/items/materials/zombie_flesh.png",
        "sell_price": 5,
        "stackable": true,
    },
    "rare_gem": {
        "type": "material",
        "name": "Rare Gem",
        "description": "A mysterious gem dropped by powerful zombies.",
        "icon": "res://assets/images/items/materials/rare_gem.png",
        "sell_price": 1000,
        "stackable": true,
        "rarity": "rare",
    },
    "weapon_part": {
        "type": "material",
        "name": "Weapon Part",
        "description": "Used to craft powerful weapons.",
        "icon": "res://assets/images/items/materials/weapon_part.png",
        "sell_price": 200,
        "stackable": true,
    },
    "boss_trophy": {
        "type": "material",
        "name": "Boss Trophy",
        "description": "Proof of defeating a zombie boss.",
        "icon": "res://assets/images/items/materials/boss_trophy.png",
        "sell_price": 5000,
        "stackable": true,
        "rarity": "legendary",
    },
    
    # Seeds and Crops remain the same...
    [Previous seeds and crops content...]
    
    # Animal Products remain the same...
    [Previous animal products content...]
    
    # Animal Feed remain the same...
    [Previous animal feed content...]
}

# NPC definitions
var npcs = {
    "mayor": {
        "name": "Mayor Thomas",
        "description": "The town's mayor.",
        "icon": "res://assets/images/npcs/mayor.png",
        "location": "town",
        "schedule": {
            "weekday": {
                "9-12": "town_hall",
                "12-14": "cafe",
                "14-18": "town_hall",
                "18-22": "home"
            },
            "weekend": {
                "10-14": "town_square",
                "14-18": "cafe",
                "18-22": "home"
            }
        },
        "dialog": {
            "greeting": "Welcome to Farmbit! I'm Mayor Thomas.",
            "default": "Hope you're enjoying our lovely town!",
            "relationship1": "Our town has a rich history of farming.",
            "relationship2": "You know, I've been mayor for over 20 years.",
            "relationship3": "You're really becoming part of our community!",
            "relationship4": "I consider you a good friend of this town now.",
            "quest": "We're having a harvest festival soon. Could you bring some of your best crops?"
        }
    },
    "store_owner": {
        "name": "Sam",
        "description": "The general store owner.",
        "icon": "res://assets/images/npcs/store_owner.png",
        "location": "general_store",
        "schedule": {
            "weekday": {
                "8-20": "general_store",
                "20-22": "home"
            },
            "weekend": {
                "10-18": "general_store",
                "18-22": "cafe"
            }
        },
        "dialog": {
            "greeting": "Welcome to my shop! Take a look around.",
            "default": "I get new stock every Wednesday!",
            "relationship1": "I've been running this shop since I was young.",
            "relationship2": "My grandfather started this store 50 years ago.",
            "relationship3": "You're becoming one of my best customers!",
            "relationship4": "I can give you a special discount as a friend.",
            "quest": "I need some fresh vegetables for a special order. Can you help?"
        }
    }
}

# Quest definitions
var quests = {
    "welcome": {
        "title": "Welcome to Farmbit",
        "description": "Meet Mayor Thomas in the town square.",
        "objectives": [
            {"type": "talk", "target": "mayor", "complete": false}
        ],
        "reward": {
            "money": 100,
            "items": {"carrot_seed": 5}
        },
        "unlocks": ["first_harvest"],
        "completed": false
    },
    "first_harvest": {
        "title": "First Harvest",
        "description": "Grow and harvest 3 of any crop.",
        "objectives": [
            {"type": "harvest", "amount": 3, "current": 0, "complete": false}
        ],
        "reward": {
            "money": 200,
            "items": {"potato_seed": 3}
        },
        "unlocks": ["animal_friend"],
        "completed": false
    }
}

# Active quests
var active_quests = []

func _ready():
    # Initialize with starting tools
    print("GameData singleton initialized")

func add_item_to_inventory(item_id, quantity = 1, quality = 1):
    if item_id in items:
        # Format for inventory items: [quantity, quality]
        if item_id in inventory:
            # Stack if stackable
            if items[item_id]["stackable"]:
                inventory[item_id][0] += quantity
            else:
                # For non-stackable, we add with a unique key
                var new_key = item_id + "_" + str(OS.get_unix_time())
                inventory[new_key] = [1, quality]
        else:
            # New item
            inventory[item_id] = [quantity, quality]
        
        # Notify inventory changed
        Events.emit_signal("inventory_changed", inventory)
        return true
    return false

func remove_item_from_inventory(item_id, quantity = 1):
    if item_id in inventory:
        # Decrease quantity
        inventory[item_id][0] -= quantity
        
        # Remove if quantity is 0
        if inventory[item_id][0] <= 0:
            inventory.erase(item_id)
            
            # If this was the selected item, deselect it
            if selected_item == item_id:
                selected_item = ""
            if selected_tool == item_id:
                selected_tool = ""
        
        # Notify inventory changed
        Events.emit_signal("inventory_changed", inventory)
        return true
    return false

func select_item(item_id):
    if item_id in inventory:
        var item_type = items[item_id]["type"]
        
        if item_type == "tool":
            selected_tool = item_id
            selected_item = ""
            Events.emit_signal("tool_selected", item_id)
        else:
            selected_item = item_id
            selected_tool = ""
            Events.emit_signal("item_selected", item_id)
        
        return true
    return false

func add_money(amount):
    player_money += amount
    Events.emit_signal("money_changed", player_money)

func remove_money(amount):
    if player_money >= amount:
        player_money -= amount
        Events.emit_signal("money_changed", player_money)
        return true
    return false

func update_energy(amount):
    player_energy = clamp(player_energy + amount, 0, player_max_energy)
    Events.emit_signal("update_energy", player_energy, player_max_energy)

func consume_energy(amount):
    if player_energy >= amount:
        update_energy(-amount)
        return true
    return false

func change_npc_relationship(npc_id, change_amount):
    if npc_id in npcs:
        if not npc_id in npc_relationships:
            npc_relationships[npc_id] = 0
            
        npc_relationships[npc_id] += change_amount
        npc_relationships[npc_id] = clamp(npc_relationships[npc_id], 0, 10)
        
        Events.emit_signal("npc_relationship_changed", npc_id, npc_relationships[npc_id])
        return true
    return false

func get_relationship_level(npc_id):
    if npc_id in npc_relationships:
        return npc_relationships[npc_id]
    return 0

func activate_quest(quest_id):
    if quest_id in quests and not quest_id in active_quests:
        active_quests.append(quest_id)
        Events.emit_signal("quest_accepted", quest_id)
        return true
    return false

func update_quest_progress(quest_id, objective_index, progress):
    if quest_id in quests and quest_id in active_quests:
        var quest = quests[quest_id]
        if objective_index < quest["objectives"].size():
            var objective = quest["objectives"][objective_index]
            
            if "current" in objective:
                objective["current"] += progress
                
                if objective["current"] >= objective["amount"]:
                    objective["complete"] = true
            
            # Check if all objectives are complete
            var all_complete = true
            for obj in quest["objectives"]:
                if not obj["complete"]:
                    all_complete = false
                    break
            
            if all_complete:
                complete_quest(quest_id)
            
            Events.emit_signal("quest_updated", quest_id, objective_index)
            return true
    return false

func complete_quest(quest_id):
    if quest_id in quests and quest_id in active_quests:
        var quest = quests[quest_id]
        
        # Give rewards
        if "reward" in quest:
            if "money" in quest["reward"]:
                add_money(quest["reward"]["money"])
                
            if "items" in quest["reward"]:
                for item_id in quest["reward"]["items"]:
                    add_item_to_inventory(item_id, quest["reward"]["items"][item_id])
        
        # Mark as completed
        quest["completed"] = true
        active_quests.erase(quest_id)
        
        # Unlock new quests
        if "unlocks" in quest:
            for new_quest_id in quest["unlocks"]:
                activate_quest(new_quest_id)
        
        Events.emit_signal("quest_completed", quest_id)
        return true
    return false

func save_game():
    var save_data = {
        "player": {
            "name": player_name,
            "money": player_money,
            "energy": player_energy,
            "max_energy": player_max_energy
        },
        "inventory": inventory,
        "relationships": npc_relationships,
        "farm": {
            "level": farm_level
        },
        "quests": {
            "active": active_quests,
            "completed": get_completed_quests()
        },
        "time": {
            "minute": TimeManager.current_minute,
            "hour": TimeManager.current_hour,
            "day": TimeManager.current_day,
            "season": TimeManager.current_season,
            "year": TimeManager.current_year
        }
    }
    
    return save_data

func load_game(save_data):
    # Load player data
    if "player" in save_data:
        player_name = save_data["player"]["name"]
        player_money = save_data["player"]["money"]
        player_energy = save_data["player"]["energy"]
        player_max_energy = save_data["player"]["max_energy"]
        Events.emit_signal("update_energy", player_energy, player_max_energy)
        Events.emit_signal("money_changed", player_money)
    
    # Load inventory
    if "inventory" in save_data:
        inventory = save_data["inventory"]
        Events.emit_signal("inventory_changed", inventory)
    
    # Load relationships
    if "relationships" in save_data:
        npc_relationships = save_data["relationships"]
        for npc_id in npc_relationships:
            Events.emit_signal("npc_relationship_changed", npc_id, npc_relationships[npc_id])
    
    # Load farm data
    if "farm" in save_data:
        farm_level = save_data["farm"]["level"]
    
    # Load quests
    if "quests" in save_data:
        # Clear active quests
        active_quests = []
        
        # Set active quests
        if "active" in save_data["quests"]:
            for quest_id in save_data["quests"]["active"]:
                active_quests.append(quest_id)
        
        # Set completed quests
        if "completed" in save_data["quests"]:
            for quest_id in save_data["quests"]["completed"]:
                if quest_id in quests:
                    quests[quest_id]["completed"] = true
    
    # Load time
    if "time" in save_data:
        TimeManager.current_minute = save_data["time"]["minute"]
        TimeManager.current_hour = save_data["time"]["hour"]
        TimeManager.current_day = save_data["time"]["day"]
        TimeManager.current_season = save_data["time"]["season"]
        TimeManager.current_year = save_data["time"]["year"]
        TimeManager._emit_all_time_signals()

func get_completed_quests():
    var completed = []
    for quest_id in quests:
        if quests[quest_id]["completed"]:
            completed.append(quest_id)
    return completed