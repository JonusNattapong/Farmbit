extends Control

onready var combat_tab = $TabContainer/Combat
onready var farming_tab = $TabContainer/Farming
onready var cooking_tab = $TabContainer/Cooking
onready var skill_points_label = $SkillPoints
onready var skill_info_panel = $SkillInfoPanel
onready var skill_tree = $SkillTree

var selected_skill = null
var selected_category = null

func _ready():
    # Connect signals
    Events.connect("skill_leveled_up", self, "_on_skill_leveled_up")
    Events.connect("skill_exp_gained", self, "_on_skill_exp_gained")
    Events.connect("skill_point_gained", self, "_on_skill_point_gained")
    Events.connect("skill_unlocked", self, "_on_skill_unlocked")
    
    # Initialize UI
    _update_skill_points()
    _populate_skill_tabs()
    
    # Hide skill info initially
    skill_info_panel.hide()

func _populate_skill_tabs():
    # Combat skills
    _populate_skill_list(combat_tab, "combat", Skills.combat_skills)
    
    # Farming skills
    _populate_skill_list(farming_tab, "farming", Skills.farming_skills)
    
    # Cooking skills
    _populate_skill_list(cooking_tab, "cooking", Skills.cooking_skills)

func _populate_skill_list(tab, category, skills):
    for skill_id in skills:
        var skill = skills[skill_id]
        var skill_button = Button.new()
        skill_button.text = skill["name"]
        skill_button.connect("pressed", self, "_on_skill_selected", [category, skill_id])
        
        # Add level indicator
        var level_label = Label.new()
        level_label.name = skill_id + "_level"
        level_label.text = "Level " + str(skill["level"])
        
        # Add exp bar
        var exp_bar = ProgressBar.new()
        exp_bar.name = skill_id + "_exp"
        exp_bar.max_value = skill["next_level_exp"]
        exp_bar.value = skill["exp"]
        exp_bar.hint_tooltip = str(skill["exp"]) + "/" + str(skill["next_level_exp"])
        
        # Add to container
        var container = VBoxContainer.new()
        container.add_child(skill_button)
        container.add_child(level_label)
        container.add_child(exp_bar)
        tab.add_child(container)

func _on_skill_selected(category, skill_id):
    selected_category = category
    selected_skill = skill_id
    
    var skills = _get_category_skills(category)
    var skill = skills[skill_id]
    
    # Update skill info panel
    skill_info_panel.get_node("SkillName").text = skill["name"]
    skill_info_panel.get_node("Level").text = "Level " + str(skill["level"])
    skill_info_panel.get_node("Description").text = skill["description"]
    
    # Show current effects
    var effects_text = "Current Effects:\n"
    for effect in skill["effects"]:
        var value = skill["effects"][effect] * skill["level"]
        effects_text += "- " + effect.capitalize().replace("_", " ") + ": +" + str(value * 100) + "%\n"
    skill_info_panel.get_node("Effects").text = effects_text
    
    # Show next level preview if can level up
    if Skills.skill_points > 0:
        var next_level_text = "Next Level:\n"
        for effect in skill["effects"]:
            var next_value = skill["effects"][effect] * (skill["level"] + 1)
            next_level_text += "- " + effect.capitalize().replace("_", " ") + ": +" + str(next_value * 100) + "%\n"
        skill_info_panel.get_node("NextLevel").text = next_level_text
        skill_info_panel.get_node("UpgradeButton").disabled = false
    else:
        skill_info_panel.get_node("NextLevel").text = "Need skill points to upgrade"
        skill_info_panel.get_node("UpgradeButton").disabled = true
    
    skill_info_panel.show()

func _on_upgrade_pressed():
    if selected_skill and Skills.skill_points > 0:
        # Deduct skill point
        Skills.skill_points -= 1
        
        # Level up skill
        Skills.gain_exp(selected_category, selected_skill, 
            Skills._get_skill_category(selected_category)[selected_skill]["next_level_exp"])
        
        # Update UI
        _update_skill_points()
        _on_skill_selected(selected_category, selected_skill)  # Refresh info panel

func _on_skill_leveled_up(skill_id, new_level):
    # Update level display
    for tab in $TabContainer.get_children():
        var level_label = tab.get_node_or_null(skill_id + "_level")
        if level_label:
            level_label.text = "Level " + str(new_level)
            break

func _on_skill_exp_gained(skill_id, amount):
    # Update exp bars
    for tab in $TabContainer.get_children():
        var exp_bar = tab.get_node_or_null(skill_id + "_exp")
        if exp_bar:
            exp_bar.value = Skills._get_skill_category(selected_category)[skill_id]["exp"]
            exp_bar.max_value = Skills._get_skill_category(selected_category)[skill_id]["next_level_exp"]
            exp_bar.hint_tooltip = str(exp_bar.value) + "/" + str(exp_bar.max_value)
            break

func _on_skill_point_gained():
    _update_skill_points()

func _update_skill_points():
    skill_points_label.text = "Skill Points: " + str(Skills.skill_points)

func _get_category_skills(category):
    match category:
        "combat":
            return Skills.combat_skills
        "farming":
            return Skills.farming_skills
        "cooking":
            return Skills.cooking_skills
    return null