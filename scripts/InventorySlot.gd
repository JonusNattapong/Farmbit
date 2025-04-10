extends Panel

signal item_selected(item_id)

# References
onready var item_texture = $ItemTexture
onready var quantity_label = $QuantityLabel
onready var quality_indicator = $QualityIndicator

# Item data
var item_id = ""
var quantity = 0
var quality = 1

func _ready():
	# Connect click signal
	connect("gui_input", self, "_on_gui_input")
	
	# Hide labels by default
	clear()

func clear():
	item_id = ""
	quantity = 0
	item_texture.texture = null
	quantity_label.visible = false
	quality_indicator.visible = false

func set_item(new_item_id, item_data, new_quantity, new_quality=1):
	item_id = new_item_id
	quantity = new_quantity
	quality = new_quality
	
	# Set item texture
	if "icon" in item_data:
		var texture_path = item_data["icon"]
		var texture = load(texture_path)
		if texture:
			item_texture.texture = texture
	
	# Set quantity label
	quantity_label.text = str(quantity)
	quantity_label.visible = quantity > 1
	
	# Set quality indicator color
	if quality > 1:
		quality_indicator.visible = true
		match quality:
			2: # Silver quality
				quality_indicator.color = Color(0.7, 0.7, 0.85, 0.7)
			3: # Gold quality
				quality_indicator.color = Color(1.0, 0.9, 0.0, 0.7)
			_: # Normal quality
				quality_indicator.visible = false
	else:
		quality_indicator.visible = false

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		# Emit signal with the item ID (or empty if no item)
		emit_signal("item_selected", item_id)