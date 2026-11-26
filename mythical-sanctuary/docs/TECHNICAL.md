# Technical Documentation — Mythical Sanctuary (Phase 1)

## 1. โครงสร้างโปรเจกต์ (Rojo)

```
mythical-sanctuary/
├── default.project.json          Rojo: Shared → ReplicatedStorage, Server → ServerScriptService, Client → StarterPlayerScripts
│                                 Workspace.StreamingEnabled = true, Lighting.Technology = Future
├── src/shared/                   ใช้ร่วมกันทั้งสองฝั่ง (ข้อมูล + กฎ)
│   ├── Config.lua                ตัวเลขปรับสมดุลทั้งหมด
│   ├── Species.lua               สัตว์ 8 สายพันธุ์ (Phase 1 เปิด 3)
│   ├── Items.lua                 ไอเท็ม + สูตรปรุงยา
│   ├── Quests.lua                ภารกิจบทนำ 8 บท
│   ├── WorldLayout.lua           แผนผังโลก (Composition data)
│   ├── LightingProfiles.lua      แสงต่อโซน × กลางวัน/กลางคืน
│   ├── AssetRegistry.lua         รายการ Asset ↔ Spec ID
│   ├── AssetLibrary.lua          โหลดโมเดลจริง หรือ Greybox
│   ├── Placement.lua             กฎวางของในเขตอนุรักษ์ (client preview + server validate)
│   └── Net.lua                   Remote ทั้งหมด + rate limit + pcall
├── src/server/
│   ├── init.server.lua           Bootstrap (ลำดับเริ่มระบบ)
│   ├── Data/DataService.lua
│   ├── World/{TerrainBuilder, WorldPopulator, EnvironmentService, NpcService}.lua
│   ├── Creatures/{CreatureFactory, CreatureService, CreatureCare}.lua
│   ├── Sanctuary/SanctuaryService.lua
│   └── Gameplay/{Inventory, QuestService, EconomyService}.lua
└── src/client/
    ├── init.client.lua, State.lua, Interactions.lua
    ├── World/{Atmosphere, Audio}.lua
    └── UI/{Theme, Toast, Hud, Journal, Windows, CreaturePanel, SanctuaryEditor, MainMenu}.lua
```

## 2. Dependency Graph (server)

```
DataService ◄── Inventory ◄── QuestService ◄── EconomyService
     ▲              ▲              ▲
     │              └──────┬───────┘
CreatureFactory ◄── CreatureService ◄── CreatureCare ◄── SanctuaryService
TerrainBuilder ◄── WorldPopulator / NpcService / SanctuaryService
```
ไม่มี require วน — การสื่อสารย้อนกลับใช้ callback injection (`CreatureCare.OnCreatureAdded`, `CreatureService.OnDiscover`)

## 3. Server-authoritative

Client ส่งแค่ "เจตนา" ผ่าน RemoteFunction ทุกตัวถูกห่อด้วย `Net.Handle` (rate limit + pcall)
เซิร์ฟเวอร์ตรวจ: ระยะทางจริง (ร้าน/หม้อยา/สมุนไพร/สัตว์), ของในกระเป๋า, ความเป็นเจ้าของ, ขอบเขตเขตอนุรักษ์, การชน, cooldown
ตั้งชื่อสัตว์ผ่าน `TextService:FilterStringAsync` (ข้อบังคับ Roblox)

| Remote | ทิศทาง | หน้าที่ |
|---|---|---|
| ProfileChanged / GetProfile | S→C | snapshot ข้อมูลผู้เล่น |
| WorldState | S→C | อากาศ + ช่วงเวลา |
| CreatureFeedback | S→C | อารมณ์/ความไว้วางใจของสัตว์ |
| Discovery | S→C | ค้นพบสัตว์/สถานที่ |
| SetSneaking | C→S | ย่อตัว (มีผลต่อ AI) |
| CreatureAction | C→S | Offer/Calm/Bond/Feed/Pet/Play/Follow/Rename |
| Forage / Craft / Buy / Sell | C→S | เศรษฐกิจ |
| TravelSanctuary / PlaceObject / MoveObject / RemoveObject / UseIncubator | C→S | เขตอนุรักษ์ |
| TalkToNpc / TrackQuest / SaveSettings | C→S | อื่น ๆ |

## 4. Data Schema (DataStore: `MythicalSanctuary_Player`, key `player_<UserId>`)

