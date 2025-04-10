extends Node

class_name MapSystem

# ระบบแผนที่แบบไดนามิก
var world_map = {}
var discovered_areas = {}
var current_region = "farm"
var map_texture = preload("res://assets/maps/world_map.png")

# โครงสร้างข้อมูลแผนที่
var map_data = {
    "farm": {
        "position": Vector2(400, 300),
        "size": Vector2(800, 600),
        "connections": ["forest", "town"],
        "enemies": [],
        "resources": ["carrot", "potato"]
    },
    "forest": {
        "position": Vector2(200, 100),
        "size": Vector2(1000, 800),
        "connections": ["farm", "mountain"],
        "enemies": ["zombie"],
        "resources": ["wood", "herbs"]
    },
    "town": {
        "position": Vector2(600, 400),
        "size": Vector2(500, 500),
        "connections": ["farm", "dock"],
        "enemies": [],
        "resources": ["shop", "inn"]
    }
}

func _ready():
    # เริ่มต้นระบบแผนที่
    init_map_system()
    discover_region(current_region)

func init_map_system():
    # โหลดข้อมูลแผนที่จากไฟล์
    var file = File.new()
    if file.file_exists("user://map_data.json"):
        file.open("user://map_data.json", File.READ)
        world_map = parse_json(file.get_as_text())
        file.close()
    else:
        world_map = map_data
        save_map_data()

func discover_region(region_name):
    # เปิดเผยพื้นที่ใหม่
    if not discovered_areas.has(region_name):
        discovered_areas[region_name] = true
        Events.emit_signal("region_discovered", region_name)
        save_map_data()

func travel_to_region(region_name):
    # เดินทางไปยังพื้นที่ใหม่
    if world_map[current_region]["connections"].has(region_name):
        current_region = region_name
        discover_region(region_name)
        Events.emit_signal("region_changed", region_name)
        return true
    return false

func get_current_region_data():
    # รับข้อมูลพื้นที่ปัจจุบัน
    return world_map.get(current_region, {})

func get_discovered_regions():
    # รับรายการพื้นที่ที่ค้นพบแล้ว
    var regions = []
    for region in discovered_areas:
        if discovered_areas[region]:
            regions.append(region)
    return regions

func save_map_data():
    # บันทึกข้อมูลแผนที่
    var file = File.new()
    file.open("user://map_data.json", File.WRITE)
    file.store_string(to_json({
        "world_map": world_map,
        "discovered_areas": discovered_areas,
        "current_region": current_region
    }))
    file.close()

func load_map_texture():
    # โหลดพื้นผิวแผนที่
    return map_texture

func generate_minimap():
    # สร้างแผนที่ย่อ
    var minimap = {}
    for region in world_map:
        if discovered_areas.get(region, false):
            minimap[region] = {
                "position": world_map[region]["position"],
                "connections": world_map[region]["connections"]
            }
    return minimap

func update_map_resources(region, resource_type, amount):
    # อัพเดททรัพยากรบนแผนที่
    if world_map.has(region):
        if not world_map[region].has("dynamic_resources"):
            world_map[region]["dynamic_resources"] = {}
        
        world_map[region]["dynamic_resources"][resource_type] = \
            world_map[region]["dynamic_resources"].get(resource_type, 0) + amount
        
        save_map_data()

func get_region_resources(region):
    # รับทรัพยากรในพื้นที่
    var resources = []
    if world_map.has(region):
        resources = world_map[region].get("resources", [])
        if world_map[region].has("dynamic_resources"):
            for res in world_map[region]["dynamic_resources"]:
                if world_map[region]["dynamic_resources"][res] > 0:
                    resources.append(res)
    return resources

func add_custom_marker(region, marker_name, position, marker_type="custom"):
    # เพิ่มเครื่องหมายกำหนดเองบนแผนที่
    if world_map.has(region):
        if not world_map[region].has("markers"):
            world_map[region]["markers"] = {}
        
        world_map[region]["markers"][marker_name] = {
            "position": {"x": position.x, "y": position.y},
            "type": marker_type
        }
        save_map_data()

func remove_custom_marker(region, marker_name):
    # ลบเครื่องหมายกำหนดเอง
    if world_map.has(region) and world_map[region].has("markers"):
        world_map[region]["markers"].erase(marker_name)
        save_map_data()