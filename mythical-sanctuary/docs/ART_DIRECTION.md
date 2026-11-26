# Mythical Sanctuary — Art Direction

| รายการ | ค่า |
|---|---|
| เอกสาร | Art Direction Bible — v0.1 (Phase 1 Vertical Slice) |
| ผู้ใช้ | 3D Environment / Creature / Concept / UI / VFX / Lighting Artist |
| อ้างอิง | [GDD.md](GDD.md) · [ASSET_SPEC.md](ASSET_SPEC.md) · [CONCEPT_BRIEFS.md](CONCEPT_BRIEFS.md) |

---

## 1. Visual Statement

**"นิทานภาพสีน้ำมันที่ปั้นด้วยดินเหนียว"** — รูปทรงหนา นุ่ม จับต้องได้เหมือนของเล่นทำมือ แต่ผิวทาด้วยพู่กันแบบภาพประกอบหนังสือเด็กชั้นดี แสงเวทมนตร์คือ "อัญมณี" ของภาพ: ใช้น้อย วางตรงจุด และนำสายตาเสมอ

สามคำที่ทุกชิ้นงานต้องผ่าน: **Warm · Handmade · Alive**

- **Warm** — แม้กลางคืนก็ยังมีแหล่งแสงอุ่นให้เห็นเสมอ (หน้าต่าง, โคม, หม้อยา)
- **Handmade** — ไม่มีเส้นตรงแบบ CAD, ไม่มี tiling ที่มองออก, ทุกอย่างดูเหมือนมีคนสร้าง/ธรรมชาติปั้น
- **Alive** — ทุกฉากมีสิ่งเคลื่อนไหวเบา ๆ: ใบไม้, หิ่งห้อย, ควันปล่องไฟ, ผิวน้ำ

---

## 2. Shape Language

### 2.1 หลักใหญ่

| หลัก | กฎ | ตัวอย่างถูก | ตัวอย่างผิด |
|---|---|---|---|
| **Organic** | ขอบทุกเส้นมีความโค้ง/ยุบเล็กน้อย; เส้นตรงยาวเกิน 8 studs ต้อง "หย่อน" หรือ "บิด" | คานหลังคาแอ่นกลาง 0.3–0.6 stud | สันหลังคาตรงเป๊ะ |
| **Asymmetric** | ไม่มีอาคาร/ต้นไม้ที่ซ้าย-ขวาเหมือนกัน; ทิศหลักเยื้อง 5–15° | ปล่องไฟเอียง, หน้าต่างขนาดไม่เท่ากัน | หน้าบ้านแบบสมมาตรสมบูรณ์ |
| **Chunky stylized proportions** | ส่วนรับน้ำหนักหนาเกินจริง 1.3–1.6× ; ฐานกว้าง หัวมน | เสาไม้หนา 1.2 stud แทน 0.6, ขอบหน้าต่างหนา | ราวบางแบบสมจริง |
| **Big-Medium-Small** | ทุก asset มีสัดส่วนรูปทรง 60/30/10 (มวลหลัก / มวลรอง / รายละเอียด) | หอนาฬิกา: ตัวหอ / หลังคา+หน้าปัด / ระเบียง+โคม | รายละเอียดเท่ากันทุกตารางนิ้ว |
| **Readable silhouette** | ทุก asset ต้องจำได้จากเงาดำล้วนที่ 64 px | | |

### 2.2 รูปทรงตามความหมาย

| รูปทรง | ใช้กับ | ความรู้สึก |
|---|---|---|
| วงกลม / หยดน้ำ | สัตว์วัยเด็ก, เห็ด, หลังคาฟาง, ไข่, โคม | ปลอดภัย น่ากอด |
| สี่เหลี่ยมมุมมน (soft box) | บ้าน, แผงตลาด, ม้านั่ง | มั่นคง อบอุ่น |
| สามเหลี่ยมโค้ง (curved spire) | หอนาฬิกา, เขากวาง, ยอดต้นไม้โบราณ, คริสตัล | เวทมนตร์ ทิศทาง ดึงสายตาขึ้น |
| เกลียว / ม้วน | รากต้นไม้ผู้เฒ่า, ลายแกะ rune, หางจิ้งจอก | ความลึกลับ ความเก่าแก่ |
| เหลี่ยมแตก (fractured) | **เฉพาะ** ซากวิหารและคริสตัล | อดีตที่พังทลาย — ใช้ด้วยความยั้งมือ |

