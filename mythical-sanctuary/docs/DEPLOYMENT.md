# Installation & Deployment Guide

## 1. เปิดเล่นทันที (ไม่ต้องติดตั้งอะไร)
1. เปิดไฟล์ `MythicalSanctuary.rbxlx` ใน Roblox Studio
2. **View → Output** เพื่อดู log
3. กด **Play** — เซิร์ฟเวอร์จะปั้นภูมิประเทศ (ครั้งแรกอาจใช้ 10–40 วินาที) แล้วจึงให้ตัวละครเกิด
4. กด "เริ่มการผจญภัย" ที่หน้าจอเปิด

## 2. พัฒนาต่อด้วย Rojo
```bash
cd mythical-sanctuary
rojo serve            # แล้วกด Connect ในปลั๊กอิน Rojo ของ Studio
rojo build -o MythicalSanctuary.rbxlx
```

## 3. Bake ภูมิประเทศ (แนะนำมาก)
เพื่อให้เปิดเซิร์ฟเร็ว และให้ Environment Artist ปั้น Terrain ต่อด้วยมือ:
1. เปิดไฟล์ใน Studio (โหมด Edit ไม่ต้องกด Play)
2. Command Bar:
   ```lua
   require(game.ServerScriptService.Server.World.TerrainBuilder).BuildWorld(true)
   ```
3. ใช้เครื่องมือ Terrain Editor ปั้น/ทาสีเพิ่ม (หน้าผา, ทางลับ, พื้นที่ซ่อน) แล้ว **Save**
4. Workspace จะมี Attribute `WorldBaked = true` → เกมจะไม่สร้างทับอีก
> ⚠️ ถ้าแก้ `WorldLayout` (แม่น้ำ/ทางเดิน/ถ้ำ) ต้อง Bake ใหม่ — งานปั้นมือจะถูกเขียนทับ ให้ล็อกเลย์เอาต์ก่อนเริ่มปั้น

## 4. นำ Asset จริงเข้าเกม (สำหรับ 3D Artist)
1. Blender → Export FBX ตาม `ASSET_SPEC.md` (Scale, แกน, Apply Transforms)
2. Studio → **3D Importer** → ตั้งชื่อ Model ให้ตรง Key ใน `AssetRegistry.lua`
3. ตั้ง Pivot = กึ่งกลางฐาน, ด้านหน้าหันแกน -Z
4. วางไว้ใน `ReplicatedStorage/Assets/` (สร้างโฟลเดอร์ชื่อ `Assets` ถ้ายังไม่มี)
5. Play — Greybox ของ Key นั้นจะถูกแทนที่อัตโนมัติ
6. ตรวจว่ายังเหลือ Greybox อะไร: `require(game.ReplicatedStorage.Shared.AssetLibrary).Report()`

**สัตว์:** `Creature_<speciesId>_<Egg|Baby|Juvenile|Adult>` ต้องมี `HumanoidRootPart`, `Humanoid` + `Animator` และโฟลเดอร์ `Animations` (Animation objects ชื่อ Idle, Walk, Run, Sleep, Eat, Drink, Play, Happy, Scared, Ability)
**NPC:** `NPC_<npcId>` (R15)
**เสียง:** อัปโหลดแล้วใส่ ID ใน `AssetRegistry.Sounds`
**ไอคอน:** ใส่ใน `AssetRegistry.Icons[IconKey] = "rbxassetid://..."`

## 5. ก่อนเผยแพร่จริง
- [ ] Game Settings → Security → **Enable Studio Access to API Services** (ทดสอบ DataStore)
- [ ] ทดสอบ 2 ผู้เล่น: **Test → Clients and Servers** (ตรวจเกาะแยก, สัตว์ภารกิจแยก, session lock)
- [ ] ทำ `PERFORMANCE_TEST_PLAN.md` บน PC + มือถือระดับกลางจริง
- [ ] ไม่มี Greybox ในพื้นที่ที่ส่งมอบ (`AssetLibrary.Report()` ว่าง)
- [ ] เสียง/เพลงทั้งหมดมีสิทธิ์ใช้งาน
- [ ] ตอบ Experience Questionnaire ตามจริง
- [ ] File → Publish to Roblox
