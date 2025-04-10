extends KinematicBody2D

# NPC Properties
export var npc_id = "farmer"
export var npc_name = "Farmer"
export var move_speed = 40
export var dialogue_range = 100

# NPC State
var daily_routine = []
var current_routine_step = 0
var dialogue_data = {}
var walking_path = []
var path_index = 0
var gifts_received_today = 0
var max_daily_gifts = 1
var current_location = ""

# Movement properties
var target_position = Vector2.ZERO
var is_moving = false
var move_direction = Vector2.ZERO

# References
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var speech_bubble = $SpeechBubble
onready var dialogue_label = $SpeechBubble/DialogueLabel
onready var collision_shape = $CollisionShape2D
onready var interaction_area = $InteractionArea

# Dialogue states
enum DialogueState {NONE, GREETING, TALKING, GIFT_RECEIVED, FAREWELL}
var current_dialogue_state = DialogueState.NONE

func _ready():
	# Hide speech bubble initially
	speech_bubble.visible = false
	
	# Load NPC specific data
	_load_npc_data()
	
	# Set up interaction area
	interaction_area.connect("body_entered", self, "_on_InteractionArea_body_entered")
	interaction_area.connect("body_exited", self, "_on_InteractionArea_body_exited")
	
	# Subscribe to events
	Events.connect("day_changed", self, "_on_day_changed")
	Events.connect("npc_gift_given", self, "_on_npc_gift_given")

func _physics_process(delta):
	if is_moving:
		# If we have a target position, move towards it
		var distance_to_target = global_position.distance_to(target_position)
		
		if distance_to_target > 5:
			move_direction = (target_position - global_position).normalized()
			var velocity = move_direction * move_speed
			
			# Move the character
			move_and_slide(velocity)
			_update_animation()
		else:
			# Reached destination
			is_moving = false
			move_direction = Vector2.ZERO
			_update_animation()
			
			# Check if following a path
			if walking_path.size() > 0:
				_follow_path()

func _load_npc_data():
	# Set name from data
	if npc_id in GameData.npcs:
		npc_name = GameData.npcs[npc_id]["name"]
	
	# Load NPC specific schedule
	_load_schedule()
	
	# Load NPC specific dialogue
	_load_dialogue()

func _load_schedule():
	# Example schedule - this would typically be loaded from a JSON file
	# Format: Array of dictionaries with time and location
	daily_routine = [
		{"hour": 6, "location": "home", "action": "wake_up"},
		{"hour": 8, "location": "farm", "action": "work"},
		{"hour": 12, "location": "cafe", "action": "eat"},
		{"hour": 14, "location": "farm", "action": "work"},
		{"hour": 18, "location": "town", "action": "social"},
		{"hour": 21, "location": "home", "action": "sleep"}
	]

func _load_dialogue():
	# Example dialogue - would typically be loaded from a file
	dialogue_data = {
		"greeting": [
			"Hello there!",
			"Nice day, isn't it?",
			"What can I do for you?",
			"Oh, it's you! How's farm life treating you?"
		],
		"farewell": [
			"See you later!",
			"Take care now!",
			"I'd better get back to work.",
			"Until next time!"
		],
		"liked_gift": [
			"Oh, thank you! I like this.",
			"That's thoughtful of you!",
			"This is nice, thank you!"
		],
		"loved_gift": [
			"Wow, this is wonderful! Thank you so much!",
			"This is my favorite! How did you know?",
			"You're so kind! I love it!"
		],
		"disliked_gift": [
			"Oh... thanks, I guess.",
			"Um, that's... thoughtful.",
			"I'm not really a fan of this, but thanks anyway."
		],
		"neutral_gift": [
			"Thanks for the gift.",
			"Oh, a present for me? Thank you.",
			"That's kind of you."
		],
		"season_spring": [
			"The flowers are beautiful this spring!",
			"It's planting season! Are your crops doing well?"
		],
		"season_summer": [
			"This heat is perfect for growing crops.",
			"Summer is my favorite time of year!"
		],
		"season_fall": [
			"The fall colors are amazing!",
			"Harvest season is so rewarding."
		],
		"season_winter": [
			"Brr, it's cold out today!",
			"Winter is a good time to plan for next year's crops."
		]
	}