### 2.3 Scale reference

- ตัวละครผู้เล่น Roblox ≈ 5 studs สูง — **ประตูบ้านสูง 7–8 studs, กว้าง 4–5** (กว้างกว่าจริงเพื่อกล้องบุคคลที่สาม)
- หน้าต่างชั้นล่าง ขอบล่างสูง 2.5–3 studs จากพื้น
- ราว/รั้ว 2.5–3 studs
- Adult Lunar Stag สูงถึงไหล่ ≈ ผู้เล่น; Adult Kitsune ≈ เข่า-สะโพก; Adult Mole ≈ ข้อเท้า-เข่า (ดู ASSET_SPEC §3)

---

## 3. Color Palettes (Hex)

> ทุก palette แบ่งเป็น **Base (70%) / Support (20%) / Accent & Magic (10%)** ห้ามใช้ Magic เป็นสีพื้นที่ใหญ่

### 3.1 Mystic Village — "Honey & Hearth"

| บทบาท | ชื่อ | Hex |
|---|---|---|
| Base | Warm Plaster | `#EADCC0` |
| Base | Oak Timber | `#7A5434` |
| Base | Cobble Grey-Ochre | `#9C8E78` |
| Base | Meadow Grass | `#7FA352` |
| Support | Terracotta Roof | `#B7593A` |
| Support | Moss Thatch | `#8C8A4E` |
| Support | Slate Blue Roof | `#56688A` |
| Support | Shutter Teal | `#3E7F7A` |
| Accent | Bunting Rose | `#D9767A` |
| Accent | Marigold | `#E8A93A` |
| Magic | Lantern Amber (= `Prop_FloatingLantern` Glow) | `#FFC878` |
| Magic | Portal Azure (= `Landmark_SanctuaryGate` Glow) | `#8CD2FF` |
| Magic | Brew Green (= `Prop_Cauldron_Public` Glow) | `#96FFAA` |

### 3.2 Whispering Forest — "Moss & Whisper"

| บทบาท | ชื่อ | Hex |
|---|---|---|
| Base | Deep Moss | `#3F5B3A` |
| Base | Canopy Green | `#5E8A4A` |
| Base | Bark Umber | `#5A4332` |
| Base | Loam | `#4A3A2C` |
| Support | Fern Lime | `#9BBF5C` |
| Support | Lichen Sage | `#A8B89A` |
| Support | River Teal | `#3F8C8C` |
| Support | Mist Lavender (ฉากหลัง) | `#A9A6C8` |
| Accent | Sunbeam Gold | `#F2D58A` |
| Magic | Glowcap Cyan (`Mushroom_Glow_A`, `Forage_dewcap`) | `#78E6FF` |
| Magic | Glowcap Violet (`Mushroom_Glow_B`) | `#C88CFF` |
| Magic | Glowcap Mint (`Mushroom_Glow_C`) | `#8CFFAA` |
| Magic | Elder Spirit Green (`Landmark_ElderTree` Glow) | `#AAFFC8` |
| Magic | Cave Amethyst (`Prop_CrystalCluster_A` Glow) | `#A082FF` |
| Magic | Moonstone (`Prop_ShrineStone` Glow) | `#D2E6FF` |
| Magic | Wisp Gold (`Forage_wisp_lily` Glow) | `#FFF0B4` |

### 3.3 Sanctuary — "Dawn Garden" (เกาะลอยส่วนตัว)

| บทบาท | ชื่อ | Hex |
|---|---|---|
| Base | Soft Clover | `#8DBF6A` |
| Base | Cream Stone | `#E4D6B8` |
| Base | Driftwood | `#A68B6A` |
| Support | Sky Pool | `#7CC6D9` |
| Support | Blossom Pink | `#F2B6C1` |
| Support | Cloud White (ทะเลเมฆรอบเกาะ) | `#F7F3EA` |
| Accent | Peach Sun | `#FFB98A` |
| Magic | Moon Glade Silver (`Habitat_MoonGlade`) | `#D2E1FF` |
| Magic | Hatchery Ember (`Prop_HatcheryNest`) | `#FFBE78` |
| Magic | Rune Blue (`Prop_RuneArch`) | `#96C8FF` |
| Magic | Return Portal (`Sanctuary_ReturnGate`) | `#8CD2FF` |

