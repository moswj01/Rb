# ✦ Mythical Sanctuary

**Roblox Open World Fantasy Creature RPG** — สำรวจโลกเวทมนตร์ ช่วยเหลือ สร้างความไว้วางใจ ดูแล และสร้างเขตอนุรักษ์สัตว์ในตำนานของตัวเอง
จักรวาล ตัวละคร และสัตว์ทั้งหมดออกแบบใหม่ทั้งหมด (Original IP)

> **สถานะ: Phase 1 Vertical Slice — ระบบเกม + ภูมิประเทศ + แผนผังโลก ทำงานจริง / งานศิลป์ 3D รอ Artist (แสดงเป็น Greybox)**
> อ่าน [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) ก่อน — สรุปตรง ๆ ว่าอะไรเสร็จ อะไรยังไม่เสร็จ

## เริ่มเล่น
เปิด `MythicalSanctuary.rbxlx` ใน Roblox Studio → Play (รายละเอียด: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md))

| ปุ่ม | การทำงาน |
|---|---|
| **C** | ย่อตัว — เข้าหาสัตว์อย่างนุ่มนวล (สัตว์ขี้กลัวจะไม่หนี) |
| **Shift** | วิ่ง (สัตว์ตกใจ) |
| **E** | โต้ตอบ (NPC, สมุนไพร, หม้อยา, ประตูมิติ) |
| **1–4** | คำสั่งกับสัตว์ที่อยู่ใกล้ |
| **J** | สมุดบันทึก (สัตว์ของฉัน, สมุดภาพสัตว์, กระเป๋า, ภารกิจ, แผนที่, ตั้งค่า) |
| **B / R** | โหมดจัดวางในเขตอนุรักษ์ / หมุน |

## สิ่งที่เล่นได้ใน Phase 1
- 🏘️ **หมู่บ้านมิสติก** + 🌲 **ป่าเสียงกระซิบ** บนภูมิประเทศ Terrain ที่ปั้นตามแผนผัง (เนิน สันเขา หุบ แม่น้ำ น้ำตก ถ้ำลับ)
- 🦊 **สัตว์ 3 สายพันธุ์** (จิ้งจอกวิญญาณ, กวางจันทรา, ตุ่นนักขุดสมบัติ) พร้อม AI มีบุคลิก ช่วงเวลา และปฏิกิริยาต่อผู้เล่น
- 🤝 **Taming ด้วยความไว้วางใจ** — ย่อตัว ให้อาหารที่ชอบ ปลอบโยน รักษาบาดแผล (ไม่มีการจับด้วยกำลัง)
- 🏝️ **เขตอนุรักษ์ส่วนตัว** บนเกาะของตัวเอง — วางที่อยู่สัตว์/ของตกแต่ง (grid + หมุน), ฟักไข่, ดูแลให้เติบโต 4 ช่วงวัย
- 🌿 เก็บสมุนไพร · ⚗️ ปรุงยา · 🛒 ร้านค้า · 📜 เนื้อเรื่อง 8 ภารกิจ · 📖 สมุดภาพสัตว์ · 🗺️ ค้นพบสถานที่
- 🌗 กลางวัน/กลางคืน · 🌧️ อากาศ dynamic · แสงเฉพาะแต่ละ biome
- 💾 บันทึกข้อมูลพร้อม Session Locking + Migration · 👥 Multiplayer · 📱 มือถือ/แท็บเล็ต

## เอกสาร
| ไฟล์ | เนื้อหา |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | Game Design Document |
| [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md) | ทิศทางศิลป์, palette ต่อ biome |
| [`docs/WORLD_DESIGN.md`](docs/WORLD_DESIGN.md) | World Design + Environmental Storytelling |
| [`docs/world_map_preview.png`](docs/world_map_preview.png) | ภาพแผนที่ภูมิประเทศ (render จากฟังก์ชันความสูงเดียวกับเกม) |
| [`docs/CREATOR_STORE_GUIDE.md`](docs/CREATOR_STORE_GUIDE.md) | **วิธีใส่โมเดลจาก Creator Store ให้แมพสมจริง (เริ่มที่นี่)** |
| [`docs/ASSET_SPEC.md`](docs/ASSET_SPEC.md) | **สเปก Asset รายชิ้นสำหรับ 3D Artist / Animator / Sound** |
| [`docs/CONCEPT_BRIEFS.md`](docs/CONCEPT_BRIEFS.md) | บรีฟสำหรับ Concept Artist |
| [`docs/TECHNICAL.md`](docs/TECHNICAL.md) | สถาปัตยกรรม, Data schema, Networking, Performance |
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | ติดตั้ง, Bake Terrain, นำ Asset เข้า, เผยแพร่ |
| [`docs/PERFORMANCE_TEST_PLAN.md`](docs/PERFORMANCE_TEST_PLAN.md) | แผนทดสอบ FPS/Memory บนอุปกรณ์จริง |
| [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) | ขอบเขตงาน / สิ่งที่ยังขาด |
