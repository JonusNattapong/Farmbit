extends CanvasLayer

onready var rain_particles = $RainParticles
onready var snow_particles = $SnowParticles
onready var lightning_flash = $LightningFlash
onready var fog_overlay = $FogOverlay
onready var wind_particles = $WindParticles
onready var overlay = $WeatherOverlay
var current_weather = "sunny"
var wind_direction = Vector2.RIGHT
var active_effects = []

func _ready():
    # Connect to weather signals
    WeatherManager.connect("weather_changed", self, "_on_weather_changed")
    WeatherManager.connect("natural_disaster_started", self, "_on_disaster_started")
    WeatherManager.connect("natural_disaster_ended", self, "_on_disaster_ended")

    # Initialize effects
    _stop_all_effects()

func _process(delta):
    # Update wind direction for particles
    if current_weather == "windy":
        wind_direction = wind_direction.rotated(delta * 0.01)  # Reduced rotation speed
        wind_particles.process_material.direction = Vector3(wind_direction.x, wind_direction.y, 0)

func _on_weather_changed(new_weather):
    current_weather = new_weather
    _stop_all_effects()

    match new_weather:
        "rainy":
            _start_rain()
        "stormy":
            _start_storm()
        "foggy":
            _start_fog()
        "windy":
            _start_wind()
        "snowy":
            _start_snow()

func _on_disaster_started(disaster_type):
    match disaster_type:
        "tornado":
            _start_tornado()
        "flood":
            _start_flood()
        "drought":
            _start_drought()
        "blizzard":
            _start_blizzard()

func _stop_all_effects():
    rain_particles.emitting = false
    snow_particles.emitting = false
    wind_particles.emitting = false
    lightning_flash.hide()
    fog_overlay.hide()
    overlay.modulate = Color(1, 1, 1, 0)

func _start_rain():
    rain_particles.emitting = true
    active_effects.append(rain_particles)
    overlay.modulate = Color(0.7, 0.7, 0.8, 0.2)

func _start_storm():
    rain_particles.emitting = true
    rain_particles.amount = 500  # Reduced particle amount
    rain_particles.speed_scale = 1  # Reduced speed scale
    overlay.modulate = Color(0.4, 0.4, 0.5, 0.4)
    _start_lightning()

func _start_fog():
    fog_overlay.show()
    fog_overlay.modulate = Color(1, 1, 1, 0.7)

func _start_wind():
    wind_particles.emitting = true
    active_effects.append(wind_particles)
    overlay.modulate = Color(0.9, 0.9, 0.9, 0.1)

func _start_snow():
    snow_particles.emitting = true
    active_effects.append(snow_particles)
    overlay.modulate = Color(1, 1, 1, 0.2)

func _start_tornado():
    wind_particles.emitting = true
    wind_particles.amount = 1000  # Reduced particle amount
    wind_particles.speed_scale = 1  # Reduced speed scale
    overlay.modulate = Color(0.6, 0.6, 0.6, 0.5)

func _start_flood():
    rain_particles.emitting = true
    rain_particles.amount = 1000  # Reduced particle amount
    overlay.modulate = Color(0.5, 0.5, 0.7, 0.6)

func _start_drought():
    overlay.modulate = Color(1, 0.8, 0.6, 0.3)

func _start_blizzard():
    snow_particles.emitting = true
    snow_particles.amount = 1000  # Reduced particle amount
    snow_particles.speed_scale = 1  # Reduced speed scale
    overlay.modulate = Color(0.8, 0.8, 0.9, 0.5)

func _start_lightning():
    _schedule_next_lightning()

func _on_lightning_timer_timeout():
    if current_weather == "stormy":
        _flash_lightning()
        _schedule_next_lightning()