### 3.4 Phase 3 Biomes (Exploration palettes)

| Biome | Base | Support | Accent / Magic | Mood |
|---|---|---|---|---|
| **Crystal Cavern** | Cave Slate `#2E3446`, Wet Basalt `#3D4456` | Deep Pool `#1F5A73`, Mineral Teal `#2878A0` | Crystal Aqua `#78E6DC`, Pearl `#E6FFFA`, Amethyst `#A082FF` | เงียบ เย็น ระยิบระยับ แสงมาจากหินเอง |
| **Frost Mountains** | Snow Shadow `#C9D6E8`, Granite `#6E7380` | Pine Ink `#2F4A48`, Glacier `#9FD0E6` | Storm Blue `#6E8CBE`, Aurora Violet `#6E5AB4`, Spark White `#F0F0FF` | ลมแรง โปร่ง ยิ่งใหญ่ |
| **Ember Valley** | Ash Basalt `#3A2E2C`, Rust Rock `#8A4A32` | Ochre Dust `#C98B4A`, Smoke `#6B5E5A` | Lava `#FF963C`, Ember Red `#A03424`, Heat Glow `#FFE68C` | อุ่น ดุดันแต่ไม่น่ากลัว (ภูเขาไฟ "หลับ") |
| **Celestial Islands** | Cloud Ivory `#F7F1E3`, Marble Blush `#EBD9CF` | Sky Gradient `#9EC9F0` → `#F4C9A8` | Sun Gold `#FFAA3C`, Phoenix Coral `#FF5A3C`, Halo `#FFF0B4` | สว่าง เบา ศักดิ์สิทธิ์ |

### 3.5 Creature palettes (จาก `Species.Palette`)

| Species | Primary | Secondary | Accent |
|---|---|---|---|
| `spirit_kitsune` | `#F2ECE4` | `#8CC4FF` | `#FFC478` |
| `lunar_stag` | `#4E5C8C` | `#D2E2FF` | `#FFF6D2` |
| `treasure_mole` | `#785C4A` | `#E8C4A0` | `#78DCD2` |
| `ember_dragon` | `#A03424` | `#FF963C` | `#FFE68C` |
| `storm_griffin` | `#C8BEAA` | `#6E8CBE` | `#F0F0FF` |
| `solar_phoenix` | `#FFAA3C` | `#FF5A3C` | `#FFF0B4` |
| `aqua_serpent` | `#2878A0` | `#78E6DC` | `#E6FFFA` |
| `shadow_wolf` | `#28283C` | `#6E5AB4` | `#BEAAFF` |

**กฎ Creature vs Environment contrast:** สัตว์ต้องแยกจากพื้นหลังโซนของมันได้ทันที — Kitsune ขาวครีมบนป่าเขียวเข้ม (value contrast), Stag น้ำเงินอมม่วง + จุดเงินเด่นในกลางคืน (glow contrast), Mole น้ำตาลจมพื้นดิน → **จมูก/เล็บ Accent `#78DCD2` ต้องอิ่มสีสุดในตัว** เพื่อไม่ให้กลืนพื้น

---

## 4. Materials & Textures

### 4.1 Hand-painted rules

1. **Lighting ไม่อบลง Albedo** — ห้ามวาดเงาตกกระทบ (cast shadow) หรือ highlight ทิศทางลงในสี; อนุญาตเฉพาะ **AO แบบนุ่ม** (ไม่เกิน 25% value drop) และ **gradient แนวตั้ง** (โคนเข้ม → ปลายสว่าง 10–15%) เพราะ Roblox มีแสงไดนามิกและ day/night
2. **Brush strokes ต้องอ่านได้ที่ระยะ 15 studs** — stroke ขนาด 6–12 px บน texture 1024 สำหรับ asset ขนาดอาคาร
3. **Edge highlight วาดด้วยมือ** ได้เฉพาะขอบที่รับแสงจากด้านบน (top-facing bevels) เท่านั้น
4. Value range ของ Albedo: 15–90% (ไม่มีดำสนิท/ขาวสนิท) — ดำสุดใช้ `#2A2420` แทน `#000000`
5. Saturation ของพื้นผิวใหญ่ ≤ 55%; สีอิ่มกว่านั้นสำหรับ accent ≤ 10% ของพื้นที่
6. Normal map ใช้เพื่อ "รูปทรงก้อน" (planks, stones, bark plates) **ไม่ใช่** micro-detail; Strength นุ่ม — ไม่ทำให้ผิวดูสมจริง
7. Roughness แทบทั้งหมด 0.7–0.95; ข้อยกเว้น: น้ำ, คริสตัล, กระจก, ยาในขวด (0.1–0.3)
8. Metalness = 0 ยกเว้นโลหะจริง (หม้อยา, ระฆัง, บานพับ, ห่วงโคม) — และแม้เป็นโลหะก็ไม่เกิน 0.8 เพื่อไม่สะท้อนดำในที่ร่ม

