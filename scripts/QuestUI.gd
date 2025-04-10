extends Control

onready var quest_list = $Background/QuestList
onready var active_quests = $Background/ActiveQuests
onready var quest_info = $Background/QuestInfo
onready var accept_button = $Background/QuestInfo/AcceptButton
onready var quest_title = $Background/QuestInfo/Title
onready var quest_description = $Background/QuestInfo/Description
onready var quest_objectives = $Background/QuestInfo/Objectives
onready var quest_rewards = $Background/QuestInfo/Rewards

var selected_quest = null

func _ready():
    # Connect signals
    QuestManager.connect("quest_accepted", self, "_on_quest_accepted")
    QuestManager.connect("quest_updated", self, "_on_quest_updated")
    QuestManager.connect("quest_completed", self, "_on_quest_completed")
    
    # Initialize quest lists
    _update_quest_lists()

func _update_quest_lists():
    # Clear lists
    quest_list.clear()
    active_quests.clear()
    
    # Add available quests
    var available = QuestManager.get_available_quests()
    for quest_id in available:
        var quest = QuestManager.get_quest_info(quest_id)
        quest_list.add_item(quest["title"], null)
        quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest_id)
    
    # Add active quests
    for quest_id in QuestManager.active_quests:
        var quest = QuestManager.active_quests[quest_id]
        active_quests.add_item(quest["title"], null)
        active_quests.set_item_metadata(active_quests.get_item_count() - 1, quest_id)
        
        # Add progress indicator
        var progress = _calculate_quest_progress(quest)
        active_quests.set_item_text(active_quests.get_item_count() - 1, 
            quest["title"] + " (" + str(progress) + "%)")

func _on_quest_list_item_selected(index):
    var quest_id = quest_list.get_item_metadata(index)
    _show_quest_info(quest_id, false)
    selected_quest = quest_id

func _on_active_quests_item_selected(index):
    var quest_id = active_quests.get_item_metadata(index)
    _show_quest_info(quest_id, true)
    selected_quest = quest_id

func _show_quest_info(quest_id, is_active):
    var quest = QuestManager.get_quest_info(quest_id) if not is_active else QuestManager.active_quests[quest_id]
    
    # Update title and description
    quest_title.text = quest["title"]
    quest_description.text = quest["description"]
    
    # Update objectives
    var objectives_text = "Objectives:\n"
    for objective in quest["objectives"]:
        var progress = objective.get("progress", 0)
        var amount = objective["amount"]
        var type_text = objective["type"].capitalize().replace("_", " ")
        
        if "target" in objective:
            type_text += " " + objective["target"].capitalize().replace("_", " ")
        
        objectives_text += "- " + type_text + ": " + str(progress) + "/" + str(amount) + "\n"
    
    quest_objectives.text = objectives_text
    
    # Update rewards
    var rewards_text = "Rewards:\n"
    if "rewards" in quest:
        if "gold" in quest["rewards"]:
            rewards_text += "- Gold: " + str(quest["rewards"]["gold"]) + "\n"
        
        if "items" in quest["rewards"]:
            for item_id in quest["rewards"]["items"]:
                var amount = quest["rewards"]["items"][item_id]
                var item_name = GameData.items[item_id]["name"]
                rewards_text += "- " + item_name + " x" + str(amount) + "\n"
        
        if "exp" in quest["rewards"]:
            for skill_type in quest["rewards"]["exp"]:
                rewards_text += "- " + skill_type.capitalize() + " EXP: " + str(quest["rewards"]["exp"][skill_type]) + "\n"
    
    quest_rewards.text = rewards_text
    
    # Update accept button
    accept_button.visible = not is_active
    accept_button.disabled = is_active

func _on_accept_button_pressed():
    if selected_quest:
        QuestManager.accept_quest(selected_quest)

func _on_quest_accepted(quest_id):
    _update_quest_lists()
    
    # Auto-select the newly accepted quest
    for i in range(active_quests.get_item_count()):
        if active_quests.get_item_metadata(i) == quest_id:
            active_quests.select(i)
            _on_active_quests_item_selected(i)
            break

func _on_quest_updated(quest_id, quest):
    _update_quest_lists()
    
    # Update info if this quest is selected
    if selected_quest == quest_id:
        _show_quest_info(quest_id, true)

func _on_quest_completed(quest_id):
    _update_quest_lists()
    
    # Clear selection if completed quest was selected
    if selected_quest == quest_id:
        selected_quest = null
        quest_title.text = ""
        quest_description.text = ""
        quest_objectives.text = ""
        quest_rewards.text = ""

func _calculate_quest_progress(quest):
    var total = 0
    var completed = 0
    
    for objective in quest["objectives"]:
        total += objective["amount"]
        completed += min(objective.get("progress", 0), objective["amount"])
    
    return int((float(completed) / total) * 100) if total > 0 else 0

func _on_close_button_pressed():
    hide()