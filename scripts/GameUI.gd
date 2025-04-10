extends Control

onready var health_bar = $TopLeft/HealthBar
onready var energy_bar = $TopLeft/EnergyBar
onready var money_label = $TopRight/MoneyLabel
onready var time_label = $TopRight/TimeLabel
onready var date_label = $TopRight/DateLabel
onready var weather_label = $TopRight/WeatherLabel
onready var weather_icon = $TopRight/WeatherIcon
onready var equipped_weapon = $BottomLeft/EquippedWeapon
onready var equipped_armor = $BottomLeft/EquippedArmor
onready var hotbar = $BottomCenter/Hotbar
onready var notification_label = $Center/NotificationLabel
onready var notification_timer = $Center/NotificationTimer
onready var disaster_warning = $Center/DisasterWarning
onready var weather_effects_indicator = $TopRight/WeatherEffects

func _ready():
    # Connect signals
    Events.connect("health_changed", self, "_update_health")
    Events.connect("energy_changed", self, "_update_energy")
    Events.connect("money_changed", self, "_update_money")
    Events.connect("time_updated", self, "_update_time")
    Events.connect("season_changed", self, "_update_season")
    Events.connect("notification", self, "_show_notification")
    Events.connect("weapon_equipped", self, "_update_weapon")
    Events.connect("armor_equipped", self, "_update_armor")
    Events.connect("inventory_changed", self, "_update_hotbar")
    Events.connect("weather_changed", self, "_update_weather_display")
    Events.connect("natural_disaster_warning", self, "_show_disaster_warning")
    Events.connect("natural_disaster_started", self, "_on_disaster_started")
    Events.connect("natural_disaster_ended", self, "_on_disaster_ended")
    
    # Initial update
    _update_all()
    disaster_warning.hide()

func _update_all():
    _update_health(GameData.current_health, GameData.max_health)
    _update_energy(GameData.current_energy, GameData.max_energy)
    _update_money(GameData.player_money)
    _update_equipped_items()
    _update_hotbar(GameData.inventory)
    _update_weather_display(WeatherManager.current_weather)

func _update_health(current, maximum):
    health_bar.max_value = maximum
    health_bar.value = current
    health_bar.get_node("Label").text = "HP: %d/%d" % [current, maximum]

func _update_energy(current, maximum):
    energy_bar.max_value = maximum
    energy_bar.value = current
    energy_bar.get_node("Label").text = "EP: %d/%d" % [current, maximum]

func _update_money(amount):
    money_label.text = "Gold: %d" % amount

func _update_time(hour, minute):
    time_label.text = "%02d:%02d" % [hour, minute]
    
    # Update day/night indicator
    if hour >= 22 or hour < 6:
        time_label.modulate = Color(0.5, 0.5, 1.0)  # Blue for night
    else:
        time_label.modulate = Color(1.0, 1.0, 0.0)  # Yellow for day

func _update_weather_display(weather_type):
    weather_label.text = weather_type.capitalize()
    
    # Update weather icon
    var weather_color = Color.white
    match weather_type:
        "sunny":
            weather_icon.texture = load("res://assets/icons/weather/sunny.png")
            weather_color = Color(1, 1, 0)  # Yellow
        "rainy":
            weather_icon.texture = load("res://assets/icons/weather/rain.png")
            weather_color = Color(0.5, 0.5, 1)  # Blue
        "stormy":
            weather_icon.texture = load("res://assets/icons/weather/storm.png")
            weather_color = Color(0.3, 0.3, 0.3)  # Dark gray
        "foggy":
            weather_icon.texture = load("res://assets/icons/weather/fog.png")
            weather_color = Color(0.7, 0.7, 0.7)  # Light gray
        "windy":
            weather_icon.texture = load("res://assets/icons/weather/wind.png")
            weather_color = Color(0.8, 0.8, 1)  # Light blue
    
    weather_icon.modulate = weather_color
    _update_weather_effects(weather_type)

func _update_weather_effects(weather_type):
    var effects = WeatherManager.get_current_effects()
    var effects_text = ""
    
    for effect in effects:
        match effect:
            "crop_growth":
                effects_text += "Crop Growth: %d%%\n" % (effects[effect] * 100)
            "energy_drain":
                effects_text += "Energy Drain: %d%%\n" % (effects[effect] * 100)
            "visibility":
                effects_text += "Visibility: %d%%\n" % (effects[effect] * 100)
    
    weather_effects_indicator.text = effects_text

func _show_disaster_warning(disaster_type):
    disaster_warning.text = "WARNING: " + disaster_type.capitalize() + " approaching!"
    disaster_warning.modulate = Color(1, 0, 0)  # Red
    disaster_warning.show()
    
    # Create warning animation
    var tween = create_tween()
    tween.tween_property(disaster_warning, "modulate:a", 0, 1)
    tween.tween_property(disaster_warning, "modulate:a", 1, 1)
    tween.set_loops(3)

func _on_disaster_started(disaster_type):
    disaster_warning.text = disaster_type.capitalize() + " in progress!"
    disaster_warning.modulate = Color(1, 0.5, 0)  # Orange
    disaster_warning.show()

func _on_disaster_ended(disaster_type):
    disaster_warning.text = disaster_type.capitalize() + " has ended."
    disaster_warning.modulate = Color(0, 1, 0)  # Green
    
    # Hide after delay
    yield(get_tree().create_timer(3.0), "timeout")
    disaster_warning.hide()

func _show_notification(message, type="info"):
    notification_label.text = message
    
    # Set color based on type
    match type:
        "warning":
            notification_label.modulate = Color(1, 0.5, 0)
        "error":
            notification_label.modulate = Color(1, 0, 0)
        "success":
            notification_label.modulate = Color(0, 1, 0)
        _:  # info
            notification_label.modulate = Color(1, 1, 1)
    
    notification_label.show()
    notification_timer.start(3.0)

[Previous weapon, armor, and hotbar update functions remain the same...]