### 4.2 Texel density

| ประเภท | เป้าหมาย (px / stud) | หมายเหตุ |
|---|---|---|
| Hero landmark (ส่วนที่ผู้เล่นเข้าใกล้ได้) | **64 px/stud** | ใช้ trim sheet + unique ส่วนสำคัญ |
| อาคาร / props ทั่วไป | **48 px/stud** | |
| พืชพรรณ / หิน scatter | **32 px/stud** | |
| ส่วนที่มองจากไกลเท่านั้น (ยอดหอ, หลังคาสูง, หน้าผา) | **16–24 px/stud** | |
| สัตว์ Adult | **96–128 px/stud** | ใบหน้าได้สัดส่วน UV มากสุด (ดู ASSET_SPEC §3) |

ความต่าง texel density ระหว่างชิ้นที่อยู่ติดกันไม่เกิน 2× (ป้องกันความคม/เบลอกระโดด)

### 4.3 Trim sheets & atlases

ขนาดสูงสุด **1024×1024** (ข้อจำกัด Roblox). การแบ่งงาน:

| Atlas ID | ขนาด | เนื้อหา | ใช้โดย |
|---|---|---|---|
| `ATL_VIL_Trim` | 1024² trim | แถบไม้คาน 3 ขนาด, ปูนฉาบ 2 สี, ฐานหินก่อ, กรอบหน้าต่าง/ประตู, ระแนง, ขอบชายคา | อาคารหมู่บ้านทุกหลัง, แผงตลาด |
| `ATL_VIL_Roof` | 1024² tileable 2×2 cell | กระเบื้องดินเผา, กระเบื้องหินชนวน, ฟาง/มอส, แผ่นไม้มุง | หลังคาหมู่บ้าน |
| `ATL_VIL_Props` | 1024² atlas | ป้ายร้าน, ผ้าใบกันแดด 4 ลาย, ลังไม้, ตะกร้า, ขวดยา, ธงราว | B01–B03, P01–P03, P04 |
| `ATL_Stone_Carved` | 1024² trim | หินแกะลาย rune, บล็อกหินโค้ง, หัวเสา, ขั้นบันได, มอสทับขอบ | L01 (ฐาน), L02, L03, L04, L06, P06, SAN-D04, SAN-B02 |
| `ATL_Nature_Bark` | 1024² tileable (V-tile) | เปลือกไม้ 3 แบบ (โบราณ/ป่า/หมู่บ้าน) แบ่ง 3 คอลัมน์ | ต้นไม้ทั้งหมด, รากม้านั่ง, โพรงจิ้งจอก |
| `ATL_Nature_Foliage` | 1024² alpha atlas | ใบไม้ 6 cluster cards, เฟิร์น 3 แบบ, ดอกไม้ 6 ชนิด, หญ้า | ต้นไม้, G01–G02, F01, F03, SAN-D03 |
| `ATL_Nature_Ground` | 1024² | หินมอส 2 แบบ, ดิน/รากเปลือย, กรวด | R01–R03, F04, P05, SAN-H03 |
| `ATL_Magic_Emissive` | 512² | หมวกเห็ดเรืองแสง (grayscale สำหรับ tint), คริสตัล, rune glow strip, เปลวไฟเย็น, ลวดลายไข่ | M01–M03, F02, C01, SAN-D01, L04 glow, SAN-H04 |
| `ATL_SAN_Habitat` | 1024² | หญ้าเงิน, หินจันทร์, ผ้ารองนอน, ไม้ลอยน้ำ | SAN-H01–H04, SAN-D05 |
| Unique hero sets | 1024² ต่อชุด | | `Landmark_ClockTower` (หน้าปัด), `Landmark_ElderTree` (ลำต้นบิด), `Landmark_Waterfall` (น้ำ) |

