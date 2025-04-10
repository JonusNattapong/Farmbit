# เอกสารทางเทคนิค Farmbit

## โครงสร้างโปรเจค
```
Farmbit/
├── assets/        # ทรัพยากรเกม
├── docs/          # เอกสาร
├── scenes/        # ฉากเกม
└── scripts/       # โค้ดเกม
```

## ระบบหลัก
1. **Core Systems**
   - GameData: จัดการข้อมูลเกม
   - Events: ระบบ Event Bus
   - TimeManager: จัดการเวลาในเกม

2. **Gameplay Systems**
   - Farming: ระบบทำฟาร์ม
   - Mining: ระบบขุดแร่
   - Crafting: ระบบคราฟต์

3. **AI Systems**
   - NPC AI
   - Enemy AI
   - Pet AI

## API หลัก

### GameData
```gdscript
save_data(data: Dictionary) -> void
load_data() -> Dictionary
```

### Events 
```gdscript
emit_signal(event_name: String, ...args) -> void
connect(event_name: String, target: Object, method: String) -> void
```

### TimeManager
```gdscript
get_current_time() -> Dictionary
advance_time(hours: int) -> void
```

## คู่มือ Developer
1. **การเพิ่มไอเทมใหม่**
   - สร้างสคริปต์ใน `scripts/items/`
   - ลงทะเบียนใน `GameData.item_db`

2. **การสร้างฉากใหม่**
   - สร้างไฟล์ `.tscn` ใน `scenes/`
   - ลงทะเบียนใน `MapSystem`

3. **การดีบัก**
   - ใช้ `Debug.log()` แทน `print()`
   - เปิดโหมด Debug ใน `project.godot`

## สิ่งที่ต้องพัฒนาเพิ่ม
- [ ] ระบบ Multiplayer
- [ ] ระบบ Modding
- [ ] ระบบ Cloud Save

เวอร์ชันเอกสาร: 1.0  
อัพเดทล่าสุด: 10 เมษายน 2025