func _update_routine():
	# Check current time and update NPC location/action
	var current_hour = TimeManager.current_hour
	
	for step in daily_routine:
		if current_hour >= step["hour"]:
			current_routine_step = daily_routine.find(step)
	
	# Get current routine details
	var routine = daily_routine[current_routine_step]
	current_location = routine["location"]
	
	# Move to the location if not already there
	_move_to_location(current_location)

func _move_to_location(location_name):
	# In a complete implementation, get world position from location name
	# For now, just simulate moving to predefined locations
	var location_positions = {
		"home": Vector2(100, 100),
		"farm": Vector2(500, 300),
		"cafe": Vector2(800, 200),
		"town": Vector2(300, 500)
	}
	
	if location_name in location_positions:
		# Set target position and start moving
		target_position = location_positions[location_name]
		is_moving = true

func _follow_path():
	# Move along a predefined path
	path_index += 1
	
	if path_index < walking_path.size():
		# Move to next point in path
		target_position = walking_path[path_index]
		is_moving = true
	else:
		# Path complete
		walking_path = []
		path_index = 0

func _update_animation():
	# Update sprite based on movement direction
	if move_direction.length() > 0:
		# Set facing direction
		if abs(move_direction.x) > abs(move_direction.y):
			# Moving horizontally
			sprite.flip_h = move_direction.x < 0
		
		# Play walking animation if available
		if animation_player.has_animation("walk"):
			animation_player.play("walk")
	else:
		# Play idle animation if available
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

func _on_day_changed(_day):
	# Reset daily state
	gifts_received_today = 0
	
	# Update routine based on new day
	_update_routine()

func _on_npc_gift_given(target_npc_id, item_id, reaction):
	if target_npc_id == npc_id:
		# Update gift counter
		gifts_received_today += 1
		
		# Show reaction dialogue
		match reaction:
			"loved":
				_show_dialogue(dialogue_data["loved_gift"], DialogueState.GIFT_RECEIVED)
			"liked":
				_show_dialogue(dialogue_data["liked_gift"], DialogueState.GIFT_RECEIVED)
			"disliked":
				_show_dialogue(dialogue_data["disliked_gift"], DialogueState.GIFT_RECEIVED)
			_:
				_show_dialogue(dialogue_data["neutral_gift"], DialogueState.GIFT_RECEIVED)

func _on_InteractionArea_body_entered(body):
	if body.name == "Player":
		# Player entered interaction range
		# Show visual indicator if needed
		pass

func _on_InteractionArea_body_exited(body):
	if body.name == "Player":
		# Player exited interaction range
		_hide_dialogue()

func interact():
	# Called when player interacts with NPC
	if current_dialogue_state == DialogueState.NONE:
		# Show greeting dialogue
		_show_dialogue(dialogue_data["greeting"], DialogueState.GREETING)
		return true
	
	return false

func receive_gift(item_id):
	# Check if NPC can receive more gifts today
	if gifts_received_today >= max_daily_gifts:
		_show_dialogue(["I've received enough gifts for today, thank you."], DialogueState.TALKING)
		return false
	
	# Check gift preferences
	var reaction = "neutral"
	var relationship_change = 1
	
	if npc_id in GameData.npcs:
		var npc_data = GameData.npcs[npc_id]
		
		if "loves" in npc_data and item_id in npc_data["loves"]:
			reaction = "loved"
			relationship_change = 3
		elif "likes" in npc_data and item_id in npc_data["likes"]:
			reaction = "liked"
			relationship_change = 2
		elif "dislikes" in npc_data and item_id in npc_data["dislikes"]:
			reaction = "disliked"
			relationship_change = -1
	
	# Update relationship
	GameData.change_relationship(npc_id, relationship_change)
	
	# Emit gift given signal
	Events.emit_signal("npc_gift_given", npc_id, item_id, reaction)
	
	return true

func _show_dialogue(dialogue_options, state):
	# Pick random dialogue from options
	var dialogue_text = dialogue_options[randi() % dialogue_options.size()]
	
	# Show speech bubble
	speech_bubble.visible = true
	dialogue_label.text = dialogue_text
	
	# Set dialogue state
	current_dialogue_state = state
	
	# Hide dialogue after delay
	yield(get_tree().create_timer(4.0), "timeout")
	_hide_dialogue()

func _hide_dialogue():
	speech_bubble.visible = false
	current_dialogue_state = DialogueState.NONE

func get_friendship_level():
	return GameData.get_relationship_level(npc_id)