### 4.4 Texture reuse rules (สูงสุด)

- 1 atlas ใช้ร่วมได้ไม่จำกัดจำนวน asset แต่ **UV island เดียวกันห้ามซ้ำเกิน 3 ครั้งในมุมกล้องเดียว** ที่ระยะ < 30 studs — ต้องหมุน/สลับ/flip island หรือใช้ vertex color tint
- พื้นผิว tileable ต้องทับด้วย **decal ทำลาย tiling** (คราบ, มอส, รอยแตก) อย่างน้อย 1 ชั้นทุก 16 studs²
- อาคารบ้าน 7 หลังใช้ `ATL_VIL_Trim` + `ATL_VIL_Roof` ร่วมกัน → ความต่างต้องมาจาก **รูปทรง + สีหลังคา + สีบานหน้าต่าง** ไม่ใช่ texture ใหม่
- Unique texture ใหม่ทั้งชุดอนุญาตเฉพาะ Hero ที่ระบุในตาราง §4.3 — ชิ้นอื่นต้องขออนุมัติ Art Director
- ต่อ zone ห้ามมี SurfaceAppearance ไม่ซ้ำกันเกิน **40 ชุด** (งบ memory บนมือถือ)

### 4.5 Roblox material notes

- Terrain ใช้ MaterialService override: Grass → `Meadow Grass` hand-painted, Ground/Mud → loam ทาสี, Cobblestone → ทางหินหมู่บ้าน (ต้องเข้ากับ `ATL_Stone_Carved`), Rock → หน้าผา, Sand → ริมแม่น้ำ
- ห้ามใช้ Material = Neon สำหรับวัตถุขนาด > 2 studs (bloom แตก); ใช้ `SurfaceAppearance` + emissive-looking albedo + `PointLight`/`SurfaceLight` แทน
- Glow ของ asset (ค่า `Glow` ใน AssetRegistry) = สีของ Light/Particle/Beam ที่โค้ดใส่ — artist วาดส่วนเรืองแสงใน albedo เป็นสีนั้นที่ value 85–95%

---

## 5. Lighting Mood

### 5.1 หลักการ

- **กลางวัน:** แสงอุ่นจากดวงอาทิตย์ + เงาสีม่วงอมฟ้า (complementary)
- **Dusk (Kitsune time):** ช่วงที่สวยที่สุดของเกม — ท้องฟ้าพีช/ชมพู, หน้าต่างเริ่มติดไฟ, หิ่งห้อยปรากฏ
- **กลางคืน:** ไม่มืดจนมองไม่เห็น ("Cozy night") — Ambient น้ำเงินอ่อน, แหล่งแสงเวทเป็นตัวนำทาง
- ทุกโซนต้องมี **"warm anchor"** มองเห็นได้เสมอ: หมู่บ้าน = หน้าต่าง/หอนาฬิกา, ป่า = ต้นไม้ผู้เฒ่า/เห็ด, Sanctuary = กระท่อม

### 5.2 Per-zone profile (ค่าตั้งต้นให้ LightingService)

