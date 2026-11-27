# คู่มือใส่โมเดลจาก Creator Store (ทำให้แมพสมจริงเร็วที่สุด)

> ทางเลือกนี้ **เบี่ยงจาก Brief เดิม** (ที่ห้ามใช้ Toolbox) ตามที่เจ้าของโปรเจกต์ตัดสินใจ
> ใช้เป็นงานชั่วคราว/ต้นแบบได้ ถ้าภายหลังจ้าง 3D Artist ทำตาม `ASSET_SPEC.md` ก็แค่ Register ทับชื่อเดิม ไม่ต้องแก้โค้ด

## ⚡ วิธีที่เร็วที่สุด: ติดตั้งชุดที่คัดไว้แล้วด้วยคำสั่งเดียว
ผมคัดโมเดลฟรี 21 ชิ้นไว้ให้แล้ว (ตรวจผ่าน Creator Store API: **ฟรี · ไม่มีสคริปต์ · โพลีกอนต่ำ**) — ดูภาพรวมที่ [`recommended_assets.png`](recommended_assets.png) และรายการ+เครดิตผู้สร้างใน `src/shared/RecommendedAssets.lua`

1. เปิดไฟล์เกมใน Studio (โหมด Edit ไม่ต้องกด Play)
2. วางใน Command Bar แล้ว Enter:
   ```lua
   require(game.ReplicatedStorage.Shared.AssetTools).InstallRecommended()
   ```
3. รอ Output ขึ้น `✔ ติดตั้งสำเร็จ 21 / 21 ชิ้น` → **File › Save** → Play

ถ้าบางหลังหันผิดด้าน ติดตั้งใหม่พร้อมองศา: `...AssetTools).Insert("Building_House_Small_A", 2210545308, 180)`
อยากเปลี่ยนเป็นโมเดลอื่น: ทำตามวิธีด้านล่าง (Register ทับชื่อเดิมได้เลย)

## ทำไมใส่แค่ ~14 ชิ้นก็พอ
เกมมีระบบ **ครอบครัว + นามแฝง**:
- ใส่ `Tree_Forest_A` ชิ้นเดียว → ต้นไม้ในป่า ~420 ต้นใช้โมเดลนี้ (หมุน/ย่อขยายต่างกันอัตโนมัติ)
- ใส่ `Tree_Forest_A` + `Tree_Forest_B` → เกมสลับ 2 แบบให้ดูไม่ซ้ำ
- ไม่มีโมเดลร้านค้า → ใช้บ้านขนาดกลางแทน, ไม่มีต้นไม้ยักษ์ → ใช้ต้นไม้ป่าขยายให้ใหญ่ ฯลฯ

## ขั้นตอน (ทำใน Studio โหมด Edit — ไม่ต้องกด Play)

**1. ดูรายการที่ต้องหา** — วางใน Command Bar (ล่างจอ) แล้ว Enter:
```lua
require(game.ReplicatedStorage.Shared.AssetTools).Missing()
```
Output จะแสดง "ชุดขั้นต่ำ" 14 ชิ้น พร้อมคำค้นภาษาอังกฤษ

**2. หาโมเดลใน Toolbox** (View › Toolbox › Creator Store › Models) แล้วลากใส่ Workspace

**3. คลิกเลือกโมเดลนั้น** แล้วสั่ง Register ด้วยชื่อ Key:
```lua
require(game.ReplicatedStorage.Shared.AssetTools).Register("Tree_Forest_A")
```
เครื่องมือจะทำให้อัตโนมัติ:
- 🛡️ **ลบสคริปต์ทุกตัวในโมเดล** (โมเดลฟรีบางตัวแฝง backdoor ที่ขโมยสิทธิ์เกมได้)
- 📏 ย่อ/ขยายให้ความสูงพอดีกับแมพ
- 📍 ตั้งจุดหมุนที่ฐาน และย้ายไป `ReplicatedStorage/Assets`

ถ้าบ้านหันหลังให้ถนน ให้ Register ใหม่พร้อมองศา: `.Register("Building_House_Small_A", 180)`

**4. ทำซ้ำจนครบชุดขั้นต่ำ** แล้ว **File › Save** → กด Play

## ชุดขั้นต่ำ 14 ชิ้น
| Key | คำค้นแนะนำ | ใช้แทนอะไรได้บ้าง |
|---|---|---|
| `Tree_Forest_A`, `Tree_Forest_B` | stylized tree / low poly tree | ต้นไม้ป่า, ต้นไม้หมู่บ้าน, ต้นไม้ยักษ์ |
| `Tree_Ancient_A` | big stylized tree | ต้นไม้กรอบภาพ, ต้นไม้ผู้เฒ่า |
| `Plant_Fern_A` | fern / bush | พุ่มไม้, สมุนไพร |
| `Rock_Moss_A` | mossy rock | หินทั้งป่า, ปากถ้ำ, หินศาลเจ้า |
| `Mushroom_Glow_A` | glowing mushroom | เห็ดเรืองแสง, สมุนไพรเรืองแสง |
| `Building_House_Small_A` / `Medium_A` / `Large_A` | fantasy cottage / medieval house | บ้านทั้งหมู่บ้าน, ร้านค้า, ห้องสมุด, บ้านในเขตอนุรักษ์ |
| `Landmark_ClockTower` | fantasy clock tower | จุดศูนย์กลางหมู่บ้าน |
| `Landmark_StoneBridge` | stone arch bridge | สะพานข้ามแม่น้ำ |
| `Landmark_NorthGate` | medieval stone gate archway | ประตูเหนือ, ประตูมิติทั้งสองฝั่ง |
| `Prop_MarketStall_A` | medieval market stall | แผงตลาดทั้งหมด |
| `Prop_Cauldron_Public` | cauldron | หม้อยาทั้งสองจุด |

## เคล็ดลับให้แมพดูสวยและเป็นสไตล์เดียวกัน
- **เลือกจากผู้สร้างหรือแพ็กเดียวกัน** — ต้นไม้/บ้าน/หินที่สไตล์ต่างกันจะดูขัดตา
- เลือกโมเดลที่ **โพลีกอนไม่สูงเกินไป** (ต้นไม้ 1 ต้น < ~5,000 tris) เพราะป่ามีหลายร้อยต้น — สำคัญมากสำหรับมือถือ
- ดู **จำนวนการใช้งาน/เรตติ้ง** และอ่านว่าผู้สร้างอนุญาตให้ใช้ฟรี
- โมเดลที่มีไฟ (PointLight) ในตัว: เกมจะเปิด-ปิดไฟตามระยะเองไม่ได้ ถ้าเยอะเกิน FPS อาจตก
- หลังใส่ครบ ลอง `Missing()` อีกครั้งเพื่อดูว่ายังเหลือ Greybox อะไร

## สิ่งที่ Creator Store ช่วยได้น้อย
- **สัตว์ 3 สายพันธุ์** ต้องมี Rig + แอนิเมชันตามระบบเกม — โมเดลฟรีมักไม่ตรง ยังเป็น Greybox (หรือหาโมเดลสัตว์ที่มี Humanoid แล้ว Register ชื่อ `Creature_spirit_kitsune_Adult` ฯลฯ ใส่ใน Assets ได้ แต่แอนิเมชันอาจไม่ตรง)
- NPC ตอนนี้ใช้ตัวละคร Roblox มาตรฐาน (ใช้งานได้)
