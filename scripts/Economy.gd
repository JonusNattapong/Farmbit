extends Node

signal money_changed(amount)
signal item_price_changed(item_id, new_price)

var player_money = 1000

var item_prices = {
    "carrot_seed": 10,
    "potato_seed": 15,
    "wheat_seed": 20
}

func add_money(amount):
    player_money += amount
    emit_signal("money_changed", player_money)

func remove_money(amount):
    player_money -= amount
    emit_signal("money_changed", player_money)

func get_item_price(item_id):
    if item_id in item_prices:
        return item_prices[item_id]
    return 0

func set_item_price(item_id, new_price):
    item_prices[item_id] = new_price
    emit_signal("item_price_changed", item_id, new_price)

func buy_item(item_id, amount):
    var price = get_item_price(item_id)
    if player_money >= price * amount:
        remove_money(price * amount)
        return true
    return false

func sell_item(item_id, amount):
    add_money(get_item_price(item_id) * amount)

func has_item(item_id, amount=1):
    return GameData.inventory.has(item_id) and GameData.inventory[item_id] >= amount

func add_item_to_inventory(item_id, amount):
    if item_id in GameData.inventory:
        GameData.inventory[item_id] += amount
    else:
        GameData.inventory[item_id] = amount

func remove_item_from_inventory(item_id, amount):
    if item_id in GameData.inventory:
        GameData.inventory[item_id] = max(0, GameData.inventory[item_id] - amount)