| Parameter | Village Day | Village Night | Forest Day | Forest Night | Sanctuary Day | Sanctuary Night |
|---|---|---|---|---|---|---|
| `Lighting.Ambient` | `#6E6458` | `#2A3350` | `#4A5A48` | `#1E2C3A` | `#7A7062` | `#33406A` |
| `Lighting.OutdoorAmbient` | `#9C8C78` | `#3C4870` | `#6E8068` | `#2C3E52` | `#A8988A` | `#4A5888` |
| `Lighting.Brightness` | 2.4 | 1.0 | 1.8 | 0.8 | 2.6 | 1.2 |
| `ColorShift_Top` | `#FFE2B0` | `#9AB0FF` | `#E8F0C0` | `#8AA8E0` | `#FFE8C8` | `#B0C0FF` |
| `Atmosphere.Density` | 0.28 | 0.32 | 0.40 | 0.45 | 0.22 | 0.26 |
| `Atmosphere.Haze` | 1.2 | 1.6 | 2.2 | 2.6 | 0.8 | 1.2 |
| `Atmosphere.Color` | `#E6D2B4` | `#5A6894` | `#B8CCA8` | `#3E5A6A` | `#F2E2CC` | `#6A7AAA` |
| `Atmosphere.Decay` | `#B48A6A` | `#2A3050` | `#6A8A6A` | `#1E2E3E` | `#D8A88A` | `#3A4A7A` |
| `ColorCorrection.Saturation` | 0.08 | −0.05 | 0.05 | 0.0 | 0.12 | 0.02 |
| `ColorCorrection.Contrast` | 0.05 | 0.08 | 0.08 | 0.10 | 0.04 | 0.06 |
| `ColorCorrection.TintColor` | `#FFF6EA` | `#DCE4FF` | `#F4FFF0` | `#D8ECFF` | `#FFF8F0` | `#E4E8FF` |
| `Bloom.Intensity / Threshold` | 0.4 / 1.6 | 0.8 / 1.2 | 0.4 / 1.6 | 1.0 / 1.1 | 0.5 / 1.5 | 0.9 / 1.2 |
| `SunRays.Intensity` | 0.06 | 0 | 0.12 (god rays ผ่านเรือนยอด) | 0 | 0.05 | 0 |

**Dusk (17:00–20:00)** = lerp Day→Night โดยดัน `ColorShift_Top` เป็น `#FFB48A` และ `Atmosphere.Color` เป็น `#E8B4A0` ช่วงกลาง (18:30)
**Rain** = Density +0.15, Haze +1.0, Saturation −0.10, Brightness ×0.7, ปิด SunRays
**Elder Tree Clearing** (sub-profile ภายในรัศมี 55 ของ Feature Clearing) = SunRays 0.2 กลางวัน; กลางคืน Ambient ดันเขียว `#2A4A3E`
**Hidden Cave** (ภายใน Chamber Radius 22) = Ambient `#2A2440`, Brightness 0, แสงทั้งหมดจาก `Prop_CrystalCluster_A` (`#A082FF`) + `dewcap`/`wisp_lily` nodes
**Tween** ข้ามโซน 3 วินาที (Quad InOut)

### 5.3 Light budget

| ตำแหน่ง | แสงสูงสุดที่ active พร้อมกันในรัศมี 120 studs |
|---|---|
| หมู่บ้าน กลางคืน | 24 dynamic lights (PointLight/SpotLight/SurfaceLight) |
| ป่า | 12 (เห็ดส่วนใหญ่ใช้ emissive albedo + Bloom ไม่มี light จริง; เฉพาะ M02 ทุก 4 กอ มี PointLight) |
| Sanctuary | 16 |
| ทุก light `Shadows = false` ยกเว้น: หอนาฬิกา (ไฟหน้าปัด), หม้อยา, ต้นไม้ผู้เฒ่า | |

---

## 6. UI Art Direction

### 6.1 Palette

| ชื่อ | Hex | ใช้กับ |
|---|---|---|
| **Midnight Blue** | `#1B2A4A` | พื้นหลัง panel (opacity 88–94%), แถบหัวเรื่อง |
| **Antique Gold** | `#C9A45C` | กรอบ, เส้นแบ่ง, ไอคอน state เลือก, ตัวอักษรย่อเมื่อไม่มีไอคอน |
| **Forest Green** | `#3E6B48` | ปุ่ม Primary / ยืนยัน / ค่าบวก (Trust up) |
| **Ivory** | `#F4EEDD` | ตัวอักษรหลัก, พื้นการ์ดไอเทม |
| Support — Deep Ink | `#0F1830` | เงา panel, ตัวอักษรบนพื้น Ivory |
| Support — Gold Light | `#E8CF94` | hover / highlight |
| Support — Soft Rose | `#C96F6A` | ค่าลบ (Dislike, Trust down) — **ไม่ใช้สีแดงสด** |
| Bar — Hunger | `#E8A93A` | |
| Bar — Energy | `#7CC6D9` | |
| Bar — Joy | `#F2B6C1` | |
| Bar — Trust | `#C9A45C` → เต็มแล้วเปลี่ยนเป็น `#FFF0B4` เรืองแสง | |

