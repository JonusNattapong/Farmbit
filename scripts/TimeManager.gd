extends Node

# Time constants
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const DAYS_PER_SEASON = 28
const SEASONS_PER_YEAR = 4

# Day/Night cycle
var is_night_time = false
var night_start_hour = 22  # 10 PM
var night_end_hour = 6     # 6 AM
# Time tracking
var current_minute = 0
var current_hour = 6  # Start at 6 AM
var current_day = 1
var current_season = "spring"  # spring, summer, fall, winter
var current_year = 1

# Time flow settings
var time_flowing = true
var time_scale = 1.0  # Time multiplier
var minutes_per_real_second = 10.0  # How many game minutes pass per real second

# Season names and order
var seasons = ["spring", "summer", "fall", "winter"]

# Tracking real time for updates
var time_accumulator = 0.0

func _ready():
    # Initialize time system
    print("TimeManager initialized")

func _process(delta):
    if time_flowing:
        time_accumulator += delta * time_scale
        
        # Check if enough real time has passed to increment game time
        var minutes_to_add = floor(time_accumulator * minutes_per_real_second)
        
        if minutes_to_add >= 1:
            add_minutes(minutes_to_add)
            time_accumulator -= minutes_to_add / minutes_per_real_second

func add_minutes(amount):
    current_minute += amount
    
    # Handle minute overflow to hours
    if current_minute >= MINUTES_PER_HOUR:
        var hours_to_add = floor(current_minute / MINUTES_PER_HOUR)
        current_minute = current_minute % MINUTES_PER_HOUR
        add_hours(hours_to_add)
    
    Events.emit_signal("time_updated", current_hour, current_minute)
    _check_day_night_cycle()

func add_hours(amount):
    current_hour += amount
    
    # Handle hour overflow to days
    if current_hour >= HOURS_PER_DAY:
        var days_to_add = floor(current_hour / HOURS_PER_DAY)
        current_hour = current_hour % HOURS_PER_DAY
        add_days(days_to_add)

func add_days(amount):
    current_day += amount
    
    # Handle day overflow to seasons
    if current_day > DAYS_PER_SEASON:
        var seasons_to_add = floor((current_day - 1) / DAYS_PER_SEASON)
        current_day = ((current_day - 1) % DAYS_PER_SEASON) + 1
        add_seasons(seasons_to_add)
    
    Events.emit_signal("day_changed", current_day)

func add_seasons(amount):
    var current_season_index = seasons.find(current_season)
    var new_season_index = (current_season_index + amount) % SEASONS_PER_YEAR
    
    # Handle season overflow to years
    var years_to_add = floor((current_season_index + amount) / SEASONS_PER_YEAR)
    
    if years_to_add > 0:
        add_years(years_to_add)
    
    current_season = seasons[new_season_index]
    Events.emit_signal("season_changed", current_season)

func add_years(amount):
    current_year += amount
    Events.emit_signal("year_changed", current_year)

func is_night():
    return is_night_time

func _check_day_night_cycle():
    # Check if it's nighttime (between night_start_hour and night_end_hour)
    var should_be_night = (current_hour >= night_start_hour or current_hour < night_end_hour)
    
    # If state should change, trigger appropriate events
    if should_be_night and not is_night_time:
        is_night_time = true
        _start_night()
    elif not should_be_night and is_night_time:
        is_night_time = false
        _start_day()

func _start_night():
    Events.emit_signal("night_started")
    Events.emit_signal("notification", "Night has fallen... Be careful!", "warning")

func _start_day():
    Events.emit_signal("day_started")
    Events.emit_signal("notification", "A new day begins.", "info")
    Events.emit_signal("year_changed", current_year)

func get_time_string():
    var am_pm = "AM"
    var display_hour = current_hour
    
    if display_hour >= 12:
        am_pm = "PM"
        if display_hour > 12:
            display_hour -= 12
    
    if display_hour == 0:
        display_hour = 12
    
    return "%d:%02d %s" % [display_hour, current_minute, am_pm]

func get_date_string():
    return "Year %d, %s %d" % [current_year, current_season.capitalize(), current_day]

func is_night():
    return current_hour >= 20 or current_hour < 6

func pause_time():
    time_flowing = false

func resume_time():
    time_flowing = true

func set_time(hour, minute):
    current_hour = hour
    current_minute = minute
    Events.emit_signal("time_updated", current_hour, current_minute)

func set_date(day, season, year):
    current_day = day
    
    if season in seasons:
        current_season = season
    
    current_year = year
    
    Events.emit_signal("day_changed", current_day)
    Events.emit_signal("season_changed", current_season)
    Events.emit_signal("year_changed", current_year)

func _emit_all_time_signals():
    # Utility function to emit all time signals - useful after loading a game
    Events.emit_signal("time_updated", current_hour, current_minute)
    Events.emit_signal("day_changed", current_day)
    Events.emit_signal("season_changed", current_season)
    Events.emit_signal("year_changed", current_year)