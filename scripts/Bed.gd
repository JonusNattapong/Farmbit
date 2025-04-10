extends Area2D

signal interact

# Interaction range
export var interaction_distance = 32

var can_interact = false
var interaction_hint = "Press SPACE to sleep"

onready var hint_label = $HintLabel
onready var sprite = $Sprite
onready var collision_shape = $CollisionShape2D

func _ready():
    # Hide hint initially
    if hint_label:
        hint_label.hide()
    
    # Connect signals
    connect("body_entered", self, "_on_body_entered")
    connect("body_exited", self, "_on_body_exited")

func _input(event):
    if can_interact and event.is_action_pressed("use_tool"):
        emit_signal("interact")

func _on_body_entered(body):
    if body.name == "Player":
        can_interact = true
        if hint_label:
            hint_label.text = interaction_hint
            hint_label.show()

func _on_body_exited(body):
    if body.name == "Player":
        can_interact = false
        if hint_label:
            hint_label.hide()