Contrast: Ivory บน Midnight Blue = ~12.9:1 (ผ่าน WCAG AAA); Gold บน Midnight Blue ~6.9:1 (ใช้เป็นตัวอักษรได้ขนาด ≥ 14 px)

### 6.2 รูปแบบ

- กรอบ: มุมมน 10–14 px + **มุมประดับทองรูปใบไม้ม้วน** (9-slice, `SliceCenter` 24 px)
- Font: หัวเรื่อง serif ที่ดูเป็นหนังสือนิทาน (Roblox: `Fantasy`/`Merriweather` family); เนื้อหา `Gotham`/`BuilderSans` + ฟอนต์ที่รองรับภาษาไทยชัดเจน — **ทดสอบภาษาไทยทุกขนาดก่อนล็อก**
- ไอคอน: ดู ASSET_SPEC §4
- Motion: เปิด panel = scale 0.92→1.0 + fade 0.18 วิ (Back Out); Trust เพิ่ม = ประกายทองลอยขึ้น
- Touch target ≥ 44×44 px บนมือถือ; ปุ่ม Sneak ด้านขวาล่าง

---

## 7. VFX Language

| เอฟเฟกต์ | รูปแบบ | สี |
|---|---|---|
| เวทมนตร์ทั่วไป | อนุภาค "ฝุ่นแสง" กลม นุ่ม ลอยขึ้นช้า ไม่มีประกายแหลม | ตาม `Glow` ของ asset |
| Trust up (`Sfx_Trust_Up`) | หัวใจเล็ก/ใบไม้ทอง 3–5 ชิ้น | `#FFC478` |
| Bond (`Sfx_Bond`) | วงแหวนแสงขยายจากพื้น + เส้นริบบิ้นเชื่อมผู้เล่น-สัตว์ | `#FFF0B4` |
| Scared | หยดเหงื่อ cartoon + ฝุ่นเท้า | ขาว |
| น้ำ | Beam ผิวน้ำเลื่อน UV + ParticleEmitter ละอองที่ฐานน้ำตก | `#BFEAF0` |
| ห้าม | การระเบิด, เลือด, สายฟ้าแหลม (ยกเว้น Storm Griffin Phase 3 ซึ่งต้องโค้งมน) | |

---

## 8. Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| ทำ silhouette ก่อน — ส่ง blockout เงาดำให้ AD อนุมัติ | เริ่มจาก detail/sculpt ก่อนรูปทรงผ่าน |
| เอียง/บิดทุกอย่างเล็กน้อย (5–15°) | ใช้มุมฉาก 90° ทุกจุด |
| หนาเกินจริง ขอบ bevel ใหญ่ (≥ 0.3 stud) อ่านแสงง่าย | ขอบคมบาง ที่ Roblox shading แล้วดูแบน |
| วาด AO นุ่ม + gradient แนวตั้ง | อบเงาตกกระทบ/แสงทิศทางลง albedo |
| ใช้ trim sheet ร่วมกัน | สร้าง texture 1024 ใหม่ต่อ prop เล็ก |
| สีเวทมนตร์ ≤ 10% ของภาพ ใช้นำสายตา | ทำทุกอย่างเรืองแสง |
| สัตว์ตาโต หัวใหญ่ในวัยเด็ก แสดงอารมณ์ด้วยหู/หาง | สัตว์ดูน่ากลัว, เขี้ยวคม, ตาแดง |
| ทุก asset เป็นต้นฉบับของเกมนี้ | อ้างอิง/ลอกตัวละคร สัตว์ สถานที่ หรือสัญลักษณ์จาก IP ที่มีอยู่ (หนัง/หนังสือ/เกมอื่น) |
| ใส่ร่องรอยการใช้ชีวิต (ถังน้ำ, ผ้าตาก, ของเล่นเด็ก) | อาคารสะอาดเหมือนเพิ่งสร้าง |
| ตรวจ asset ที่มือถือ (Graphics level 3) | ตรวจแค่ PC Graphics 10 |
| เคารพ Pivot = bottom-center, Forward = −Z | ส่งโมเดลที่ origin ลอยหรือหันผิดทิศ |
| ทำงานที่ scale จริงใน studs | scale โมเดลใน Studio หลัง import |