func _flash_lightning():
    lightning_flash.show()

    # Reuse tween for flash effect
    if not has_node("LightningTween"):
        var tween = Tween.new()
        add_child(tween)
    else:
        tween = $LightningTween

    tween.interpolate_property(lightning_flash, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(lightning_flash, "modulate", Color(1, 1, 0.05, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_all_completed")
    lightning_flash.hide()

func _schedule_next_lightning():
    if current_weather == "stormy":
        var next_strike = rand_range(5, 15)  # Random time between 5-15 seconds
        lightning_timer.start(next_strike)

func _on_enemy_died(enemy_type, position):
    # Remove from active zombies list
    if active_effects.has(rain_particles):
        active_effects.remove(rain_particles)
    if active_effects.has(snow_particles):
        active_effects.remove(snow_particles)
    if active_effects.has(wind_particles):
        active_effects.remove(wind_particles)
    active_effects.clear()
func _process(delta):
    # Update wind direction for particles
    if current_weather == "windy":
        wind_direction = wind_direction.rotated(delta * 0.1)
        wind_particles.process_material.direction = Vector3(wind_direction.x, wind_direction.y, 0)

func _on_weather_changed(new_weather):
    current_weather = new_weather
    _stop_all_effects()
    
    match new_weather:
        "rainy":
            _start_rain()
        "stormy":
            _start_storm()
        "foggy":
            _start_fog()
        "windy":
            _start_wind()
        "snowy":
            _start_snow()

func _on_disaster_started(disaster_type):
    match disaster_type:
        "tornado":
            _start_tornado()
        "flood":
            _start_flood()
        "drought":
            _start_drought()
        "blizzard":
            _start_blizzard()

func _on_disaster_ended(disaster_type):
    _on_weather_changed(current_weather)  # Reset to current weather effects

func _stop_all_effects():
    rain_particles.emitting = false
    snow_particles.emitting = false
    lightning_flash.hide()
    fog_overlay.hide()
    wind_particles.emitting = false
    overlay.modulate = Color(1, 1, 1, 0)

func _start_rain():
    rain_particles.emitting = true
    overlay.modulate = Color(0.7, 0.7, 0.8, 0.2)

func _start_storm():
    rain_particles.emitting = true
    rain_particles.amount = 1000
    rain_particles.speed_scale = 2
    overlay.modulate = Color(0.4, 0.4, 0.5, 0.4)
    _start_lightning()

func _start_fog():
    fog_overlay.show()
    fog_overlay.modulate = Color(1, 1, 1, 0.7)

func _start_wind():
    wind_particles.emitting = true
    overlay.modulate = Color(0.9, 0.9, 0.9, 0.1)

func _start_snow():
    snow_particles.emitting = true
    overlay.modulate = Color(1, 1, 1, 0.2)

func _start_tornado():
    wind_particles.emitting = true
    wind_particles.amount = 2000
    wind_particles.speed_scale = 3
    overlay.modulate = Color(0.6, 0.6, 0.6, 0.5)

func _start_flood():
    rain_particles.emitting = true
    rain_particles.amount = 2000
    overlay.modulate = Color(0.5, 0.5, 0.7, 0.6)

func _start_drought():
    overlay.modulate = Color(1, 0.8, 0.6, 0.3)

func _start_blizzard():
    snow_particles.emitting = true
    snow_particles.amount = 2000
    snow_particles.speed_scale = 2
    overlay.modulate = Color(0.8, 0.8, 0.9, 0.5)

func _start_lightning():
    _schedule_next_lightning()

func _on_lightning_timer_timeout():
    if current_weather == "stormy":
        _flash_lightning()
        _schedule_next_lightning()

func _flash_lightning():
    lightning_flash.show()
    
    # Create tween for flash effect
    var tween = create_tween()
    tween.tween_property(lightning_flash, "modulate", Color(1, 1, 1, 0), 0.1)
    tween.tween_property(lightning_flash, "modulate", Color(1, 1, 1, 1), 0.05)
    tween.tween_property(lightning_flash, "modulate", Color(1, 1, 1, 0), 0.2)
    
    # Hide after flash
    yield(tween, "finished")
    lightning_flash.hide()
    
    # Notify weather manager to check for strikes
    if WeatherManager.check_lightning_strike():
        Events.emit_signal("lightning_strike")

func _schedule_next_lightning():
    if current_weather == "stormy":
        var next_strike = rand_range(5, 15)  # Random time between 5-15 seconds
        lightning_timer.start(next_strike)