```lua
{ Data = {
    Version = 2, Coins, Level, XP,
    Inventory = { [itemId] = count },
    Creatures = { ["c1"] = { Species, Name, Stage, Personality, Hunger, Energy, Joy, CareXP, Born, Origin, Following } },
    Bestiary  = { [speciesId] = { Seen, FirstSeen, Bonded } },
    Landmarks = { [landmarkId] = timestamp },
    Quests    = { Active = { [questId] = { ["1"] = progress } }, Done = { [questId] = t }, Tracked },
    Sanctuary = { Objects = { ["o1"] = { Item, X, Z, Rot, Egg?, HatchAt? } }, NextId, Expansion },
    Settings  = { Music, Sfx, Graphics, ShowHints },
    Stats     = { Rescued, Bonded, Hatched, Foraged, Brewed },
    LastOnline, NextCreatureId },
  Lock = { JobId, Time } }
```
- **Session Lock:** `UpdateAsync` ตั้ง Lock = JobId ปัจจุบัน; ถ้าเซิร์ฟอื่นถือล็อกอยู่ (< 30 นาที) จะรอ+ลองใหม่ 6 ครั้งแล้วค่อย Kick; ตอนออกเกมปลดล็อก
- **Migration:** เพิ่ม `Config.DataVersion` + ฟังก์ชันใน `migrations[N]` (N→N+1)
- **Save:** JSON round-trip ก่อนบันทึก (กัน non-serializable), ปฏิเสธการเขียนทับถ้าล็อกเป็นของเซิร์ฟอื่น

## 5. Creature AI

State machine ต่อ entity (ตาราง Lua ฝั่งเซิร์ฟเวอร์), Heartbeat เดียววนทุก entity:

| ระยะผู้เล่นใกล้สุด | ความถี่คิด | การทำงาน |
|---|---|---|
| ≤ 160 | 0.25 วิ | เต็มรูปแบบ |
| ≤ 420 | 2 วิ | เต็มรูปแบบ (หยาบ) |
| > 420 | 3 วิ (ตรวจระยะอย่างเดียว) | Dormant: หยุดเดิน ไม่คำนวณ |

การเคลื่อนที่: < 40 studs ใช้ `Humanoid:MoveTo`, ไกลกว่านั้นใช้ `PathfindingService` (async, ยกเลิกได้ด้วย token)
แอนิเมชัน: ถ้าโมเดลมีโฟลเดอร์ `Animations` จะเล่นผ่าน Animator ตามชื่อ (Idle/Walk/Run/Sleep/Eat/Drink/Play/Happy/Scared/Ability) และตั้ง Attribute `Anim` ให้ client ทุกครั้ง

## 6. Performance Strategy

| เทคนิค | ที่ใช้ |
|---|---|
| Instance Streaming | `Workspace.StreamingEnabled`, โมเดลตั้ง `ModelStreamingMode = Atomic` |
| AI LOD | ตามตารางข้อ 5 |
| จำกัดไฟ | client เปิดเฉพาะ PointLight ที่ใกล้สุด N ดวง (Low 6 / Medium 14 / High 28) |
| อนุภาค | rig เดียวรอบกล้อง, อัตราปล่อยตามระดับกราฟิก |
| Terrain | สร้างครั้งเดียว + แนะนำ Bake (ไม่ต้องสร้างทุกครั้งที่เปิดเซิร์ฟ) |
| Greybox พืช | CanQuery/CanCollide ปิดในของเล็ก, CastShadow ปิดในพุ่มไม้ |
| ต้องทำเมื่อมี Mesh จริง | LOD (RenderFidelity Automatic), Texture Atlas, CollisionFidelity Box สำหรับ prop เล็ก |

## 7. การขยายระบบ (How-to)

- **เพิ่มสัตว์:** เพิ่มใน `Species.lua` (Phase = 1) + ใส่ใน `WorldLayout.SpawnAreas` + ส่งโมเดล `Creature_<id>_<Stage>`
- **เพิ่มของตกแต่ง:** `Items.lua` (Placeable, Footprint, AssetKey) + `AssetRegistry.Environment[AssetKey]`
- **เพิ่มภารกิจ:** `Quests.lua` แล้วเรียก `QuestService.Progress(player, Type, Target)` จากระบบที่เกี่ยวข้อง
- **เพิ่มโซน:** `WorldLayout.Zones` + `LightingProfiles.Zones` + ส่วนขยายใน `TerrainBuilder.HeightAt`
