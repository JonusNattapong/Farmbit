extends Node

signal weather_changed(new_weather)
signal natural_disaster_started(disaster_type)
signal natural_disaster_ended(disaster_type)

# Weather types and their effects
const WEATHER_TYPES = {
    "sunny": {
        "crop_growth": 1.0,
        "energy_drain": 1.0,
        "visibility": 1.0
    },
    "rainy": {
        "crop_growth": 1.2,
        "energy_drain": 1.1,
        "visibility": 0.8,
        "auto_water": true
    },
    "stormy": {
        "crop_growth": 0.8,
        "energy_drain": 1.3,
        "visibility": 0.6,
        "lightning_chance": 0.1
    },
    "foggy": {
        "crop_growth": 0.9,
        "energy_drain": 1.1,
        "visibility": 0.4
    },
    "windy": {
        "crop_growth": 0.9,
        "energy_drain": 1.2,
        "visibility": 0.9
    }
}

# Natural disasters
const DISASTERS = {
    "tornado": {
        "duration": 120,  # 2 game hours
        "damage": 50,
        "crop_destroy_chance": 0.3
    },
    "flood": {
        "duration": 360,  # 6 game hours
        "damage": 30,
        "crop_destroy_chance": 0.5
    },
    "drought": {
        "duration": 1440,  # 24 game hours
        "crop_damage": 0.2,  # 20% damage per hour
        "energy_drain": 1.5
    },
    "blizzard": {
        "duration": 240,  # 4 game hours
        "damage": 40,
        "freeze_chance": 0.4
    }
}

var current_weather = "sunny"
var current_disaster = null
var disaster_time_remaining = 0

func _ready():
    # Connect to time signals
    TimeManager.connect("time_updated", self, "_on_time_updated")
    TimeManager.connect("day_changed", self, "_on_day_changed")
    TimeManager.connect("season_changed", self, "_on_season_changed")
    
    # Initial weather update
    _update_weather()

func _on_time_updated(hour, minute):
    # Update disaster duration
    if current_disaster:
        disaster_time_remaining -= 1
        if disaster_time_remaining <= 0:
            _end_disaster()
    
    # Random weather changes
    if hour % 3 == 0 and minute == 0:  # Check every 3 hours
        if randf() < 0.3:  # 30% chance
            _update_weather()

func _on_day_changed(day):
    # Guaranteed weather change on new day
    _update_weather()

func _on_season_changed(season):
    # Update weather probabilities based on season
    _update_weather_probabilities(season)
    _update_weather()

func _update_weather():
    var old_weather = current_weather
    var probabilities = _get_weather_probabilities()
    
    # Choose new weather based on probabilities
    var roll = randf()
    var cumulative = 0
    
    for weather in probabilities:
        cumulative += probabilities[weather]
        if roll <= cumulative:
            current_weather = weather
            break
    
    if current_weather != old_weather:
        emit_signal("weather_changed", current_weather)
        Events.emit_signal("notification", "The weather has changed to " + current_weather, "info")

func _get_weather_probabilities():
    var season = TimeManager.current_season
    var time = TimeManager.current_hour
    
    # Base probabilities
    var probabilities = {
        "sunny": 0.5,
        "rainy": 0.2,
        "stormy": 0.1,
        "foggy": 0.1,
        "windy": 0.1
    }
    
    # Modify based on season
    match season:
        "spring":
            probabilities["rainy"] += 0.2
            probabilities["sunny"] -= 0.1
        "summer":
            probabilities["sunny"] += 0.2
            probabilities["stormy"] += 0.1
        "fall":
            probabilities["windy"] += 0.2
            probabilities["foggy"] += 0.1
        "winter":
            probabilities["sunny"] -= 0.2
            probabilities["stormy"] += 0.1
    
    # Modify based on time
    if time >= 20 or time <= 5:  # Night
        probabilities["foggy"] += 0.1
    
    return probabilities

func start_disaster(disaster_type):
    if disaster_type in DISASTERS and not current_disaster:
        current_disaster = disaster_type
        disaster_time_remaining = DISASTERS[disaster_type]["duration"]
        
        emit_signal("natural_disaster_started", disaster_type)
        Events.emit_signal("notification", "Warning: " + disaster_type.capitalize() + " incoming!", "warning")

func _end_disaster():
    if current_disaster:
        emit_signal("natural_disaster_ended", current_disaster)
        Events.emit_signal("notification", "The " + current_disaster + " has ended", "info")
        current_disaster = null
        disaster_time_remaining = 0

func get_current_effects():
    var effects = WEATHER_TYPES[current_weather].duplicate()
    
    # Add disaster effects if active
    if current_disaster:
        var disaster = DISASTERS[current_disaster]
        for key in disaster:
            if key != "duration":
                effects[key] = disaster[key]
    
    return effects

func check_lightning_strike():
    if current_weather == "stormy":
        if randf() < WEATHER_TYPES["stormy"]["lightning_chance"]:
            return true
    return false

func is_crop_watered_by_rain():
    return current_weather == "rainy" and WEATHER_TYPES["rainy"]["auto_water"]