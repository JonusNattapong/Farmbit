extends Control

onready var dialogue_box = $DialogueBox
onready var npc_name_label = $DialogueBox/NPCName
onready var dialogue_text = $DialogueBox/DialogueText
onready var options_container = $DialogueBox/OptionsContainer

var is_active = false
var current_options = []
var current_npc = null

func _ready():
    # Hide dialogue UI initially
    hide()
    
    # Connect to dialogue events
    Events.connect("dialog_open", self, "_on_dialog_open")
    Events.connect("dialog_closed", self, "_on_dialog_closed")

func _on_dialog_open(text, npc_name, options = []):
    # Show dialogue UI
    show()
    is_active = true
    
    # Set dialogue content
    npc_name_label.text = npc_name
    dialogue_text.text = text
    
    # Clear previous options
    for child in options_container.get_children():
        child.queue_free()
    
    # Add new options if any
    current_options = options
    if options.size() > 0:
        for i in range(options.size()):
            var option = options[i]
            var button = Button.new()
            button.text = option
            button.connect("pressed", self, "_on_option_selected", [i])
            options_container.add_child(button)
    else:
        # Add continue button if no options
        var continue_button = Button.new()
        continue_button.text = "Continue"
        continue_button.connect("pressed", self, "_on_continue_pressed")
        options_container.add_child(continue_button)

func _on_dialog_closed():
    # Hide dialogue UI
    hide()
    is_active = false
    current_options = []
    current_npc = null

func _on_option_selected(option_index):
    if current_npc and current_options.size() > option_index:
        # Handle option selection
        if current_npc.has_method("handle_dialogue_option"):
            current_npc.handle_dialogue_option(option_index)
    
    # Close dialogue
    Events.emit_signal("dialog_closed")

func _on_continue_pressed():
    # Close dialogue
    Events.emit_signal("dialog_closed")

func _input(event):
    if is_active and event.is_action_pressed("ui_cancel"):
        # Close dialogue when ESC is pressed
        Events.emit_signal("dialog_closed")