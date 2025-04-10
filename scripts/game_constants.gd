extends Node

# Time constants
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const DAYS_PER_SEASON = 28
const SEASONS_PER_YEAR = 4
const SEASON_NAMES = ["Spring", "Summer", "Fall", "Winter"]

# Player constants
const STARTING_MONEY = 1000
const STARTING_ENERGY = 100
const MAX_ENERGY = 100
const ENERGY_RESTORE_SLEEP = 100
const INVENTORY_CAPACITY = 20

# Movement constants
const PLAYER_SPEED = 100
const NPC_SPEED = 40

# Farm constants
const TILE_SIZE = 16
const FARM_GRID_WIDTH = 20
const FARM_GRID_HEIGHT = 15
const MAX_FARM_LEVEL = 5

# Tool energy costs
const ENERGY_COST = {
    "hoe": 2,
    "watering_can": 1,
    "axe": 4,
    "hammer": 4,
    "fishing_rod": 3
}

# NPC relationship levels
const RELATIONSHIP_LEVELS = {
    0: "Stranger",
    2: "Acquaintance",
    4: "Friend",
    6: "Close Friend",
    8: "Best Friend",
    10: "Family"
}

# Item quality levels
const QUALITY_LEVELS = {
    0: "Poor",
    1: "Normal",
    2: "Silver",
    3: "Gold",
    4: "Iridium"
}

# Quality multipliers for selling price
const QUALITY_MULTIPLIERS = {
    0: 0.75,  # Poor quality
    1: 1.0,   # Normal quality
    2: 1.25,  # Silver quality
    3: 1.5,   # Gold quality
    4: 2.0    # Iridium quality
}