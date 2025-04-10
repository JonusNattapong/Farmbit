extends Node

# Player signals
signal update_energy(current, maximum)
signal energy_changed(amount)
signal health_changed(current, maximum)
signal money_changed(new_amount)
signal inventory_changed(inventory)
signal tool_selected(tool_id)
signal item_selected(item_id)
signal item_used(item_id)
signal player_died()
signal player_respawned()

# Combat signals
signal enemy_spawned(enemy_type, position)
signal enemy_died(enemy_type, position)
signal spawn_item(item_id, position)
signal spawn_zombie(position)
signal boss_spawned(boss_type, position)
signal boss_defeated()
signal damage_dealt(amount, target)
signal weapon_equipped(weapon_id)
signal armor_equipped(armor_id)

# Farm related signals
signal till_soil(position)
signal water_soil(position)
signal plant_seed(position, seed_id)
signal harvest_crop(position)
signal feed_animal(position, feed_id)
signal pet_animal(position)
signal collect_animal_product(position)

# Time signals
signal time_updated(hour, minute)
signal day_changed(day)
signal season_changed(season)
signal year_changed(year)
signal night_started()  # For zombie spawning
signal day_started()    # For zombie despawning

# UI signals
signal notification(message, type)
signal dialog_open(dialog_text, npc_name, options)
signal dialog_closed()
signal shop_opened(shop_inventory)
signal shop_closed()
signal quest_updated(quest_id, status)
signal quest_completed(quest_id)
signal combat_stats_updated(health, energy)

# NPC signals
signal npc_relationship_changed(npc_id, relationship_level)
signal npc_gift_given(npc_id, item_id)

# Game state signals
signal game_saved()
signal game_loaded()
signal game_paused()
signal game_resumed()

# Weather signals
signal weather_changed(weather_type)
signal weather_effect_started(effect_type)
signal weather_effect_ended(effect_type)
signal lightning_strike()
signal crop_damaged_by_weather(amount)
signal player_damaged_by_weather(amount)
signal natural_disaster_warning(disaster_type)
signal natural_disaster_started(disaster_type)
signal natural_disaster_ended(disaster_type)

# Pet signals
signal pet_obtained(pet_id)
signal pet_leveled_up(pet_id, new_level)
signal pet_skill_unlocked(pet_id, skill_id)
signal pet_mood_changed(pet_id, new_mood)
signal pet_stats_updated(pet_id, stats)
signal pet_attack(pet_id, damage)
signal pet_guarding_area(pet_id)
signal pet_herding_started(pet_id)
signal pet_harvest_boost(pet_id)
signal pet_message_delivery(pet_id)
signal pet_command_menu_opened(pet_id)

# Cooking signals
signal cooking_started(recipe)
signal cooking_completed(recipe)
signal cooking_failed(reason)
signal recipe_unlocked(recipe_id)
signal cooking_status_changed(status, message)

func _ready():
    print("Events singleton initialized")