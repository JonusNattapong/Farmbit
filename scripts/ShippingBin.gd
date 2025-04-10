extends Area2D

signal item_shipped(item_id, quantity, quality)

onready var popup = $InteractionPopup
var is_player_nearby = false
var farm_controller = null

func _ready():
	# Connect signals
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")
	
	# Find farm controller
	farm_controller = get_node("/root/Farm")

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true
		popup.text = "Press Space to Ship Items"
		popup.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
		popup.visible = false

func _input(event):
	if event.is_action_pressed("use_tool") and is_player_nearby:
		# Show shipping interface
		open_shipping_menu()

func open_shipping_menu():
	# We'll create a simple menu to select items for shipping
	var inventory_ui = load("res://scenes/ShippingMenu.tscn").instance()
	get_tree().get_root().add_child(inventory_ui)
	inventory_ui.connect("item_shipped", self, "_on_item_shipped")
	inventory_ui.popup_centered()

func _on_item_shipped(item_id, quantity, quality):
	# Add to farm's shipping bin
	farm_controller.add_to_shipping_bin(item_id, quantity, quality)
	emit_signal("item_shipped", item_id, quantity, quality)