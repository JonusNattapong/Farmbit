extends Control

# References to UI elements
onready var item_grid = $Panel/ItemGrid
onready var money_label = $Panel/MoneyLabel
onready var item_details_panel = $Panel/ItemDetailsPanel
onready var item_name_label = $Panel/ItemDetailsPanel/ItemName
onready var item_description_label = $Panel/ItemDetailsPanel/ItemDescription
onready var use_button = $Panel/ItemDetailsPanel/UseButton
onready var drop_button = $Panel/ItemDetailsPanel/DropButton
onready var gift_button = $Panel/ItemDetailsPanel/GiftButton
onready var sell_button = $Panel/ItemDetailsPanel/SellButton
onready var close_button = $Panel/CloseButton

# Tracking
var current_selected_item = ""
var inventory_slots = []
const MAX_SLOTS = 24

# Preload slot scene
var slot_scene = preload("res://scenes/InventorySlot.tscn")

func _ready():
	# Connect signals
	Events.connect("inventory_changed", self, "_on_inventory_changed")
	Events.connect("money_changed", self, "_on_money_changed")
	close_button.connect("pressed", self, "_on_close_button_pressed")
	use_button.connect("pressed", self, "_on_use_button_pressed")
	drop_button.connect("pressed", self, "_on_drop_button_pressed")
	gift_button.connect("pressed", self, "_on_gift_button_pressed")
	sell_button.connect("pressed", self, "_on_sell_button_pressed")
	
	# Initialize inventory UI
	_initialize_inventory_grid()
	_update_money_display()
	
	# Hide by default, will be shown when inventory key is pressed
	visible = false

func _initialize_inventory_grid():
	# Clear existing slots
	for slot in item_grid.get_children():
		item_grid.remove_child(slot)
		slot.queue_free()
	
	# Create inventory slots
	for i in range(MAX_SLOTS):
		var slot = slot_scene.instance()
		slot.connect("item_selected", self, "_on_item_selected")
		item_grid.add_child(slot)
		inventory_slots.append(slot)
	
	# Update slots with current inventory
	_update_inventory_display()

func _update_inventory_display():
	# Get current inventory from game data
	var inventory = GameData.inventory
	
	# Reset all slots
	for slot in inventory_slots:
		slot.clear()
	
	# Fill slots with items
	var slot_index = 0
	for item_id in inventory:
		if slot_index < inventory_slots.size():
			var item_data = GameData.items[item_id]
			var quantity = inventory[item_id]["quantity"]
			var quality = inventory[item_id]["quality"]
			
			inventory_slots[slot_index].set_item(item_id, item_data, quantity, quality)
			slot_index += 1

func _update_money_display():
	money_label.text = "Gold: " + str(GameData.player_money)

func _on_inventory_changed(_inventory):
	_update_inventory_display()

func _on_money_changed(new_amount):
	money_label.text = "Gold: " + str(new_amount)

func _on_item_selected(item_id):
	# Store selected item
	current_selected_item = item_id
	
	if item_id.empty():
		# No item selected, hide details panel
		item_details_panel.visible = false
	else:
		# Show item details
		var item_data = GameData.items[item_id]
		item_name_label.text = item_data["name"]
		item_description_label.text = item_data["description"]
		
		# Show/hide buttons based on item type
		var item_type = item_data["type"]
		use_button.visible = item_type in ["tool", "seed", "crop", "animal_product", "animal_feed"]
		drop_button.visible = true
		gift_button.visible = item_type != "tool"
		sell_button.visible = item_data["sell_price"] > 0
		
		# Show the details panel
		item_details_panel.visible = true

func _on_use_button_pressed():
	if current_selected_item.empty():
		return
		
	var item_data = GameData.items[current_selected_item]
	var item_type = item_data["type"]
	
	match item_type:
		"tool":
			# Set as active tool
			Events.emit_signal("tool_changed", current_selected_item)
		"seed":
			# Set as active seed
			Events.emit_signal("seed_selected", current_selected_item)
		"crop", "animal_product":
			# Eat for energy if edible
			if "energy" in item_data and item_data["energy"] > 0:
				Events.emit_signal("item_consumed", current_selected_item)
				GameData.remove_item_from_inventory(current_selected_item, 1)
		"animal_feed":
			# Use as animal feed (specific handling in the farm scene)
			Events.emit_signal("feed_selected", current_selected_item)

func _on_drop_button_pressed():
	if current_selected_item.empty():
		return
		
	GameData.remove_item_from_inventory(current_selected_item, 1)
	if not GameData.has_item(current_selected_item):
		current_selected_item = ""
		item_details_panel.visible = false

func _on_gift_button_pressed():
	if current_selected_item.empty():
		return
		
	# Toggle gift mode in game (handled by Farm scene)
	Events.emit_signal("gift_mode_toggled", current_selected_item)
	hide()

func _on_sell_button_pressed():
	if current_selected_item.empty():
		return
		
	# Sell the item
	var sell_price = GameData.get_sell_price(current_selected_item)
	GameData.add_money(sell_price)
	GameData.remove_item_from_inventory(current_selected_item, 1)
	
	if not GameData.has_item(current_selected_item):
		current_selected_item = ""
		item_details_panel.visible = false

func _on_close_button_pressed():
	hide()

func _input(event):
	if event.is_action_pressed("open_inventory"):
		if visible:
			hide()
		else:
			show()
			_update_inventory_display()
			_update_money_display()