# Mythical Sanctuary — Asset Specification (ASSET_SPEC)

| รายการ | ค่า |
|---|---|
| เอกสาร | Production Asset Spec — Phase 1 Vertical Slice |
| Source of truth | `src/shared/AssetRegistry.lua` (Key, Spec ID, Size, Shape, Light, Glow), `Species.lua`, `Items.lua` |
| ผู้ใช้ | 3D Environment Artist, Creature Artist/Rigger/Animator, UI Artist, Sound Designer, Tech Artist |
| สถานะ | ทุก Key ด้านล่างแสดงเป็น **Greybox Blockout** ในเกมจนกว่าจะส่งโมเดลจริง |
| อ้างอิง | [ART_DIRECTION.md](ART_DIRECTION.md) (palette, atlas IDs, texel density) · [WORLD_DESIGN.md](WORLD_DESIGN.md) (ตำแหน่งในโลก) · [CONCEPT_BRIEFS.md](CONCEPT_BRIEFS.md) |

**สารบัญ**
0. Delivery pipeline (สรุป)
1. Global standards (pivot, child parts, LOD, collision, ปัญหา orientation)
2. Environment specs — 58 keys
3. Creature specs — CRE-RIG, CRE-01..03
4. UI icon spec — 22 icons
5. Audio spec — 24 keys
6. Naming conventions
7. Blender → Roblox export settings
8. Future / gap assets (ไม่อยู่ใน AssetRegistry)
9. Delivery checklist

---

## 0. Delivery Pipeline (สรุป)

1. สร้างโมเดลใน Blender ตาม spec นี้ (หน่วย 1 Blender unit = 1 stud, ดู §7)
2. Export `.fbx` → Roblox Studio **3D Importer**
3. ตั้งชื่อ Model **ตรงกับ Key** ใน `AssetRegistry` ทุกตัวอักษร (case-sensitive) เช่น `Landmark_ClockTower`
4. วางที่ `ReplicatedStorage/Assets/<Key>` — **Pivot = กึ่งกลางฐาน (bottom-center), หน้า = −Z**
5. ใส่ child parts/attachments ตามที่ระบุใน spec ของ Key นั้น (ชื่อตรงตัว)
6. เกมจะใช้โมเดลจริงแทน Greybox อัตโนมัติ (ไม่ต้องแก้โค้ด)

สัตว์: Model ชื่อ `Creature_<speciesId>_<Stage>` (Stage = `Egg` / `Baby` / `Juvenile` / `Adult`) ต้องมี `HumanoidRootPart` + `Humanoid` (หรือ `AnimationController`) + `Animator` และโฟลเดอร์ `Animations` ที่มี Animation objects ชื่อตาม `AssetRegistry.CreatureAnimations`

---

## 1. Global Standards

### 1.1 Pivot & orientation

| กฎ | รายละเอียด |
|---|---|
| Pivot | `Model.WorldPivot` อยู่ **กึ่งกลาง bounding box ในแกน X/Z และที่ฐาน (Y ต่ำสุดของส่วนที่แตะพื้น)** |
| Forward | หน้าหลักของ asset (ประตู, เคาน์เตอร์, หน้าปัด, ช่องเปิด) หันไปทาง **−Z** ของ local space |
| Up | +Y |
| Ground sink | ส่วนที่ต้องฝังดิน (ราก, ฐานหิน, ฐานบ้าน) ให้ยื่นต่ำกว่า pivot **0.5–2 studs** เพื่อกันลอยบน terrain ที่ลาด — ส่วนนี้ไม่นับใน Size.Y |
| Scale | โมเดลต้องมีขนาดตรง `Size` ใน registry **±10%** โดยไม่ต้อง scale ใน Studio (ค่า `Scale` ใน WorldLayout โค้ดเป็นคนคูณ) |

### 1.2 Child parts & attachments (สัญญาระหว่าง Art ↔ Code)

| ชื่อ (ตรงตัว) | Class | ใช้เมื่อ | พฤติกรรมฝั่งโค้ด |
|---|---|---|---|
| `LightSource` | Attachment (ซ้ำได้หลายตัว) | Key ที่ `Light = true` | โค้ดใส่ `PointLight` อุ่น `#FFC878` และเปิดเฉพาะกลางคืน/dusk |
| `GlowSource` | Attachment (ซ้ำได้) | Key ที่มีค่า `Glow` | โค้ดใส่ `PointLight`/`ParticleEmitter` สีตาม `Glow` |
| `Interact` | Attachment | สิ่งที่ผู้เล่นกดใช้ (หม้อยา, ประตูมิติ, forage node, เคาน์เตอร์) | จุดยึด `ProximityPrompt` |
| `PortalSurface` | BasePart (`Transparency` ≥ 0.6, `CanCollide = false`, `CanTouch = true`) | ประตูมิติ | โค้ดตรวจ `.Touched` / ใส่ shader-like Beam |
| `SpawnPoint` | Attachment | ประตูที่ผู้เล่นโผล่ออกมา | ผู้เล่น teleport มาที่จุดนี้ หันตาม −Z ของ attachment |
| `NpcStand` | Attachment | ร้าน/จุดที่ NPC ยืนทำงาน | NPC เดินไปยืนที่นี่ (แทนพิกัด Home ที่อยู่กลางอาคาร) |
| `NpcDoor` | Attachment | บ้านที่ NPC "กลับเข้าไป" ตอนกลางคืน | NPC เดินถึงประตูแล้ว fade out |
| `CreatureSlot` | Attachment (ซ้ำได้: `CreatureSlot` ทุกตัวชื่อเดียวกัน) | Habitat | จุดที่สัตว์นอน/พัก |
| `DrinkSpot` | Attachment (ซ้ำได้) | Spring Pond | AI state Drink เดินมาที่นี่ |
| `EggSlot` | Attachment | Hatchery Nest | จุดวางไข่ |
| `Seat` | Roblox `Seat` | ม้านั่ง | นั่งได้จริง |
| `Collision` | Folder ของ Part ชื่อ `Col_*` (`Transparency = 1`) | อาคาร/landmark ที่ต้องการ collision แม่นแต่ถูก | โค้ดไม่แตะ; MeshPart หลักตั้ง `CanCollide = false` |
| `Emitter_<ชื่อ>` | Attachment | จุดปล่อยอนุภาค (ควัน, ละออง, ไอน้ำ) | โค้ด/VFX ใส่ `ParticleEmitter` |

> ชื่อเหล่านี้คือ **contract ที่เสนอ** ให้ Code team ใช้ — `LightSource`, `Interact`, `PortalSurface` มาจาก brief; ชื่อที่เหลือเป็นข้อเสนอของเอกสารนี้ ต้องยืนยันกับโค้ดก่อน art lock

### 1.3 Triangle budget & LOD policy

- **ข้อจำกัด Roblox:** MeshPart หนึ่งชิ้น ≤ **10,000 tris** ต่อการ import (ตาม pipeline ของทีม) → asset ที่งบเกินต้อง **แยกเป็นหลาย MeshPart** ตามที่ระบุ
- **LOD0** = ที่ import เข้าเกม; **LOD1/LOD2** = ส่งเป็นไฟล์ `<Key>_LOD1.fbx`, `<Key>_LOD2.fbx` ใน source repo
- Phase 1 runtime ใช้ Roblox automatic LOD (`RenderFidelity = Automatic`) + StreamingEnabled; LOD1/LOD2 ที่ artist ทำเองใช้กับ (ก) `Model.LevelOfDetail = StreamingMesh` imposter ของ landmark และ (ข) ระบบสลับ LOD ของ Scatter ที่โค้ดอาจเพิ่มใน Phase 2
- เป้าหมายระยะ: LOD0 < 80 studs · LOD1 80–250 · LOD2 > 250
- LOD1 ≈ 40–45% ของ LOD0, LOD2 ≈ 10–15% — **silhouette ต้องไม่เปลี่ยน** (ลดใน loop ภายในก่อนขอบนอก)

### 1.4 ⚠ Orientation conflicts ที่พบใน source (ต้องให้ Code ยืนยัน)

1. **Yaw ของอาคารในหมู่บ้านหันด้าน local +Z เข้าจัตุรัส.** ถ้าโค้ดวางด้วย `CFrame.Angles(0, math.rad(Yaw), 0)` แบบปกติ `LookVector` (= −Z) จะเป็น `(−sin Yaw, 0, −cos Yaw)` ตัวอย่าง:
   - `Building_FeedShop` (−38,−34) Yaw 35 → LookVector (−0.57, −0.82) ชี้ **ออกจาก** จัตุรัส (จัตุรัสอยู่ทิศ +X,+Z)
   - `Building_Apothecary` (44,−30) Yaw −40 → (0.64, −0.77) ชี้ออก
   - `Building_Library` (−78,48) Yaw 120 → (−0.87, 0.5) ชี้ออก
   - `Landmark_SanctuaryGate` (−30,72) Yaw 200 → (0.34, 0.94) ชี้ไปทางใต้ ห่างจากจัตุรัส
   - `Landmark_Waterfall` Yaw 0 → หันไปทิศเหนือ (เข้าหน้าผา) แทนที่จะหันหาผู้เล่นทางใต้
   รูปแบบนี้สม่ำเสมอทุกตัว → **ข้อสรุป: layout ถูกออกแบบโดยถือว่าหน้า = +Z** ทางแก้ที่แนะนำ: ให้โค้ด PlacementService หมุนเพิ่ม 180° (`Yaw + 180`) ตอนวาง และ **artist ยังคง author หน้า = −Z ตาม registry** (ไม่ต้องแก้งาน art)
2. **`Landmark_StoneBridge` Size = (52, 14, 16)** ระบุช่วงสะพานยาวตามแกน X แต่ Yaw = 92 จะหมุนช่วงสะพานไปตามแนวเหนือ–ใต้ **ขนานกับแม่น้ำ** (BridgeRoad วิ่งตะวันออก–ตะวันตก) ข้อเสนอ: ยึด Size (artist ทำช่วงสะพานตามแกน X) และให้โค้ดใช้ Yaw ≈ 2 (หรือหัก 90 ออก) — **หรือ** เปลี่ยน Size เป็น (16, 14, 52) ถ้าต้องการให้ทิศเดินทาง = forward

จนกว่าจะยืนยัน spec ด้านล่างเขียนตาม registry: **หน้า = −Z, Size ตามแกนที่ registry ระบุ**

### 1.5 Collision policy

| ประเภท | CollisionFidelity | หมายเหตุ |
|---|---|---|
| อาคาร / landmark | MeshPart `CanCollide = false` + โฟลเดอร์ `Collision` (Parts ง่าย ๆ) | ถูกที่สุดและควบคุมได้ |
| Props ขนาดกลาง | `Hull` | |
| Props เล็กที่ไม่ขวางทาง (เห็ด, เฟิร์น, ดอกไม้, forage) | `Box` + `CanCollide = false` | ผู้เล่นและสัตว์เดินผ่านได้ |
| ต้นไม้ | ลำต้น `Hull` (หรือ `Col_Trunk` cylinder), เรือนยอด `CanCollide = false`, `CanQuery = false` | กัน PathfindingService ติดใบไม้ |
| หิน scatter | `Hull` | |
| ทุก MeshPart ที่ไม่ใช่ collision | `CanTouch = false` | ลด physics cost |

### 1.6 SurfaceAppearance standard

| Map | ชื่อไฟล์ | รูปแบบ | หมายเหตุ |
|---|---|---|---|
| ColorMap | `T_<Key>_C.png` | sRGB, RGBA | Alpha ใช้กับ `AlphaMode = Overlay` (tint) หรือ `Transparency` (ใบไม้) |
| NormalMap | `T_<Key>_N.png` | OpenGL (+Y), Linear | |
| RoughnessMap | `T_<Key>_R.png` | Grayscale | |
| MetalnessMap | `T_<Key>_M.png` | Grayscale | **ส่งเฉพาะ asset ที่มีโลหะ** |

ถ้า asset ใช้ atlas ร่วม ให้อ้าง SurfaceAppearance ของ atlas (`T_ATL_<ID>_*`) ไม่ต้องส่ง texture ซ้ำ — SurfaceAppearance **เปลี่ยนค่าด้วยสคริปต์ตอน runtime ไม่ได้** สิ่งที่ต้องเปลี่ยนสีตามเวลาให้แยกเป็นชิ้นที่ใช้ `MeshPart.Color` + `AlphaMode = Overlay`

---

## 2. Environment Specs

> รูปแบบแต่ละรายการ: **Spec ID · Key** — `Size` (X × Y × Z studs) และ `Shape` ของ Greybox จาก registry
> Tris = LOD0 / LOD1 / LOD2 · Tex = ขนาด texture เฉพาะ (ถ้ามี) + atlas ที่ใช้ (ID ใน ART_DIRECTION §4.3)

### 2.1 Landmarks (ENV-L01 – L07)

#### ENV-L01 · `Landmark_ClockTower`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 22 × 78 × 22 · Shape `Tower` · `Light = true` |
| ตำแหน่ง | (0,0,0) Yaw 0 — ใจกลางจัตุรัส, Role `Hero` |
| Description & story | หอนาฬิกาแห่ง "สัญญาผู้เฝ้าตะเกียง" สิ่งก่อสร้างแรกของหมู่บ้าน ฐานหินเก่าแก่สลักคำสัญญา "ไม่ล่า ไม่กักขัง" รอบฐาน, ตัวหอโครงไม้ปูนฉาบ, หน้าปัดนาฬิกา 4 ด้าน, หอระฆังเปิดโล่งด้านบน, ยอดแหลมโค้งมีใบพัดบอกทิศรูปจิ้งจอกหางม้วน |
| Silhouette | 3 ช่วงชัดเจน (ฐานกว้าง 22 → ตัวหอเรียว ~14 → หอระฆัง ~12 + ยอดแหลมโค้งเอียง 6° ไปทางตะวันออก) ยอดต้องอ่านได้จากป่า (North Gate) ห่าง 150 studs — ไม่มีสิ่งอื่นในหมู่บ้านที่สูงเกิน 40 |
| Tris | 14,000 / 6,000 / 1,800 — แยก 3 MeshParts: `Base` (≤ 5k), `Shaft` (≤ 5k), `Crown` (หน้าปัด+หอระฆัง+ยอด ≤ 4k) |
| Texture | Unique 1024² (หน้าปัด, จารึกฐาน) + `ATL_Stone_Carved` (ฐาน) + `ATL_VIL_Trim` (ตัวหอ) + `ATL_VIL_Roof` (ยอด กระเบื้องหินชนวน `#56688A` แพตช์ซ่อม 2 เฉด) |
| SurfaceAppearance | C, N, R; M เฉพาะระฆัง/เข็มนาฬิกา/ใบพัด (brass) |
| Collision | `Collision`: กล่องฐาน 22×10×22 + กล่องตัวหอ 14×60×14; MeshParts `CanCollide = false` |
| Pivot | กึ่งกลางฐาน; หน้าปัดหลักหัน −Z |
| Child parts | `LightSource` ×4 (หลังหน้าปัดแต่ละด้าน) + ×2 (โคมฐานด้าน +Z ใกล้จุดยืนมาริเบล); `NpcStand` ที่ local (8, 0, 14) = Home ของ `npc_elder` (ม้านั่งหิน); `Emitter_Birds` ที่หอระฆัง; เข็มนาฬิกาแยก MeshPart `HandHour`, `HandMinute` (pivot ที่แกนหมุน) ให้โค้ดหมุนตาม `ClockTime` |
| Variation | ชิ้นเดียว (hero) — ห้ามใช้ซ้ำ |
| ⚠ หมายเหตุ | MainRoad และ MarketLane วิ่งผ่าน (0,0,0) → ฐานหอต้องมีลานวงกลม (plaza ring) ในตัว กว้างรัศมี ~16 ให้ถนนชนขอบ; NPC Pip ตอน 17:00 ไปยืนที่ (5,0,−6) ซึ่งอยู่ในฐานหอ (WORLD_DESIGN WD-07) |

#### ENV-L02 · `Landmark_StoneBridge`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 52 × 14 × 16 · Shape `Bridge` |
| ตำแหน่ง | (132,0,2) Yaw 92 — ข้ามแม่น้ำ (กว้าง 26, ระดับน้ำ 19) บน BridgeRoad (W9) · Role `Hero` |
| Description & story | สะพานหินโค้งสามช่วงที่ชาวบ้านสร้างร่วมกันหลังน้ำท่วมใหญ่ หินแต่ละก้อนมีรอยมือ/ชื่อสลักเล็ก ๆ ของครอบครัวที่ช่วยสร้าง; ช่วงกลางโค้งสูงให้เรือเล็กลอดได้; ราวหินเตี้ยมีโคมเหล็ก 2 ต้นกลางสะพาน |
| Silhouette | โค้งหลังเต่าชัด (ดาดฟ้ากลางสูงกว่าปลาย ~3 studs), ช่องโค้งใต้สะพาน 1 ใหญ่ (กว้าง ≥ 28 คร่อมแม่น้ำ) + 2 เล็กที่ตลิ่ง, เสาค้ำทรงหยดน้ำทวนกระแส — ต่างจาก North Gate (ไม้, แนวตั้ง) ด้วยมวลหินแนวนอน |
| Tris | 7,000 / 3,000 / 900 — `Deck` (≤ 4k), `Arches` (≤ 3k) |
| Texture | `ATL_Stone_Carved` + decal มอส/คราบน้ำแนวระดับน้ำ |
| SurfaceAppearance | C, N, R; M เฉพาะโคมเหล็ก |
| Collision | `Collision`: ทางลาด 2 ชิ้น + ดาดฟ้า (Wedge/Part) ผิวเรียบให้เดินลื่น, ราว 2 ชิ้นสูง 3 |
| Pivot | กึ่งกลางฐาน (ระดับตลิ่ง); ช่วงสะพานตามแกน **X** ตาม Size (ดู §1.4 ข้อ 2) |
| Child parts | `LightSource` ×2 (โคมกลางสะพาน); `Emitter_Mist` ×1 ใต้โค้งกลาง |
| Variation | Hero ชิ้นเดียว |

#### ENV-L03 · `Landmark_NorthGate`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 30 × 26 × 8 · Shape `Arch` |
| ตำแหน่ง | (0,0,−150) Yaw 0 — ปลาย MainRoad (W12) เข้า ForestTrail |
| Description & story | ซุ้มประตูไม้ซุงแกะสลักเส้นแบ่ง "บ้าน" กับ "ป่า" ไม่มีบานประตู (หมู่บ้านไม่เคยปิดกั้นสัตว์) คานบนแกะรูปสัตว์ 3 ตัวพันกัน (จิ้งจอกหางสาม, กวางเขาจันทร์เสี้ยว, ตุ่นตัวกลม) แบบลายเส้นไม่บอกตรง ๆ; มีตะขอแขวนโคม, ริบบิ้นผ้าที่ชาวบ้านผูกขอพร |
| Silhouette | เสาไม้คู่บิดเกลียวเล็กน้อย + คานบนโค้งแอ่นลงกลาง (ไม่ใช่ทรงโค้งขึ้นแบบซุ้มหิน) — ช่องเปิดกว้าง ≥ 14, สูง ≥ 16 |
| Tris | 4,000 / 1,700 / 450 |
| Texture | `ATL_Nature_Bark` (ซุง) + `ATL_VIL_Props` (ริบบิ้น, โคม) |
| SurfaceAppearance | C, N, R; ริบบิ้นใช้ alpha Transparency |
| Collision | `Collision`: เสา 2 ต้น (cylinder ~3×26) เท่านั้น |
| Pivot | กึ่งกลางฐาน; ด้านหมู่บ้าน = +Z, ด้านป่า = −Z |
| Child parts | `LightSource` ×2 (โคมแขวนสองข้าง); `NpcStand` ด้านหมู่บ้าน local (4, 0, 6) สำหรับ Rowan 06:00 (WorldLayout ให้ (0,0,−140) = 10 studs ใต้ประตู) |
| Variation | ชิ้นเดียว |

#### ENV-L04 · `Landmark_SanctuaryGate`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 18 × 22 × 6 · Shape `Arch` · Glow `#8CD2FF` (140,210,255) |
| ตำแหน่ง | (−30,0,72) Yaw 200 · Role `Portal` |
| Description & story | ซุ้มหินโบราณที่หลับมาหลายชั่วอายุคน "ตื่น" เมื่อผู้เล่นมาถึง — ครึ่งซ้ายยังมีมอสและเถาวัลย์คลุม ครึ่งขวา rune เรืองฟ้า; ภายในช่องเปิดเห็นภาพเกาะเมฆเลือนราง |
| Silhouette | ซุ้มโค้งแหลมแบบหยดน้ำคว่ำ (pointed ogee) สูงชะลูด ไม่สมมาตร — หินก้อนบนสุดเอียง; ต่างจาก `Prop_RuneArch` (เตี้ย ตกแต่ง) และ `Prop_CaveEntrance` (หินธรรมชาติ) |
| Tris | 3,200 / 1,400 / 400 |
| Texture | `ATL_Stone_Carved` + `ATL_Magic_Emissive` (แถบ rune) |
| SurfaceAppearance | C, N, R; แถบ rune ColorMap สี `#8CD2FF` value 90% |
| Collision | `Collision`: เสาหิน 2 ข้าง; ช่องเปิดโล่ง |
| Pivot | กึ่งกลางฐาน; หน้าเข้า = −Z |
| Child parts | `PortalSurface` (แผ่นบางเต็มช่องเปิด ~10 × 14, หนา 0.2); `Interact` กลางช่องที่สูง 3; `GlowSource` ×3 (rune ซ้าย/ขวา/ยอด); `SpawnPoint` ด้าน −Z ห่าง 6 studs (ผู้เล่นกลับจาก Sanctuary โผล่ที่นี่) |
| Variation | ชิ้นเดียว; คู่แฝดคือ SAN-B02 (ต้องเป็นชุดเดียวกันทางสายตา) |

#### ENV-L05 · `Landmark_ElderTree`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 70 × 120 × 70 · Shape `Tree` · Glow `#AAFFC8` (170,255,200) |
| ตำแหน่ง | (−90,0,−560) Yaw 20 — กลาง Clearing R55 · Role `Hero` |
| Description & story | ต้นไม้ผู้เฒ่า หัวใจของป่า ลำต้นบิดเป็นเกลียวจากรากที่ม้วนขึ้นเหนือดินเป็นซุ้ม 3–4 ซุ้มที่ผู้เล่นเดินลอดได้, รากกลวงเป็นท่อให้ลมผ่าน (ที่มาของ "เสียงกระซิบ"), กิ่งบนห้อยมอสวิญญาณเรืองเขียวอ่อนและผลไม้แสงคล้ายโคม; ใต้รากด้านหนึ่งมีโพรงที่จิ้งจอกบาดเจ็บนอน (q04) |
| Silhouette | "มือที่แบออก" — ลำต้นหนา ~18 ที่โคน บิด 40° ตลอดความสูง, แตกเป็นกิ่งใหญ่ 3 กิ่งที่สูง ~70, เรือนยอดทรงร่มกว้าง 70 ไม่สมมาตร (หนักไปทางตะวันออก); ต่างจาก Tree_Ancient ด้วยขนาดเกือบ 2 เท่าและรากซุ้ม |
| Tris | 20,000 / 8,000 / 2,200 — `Trunk` (≤ 9k), `Roots` (≤ 6k), `Canopy` (cards ≤ 5k) |
| Texture | Unique 1024² ลำต้น (ลายเปลือกเกลียว) + `ATL_Nature_Bark` (ราก) + `ATL_Nature_Foliage` + `ATL_Magic_Emissive` (มอสวิญญาณ, ผลไม้แสง) |
| SurfaceAppearance | ลำต้น/ราก C, N, R · ใบ C (alpha `Transparency`), R |
| Collision | `Col_Trunk` (cylinder Ø 16), `Col_Root_*` 4–6 กล่องเฉพาะรากที่สูงพอขวาง; เรือนยอด `CanCollide = false`, `CanQuery = false` |
| Pivot | กึ่งกลางลำต้นที่ระดับดิน (ไม่ใช่กึ่งกลางเรือนยอด) |
| Child parts | `GlowSource` ×6 ในเรือนยอด; `LightSource` ×0; `Emitter_Fireflies` ×2; `Emitter_Leaves` ×1; attachment `RescueSpot` ที่ปากโพรงราก (จุดวางจิ้งจอกบาดเจ็บ q04 — ชื่อที่เสนอ) |
| Variation | ชิ้นเดียว |
| หมายเหตุ | ยอดต้องเห็นจาก North Gate (ห่าง ~420) — ห้ามมีหมอกใบไม้ที่ทำให้ silhouette ยอดหาย |

#### ENV-L06 · `Landmark_TempleRuins`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 60 × 34 × 50 · Shape `Ruins` |
| ตำแหน่ง | (238,0,−662) Yaw −25 บน Mound (235,−660) R70 · Role `Hero` |
| Description & story | วิหารของ "ผู้รักษาแสง" ผู้ทำเหรียญ Lumen ยุคแรก — แนวเสาวงกลมครึ่งวงที่ยังยืน 5 ต้น หัก 4 ต้น, แท่นบูชากลางมีจานหินรูปดวงอาทิตย์ (ลาย Lumen) เรืองแสงจาง ๆ, บันไดกว้างพังครึ่ง, เสาหนึ่งล้มพาดเป็นสะพานข้ามร่อง; รากไม้และมอสกลืนหิน; มีรูตุ่นขุดอยู่ที่ฐานแท่น |
| Silhouette | เส้นแนวตั้งหัก (เสาสูงไม่เท่ากัน 12–34) ตัดกับเส้นทแยง (เสาล้ม) — **เป็น asset เดียวในเกมที่ใช้ shape language แบบเหลี่ยมแตก** |
| Tris | 12,000 / 5,000 / 1,500 — แยก modular: `Pillar_Standing_*`, `Pillar_Fallen`, `Altar`, `Stairs`, `Floor` (แต่ละชิ้น ≤ 3k) |
| Texture | `ATL_Stone_Carved` + `ATL_Nature_Foliage` (เถา) + unique 512² จานแท่นบูชา |
| SurfaceAppearance | C, N, R |
| Collision | `Collision`: กล่องต่อเสา + บันไดเป็น wedge + พื้น |
| Pivot | กึ่งกลางพื้นวิหาร; บันไดหลักหัน −Z |
| Child parts | `GlowSource` ×1 ที่จานแท่นบูชา (ข้อเสนอสี Sunbeam Gold `#F2D58A` — registry ยังไม่มีค่า `Glow` ของ L06 ต้องเพิ่มถ้าต้องการให้โค้ดเปิดแสง); `Emitter_Dust` ×1 |
| Variation | ชิ้นส่วน modular ใช้ซ้ำได้ใน Phase 3 (Celestial Islands) แต่ต้องเปลี่ยน trim |

#### ENV-L07 · `Landmark_Waterfall`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 34 × 70 × 10 · Shape `Waterfall` |
| ตำแหน่ง | (150,0,−912) Yaw 0 หน้าหน้าผา Cliff (150,−960) R130 H70 · ต้นแม่น้ำ (150,−905) ระดับ 46 · Role `Hero` |
| Description & story | น้ำตกสองชั้นไหลจากรอยแยกหน้าผา ชั้นบนแคบพุ่งแรง ชั้นล่างกระจายเป็นม่านกว้างลงแอ่ง; ขอบหินมีมอสเงิน, กลางคืนกวางจันทรามาซ่อนตัวด้านหลังม่านน้ำ (ตาม Lore) |
| Silhouette | ม่านน้ำทรงตัว "Y" กลับหัว (แคบบน กว้างล่าง) เอียงไม่สมมาตร; หินขอบยื่นคล้ายริมฝีปากล่างแตก 2 ระดับ |
| Tris | 4,500 / 1,800 / 600 — `RockLip` (≤ 3k), `WaterSheet_Upper`, `WaterSheet_Lower`, `Foam` (รวม ≤ 1.5k) |
| Texture | Unique 1024² น้ำ (ลายไหลแนวตั้ง tileable แกน V) + `ATL_Nature_Ground` |
| SurfaceAppearance | หิน C, N, R · น้ำใช้ **`Texture` object** ชื่อ `Flow` บน WaterSheet (โค้ดเลื่อน `OffsetStudsV`) แทน SurfaceAppearance |
| Collision | หินเท่านั้น (`Hull`); WaterSheet/Foam `CanCollide = false`, `CanQuery = false` |
| Pivot | กึ่งกลางฐานแอ่งน้ำ; ม่านน้ำหน้า −Z (ดู §1.4 — ผู้เล่นมาจากทิศใต้ = +Z ของโลก) |
| Child parts | `Emitter_Mist` ×2 (ฐาน), `Emitter_Splash` ×1, attachment `SoundEmitter` (โค้ดผูก `Ambience_Waterfall`), `GlowSource` ×0 |
| Variation | ชิ้นเดียว |

### 2.2 Village Buildings (ENV-B01 – B03, B10 – B16)

**กฎร่วมของอาคาร**
- ใช้ `ATL_VIL_Trim` + `ATL_VIL_Roof` (+ `ATL_VIL_Props` สำหรับป้าย/ของประดับ) — ความต่างระหว่างหลังมาจาก **รูปทรง, สีหลังคา, สีบานหน้าต่าง, ของประดับ**
- `Light = true` ทุกหลัง → `LightSource` อย่างน้อย 1 ต่อหน้าต่างชั้นล่างที่หันหาทางเดิน (ต่ำสุด 2, สูงสุด 6 ต่อหลัง) วางหลังกระจก 0.5 stud; หน้าต่างกลางคืนใช้ ColorMap ส่วนกระจกเป็นสีอุ่น `#FFC878` ที่ value 70%
- ประตูสูง 7–8, กว้าง 4–5; ห้องภายในไม่มี (ยกเว้นร้านแบบเปิดหน้า) — ประตูบ้านปิดถาวร
- Collision: โฟลเดอร์ `Collision` 1–4 กล่อง
- Tris: Small 3,500 / 1,500 / 450 · Medium 4,500 / 2,000 / 600 · Large/ร้าน 6,000–9,000 (แยก MeshPart เมื่อเกิน 10k)
- SurfaceAppearance จาก atlas: C, N, R (+ M เฉพาะป้ายเหล็ก, บานพับ)
- ห้ามใช้สีหลังคาเดียวกันกับบ้านที่ติดกันในระยะ < 50 studs

#### ENV-B01 · `Building_FeedShop`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 26 × 24 × 20 · `Building` · `Light = true` |
| ตำแหน่ง | (−38,0,−34) Yaw 35 · Role `Shop` · NPC `npc_bramble` (Home (−34,0,−26)) |
| Description & story | ร้านอาหารสัตว์ของแบรมเบิล ชายร่างใหญ่ใจดี — หน้าร้านเปิดโล่งเป็นเคาน์เตอร์ไม้กว้าง ใต้กันสาดผ้าลายทางเขียว-ครีม; ด้านข้างติดไซโลถังไม้กลมสำหรับเก็บเมล็ด, กระสอบ glowberry และ honeyroot วางกองหน้าร้าน, รางอาหารไม้ยาวหน้าร้านให้สัตว์ป่าแวะกิน |
| Silhouette | กล่องหลักหลังคาจั่วต่ำ terracotta `#B7593A` + **ไซโลทรงกระบอกหลังคากรวย** ด้านหนึ่ง + กันสาดเอียงยื่น 4 studs — ไซโลคือจุดจำ |
| Tris | 6,000 / 2,500 / 800 |
| Texture | atlas หมู่บ้าน + ป้ายร้านรูปเมล็ด/อุ้งเท้า (ไม่มีตัวอักษร — ใช้ภาพ) |
| Child parts | `NpcStand` หลังเคาน์เตอร์ (ตรงกับ Home ของ Bramble ซึ่งอยู่ห่าง pivot ~9 studs — ร้านต้องมีพื้นที่ยืนภายในบริเวณนั้น); `Interact` บนเคาน์เตอร์ (เปิด Shop UI); `LightSource` ×3 (2 หน้าต่าง + 1 โคมใต้กันสาด); `NpcDoor` ไม่ต้อง |
| Collision | ตัวร้าน + ไซโล + เคาน์เตอร์ (ผู้เล่นเข้าหลังเคาน์เตอร์ไม่ได้) |
| Variation | ชิ้นเดียว |

#### ENV-B02 · `Building_Apothecary`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 24 × 28 × 22 · `Building` · `Light = true` |
| ตำแหน่ง | (44,0,−30) Yaw −40 · Role `Crafting` · NPC `npc_willow` (Home (48,0,−22)); หม้อยาสาธารณะ `Prop_Cauldron_Public` อยู่ที่ (52,0,−14) หน้าร้าน |
| Description & story | ร้านยาของวิลโลว์ อาคารสูงเอียงเล็กน้อยเหมือนจะล้มแต่ไม่ล้ม หน้าต่างกระจกโค้งยื่น (bay) เป็นเรือนกระจกย่อมปลูกสมุนไพร, ราวตากสมุนไพรใต้ชายคา (silverfern สีเงิน, wisp lily), ปล่องไฟอิฐคดเคี้ยวมีควันสีเขียวจาง ๆ, ขวดยาสีต่าง ๆ เรียงที่ขอบหน้าต่าง |
| Silhouette | **ทรงสูงชะลูดเอียง 4°** + ปล่องไฟคด + bay window กระจก — ตรงข้ามกับ Feed Shop (เตี้ยกว้าง) |
| Tris | 6,500 / 2,700 / 850 |
| Texture | atlas หมู่บ้าน; กระจกเรือนกระจกใช้ส่วนแยก MeshPart `Glass` (Transparency 0.3, Roughness 0.15) |
| Child parts | `NpcStand` ที่เคาน์เตอร์หน้าร้าน (ห่าง pivot ~9 studs ตาม Home ของ Willow); `Interact` เคาน์เตอร์ (Quest/คุยกับ Willow); `LightSource` ×4; `Emitter_ChimneySmoke` ที่ปล่องไฟ (สีควัน `#B8E0C0`) |
| Collision | ตัวอาคาร + bay window |
| Variation | ชิ้นเดียว |

#### ENV-B03 · `Building_Library`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 40 × 38 × 30 · `Building` · `Light = true` |
| ตำแหน่ง | (−78,0,48) Yaw 120 · Role `Bestiary` · NPC `npc_quill` (Home (−72,0,40) อยู่ทั้งวัน) |
| Description & story | ห้องสมุดสองชั้นของควิลล์ นักบันทึกสัตว์ — ปีกหลักหลังคาจั่วกว้าง + **หอทรงกลมหลังคากรวยสีน้ำเงินชนวน** สำหรับห้องอ่านหนังสือ, หน้าต่างวงกลมบานใหญ่, ระเบียงชั้นสองมีกล้องส่องทางไกลทองเหลืองชี้ไปทางป่า, ภาพวาดสัตว์ (เงาของ 8 สายพันธุ์) แปะที่หน้าต่าง, กองหนังสือล้นออกมาวางที่ม้านั่งหน้าประตู |
| Silhouette | ป้อมทรงกลมสูงกว่าตัวอาคาร (38) + จั่วกว้าง 40 — อาคารใหญ่ที่สุดในหมู่บ้านรองจากหอนาฬิกา |
| Tris | 9,000 / 3,800 / 1,100 — `Main` (≤ 6k), `Tower` (≤ 3k) |
| Texture | atlas หมู่บ้าน + `ATL_Stone_Carved` (ฐาน) |
| Child parts | ห้องโถงด้านหน้าเปิดได้ (ทางเข้าโค้ง) หรือโต๊ะเขียนหนังสือที่ระเบียงหน้า — `NpcStand` ที่ตำแหน่ง Home ของ Quill (ห่าง pivot ~10 studs); `Interact` (Bestiary UI); `LightSource` ×6; กล้องส่องทางไกลแยก MeshPart `Telescope` |
| Collision | Main + Tower + ขั้นบันได |
| Variation | ชิ้นเดียว |

#### ENV-B10 · `Building_House_Small_A`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 18 × 18 × 16 · `Building` · `Light = true` |
| ตำแหน่ง | (−110,0,−60) Yaw 60 — บ้านของ **Bramble** (จุดหมาย 19:00) |
| Story | กระท่อมคนทำงานหนัก หลังคามอส/ฟางหนาโค้ง, ประตูโค้งกลม, กองฟืน, ถุงมือทำสวนตากที่รั้ว |
| Silhouette | **หลังคาฟางโค้งมนคลุมต่ำเกือบถึงพื้น** + ปล่องไฟหินเตี้ยข้างเดียว — มนที่สุดในกลุ่มบ้าน |
| Tris / Tex | Small budget · หลังคา Moss Thatch `#8C8A4E`, บานหน้าต่าง Shutter Teal `#3E7F7A` |
| Child parts | `NpcDoor` หน้าประตู (−Z); `LightSource` ×2 |
| Variation | ห้ามใช้หลังคาฟางกับ Small_B/C |

#### ENV-B11 · `Building_House_Small_B`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 16 × 20 × 16 · `Building` · `Light = true` |
| ตำแหน่ง | (−40,0,95) Yaw 175 — บ้านของ **Pip** (Home) |
| Story | บ้านสองชั้นแคบของครอบครัวพิป เด็กที่หลงใหลสัตว์ — ชั้นบนยื่นออก (jetty) เหนือประตู, ชิงช้าเชือกที่กิ่งไม้ข้างบ้าน, ภาพวาดสัตว์ด้วยชอล์กบนผนัง, บ้านนกเล็กติดผนัง |
| Silhouette | **สูง-แคบ ชั้นบนยื่นเอียง** หลังคาจั่วชันชนวน `#56688A` |
| Tris / Tex | Small budget · บานหน้าต่าง Marigold `#E8A93A` |
| Child parts | `NpcDoor`; `LightSource` ×2 (ชั้นล่าง + ห้องเด็กชั้นบน) |
| Variation | — |

#### ENV-B12 · `Building_House_Small_C`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 18 × 17 × 18 · `Building` · `Light = true` |
| ตำแหน่ง | (40,0,110) Yaw −170 — ยังไม่มีเจ้าของใน Phase 1 (เผื่อ NPC ใหม่) |
| Story | บ้านทรงเตี้ยสี่เหลี่ยมจัตุรัสของคนสวน มีเพิงเก็บฟืนต่อข้าง (lean-to) และรั้วแปลงผักเล็ก |
| Silhouette | **หลังคาปั้นหยา (hip) เตี้ยแบน + เพิงข้าง** — แนวนอน ตรงข้าม Small_B |
| Tris / Tex | Small budget · หลังคา Terracotta `#B7593A`, บานหน้าต่าง Bunting Rose `#D9767A` |
| Child parts | `NpcDoor`; `LightSource` ×2 |

#### ENV-B13 · `Building_House_Medium_A`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 24 × 24 × 20 · `Building` · `Light = true` |
| ตำแหน่ง | (−120,0,10) Yaw 95 — บ้านของ **Elder Maribel** (20:00) |
| Story | บ้านผู้เฒ่า ทรงตัว L กล่องดอกไม้ทุกหน้าต่าง, กระดิ่งลมไม้ไผ่และเปลือกหอยหลายพวงที่ระเบียง (เสียงกระดิ่งลม = เบาะแสจิ้งจอก ทำให้ผู้เล่นนึกถึง), เก้าอี้โยกบนระเบียง |
| Silhouette | **ผัง L + ระเบียงหน้ามีหลังคาของตัวเอง** |
| Tris / Tex | Medium budget · หลังคา Terracotta + แพตช์ชนวน, บานหน้าต่าง Teal |
| Child parts | `NpcDoor`; `LightSource` ×3; `Emitter_ChimneySmoke` |

#### ENV-B14 · `Building_House_Medium_B`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 22 × 26 × 22 · `Building` · `Light = true` |
| ตำแหน่ง | (85,0,−75) Yaw −60 — บ้านของ **Willow** (21:00), ใกล้แม่น้ำ |
| Story | บ้านนักปรุงยา หน้าต่างหลังคา (dormer) กระจกใหญ่สำหรับปลูกต้นไม้ในร่ม, กระถางหลายขนาดบนบันได, ราวตากผ้าสีเขียวอ่อน |
| Silhouette | **dormer กระจกคู่บนหลังคาจั่วสูง** + บันไดหน้าบ้าน 3 ขั้น (ฐานยกเพราะใกล้แม่น้ำ) |
| Tris / Tex | Medium budget · หลังคา Moss Thatch ผสมแผ่นไม้มุง, บานหน้าต่าง Forest-ish `#3E7F7A` |
| Child parts | `NpcDoor`; `LightSource` ×3 |

#### ENV-B15 · `Building_House_Medium_C`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 26 × 22 × 20 · `Building` · `Light = true` |
| ตำแหน่ง | (−85,0,−110) Yaw 30 — ขอบหมู่บ้านใกล้ป่า, ยังไม่มีเจ้าของ |
| Story | บ้าน-ยุ้งฉางกว้างเตี้ย มีช่องเก็บฟางชั้นบน (hay loft) ประตูบานคู่ใหญ่, เป็นบ้านหลังสุดท้ายก่อนเข้าป่า — ผนังด้านป่ามีรอยข่วนเก่า/ขนสัตว์ติด (สัตว์มาแวะ) |
| Silhouette | **กว้าง-เตี้ย หลังคาจั่วแบบยุ้ง (gambrel) + ช่องรอกยื่น** |
| Tris / Tex | Medium budget · หลังคาแผ่นไม้มุง, บานประตูแดงซีด `#B7593A` 70% sat |
| Child parts | `NpcDoor`; `LightSource` ×2 |

#### ENV-B16 · `Building_House_Large_A`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 32 × 30 × 26 · `Building` · `Light = true` |
| ตำแหน่ง | (70,0,70) Yaw −140 — บ้านของ **Rowan** (Home) ช่างไม้/ผู้ดูแลทางป่า |
| Story | บ้านใหญ่สุดสองชั้นครึ่ง พร้อมโรงงานไม้ด้านข้าง (กองไม้ซุง, ม้าเลื่อย, เครื่องมือแขวน), หอสังเกตเล็กบนหลังคาสำหรับดูป่าตอนเช้า (Rowan ไปประตูเหนือ 06:00) |
| Silhouette | **หลังคาหลายระดับ + หอสังเกตเล็กบนสัน + โรงงานเพิงเปิดข้าง** |
| Tris / Tex | 6,000 / 2,500 / 800 · หลังคาชนวน + terracotta (สองส่วนต่างสีชัด) |
| Child parts | `NpcDoor`; `LightSource` ×4; `Emitter_ChimneySmoke` |

### 2.3 Props (ENV-P01 – P07, ENV-C01)

#### ENV-P01 · `Prop_MarketStall_A`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 12 × 12 × 8 · Shape `Stall` |
| ตำแหน่ง | (−20,0,24) Yaw 160 — Pip ยืนใกล้ตอน 07:00 (−18,20) |
| Story | แผงผลไม้ — ลังไม้ glowberry เรืองฟ้าจาง, ตะกร้า spirit plum, ตาชั่งแขวน, กันสาดผ้าลายทาง **ครีม-แดง** |
| Silhouette | **กันสาดผ้าโค้งทรงคลื่น (scalloped)** บนเสาไม้ 4 ต้น |
| Tris | 1,800 / 800 / 250 |
| Texture | `ATL_VIL_Props` + `ATL_VIL_Trim` |
| SurfaceAppearance | C, N, R; ผ้ากันสาด alpha ขอบ |
| Collision | `Hull` ของเคาน์เตอร์เท่านั้น; ผ้ากันสาด `CanCollide = false` |
| Child parts | `NpcStand` ด้านหลังแผง (แทนพิกัด Pip ที่อยู่ใน footprint); `Interact` (สำรองไว้ Phase 2) |
| Variation | A/B/C ใช้ชิ้นส่วนเดียวกันได้ ≤ 50% |

#### ENV-P02 · `Prop_MarketStall_B`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 12 × 12 × 8 · `Stall` |
| ตำแหน่ง | (22,0,26) Yaw −150 — Rowan ยืนใกล้ตอน 11:00 (24,22) |
| Story | แผงของจุกจิก — กระดิ่ง, โมบายไม้รูปสัตว์, ผ้าพันคอถัก, ธงราวสามเหลี่ยมระหว่างเสา |
| Silhouette | **หลังคาไม้แข็งทรงจั่วเล็ก** (ไม่ใช่ผ้า) + ธงราว + ของแขวนห้อยเป็นแนว |
| Tris / Tex / Collision | เหมือน P01 |
| Child parts | `NpcStand` หลังแผง |

#### ENV-P03 · `Prop_MarketStall_C`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 10 × 11 × 8 · `Stall` |
| ตำแหน่ง | (30,0,−6) Yaw −100 — ริม MarketLane (W8) ⚠ ตรวจว่ากันสาดไม่ยื่นทับเลน |
| Story | รถเข็นต้นไม้/สมุนไพรล้อไม้ — กระถางเฟิร์น, ดอกไม้ป่า, ร่มผ้าใบเดี่ยว |
| Silhouette | **รถเข็นมีล้อ 2 ล้อ + ร่มกลมคันเดียว** — เล็กสุดและไม่มีเสา 4 ต้น |
| Tris | 1,600 / 700 / 220 |
| Child parts | — |

#### ENV-P04 · `Prop_Cauldron_Public`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 6 × 5 × 6 · Shape `Prop` · Glow `#96FFAA` (150,255,170) · Role `Cauldron` |
| ตำแหน่ง | (52,0,−14) Yaw 0 หน้า Apothecary |
| Story | หม้อยาสาธารณะเหล็กหล่อดำอมเขียวบนขาตั้งหินสามขา ไฟใต้หม้อเป็นเปลวเย็นสีเขียว, ทัพพีไม้พาดขอบ, ชั้นวางขวดเปล่าข้าง ๆ ให้ทุกคนใช้ |
| Silhouette | ทรงกลมป่องปากแคบ + ขาสามขาหินเตี้ย + ทัพพียื่นเฉียง — ต่างจาก SAN-B03 ด้วยขาหินและความสะอาด |
| Tris | 2,200 / 950 / 300 |
| Texture | `ATL_VIL_Props` + `ATL_Magic_Emissive` (ผิวยา) |
| SurfaceAppearance | C, N, R, **M** (เหล็กหล่อ 0.6) |
| Collision | `Hull` |
| Child parts | `Interact` ที่ขอบหม้อสูง 4 (เปิด Crafting UI); `GlowSource` ×1 ผิวยา; `Emitter_Steam` ×1; `Emitter_Bubbles` ×1; ผิวยาแยก MeshPart `BrewSurface` (`AlphaMode = Overlay` ให้โค้ดเปลี่ยนสีตามสูตร) |

#### ENV-P05 · `Prop_CaveEntrance`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 20 × 16 × 10 · Shape `Arch` |
| ตำแหน่ง | (−298,0,−424) Yaw 70 — ปลาย HiddenTrail; อุโมงค์เริ่ม (−298,32,−424) ⚠ ดู WORLD_DESIGN WD-05 |
| Story | ปากถ้ำหินธรรมชาติบนไหล่เขา ม่านเฟิร์นและรากห้อยลงปิดครึ่งช่อง, rune เก่าจาง ๆ บนหินขอบบน, เศษคริสตัลม่วงเล็ก ๆ ตกที่ปากทาง (เบาะแส) |
| Silhouette | ช่องโค้งต่ำไม่สมมาตร (ช่องเปิด ~8 กว้าง × 8 สูง ≥ ทาง W4) หินยื่นเหมือนหน้าผากคิ้วขมวด — ดู "ธรรมชาติ" ไม่ใช่สิ่งก่อสร้าง |
| Tris | 3,200 / 1,300 / 400 |
| Texture | `ATL_Nature_Ground` + `ATL_Nature_Foliage` (ม่านเฟิร์น/ราก alpha) |
| SurfaceAppearance | C, N, R |
| Collision | `PreciseConvexDecomposition` ของหิน; ม่านเฟิร์น `CanCollide = false` |
| Pivot | กึ่งกลางฐานช่องเปิด; ช่องเปิดหัน −Z (ออกสู่ทาง) |
| Child parts | `Emitter_CaveMist` ×1; `GlowSource` ×1 ลึกในช่อง (แสงม่วงจาง ๆ ลอดออก ใช้ `#A082FF` ของ C01) |
| หมายเหตุ | ต้องผสานกับ terrain ของ Hill — ขอบหินยื่นลงใต้ pivot 2 studs และด้านหลังยาวพอปิดรอยต่อ voxel |

#### ENV-C01 · `Prop_CrystalCluster_A`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 14 × 18 × 14 · Shape `Crystal` · Glow `#A082FF` (160,130,255) |
| ตำแหน่ง | (−372,0,−462) กลาง Chamber (−372,28,−462) R22 ⚠ WD-06 |
| Story | กอคริสตัลอเมทิสต์ที่สะสมแสงจากรากต้นไม้ผู้เฒ่ามานับพันปี — teaser ของ Crystal Cavern (Phase 3); ฐานมีหินแม่สีเทาเข้ม, ผลึกใหญ่ 1 แท่ง + กลาง 4–5 + เล็กกระจาย |
| Silhouette | แท่งหลักเอียง 15° สูง 18 + ผลึกรองแผ่ออกแบบพัด — หกเหลี่ยมแต่ปลายมนเล็กน้อย (ไม่แหลมคม) |
| Tris | 2,800 / 1,200 / 350 |
| Texture | `ATL_Magic_Emissive` + `ATL_Nature_Ground` (ฐาน) |
| SurfaceAppearance | C, N, R (Roughness 0.15 ที่ผลึก); `AlphaMode = Overlay` ที่แกนในผลึกเพื่อให้โค้ด pulse สี |
| Collision | `Hull` |
| Child parts | `GlowSource` ×3 (แท่งหลัก + 2 กลาง) |
| Variation | ตัวอักษร `_A` บ่งว่าจะมี `_B`, `_C` ใน Phase 3 — ออกแบบ shape kit ให้ต่อยอดได้ |

#### ENV-P06 · `Prop_ShrineStone`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 6 × 10 × 6 · Shape `Rock` · Glow `#D2E6FF` (210,230,255) |
| ตำแหน่ง | (95,0,−810) Yaw 140 — กลางทุ่งดอกไม้ริมน้ำตก (spawn Lunar Stag) |
| Story | หินตั้งศาลจันทร์ แกะรูปจันทร์ 3 ข้างขึ้นเรียงแนวตั้ง (เสี้ยว-ครึ่ง-เต็ม) ร่องแกะเรืองเงินเฉพาะกลางคืน, ฐานมีเครื่องเซ่นเล็ก ๆ (moonleaf แห้ง) ที่ชาวบ้านทิ้งไว้ |
| Silhouette | แท่งหินตั้งเอียงไม่สมมาตร ยอดมนเว้าเป็นรูปเสี้ยวจันทร์ — ต่างจาก Rock_Moss ด้วยความตั้งสูงและร่องแกะ |
| Tris | 1,200 / 500 / 150 |
| Texture | `ATL_Stone_Carved` + `ATL_Magic_Emissive` (ร่อง) |
| SurfaceAppearance | C, N, R |
| Collision | `Hull` |
| Child parts | `GlowSource` ×1 (กลางคืนเท่านั้น); `Interact` (สำรอง — อ่านจารึก/Bestiary clue) |

#### ENV-P07 · `Prop_FloatingLantern`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 2 × 3 × 2 · Shape `Lantern` · Glow `#FFC878` (255,200,120) |
| ใช้โดย | Item `decor_lantern` (Footprint 2×2, 25 Lumen) — วางใน Sanctuary |
| Story | โคมกระดาษสาโครงไม้ไผ่ ฝาทองเหลืองเล็ก ลอยได้ด้วยหินเวทจิ๋วที่ก้นโคม; ภายในมีดวงไฟอุ่น |
| Silhouette | ทรงหยดน้ำกลับหัว/ทรงโคมจีนกลมป่อง + ฝาแหลมเล็ก + พู่ห้อยล่าง — ไม่มีขาตั้ง |
| Tris | 450 / 200 / 80 |
| Texture | 256² เฉพาะ หรือ cell ใน `ATL_VIL_Props` |
| SurfaceAppearance | C, R (กระดาษ `AlphaMode = Overlay` ให้โค้ด tint ได้) ; M เฉพาะฝา |
| Collision | `Box`, `CanCollide = false` |
| Pivot | กึ่งกลางก้นโคม — โค้ดยกลอยสูง ~3 studs และ bob ขึ้นลง |
| Child parts | `GlowSource` ×1 กลางโคม |
| Variation | — (Phase 2: สีกระดาษ cosmetic) |

### 2.4 Vegetation & Rocks (ENV-T, M, G, R)

**กฎร่วม:** เปลือกไม้จาก `ATL_Nature_Bark`, ใบจาก `ATL_Nature_Foliage` (cards + `AlphaMode = Transparency`), ใบต้องมีพื้นผิวรูปก้อน (clump mesh) ไม่ใช่ card ลอยเปล่า — card ใช้เฉพาะขอบเพื่อ silhouette ฟู; normal ของใบ **ถ่ายจากทรงกลม (spherical normals)** ให้แรเงานุ่มแบบสไตไลซ์; ลำต้น `Hull` หรือ `Col_Trunk`, ใบ `CanCollide = false`, `CanQuery = false`

#### Hero trees — ENV-T01 – T03 (วางด้วยมือใน `WorldLayout.HeroTrees`)

| Spec · Key | Size | ตำแหน่ง (Scale) | Story & Silhouette | Tris |
|---|---|---|---|---|
| **ENV-T01 · `Tree_Ancient_A`** | 34 × 70 × 34 | (−24,−190) ×1.2 · (−30,−505) ×1.15 | ต้นไม้ "ผู้เฝ้าประตู" — **ลำต้นเอียงโค้งเป็นซุ้ม 20°** รากยกสูงเหมือนขาเดิน, เรือนยอดก้อนใหญ่ 2 ก้อนหนักไปทางที่เอียง ใช้เฟรมทางเดิน (คู่กับ T02 ที่ปากทางป่า) | 9,000 / 3,500 / 1,000 (`Trunk` ≤ 6k, `Canopy` ≤ 3k) |
| **ENV-T02 · `Tree_Ancient_B`** | 30 × 64 × 30 | (26,−205) ×1.1 · (200,−610) ×1.25 | **ลำต้นตรงสูงเรียว + เรือนยอดทรงร่มแบนกว้าง** (umbrella) อยู่สูง — ให้ภาพแนวตั้งตัดกับ T01 ที่เอียง; มีเห็ดชั้น (bracket fungus) เกาะลำต้น | 8,500 / 3,300 / 950 |
| **ENV-T03 · `Tree_Ancient_C`** | 38 × 76 × 38 | (−70,−470) ×1.3 · (100,−870) ×1.2 | **ลำต้นแฝดแยกเป็นตัว V** มีโพรงกลวงที่โคนสูงพอผู้เล่นมุดได้ (2.5 × 6), เรือนยอดสามก้อน — ใหญ่ที่สุดในกลุ่ม ใช้เป็นฉากหน้า/ฉากหลังของ Elder Tree และ FallsTrail | 9,500 / 3,700 / 1,100 |

ร่วม: Texture `ATL_Nature_Bark` (คอลัมน์ "โบราณ") + `ATL_Nature_Foliage`; SurfaceAppearance C, N, R; Pivot กึ่งกลางโคนลำต้น (ไม่ใช่กึ่งกลางเรือนยอด เพราะลำต้นเอียง); Child: `Emitter_Leaves` ×1; Variation: แต่ละ key ใช้ 2 ครั้งใน layout ด้วย Yaw ต่างกัน → รูปทรงต้องดูดีทุกมุม 360°

#### Forest trees — ENV-T10 – T13 (Scatter `Tree_Forest`, Count 420, MinSpacing 26, Scale 0.85–1.35, MaxSlope 0.55)

| Spec · Key | Size | Silhouette ที่ต้องต่างกัน | Tris |
|---|---|---|---|
| **ENV-T10 · `Tree_Forest_A`** | 18 × 44 × 18 | **ทรงไข่กลม** (oak-like) ลำต้นโค้ง S เล็กน้อย เรือนยอดก้อนเดียวใหญ่ | 2,500 / 1,000 / 250 |
| **ENV-T11 · `Tree_Forest_B`** | 16 × 40 × 16 | **ทรงกรวยสไตไลซ์ซ้อนชั้น 3–4 ชั้น** (สนแบบนุ่ม ปลายชั้นม้วนขึ้น) | 2,200 / 900 / 220 |
| **ENV-T12 · `Tree_Forest_C`** | 20 × 48 × 20 | **กิ่งกางหลายก้อน (3–5 clusters)** ช่องว่างระหว่างก้อนให้แสงลอด — สูงสุดของกลุ่ม | 2,800 / 1,100 / 280 |
| **ENV-T13 · `Tree_Forest_D`** | 14 × 36 × 14 | **ต้นอ่อนเรียวใบห้อยลู่ (weeping)** ลำต้นบาง — ใช้แทรกให้ป่ามีจังหวะ | 1,800 / 750 / 180 |

ร่วม: งบรวมฉากป่าสูง — 420 instance → ใช้ StreamingEnabled + Atmosphere ป่า; Texture เฉพาะ atlas (ห้าม unique); สีเรือนยอดผ่าน vertex color 3 ระดับ (Canopy Green `#5E8A4A` / Deep Moss `#3F5B3A` / Fern Lime `#9BBF5C` ปลายยอด) โค้ดอาจสุ่ม `MeshPart.Color` tint ±6% ถ้าใช้ `AlphaMode = Overlay`; Collision `Col_Trunk` cylinder; ห้ามมีกิ่งต่ำกว่า 7 studs ที่ยื่นเกินรัศมีลำต้น 3 studs (กันผู้เล่น/สัตว์ติด และ `KeepOffPaths 14`)

#### Village trees — ENV-T20 – T21 (Scatter `Tree_Village`, Count 40, MinSpacing 34, Scale 0.9–1.2, KeepOffLandmarks 26)

| Spec · Key | Size | Story & Silhouette | Tris |
|---|---|---|---|
| **ENV-T20 · `Tree_Village_A`** | 16 × 26 × 16 | ต้นผลไม้ที่ชาวบ้านปลูก — **ทรงกลมแป้นตัดแต่ง** มีผล glowberry เรืองฟ้าจาง ๆ (ใช้ cell emissive เล็ก ไม่ต้องมี light) | 2,000 / 850 / 220 |
| **ENV-T21 · `Tree_Village_B`** | 14 × 22 × 14 | ต้นดอกบาน — **ลำต้นบิดเตี้ย กิ่งแผ่ออกด้านข้าง** ดอกชมพู Blossom `#F2B6C1`; `Emitter_Petals` ×1 | 1,800 / 750 / 200 |

#### Glow mushrooms — ENV-M01 – M03 (Scatter `Mushroom_Glow`, Count 260, MinSpacing 14, `NearTrees = true`)

| Spec · Key | Size | Glow | Silhouette | Tris |
|---|---|---|---|---|
| **ENV-M01 · `Mushroom_Glow_A`** | 3 × 3 × 3 | `#78E6FF` | กอ 3 ดอก **หมวกกลมแบน** (ทรงร่ม) ก้านโค้ง | 350 / 150 / 50 |
| **ENV-M02 · `Mushroom_Glow_B`** | 4 × 5 × 4 | `#C88CFF` | **ดอกเดี่ยวสูงหมวกทรงระฆัง/โคม** + ลูกเล็ก 2 — ตัวที่โค้ดใส่ PointLight (ทุก 4 กอ) | 400 / 180 / 60 |
| **ENV-M03 · `Mushroom_Glow_C`** | 2 × 2 × 2 | `#8CFFAA` | **กระดุมกลมเล็ก 5–7 ดอก** เกาะเป็นแพ | 300 / 130 / 40 |

ร่วม: `ATL_Magic_Emissive` (หมวก grayscale + `AlphaMode = Overlay` ให้สีมาจาก `MeshPart.Color` = Glow) + ก้านใน `ATL_Nature_Foliage`; Collision `Box`, `CanCollide = false`; Child `GlowSource` ×1 (โค้ดเปิด light ตามงบ); ใต้หมวกวาดเป็น gills สีสว่างกว่าหมวก 10% (แสงสะท้อนขึ้น)

#### Ferns — ENV-G01 – G02 (Scatter `Plant_Fern`, Count 700, MinSpacing 8)

| Spec · Key | Size | Silhouette | Tris |
|---|---|---|---|
| **ENV-G01 · `Plant_Fern_A`** | 4 × 3 × 4 | **กอเตี้ยแผ่ราบเป็นดาว** 8–10 ใบ | 400 / 180 / 60 |
| **ENV-G02 · `Plant_Fern_B`** | 5 × 4 × 5 | **กอตั้งสูงกว่า ใบโค้งออก + ยอดม้วน (fiddlehead) 2–3 ยอด** | 500 / 220 / 70 |

ร่วม: `ATL_Nature_Foliage` (alpha `Transparency`); Collision `CanCollide = false`, `CanQuery = false`; ต้องแยกจาก `Forage_silverfern` ได้ทันที (เฟิร์นทั่วไปเขียว `#9BBF5C`, silverfern ใบเงินมีประกาย)

#### Mossy rocks — ENV-R01 – R03 (Scatter `Rock_Moss`, Count 140, MinSpacing 30, Scale 0.6–1.8, KeepOffRiver 0 = วางในน้ำได้)

| Spec · Key | Size | Silhouette | Tris |
|---|---|---|---|
| **ENV-R01 · `Rock_Moss_A`** | 8 × 5 × 7 | **ก้อนมนทรงขนมปัง** มอสหนาด้านบนไหลลงข้างเดียว | 600 / 250 / 80 |
| **ENV-R02 · `Rock_Moss_B`** | 12 × 7 × 10 | **แผ่นหินยอดแบนเอียง** (นั่งได้) แตกเป็น 2 ชั้น | 800 / 350 / 100 |
| **ENV-R03 · `Rock_Moss_C`** | 5 × 4 × 5 | **กลุ่มก้อนเล็ก 3 ก้อน** ซ้อนกัน | 450 / 200 / 60 |

ร่วม: `ATL_Nature_Ground`; มอสด้านบน **ต้องอยู่ "บน" เสมอ** — ห้าม pivot หมุนแกนอื่นนอกจาก Y (โค้ดหมุนแค่ Yaw); ส่วนฝังดิน 1 stud ใต้ pivot; Collision `Hull`; ก้อนที่อยู่ในแม่น้ำมีคราบน้ำ — ใช้ decal ไม่ต้องทำ variant ใหม่

### 2.5 Forage Nodes (ENV-F01 – F04)

**กฎร่วม:** ผู้เล่นต้องแยก forage node ออกจาก scatter ได้ที่ระยะ 20 studs ด้วย (1) silhouette เฉพาะ (2) ประกาย/แสงเล็ก ๆ (3) ขนาดเกินสัดส่วนเล็กน้อย; `Interact` attachment ที่ความสูง 1–1.5 (`InteractDistance 10`); Collision `Box`, `CanCollide = false`; Respawn 90 วิ — โค้ดซ่อนโมเดลเมื่อเก็บ จึงต้องเป็น Model เดียว (ไม่ฝังกับ terrain); Tris ≤ 600; Texture cell ใน `ATL_Nature_Foliage` / `ATL_Magic_Emissive`; ชื่อ Key = `Forage_<itemId>` ตรงกับ `Items.lua`

| Spec · Key | Size | Glow | Description & silhouette | ไอคอนคู่ |
|---|---|---|---|---|
| **ENV-F01 · `Forage_silverfern`** | 3 × 2 × 3 | — | เฟิร์นใบเงินกอเล็ก ใบปลายม้วน ผิวใบ Roughness 0.4 ให้แวววับเมื่อหมุนกล้อง + จุดประกายอนุภาค `Emitter_Sparkle` | `icon_silverfern` |
| **ENV-F02 · `Forage_dewcap`** | 2 × 2 × 2 | `#78E6FF` | เห็ดหมวกถ้วยคว่ำหงายรับน้ำค้าง — **หยดน้ำใสบนหมวก** (MeshPart แยก `Dew`, Transparency 0.2) ต่างจาก Mushroom_Glow ด้วยหมวกหงายและหยดน้ำ | `icon_dewcap` |
| **ENV-F03 · `Forage_wisp_lily`** | 2 × 3 × 2 | `#FFF0B4` | ลิลลี่ก้านสูง ดอกรูปเปลวเทียนกลีบบาง บานเฉพาะยามค่ำ — กลีบแยก MeshPart `Petals` ให้โค้ดซ่อน/ย่อเมื่อเป็นกลางวัน (หุบ) ; `GlowSource` กลางดอก | `icon_wisp_lily` |
| **ENV-F04 · `Forage_honeyroot`** | 3 × 1 × 3 | — | ปมรากไม้สีน้ำผึ้งโผล่พ้นดิน มียางอำพันเยิ้ม (Roughness 0.2) + ใบเล็ก 2 ใบชี้ขึ้นให้มองเห็น | `icon_honeyroot` |

### 2.6 Sanctuary Placeables (SAN-H01 – H04, SAN-D01 – D05)

**กฎร่วม:** วางบน grid `GridSize = 2` → **footprint ของโมเดล (X/Z) ต้องตรงกับ `Footprint` ใน `Items.lua` เป๊ะ** ไม่ยื่นเกิน (ยกเว้นใบไม้/อนุภาคบางเบา ≤ 0.5 stud) เพราะ placement ตรวจชนด้วย footprint; หมุนได้ทีละ 90° → ทุกด้านต้องดูดี; pivot กึ่งกลางฐาน; ผู้เล่นวางสูงสุด 150 ชิ้น → งบต่อชิ้นต้องประหยัด

| Spec · Key | Item Id · Footprint · ราคา | Size · Glow | Description & story | Silhouette | Tris | Texture | Collision | Child parts |
|---|---|---|---|---|---|---|---|---|
| **SAN-H01 · `Habitat_KitsuneDen`** | `habitat_kitsune_den` · 10×10 · 150 | 10 × 7 × 10 | โพรงรากไม้อบอุ่น: รากโค้งเป็นโดม มอสคลุม ปากโพรงกลมขนาดจิ้งจอก ข้างในมีเบาะใบไม้แห้ง, โคมวิญญาณเล็กห้อยที่ราก, กระดิ่งลมเล็ก (เบาะแส) | โดมรากไม่สมมาตร + ปากโพรงเยื้องข้าง | 3,500 / 1,500 / 450 | `ATL_SAN_Habitat` + `ATL_Nature_Bark` | `Hull` ของโดม; ปากโพรงโล่ง | `CreatureSlot` ×3 (ใน/หน้าโพรง), `GlowSource` ×1 (โคม `#8CC4FF`) |
| **SAN-H02 · `Habitat_MoonGlade`** | `habitat_moon_glade` · 14×14 · 220 | 14 × 6 × 14 · `#D2E1FF` | ลานหญ้าเงินวงกลม + หินจันทร์ตั้ง 5 ก้อนเป็นวง (ก้อนสูงสุด 6), แอ่งน้ำเล็กสะท้อนดวงจันทร์ตรงกลาง | วงหินตั้งความสูงไม่เท่ากัน (ลดหลั่น) แบนต่ำ | 3,000 / 1,300 / 400 | `ATL_SAN_Habitat` + `ATL_Stone_Carved` | หินแต่ละก้อน `Hull`; หญ้า `CanCollide = false` | `CreatureSlot` ×2, `GlowSource` ×5 (บนหินแต่ละก้อน, กลางคืน), `DrinkSpot` ×1 |
| **SAN-H03 · `Habitat_MoleBurrow`** | `habitat_mole_burrow` · 8×8 · 120 | 8 × 4 × 8 | เนินดินกลมกับรูอุโมงค์ 3 รู, เศษคริสตัลฟ้า `#78DCD2` ที่ตุ่นสะสม, ป้ายไม้เล็กปักเอียง | เนินมน + รู 3 รูต่างระดับ | 2,200 / 950 / 300 | `ATL_Nature_Ground` + `ATL_SAN_Habitat` | `Hull` (เตี้ย เดินข้ามได้) | `CreatureSlot` ×3 (ที่ปากรู), `Emitter_Dirt` ×1 (โค้ดใช้ตอน `Dig`) |
| **SAN-H04 · `Prop_HatcheryNest`** | `incubator` · 6×6 · 80 | 6 × 4 × 6 · `#FFBE78` | รังกิ่งไม้สาน วางบนหินเวทอุ่น 3 ก้อนที่เรืองส้มจาง ๆ, ผ้าห่มถักเล็กพาดขอบ | ชามรังกลมบนสามขาหิน | 1,500 / 650 / 200 | `ATL_SAN_Habitat` + `ATL_Magic_Emissive` | `Hull` | `EggSlot` ×1 (กลางรัง สูง ~2.5), `GlowSource` ×1, `Emitter_Warmth` ×1 |
| **SAN-D01 · `Prop_GlowcapCluster`** | `decor_mushroom_lamp` · 4×4 · 30 | 4 × 4 × 4 · `#78E6FF` | กอเห็ดเรืองแสงหลายขนาด (5–7 ดอก) บนแผ่นดินกลม — เวอร์ชัน "จัดสวน" ของ M01–M03 | ขั้นบันไดความสูง 1–4 ไล่ระดับ บนฐานดิสก์ | 700 / 300 / 100 | `ATL_Magic_Emissive` | `Box`, `CanCollide = false` | `GlowSource` ×1 |
| **SAN-D02 · `Prop_RootBench`** | `decor_bench` · 6×2 · 40 | 6 × 3 × 2 | ม้านั่งที่รากไม้บิดตัวเองเป็นที่นั่งและพนัก, มีหน่อใบงอกที่ปลายพนัก | ขาเป็นรากโค้ง 2 ข้าง ไม่ใช่ขาตรง | 900 / 400 / 120 | `ATL_Nature_Bark` | `Hull` | `Seat` (Roblox Seat, ด้านหน้า −Z) |
| **SAN-D03 · `Prop_WildflowerPatch`** | `decor_flowerbed` · 6×6 · 20 | 6 × 1 × 6 | แปลงดอกไม้ป่าหลากสี (ชมพู, ทอง, ฟ้า, ขาว) สัตว์ชอบนอนเล่น | แบนต่ำ ขอบนุ่มไม่เป็นสี่เหลี่ยม (ภายใน footprint) | 700 / 300 / 100 | `ATL_Nature_Foliage` | `CanCollide = false` | `CreatureSlot` ×1 (จุดนอนเล่น) |
| **SAN-D04 · `Prop_RuneArch`** | `decor_stone_arch` · 8×4 · 90 | 8 × 10 × 4 · `#96C8FF` | ซุ้มหินโบราณขนาดเล็กสลักอักขระเรืองแสงฟ้า, เถาดอกไม้เลื้อย | **ซุ้มครึ่งวงกลมเตี้ยกว้าง** (ช่อง ~4 × 7) — ต่างจาก SanctuaryGate ที่สูงชะลูดแหลม | 1,800 / 800 / 250 | `ATL_Stone_Carved` + `ATL_Magic_Emissive` | `Collision`: เสา 2 ข้าง | `GlowSource` ×2 |
| **SAN-D05 · `Prop_SpringPond`** | `decor_pond` · 12×12 · 110 | 12 × 1 × 12 | บ่อน้ำพุใสขอบหินมนเตี้ย ผิวน้ำมีกลีบดอกลอย, น้ำพุเล็กผุดกลาง — สัตว์ใช้ดื่ม (+Joy) | ทรงไข่ไม่สมมาตรในกรอบ 12×12; ขอบสูง 1 | 1,600 / 700 / 220 | `ATL_SAN_Habitat` (หิน) + น้ำเป็น MeshPart แยก `Water` (Transparency 0.25, Roughness 0.05, `Texture` `Flow` ช้า) | ขอบหิน `Hull`; น้ำ `CanCollide = false` | `DrinkSpot` ×4 (รอบขอบ), `Emitter_Spring` ×1 |

> Size.Y = 1 ของ SAN-D05: grid placement ไม่ขุด terrain → ต้องเป็น **บ่อยกขอบ** (น้ำอยู่สูง ~0.7 ใต้ขอบ) ไม่ใช่บ่อลึกใต้ดิน

### 2.7 Sanctuary Fixed Structures (SAN-B01 – B03)

#### SAN-B01 · `Sanctuary_Cottage`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 26 × 24 × 22 · `Building` · `Light = true` |
| Story | กระท่อม "เกาะสัญญา" ที่รกร้างมานาน — ผู้เล่นเริ่มด้วยสภาพซ่อมแซมแล้วบางส่วน (หลังคาใหม่ครึ่ง เก่าครึ่ง), ระเบียงไม้รอบด้านหน้า, ปล่องไฟหิน, หน้าต่างกลมชั้นลอย, ไม้เลื้อยดอกขาว |
| Silhouette | หลังคาจั่วสูงทรงหมวกแม่มดนุ่ม (ปลายสันงอเล็กน้อย) + ระเบียงยื่น — ต้องต่างจากบ้านทุกหลังในหมู่บ้านด้วยหลังคาโค้งนี้ |
| Tris | 6,500 / 2,700 / 850 |
| Texture | `ATL_VIL_Trim` + `ATL_VIL_Roof` + palette Sanctuary (Cream Stone `#E4D6B8`, Driftwood `#A68B6A`) |
| SurfaceAppearance | C, N, R |
| Collision | `Collision` 2–3 กล่อง + ระเบียง |
| Child parts | `LightSource` ×4; `Interact` ที่ประตู (สำรอง Phase 2: ห้องเก็บของ/ตกแต่งภายใน); `Emitter_ChimneySmoke` |

#### SAN-B02 · `Sanctuary_ReturnGate`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 18 × 22 × 6 · `Arch` · Glow `#8CD2FF` |
| Story | ซุ้มคู่แฝดของ `Landmark_SanctuaryGate` แต่ทำจากหินเมฆสีครีมและไม้ลอยน้ำ — rune ชุดเดียวกัน (ภาษาเดียวกัน) เพื่อให้ผู้เล่นเข้าใจว่า "สองประตูนี้เชื่อมกัน" |
| Silhouette | ทรงแหลม ogee เดียวกับ L04 แต่ **กลับด้าน** ความไม่สมมาตร (หินเอียงไปอีกทาง) และไม่มีมอสคลุม |
| Tris | 3,200 / 1,400 / 400 |
| Texture | `ATL_Stone_Carved` (variant สีครีมผ่าน vertex color) + `ATL_Magic_Emissive` |
| Collision | เสา 2 ข้าง |
| Child parts | `PortalSurface`, `Interact`, `GlowSource` ×3, `SpawnPoint` ด้าน −Z ห่าง 6 studs (จุดเกิดเมื่อเข้าเกาะ) |

#### SAN-B03 · `Sanctuary_Cauldron`
| ฟิลด์ | Spec |
|---|---|
| Registry | Size 6 × 5 × 6 · `Prop` · Glow `#96FFAA` |
| Story | หม้อยาเก่าของเจ้าของเกาะคนก่อน ทองแดงขึ้นสนิมเขียว (patina) แขวนบนขาตั้งไม้สามขาแบบตั้งแคมป์ — ส่วนตัว อบอุ่น ต่างจากหม้อสาธารณะ |
| Silhouette | หม้อแขวนจากโครงไม้สามขา (tripod) — **ต่างจาก P04 ที่ตั้งบนหิน** |
| Tris | 2,000 / 900 / 280 |
| Texture | `ATL_VIL_Props` + `ATL_Magic_Emissive` |
| SurfaceAppearance | C, N, R, M (ทองแดง 0.5, patina 0) |
| Collision | `Hull` |
| Child parts | เหมือน P04: `Interact`, `GlowSource`, `Emitter_Steam`, `Emitter_Bubbles`, `BrewSurface` |

### 2.8 Environment summary

| หมวด | Keys | จำนวน |
|---|---|---|
| Landmarks | ENV-L01–L07 | 7 |
| Village buildings | ENV-B01–B03, B10–B16 | 10 |
| Props | ENV-P01–P07, ENV-C01 | 8 |
| Trees | ENV-T01–T03, T10–T13, T20–T21 | 9 |
| Mushrooms / Ferns / Rocks | ENV-M01–M03, G01–G02, R01–R03 | 8 |
| Forage | ENV-F01–F04 | 4 |
| Sanctuary placeables | SAN-H01–H04, SAN-D01–D05 | 9 |
| Sanctuary fixed | SAN-B01–B03 | 3 |
| **รวม** | | **58** |

**ลำดับความสำคัญในการผลิต (แนะนำ):** P0 = L01, L05, L04, P04, SAN-H01, SAN-H04, F01–F04 (critical path q01–q07) · P1 = Landmarks ที่เหลือ, B01–B03, T01–T03, T10–T13, SAN-B01–B03 · P2 = บ้าน, แผง, decor, scatter ที่เหลือ

---

## 3. Creature Specs

### 3.0 CRE-RIG — Standard Quadruped Rig

ทุกสายพันธุ์ใช้ชื่อกระดูกชุดเดียวกันเพื่อให้ระบบ expression/look-at ในโค้ดใช้ร่วมกันได้ — กระดูกเฉพาะสายพันธุ์เพิ่มเติมได้ แต่ **ห้ามเปลี่ยนชื่อกระดูกมาตรฐาน**

**โครงสร้างโมเดลใน Roblox**
```
Creature_<speciesId>_<Stage>  (Model, PrimaryPart = HumanoidRootPart)
├── HumanoidRootPart          (Part, Transparency 1, CanCollide false, กล่องครอบลำตัว, pivot = พื้นใต้ลำตัว หน้า −Z)
├── Body                      (MeshPart skinned — ตัว + หัว + หาง)
│   └── Root (Bone) → ... (ลำดับกระดูกด้านล่าง)
├── Eyes                      (MeshPart แผ่นตาโค้งเล็กน้อย, skinned กับ Head) 
│   └── Expression            (Decal — โค้ดสลับ Texture ตามอารมณ์)
├── AnimationController (หรือ Humanoid)
│   └── Animator
└── Animations (Folder)
    ├── Idle, Walk, Run, Sleep, Eat, Drink, Play, Happy, Scared, Ability   (Animation objects)
```

**Bone list (CRE-RIG v1)**

| กลุ่ม | กระดูก (ลำดับ parent → child) | หมายเหตุ |
|---|---|---|
| Core | `Root` → `Hips` → `Spine1` → `Spine2` → `Spine3` → `Neck` → `Head` | `Root` อยู่ที่พื้นใต้สะโพก (ตรงกับ pivot) ใช้สำหรับ root motion ของ Ability (MoonStep) เท่านั้น |
| Face | `Head` → `Jaw`; `Head` → `Eye_L`, `Eye_R` (look-at); `Head` → `EyelidUpper_L`, `EyelidUpper_R`, `EyelidLower_L`, `EyelidLower_R`; `Head` → `Brow_L`, `Brow_R` | eyelid ปิดได้สนิท (blink/sleep) |
| Ears | `Head` → `Ear_L_01` → `Ear_L_02`; `Head` → `Ear_R_01` → `Ear_R_02` | หูคือเครื่องมือแสดงอารมณ์อันดับ 1 |
| Tail | `Hips` → `Tail_01` → … → `Tail_NN` | จำนวนตามสายพันธุ์ |
| Front legs | `Spine3` → `Clavicle_FL` → `UpperArm_FL` → `Forearm_FL` → `Paw_FL` → `Toe_FL` (และ `_FR`) | |
| Hind legs | `Hips` → `Thigh_HL` → `Shin_HL` → `Hock_HL` → `Paw_HL` → `Toe_HL` (และ `_HR`) | |
| IK helpers (Blender only) | `IK_Paw_*`, `Pole_*` | **ไม่ export** (ลบ deform flag) |

ข้อกำหนดการ skin: ≤ 4 influences/vertex, normalize weights, ไม่มี vertex ที่ weight = 0; bone roll สม่ำเสมอ (Y-forward ตาม §7)

### 3.1 Facial Expression Approach

ระบบผสม 2 ชั้น:
1. **Bone-driven (ต่อเนื่อง):** eyelids, brows, ears, jaw — animator ใส่ใน clip; โค้ดอาจ override หู/เปลือกตาด้วย `Bone.Transform` สำหรับ blink อัตโนมัติ (ทุก 3–6 วิ) และ look-at (`Eye_L/R` หันหาผู้เล่นในระยะ 20 studs)
2. **Texture swap (สถานะ):** `Eyes.Expression` (Decal) — 8 ภาพ PNG 256×256 ต่อสายพันธุ์, ชื่อ `T_<speciesId>_Eye_<State>`:

| State | ใช้เมื่อ | ลักษณะ |
|---|---|---|
| `Neutral` | default | ม่านตากลมโต จุดประกาย 2 จุด |
| `Happy` | Happy, Bond, Feed favorite | ตาโค้ง ^^ |
| `Blink` | blink อัตโนมัติ | เส้นปิด |
| `Sleepy` | Sleep, Energy < 20 | ครึ่งปิด |
| `Scared` | Scared, Flee | ม่านตาเล็ก ขอบขาวมาก |
| `Love` | Trust ≥ 80 เข้าใกล้ผู้เล่น | ประกายรูปดาว/หัวใจเล็ก |
| `Curious` | Approach, เห็นของใหม่ | ม่านตาขยาย 1 ข้างโตกว่า |
| `Sad` | Joy < 25 | ตาตกเปลือกตาบนเอียง |

> เหตุผล: `SurfaceAppearance` เปลี่ยนตอน runtime ไม่ได้ จึงแยกตาเป็น MeshPart + Decal; เส้นและสีตาต้องเข้ากับ body texture

### 3.2 Animation List (ทุกสายพันธุ์) — 30 fps

| Animation (ชื่อตรงตัว) | Frames | Loop | Priority (Roblox) | Markers | หมายเหตุ |
|---|---|---|---|---|---|
| `Idle` | 120–180 | ✔ | Idle | — | หายใจ, ขยับหู, มองซ้ายขวา 1 ครั้ง; ห้ามมี "ท่าใหญ่" ที่ซ้ำให้เห็นชัด |
| `Walk` | 24–36 (1 รอบก้าว) | ✔ | Movement | `Step` ทุกก้าวเท้า | ความเร็วอ้างอิง = `Speed.Walk` ของสายพันธุ์ — ระบุ stride length ใน metadata ให้โค้ดปรับ playback speed |
| `Run` | 16–22 | ✔ | Movement | `Step` | อ้างอิง `Speed.Run`; ช่วงลอยตัวชัด |
| `Sleep` | 150–240 | ✔ | Idle | — | ขดตัว หายใจช้า eyelids ปิด; ท่าเข้า/ออกไม่ต้องแยก (โค้ด blend 0.4 วิ) |
| `Eat` | 48–72 | ✔ | Action | `Bite` | ก้มกินจากพื้น/มือผู้เล่น (หัวต่ำระดับ 0.5–1 stud) |
| `Drink` | 60–90 | ✔ | Action | `Lap` | ก้มเลียน้ำ; Stag ก้มคอยาว |
| `Play` | 72–120 | ✗ | Action | — | ท่าเล่นเฉพาะสายพันธุ์ (ด้านล่าง) จบที่ท่า Idle |
| `Happy` | 40–60 | ✗ | Action | `Sparkle` (เฟรมพีค) | ตอบรับอาหารโปรด/ลูบ/Trust up |
| `Scared` | 20–30 | ✗ | Action | — | สะดุ้ง ถอย หูลู่ แล้วโค้ดตัดเข้า Run (Flee) |
| `Ability` | 60–120 | ✗ | Action4 | `AbilityFire` (เฟรมที่ VFX เริ่ม), `AbilityEnd` | ดู §3.3–3.5 |

**Egg stage:** ใช้แค่ `Idle` (โยกเบา ๆ ทุก 4 วิ), `Happy` (กระดิกเมื่อถูกลูบ), `Sleep` (นิ่ง + เรืองแสงหายใจ) — ชื่ออื่นไม่ต้องมี (โค้ดต้อง fallback เป็น Idle) · rig ของ Egg: `Root` → `Shell` → `ShellTop` เท่านั้น

**Emotional reactions (แนะนำ — ยังไม่อยู่ใน `CreatureAnimations`; ต้องเพิ่มใน registry ก่อนโค้ดจะเรียกได้):** `Curious` (เอียงหัว 3 จังหวะ), `ShyPeek` (หลบหลังของแล้วโผล่), `Nuzzle` (ถูหัวกับผู้เล่น — ใช้ตอน Bond), `Sad` (นั่งหูตก), `Yawn`, `Stretch`, `Startle` (เล็กกว่า Scared ไม่วิ่งหนี), `Dislike` (สะบัดหน้าใส่อาหารที่ไม่ชอบ — ปัจจุบันใช้ `Scared` แทน) — ดู §8

**Stage proportions rule:** ทุก stage ใช้ชื่อกระดูกเดียวกันแต่ **สัดส่วนต่างกัน (ไม่ใช่ scale)** — animation ต้องทำแยกต่อ stage หรือ retarget แล้วแก้มือ; Baby เคลื่อนไหวเร็ว กระเด้ง ซุ่มซ่าม, Adult มั่นคงสง่า. `Species.Size` (Baby/Juvenile/Adult) เป็น scale ที่โค้ดคูณ "บน" โมเดล — **ต้องตกลงกับ Code:** (ก) artist ทำทุก stage ที่ขนาด Adult-reference แล้วโค้ดคูณ `Species.Size` หรือ (ข) artist ทำขนาดจริงต่อ stage และโค้ดใช้ scale = 1 — เอกสารนี้แนะนำ (ข) เพราะสัดส่วนเปลี่ยนต่อ stage อยู่แล้ว; `Species.Size` ไม่มีค่าของ `Egg`

---

### 3.3 CRE-01 · Spirit Kitsune (`spirit_kitsune`) — จิ้งจอกวิญญาณ

| ข้อมูล | ค่า |
|---|---|
| Element / Rarity / ActiveTime | Spirit · Uncommon · **Dusk** |
| Personalities | Playful, Curious, Shy |
| Palette | Primary `#F2ECE4` (ขนครีมขาว) · Secondary `#8CC4FF` (ปลายหาง/หู "สงบ") · Accent `#FFC478` (ปลายหาง "ดีใจ", ดวงตา) |
| Lore cue | เกิดจากแสงหิ่งห้อยนับพันดวง **หางสามหาง** เรืองตามอารมณ์ — ฟ้าเมื่อสงบ ทองเมื่อดีใจ |
| Ability | `WispLight` — แสงวิญญาณนำทาง: ปล่อยดวงไฟวิญญาณส่องทางในที่มืด |
| Clues | รอยเท้าเรืองแสงจาง ๆ · เสียงกระดิ่งลมทั้งที่ไม่มีลม · กลีบดอกไม้ลอยวนเป็นวง |
| Personality in silhouette | หูใหญ่ตั้งไวรับรู้ (อยากรู้), หางสามหางพลิ้วเป็นตัว S (ขี้เล่น), ตัวเรียวยาวพร้อมหลบ (ขี้กลัว) — ท่ายืนเอียงหัว 10° เป็น default |

**Stages**

| Stage | Concept & สัดส่วน | Tris | Texture |
|---|---|---|---|
| **Egg** | ไข่ทรงหยดน้ำสีครีมมุก ลายเกลียวสามเส้นสีฟ้าเรืองวนจากยอด (ใบ้หางสาม), ผิวโปร่งแสงเล็กน้อยเห็นแสงเต้นข้างใน; สูง ~1.6 studs | 1,200 | 512² |
| **Baby** | หัว:ตัว ≈ 1:1, หูใหญ่เกินหัว (หูยาว 70% ของหัว), ขาสั้นอวบ, ตาใหญ่ 30% ของหน้า, **หางสามหางสั้นป่องเหมือนพุ่มขนนุ่ม** ยังไม่แยกชัด, ขนฟูทั้งตัว ปลายหางเรืองแค่จุดเล็ก | 4,000 | 1024² body + eyes 256² |
| **Juvenile** | หัว:ตัว ≈ 1:1.6, ขายืดยาว (ช่วงซุ่มซ่าม), หูยังใหญ่ ตัวผอมลง, **หางยาวเท่าตัวแยกเป็นสามชัดเจน** ปลายเรืองครึ่งหาง, มีแผงขนคอเริ่มขึ้น | 6,000 | 1024² + 256² |
| **Adult** | หัว:ตัว ≈ 1:2.2, ตัวเพรียวสง่า อกมีแผงขนฟูเหมือนผ้าพันคอ, หน้าแคบลงตาเรียวขึ้นแต่ยังโต, **หางสามหางยาว 1.3× ลำตัวพลิ้วแยกกันเป็นพัด** ปลายเรืองกว้าง 40% ของหาง, ลายเส้นฟ้าจางที่ขา/หน้าผาก; สูงถึงไหล่ ≈ 3 studs (ระดับเข่า-สะโพกผู้เล่น) | 8,000 (body ≤ 7k + eyes) | 1024² + 256² |

**Rig เพิ่มเติม (CRE-01)**
- หางสาม chain: `TailA_01–05`, `TailB_01–05`, `TailC_01–05` (parent = `Hips`) — CRE-01 ไม่มี `Tail_*` (Baby ใช้ 3 กระดูกต่อหาง: `_01–03`)
- `Ruff` (แผงขนคอ, parent `Spine3`) — Juvenile/Adult
- รวม ≈ 56 กระดูก (Adult)

**Mood tail glow (เทคนิค):** ColorMap ของ `Body` ปลายหางเป็น **alpha = 0** + `AlphaMode = Overlay` → โค้ดตั้ง `Body.Color` = `#8CC4FF` (สงบ) / `#FFC478` (ดีใจ) / ขาว (กลัว) ; เพิ่ม `GlowSource` attachments ×3 ที่ `TailA_05`, `TailB_05`, `TailC_05` (parent กับกระดูก) ให้โค้ดใส่ PointLight Range 8

**Animation notes (CRE-01)**

| Anim | Frames | Notes |
|---|---|---|
| Idle | 150 | นั่งครึ่งตัว หางสามโบกสลับเฟสกัน (ไม่ sync), หูกระดิกฟังเสียง 1 ครั้ง |
| Walk | 28 | ก้าวเบาเหมือนเขย่ง หางลอยตาม (ช้ากว่าตัว 4–6 เฟรม) |
| Run | 18 | วิ่งกระโดดแบบ bound หางลู่ชิดกันเป็นลำเดียว |
| Sleep | 180 | ขดเป็นวงกลม หางสามพันรอบตัวเหมือนผ้าห่ม ปลายหางเรืองหายใจ |
| Eat | 60 | ก้มงับเร็ว 2 ครั้งแล้วเคี้ยว หูกระดิก |
| Drink | 72 | เลียน้ำเร็ว หางนิ่ง |
| Play | 96 | กระโจนไล่จับดวงไฟวิญญาณของตัวเอง หมุน 1 รอบ แล้วนั่งหอบ |
| Happy | 48 | หางสามตั้งพัดออกพร้อมกัน (โค้ดเปลี่ยนสีเป็นทอง) + กระดิกก้น |
| Scared | 24 | สะดุ้งตัวลอย หูลู่ หางรวบหนีบ |
| Ability (`WispLight`) | 90 | นั่งตั้งตรง หลับตา หางสามยกขึ้นเหมือนเปลวเทียน → เฟรม 45 `AbilityFire`: ปลายหางปล่อยดวงไฟ → ลืมตา |

**Ability VFX — WispLight:** ดวงไฟวิญญาณ 3 ดวง (ขนาด 0.6 stud) ลอยออกจากปลายหางแต่ละหาง สี `#8CC4FF` แกนกลาง `#FFFFFF`, หมุนวนรอบตัวแล้วลอยนำหน้าผู้เล่น 6–10 studs; แต่ละดวงมี PointLight Range 16, Brightness 1.5; อนุภาคหาง (trail) สั้น 0.4 วิ; หายไปพร้อมฝุ่นแสงทอง `#FFC478` — ใช้ในถ้ำลับ/ป่ากลางคืน

---

### 3.4 CRE-02 · Lunar Stag (`lunar_stag`) — กวางจันทรา

| ข้อมูล | ค่า |
|---|---|
| Element / Rarity / ActiveTime | Moon · Rare · **Night** |
| Personalities | Shy, Solitary, Curious |
| Palette | Primary `#4E5C8C` (ขนน้ำเงินคราม) · Secondary `#D2E2FF` (จุดดาว/ท้อง/เขา) · Accent `#FFF6D2` (แสงจันทร์ในเขา, ดวงตา) |
| Lore cue | **เขาเปลี่ยนรูปตามข้างขึ้นข้างแรม**; คืนเดือนมืดซ่อนที่ริมน้ำตก; ยอมให้เห็นเฉพาะผู้ที่เดินแผ่วเบา |
| Ability | `MoonStep` — ก้าวแสงจันทร์: กระโดดข้ามระยะไกลทิ้งรอยแสงจันทร์บนพื้น |
| Clues | ใบไม้เป็นประกายเงินตามทางเดิน · รอยกีบรูปพระจันทร์เสี้ยว · เสียงกระซิบใกล้แหล่งน้ำ |
| Personality in silhouette | ขายาวเรียวสง่า (ระยะหนี 34 — ไวที่สุด), คอยาวตั้งสูงระวังภัย (ขี้กลัว), ยืนห่างคนอื่นทรงสูงโดดเดี่ยว (สันโดษ) |

**Stages**

| Stage | Concept & สัดส่วน | Tris | Texture |
|---|---|---|---|
| **Egg** | ไข่ทรงรีสีน้ำเงินคราม ลายจุดดาว `#D2E2FF` ที่เรืองตามจังหวะ, เปลือกมีรอยนูนรูปเสี้ยวจันทร์ด้านหนึ่ง; สูง ~1.8 studs | 1,200 | 512² |
| **Baby** | ลูกกวางขายาวเก้งก้าง (ขา 60% ของความสูง), หัวโตตาโต, หูกว้างแบบใบไม้, **ยังไม่มีเขา — มีตุ่มเรืองแสงสองจุดบนหัว**, ลายจุดดาวเยอะบนหลัง | 4,500 | 1024² + 256² |
| **Juvenile** | คอยาวขึ้น ลำตัวยืด ลายจุดเริ่มจางรวมเป็นแถบ, **เขาเริ่มเป็นกิ่งเล็ก 2 แฉกโปร่งแสง** | 6,500 | 1024² + 256² |
| **Adult** | สง่าที่สุดในเกม คอยาวโค้ง อกกว้าง ขาเรียวยาว กีบเงิน, ลายดาวเหลือแค่ที่สะโพกและหน้าผาก, **เขากิ่งก้านกว้าง ~1.2× ความกว้างไหล่ ภายในมีแสงจันทร์ไหลเป็นเส้น**; สูงถึงไหล่ ≈ 5 studs (เท่าผู้เล่น) | 9,000 (body ≤ 7k + antlers ≤ 2k) | 1024² body + 512² antlers + 256² eyes |

**Rig เพิ่มเติม (CRE-02)**
- คอยาว: เพิ่ม `Neck2` แทรกระหว่าง `Neck` กับ `Head` (`Neck` → `Neck2` → `Head`) — ชื่อ `Neck` มาตรฐานคงเดิม
- หางสั้น `Tail_01–02`
- เขา: **MeshPart แข็งแยก** ไม่ skinned — `Antler_Crescent`, `Antler_Half`, `Antler_Full` ยึดกับกระดูก `Head` ผ่าน `RigidConstraint` (Attachment0 = Bone `Head`) โค้ดสลับ `Transparency` ตามข้างขึ้นข้างแรม (Phase 1: ใช้ `Antler_Full` เป็นค่าเริ่มต้นถ้าโค้ดยังไม่มี moon phase); เขาเรืองด้วย `AlphaMode = Overlay` + `GlowSource` ×2 ที่ปลายเขา
- รวม ≈ 52 กระดูก

**Animation notes (CRE-02)**

| Anim | Frames | Notes |
|---|---|---|
| Idle | 180 | ยืนนิ่งสง่า หูหมุนฟังทีละข้าง, เงยหน้ามองจันทร์ 1 ครั้ง |
| Walk | 36 | ก้าวยาวช้า (Walk 8) คอโยกตามจังหวะ |
| Run | 20 | กระโจนสองจังหวะแบบ stotting เบา ๆ — ลอยนาน (Run 30 เร็วสุดของ Phase 1) |
| Sleep | 210 | หมอบพับขา คอโค้งพาดหลัง เขาเรืองหรี่ลง |
| Eat | 66 | ก้มเล็มใบไม้จากพื้น/มือ เคี้ยวช้า |
| Drink | 90 | กางขาหน้าเล็กน้อยก้มคอยาว ผิวน้ำเป็นวง (โค้ดใส่ ripple ที่ `Bite`/`Lap` marker) |
| Play | 108 | วิ่งวนเป็นวงกว้างทิ้งรอยแสง 3 รอยแล้วหยุดสะบัดหัว |
| Happy | 54 | ก้มหัวโค้งให้ผู้เล่น (bow) เขาเรืองสว่างวาบ |
| Scared | 26 | ยกหัวสูงสุด ตาโต กระทืบกีบหน้า 1 ครั้ง → โค้ดตัดเข้า Run |
| Ability (`MoonStep`) | 110 | ย่อตัว (เฟรม 0–30) → เฟรม 32 `AbilityFire` กระโดดโค้งไกล (**ใช้ root motion บน `Root`**: ระยะอ้างอิง 24 studs, สูง 8) → ลงพื้นนุ่มเฟรม 80 → `AbilityEnd` |

**Ability VFX — MoonStep:** ตอนกระโดด Beam ริบบิ้นแสง `#D2E2FF` ตามสะโพก, ฝุ่นดาวร่วงจากกีบ; จุดลงและจุดออกตัวทิ้ง **decal รอยกีบรูปเสี้ยวจันทร์** สี `#FFF6D2` เรืองแล้ว fade ใน 4 วิ (ตรงกับ Clue "รอยกีบรูปพระจันทร์เสี้ยว"); ไม่มีเสียงดัง — เป็นเสียงกระดิ่งแก้วเบา ๆ

---

### 3.5 CRE-03 · Treasure Mole (`treasure_mole`) — ตุ่นนักขุดสมบัติ

| ข้อมูล | ค่า |
|---|---|
| Element / Rarity / ActiveTime | Earth · Common · **Day** |
| Personalities | Curious, Playful, Solitary |
| Palette | Primary `#785C4A` (ขนน้ำตาลกำมะหยี่) · Secondary `#E8C4A0` (หน้า/ท้อง/อุ้งเท้า) · Accent `#78DCD2` (จมูกคริสตัล, ปลายเล็บ, เศษแร่ที่สะสม) |
| Lore cue | ตัวกลม จมูกไวต่อแร่คริสตัล สะสมของแวววาวในโพรง โผล่มาทักนักเดินทางใจดีด้วยเสียงจิ๊บ ๆ |
| Ability | `Dig` — ขุดหาสมบัติ: ขุดดินหาสมุนไพรและของมีค่าให้เจ้าของวันละครั้ง |
| Clues | กองดินเล็ก ๆ เป็นแนวยาว · เศษคริสตัลเล็ก ๆ ตกอยู่ · เสียงขุดดินใต้เท้า |
| Personality in silhouette | ตัวกลมเหมือนก้อนขนมปัง (เป็นมิตร, Common = ตัวแรกที่ผู้เล่นมักเจอ), จมูกยื่นชี้ไปข้างหน้า (อยากรู้), อุ้งเท้าหน้าใหญ่เกินตัว (นักขุด) |

**Stages**

| Stage | Concept & สัดส่วน | Tris | Texture |
|---|---|---|---|
| **Egg** | ไข่กลมป้อมสีน้ำตาลทราย ผิวขรุขระเหมือนก้อนดินมีเศษคริสตัลฟ้าฝังอยู่ 3–4 จุด; สูง ~1.2 studs | 1,000 | 512² |
| **Baby** | ก้อนกลมเกือบสมบูรณ์ (สูง:ยาว ≈ 1:1.1), ตาเป็นจุดเล็กแต่มีประกาย (ตุ่นตาเล็ก — ชดเชยด้วย brows ใหญ่), จมูกชมพูอมฟ้าเล็ก, อุ้งเท้าหน้าใหญ่เท่าหัว | 3,500 | 1024² + 256² |
| **Juvenile** | ตัวยาวขึ้นเป็นทรงลูกแพร์, จมูกยื่นยาวเริ่มมีผลึกคริสตัลที่ปลาย, เล็บหน้า 5 เล็บเห็นชัด | 5,000 | 1024² + 256² |
| **Adult** | ทรงหยดน้ำนอนอวบ, **จมูกยาวปลายเป็นผลึกคริสตัลฟ้าเรืองจาง**, อุ้งเท้าหน้ากว้างเหมือนพลั่ว เล็บปลายคริสตัล, กระเป๋าขนที่ท้อง (เก็บของแวววาว — มีเศษคริสตัลโผล่), หนวดยาว; สูงถึงหลัง ≈ 1.8 studs (ข้อเท้า-เข่าผู้เล่น) | 6,500 | 1024² + 256² |

**Rig เพิ่มเติม (CRE-03)**
- `Snout_01` → `Snout_02` (parent `Head`) — จมูกฟุดฟิด
- `Whisker_L`, `Whisker_R`
- นิ้วหน้า: `Digit_FL_1–3`, `Digit_FR_1–3` (parent `Paw_F*`) สำหรับท่าขุด
- หางสั้น `Tail_01–02`
- Ears: ตุ่นหูเล็ก — ใช้ `Ear_*_01` เท่านั้น (ไม่มี `_02`) แต่ต้องคงชื่อไว้
- รวม ≈ 50 กระดูก

**Animation notes (CRE-03)**

| Anim | Frames | Notes |
|---|---|---|
| Idle | 120 | นั่งยองดมอากาศ จมูกฟุดฟิด (Snout loop เร็ว), หันซ้ายขวา |
| Walk | 24 | เตาะแตะ ตัวโยกข้าง (Walk 7) |
| Run | 16 | วิ่งรัวสั้น ๆ ตัวกลิ้งเกือบจะเป็นลูกบอล (Run 14 ช้าสุด — ดูตลก ไม่ใช่น่าสงสาร) |
| Sleep | 150 | นอนหงายท้องป่อง อุ้งเท้าหน้ากอดอก (Solitary: ขดในรู) |
| Eat | 54 | จับอาหารด้วยอุ้งเท้าหน้าสองข้างแล้วแทะรัว |
| Drink | 60 | จุ่มจมูกแล้วสะบัด |
| Play | 84 | ขุดหลุมเล็กแล้วโผล่หัวจากอีกด้าน ("ปิดตาจ๊ะเอ๋") |
| Happy | 44 | ยืนสองขาหลังปรบอุ้งเท้า + กระโดดเล็ก |
| Scared | 22 | มุดหัวลงดินครึ่งตัว ก้นโผล่สั่น → โค้ดตัดเข้า Run |
| Ability (`Dig`) | 100 | ดมพื้น 3 จังหวะ → ขุดรัวด้วยอุ้งเท้าหน้า (ดินกระเด็นข้างหลัง) → เฟรม 70 `AbilityFire` ดึงของขึ้นมาชูด้วยความภูมิใจ → `AbilityEnd` |

**Ability VFX — Dig:** อนุภาคดิน (สี Loam `#4A3A2C` + Secondary `#E8C4A0`) พ่นเป็นโค้งไปด้านหลัง 1.5 วิ, ก้อนดินเล็กกลิ้ง; ที่ `AbilityFire` ประกายคริสตัล `#78DCD2` 4–6 จุด + ของที่ได้ (โมเดลไอคอน 3D เล็กหรือ BillboardGui ไอคอน item) เด้งขึ้น 2 studs; เหลือกองดินเล็ก (decal/MeshPart ชั่วคราว 10 วิ) — ตรงกับ Clue "กองดินเล็ก ๆ เป็นแนวยาว"

### 3.6 Creature delivery matrix

| Model name | Spec | Tris | Animations |
|---|---|---|---|
| `Creature_spirit_kitsune_Egg` | CRE-01 | 1,200 | Idle, Happy, Sleep |
| `Creature_spirit_kitsune_Baby` | CRE-01 | 4,000 | ทั้ง 10 |
| `Creature_spirit_kitsune_Juvenile` | CRE-01 | 6,000 | ทั้ง 10 |
| `Creature_spirit_kitsune_Adult` | CRE-01 | 8,000 | ทั้ง 10 |
| `Creature_lunar_stag_Egg` | CRE-02 | 1,200 | Idle, Happy, Sleep |
| `Creature_lunar_stag_Baby` | CRE-02 | 4,500 | ทั้ง 10 |
| `Creature_lunar_stag_Juvenile` | CRE-02 | 6,500 | ทั้ง 10 |
| `Creature_lunar_stag_Adult` | CRE-02 | 9,000 | ทั้ง 10 |
| `Creature_treasure_mole_Egg` | CRE-03 | 1,000 | Idle, Happy, Sleep |
| `Creature_treasure_mole_Baby` | CRE-03 | 3,500 | ทั้ง 10 |
| `Creature_treasure_mole_Juvenile` | CRE-03 | 5,000 | ทั้ง 10 |
| `Creature_treasure_mole_Adult` | CRE-03 | 6,500 | ทั้ง 10 |

รวม 12 โมเดล, 3 × 3 × 10 + 3 × 3 = **99 animation clips**. แอนิเมชันใส่เป็น Animation objects ในโฟลเดอร์ `Animations` ของแต่ละโมเดล **หรือ** กรอก AnimationId ใน `AssetRegistry.Creatures[<speciesId>].Animations` (ใช้ร่วมทุก stage ถ้าไม่ได้ใส่ในโมเดล)

**ขนาดใน Roblox:** ทุก stage รวม ≤ 9,000 tris จึงอยู่ใต้ขีด 10,000 ต่อ MeshPart; HumanoidRootPart ต้องครอบลำตัว (ไม่รวมหาง) เพื่อ pathfinding agent radius ที่ถูกต้อง — Kitsune Adult ~2 × 3 × 4, Stag Adult ~2.5 × 5 × 5, Mole Adult ~1.8 × 1.8 × 2.6

---

## 4. UI Icon Spec

**มาตรฐาน:** PNG 256×256 RGBA โปร่งใส · subject อยู่ใน safe area 224×224 (ขอบ 16 px) · มุมมอง 3/4 จากบน-หน้าเล็กน้อย · hand-painted เหมือน texture · แสงหลักซ้ายบน + rim light อุ่นขวา · เส้นขอบ (ink outline) 3 px สี `#0F1830` opacity 70% เพื่ออ่านบน Midnight Blue `#1B2A4A` · เงาตกด้านล่าง 1 ชั้นนุ่ม (opacity 25%) · ไม่มีกรอบ/พื้นหลัง (UI ใส่กรอบทอง `#C9A45C` เอง) · ทดสอบอ่านออกที่ 48 px · ชื่อไฟล์ = Icon key · อัปโหลดแล้วใส่ใน `AssetRegistry.Icons[<IconKey>]` (ถ้าว่าง UI แสดงตัวอักษรย่อบนกรอบทอง)

| Icon Key | Item Id | Category | Subject & silhouette | สีหลัก |
|---|---|---|---|---|
| `icon_glowberry` | glowberry | Food | พวงเบอร์รี่กลม 3 ลูก + ใบ 1 ใบ, ลูกเรืองแสงจากข้างใน | `#78E6FF` บน `#3F5B3A` |
| `icon_spirit_plum` | spirit_plum | Food | พลัมลูกเดียวผิวใสฟ้า เห็นแสงวนข้างใน, ก้านมีใบเล็ก | `#8CC4FF`, ประกาย `#FFC478` |
| `icon_moonleaf` | moonleaf | Food | ใบไม้เดี่ยวรูปเสี้ยวจันทร์ เส้นใบเงินเรือง | `#D2E2FF`, ขอบ `#4E5C8C` |
| `icon_honeyroot` | honeyroot | Food | ปมรากอวบ 2 แฉก ยางอำพันหยด 1 หยด | `#C98B4A`, `#E8A93A` |
| `icon_crystal_grub` | crystal_grub | Food | หนอนอวบ 3 ปล้อง ผิวคริสตัลฟ้าโปร่ง ยิ้ม (น่ารัก ไม่น่าขยะแขยง) | `#78DCD2` |
| `icon_silverfern` | silverfern | Herb | ใบเฟิร์นเดี่ยวปลายม้วน สีเงินมีประกาย 2 จุด | `#C8D0D8`, `#9BBF5C` |
| `icon_dewcap` | dewcap | Herb | เห็ดหมวกหงายมีหยดน้ำใสบนหมวก | `#78E6FF` |
| `icon_wisp_lily` | wisp_lily | Herb | ดอกลิลลี่รูปเปลวเทียนบาน แสงทองตรงกลาง | `#FFF0B4`, `#F2ECE4` |
| `icon_healing_salve` | healing_salve | Potion | กระปุกดินเผาเตี้ยฝาผ้าผูกเชือก ใบเฟิร์นเงินเหน็บ, ขี้ผึ้งเขียวล้นขอบ | `#96FFAA`, `#B7593A` |
| `icon_calming_draught` | calming_draught | Potion | ขวดแก้วกลมคอยาว ของเหลวม่วงอ่อนมีดอกลิลลี่ลอย, ไอระเหยเป็นเกลียว | `#C88CFF`, `#FFF0B4` |
| `icon_growth_tonic` | growth_tonic | Potion | ขวดแก้วทรงหยดน้ำ ของเหลวทองมีต้นอ่อนงอกจากจุก | `#E8A93A`, `#8DBF6A` |
| `icon_egg_kitsune` | egg_spirit_kitsune | Egg | ไข่หยดน้ำครีมมุก ลายเกลียวฟ้า 3 เส้น (ตรงกับ `Creature_spirit_kitsune_Egg`) | `#F2ECE4`, `#8CC4FF` |
| `icon_kitsune_den` | habitat_kitsune_den | Habitat | โดมรากไม้มอสคลุม ปากโพรงกลมมีแสงฟ้า | `#5A4332`, `#8CC4FF` |
| `icon_moon_glade` | habitat_moon_glade | Habitat | วงหินจันทร์ 3 ก้อนบนหญ้าเงิน จันทร์เสี้ยวเหนือ | `#D2E1FF`, `#4E5C8C` |
| `icon_mole_burrow` | habitat_mole_burrow | Habitat | เนินดินมีรู 2 รู + เศษคริสตัลฟ้า | `#785C4A`, `#78DCD2` |
| `icon_incubator` | incubator | Habitat | รังกิ่งไม้สานบนหินเรืองส้ม (ไม่มีไข่ — แยกจาก icon_egg) | `#A68B6A`, `#FFBE78` |
| `icon_lantern` | decor_lantern | Decor | โคมกระดาษลอย ฝาทองเหลือง พู่ห้อย | `#FFC878` |
| `icon_glowcap` | decor_mushroom_lamp | Decor | กอเห็ดสามขนาดบนแผ่นดินกลม | `#78E6FF`, `#C88CFF` |
| `icon_bench` | decor_bench | Decor | ม้านั่งรากไม้โค้ง หน่อใบที่พนัก | `#7A5434`, `#9BBF5C` |
| `icon_flowerbed` | decor_flowerbed | Decor | แปลงดอกไม้ป่า 4 สีทรงวงรี | `#F2B6C1`, `#E8A93A`, `#7CC6D9` |
| `icon_rune_arch` | decor_stone_arch | Decor | ซุ้มหินครึ่งวงกลม rune ฟ้าเรือง | `#E4D6B8`, `#96C8FF` |
| `icon_pond` | decor_pond | Decor | บ่อน้ำวงรีขอบหิน กลีบดอกลอย น้ำพุเล็ก | `#7CC6D9`, `#E4D6B8` |

รวม **22 icons**. ความสอดคล้องหมวด: Food = ของดิบบนใบไม้/ก้าน, Herb = ต้นเดี่ยว, Potion = ภาชนะ, Habitat/Decor = มุมมองไอโซเมตริกเล็กของ asset 3D จริง (ต้องอ้างอิงโมเดลที่อนุมัติแล้ว)

**ไอคอนที่ UI น่าจะต้องใช้แต่ไม่มีใน Items.lua** (Lumen coin, Hunger/Energy/Joy/Trust, Sneak button, Bestiary, Quest) → ดู §8

---

## 5. Audio Spec

**มาตรฐาน:** OGG Vorbis (หรือ MP3 320) 44.1 kHz · Music/Ambience 2D = stereo · 3D emitters = **mono** · Loudness: Music −18 LUFS integrated, Ambience −24, SFX peak −6 dBFS · loop ต้อง seamless (crossfade ภายในไฟล์ zero-crossing) · **ต้องเป็นเสียงที่มีสิทธิ์ใช้งาน** (ทำเอง/ซื้อลิขสิทธิ์ถูกต้อง) · อัปโหลดแล้วใส่ SoundId ใน `AssetRegistry.Sounds` (0 = เงียบ) · RollOffMode = `InverseTapered` สำหรับทุกเสียง 3D

| Key | Description | Length | Loop | 2D/3D | RollOff Min / Max (studs) | หมายเหตุ |
|---|---|---|---|---|---|---|
| `Music_Village_Day` | วอลซ์อบอุ่น 3/4: แอคคอร์เดียน, กีตาร์ไนลอน, ฟลุตไม้, เชลโลพิซซิคาโต — "เช้าวันอาทิตย์ในตลาด" | 2:30–3:00 | ✔ | 2D | — | key เมเจอร์, 96 BPM |
| `Music_Village_Night` | เวอร์ชันช้าของธีมหมู่บ้าน: เปียโนนุ่ม, celesta, สายเบา — กล่อมนอน | 2:30 | ✔ | 2D | — | ใช้ motif เดียวกับ Day |
| `Music_Forest_Day` | ฮาร์ป + ฟลุตอัลโต + มาริมบาไม้ + pad สาย — ลึกลับแต่ใจดี | 3:00 | ✔ | 2D | — | เว้นช่องว่าง (rest) เยอะ ให้เสียงธรรมชาติเด่น |
| `Music_Forest_Night` | กล่องดนตรี + กระดิ่งแก้ว + โดรนเชลโลต่ำ + เสียงประสานหญิงไร้คำ | 3:00 | ✔ | 2D | — | ห้ามน่ากลัว: ไม่มี dissonance ค้าง |
| `Music_Sanctuary` | ธีม "บ้านของฉัน": กีตาร์ + ฮัมเบา + กลองแปรง — ซ้ำได้นานไม่เบื่อ | 3:00–3:30 | ✔ | 2D | — | ธีมหลักของเกม |
| `Ambience_Village` | เสียงผู้คนคุยไกล ๆ (walla ไม่มีคำชัด), ไก่ขัน, ระฆังลม, ค้อนช่างไม้ไกล | 1:30 | ✔ | 2D | — | Volume ลดตามเวลา ปิดกลางคืน (สลับเป็น Ambience_Night) |
| `Ambience_Forest` | ใบไม้ไหว, นกร้อง 4–5 ชนิด (สมมติ — ไม่ใช่นกจริงที่จำได้), แมลงเบา ๆ, ลมลอดราก "กระซิบ" | 2:00 | ✔ | 2D | — | layer กระซิบเบามาก (−30 LUFS) |
| `Ambience_Night` | จิ้งหรีด, ลมเย็น, นกฮูกไกล 1 ครั้งต่อนาที, กบ | 2:00 | ✔ | 2D | — | ใช้ทั้งหมู่บ้านและป่า (กลางคืน) |
| `Ambience_River` | ลำธารไหลกลาง ๆ มีเสียงน้ำกระทบหิน | 0:45 | ✔ | 3D | 10 / 80 | โค้ดวาง emitter ตาม `River.Points` (8 จุด) |
| `Ambience_Waterfall` | น้ำตกดังกว้าง + ละอองซ่า + ต่ำหนัก | 0:45 | ✔ | 3D | 30 / 260 | ผูกกับ `SoundEmitter` ของ ENV-L07 |
| `Ambience_Rain` | ฝนพรำนุ่มบนใบไม้ + หยดจากชายคา | 1:30 | ✔ | 2D | — | fade in/out 4 วิ ตาม weather |
| `Sfx_Footstep_Grass` | ก้าวบนหญ้า 1 ก้าว (นุ่ม) | 0.2–0.35 s | ✗ | 3D | 5 / 40 | โค้ดสุ่ม `PlaybackSpeed` 0.92–1.08; ส่งเพิ่ม 3–4 variation เป็นไฟล์สำรอง |
| `Sfx_Footstep_Stone` | ก้าวบนหินกรวด/cobblestone | 0.2–0.35 s | ✗ | 3D | 5 / 40 | Terrain Cobblestone/Rock |
| `Sfx_Footstep_Wood` | ก้าวบนไม้ (ระเบียง, สะพานไม้) | 0.2–0.35 s | ✗ | 3D | 5 / 40 | — |
| `Sfx_Footstep_Mud` | ก้าวบนโคลนนุ่ม (HiddenTrail) | 0.25–0.4 s | ✗ | 3D | 5 / 40 | Terrain Mud |
| `Sfx_Forage` | ดึงต้นไม้เบา ๆ + "ติ๊ง" ใสเล็ก ๆ (ได้ของ) | 0.6–0.9 s | ✗ | 2D | — | ผู้เล่นตัวเองได้ยิน 2D |
| `Sfx_Potion_Brew` | ฟองเดือดปุด ๆ + คนทัพพี + "วิ้ง" เวทมนตร์จบ | 3.0 s (= `Seconds` ของสูตร 3 วิ) | ✗ | 3D | 8 / 60 | growth_tonic ใช้ 4 วิ → โค้ด loop ส่วนกลาง หรือส่ง variation 4 วิ |
| `Sfx_Trust_Up` | ระฆังแก้วขึ้น 2 โน้ต (เมเจอร์เทิร์ด) นุ่ม | 0.5–0.8 s | ✗ | 2D | — | เล่นบ่อย → ต้องไม่ล้าหู |
| `Sfx_Bond` | สติงเกอร์อบอุ่น: arpeggio ฮาร์ป + celesta + pad ขึ้น | 2.5–3.5 s | ✗ | 2D | — | moment สำคัญที่สุด ducks music −8 dB |
| `Sfx_UI_Open` | กระดาษ/หนังสือพลิก + ระฆังเล็ก | 0.25 s | ✗ | 2D | — | |
| `Sfx_UI_Click` | ไม้เคาะเบา "ต๊อก" | 0.08 s | ✗ | 2D | — | |
| `Creature_spirit_kitsune_Call` | เสียงร้องสั้นใสคล้ายกระดิ่งลมผสมเสียงร้องสุนัขจิ้งจอกเล็ก ๆ แบบ "คยุ้น" (ตรงกับ Clue กระดิ่งลม) | 0.8–1.2 s | ✗ | 3D | 10 / 120 | Baby: โค้ด pitch +20% |
| `Creature_lunar_stag_Call` | เสียงร้องต่ำนุ่มยาว ผสมเสียงกระซิบลมและโทนแก้ว (ตรงกับ Clue เสียงกระซิบใกล้น้ำ) | 1.2–1.8 s | ✗ | 3D | 15 / 180 | ได้ยินไกลกว่าตัวอื่น (ช่วยตามหาตอนกลางคืน) |
| `Creature_treasure_mole_Call` | "จิ๊บ ๆ" สองพยางค์ + ฟุดฟิดจมูก | 0.5–0.8 s | ✗ | 3D | 6 / 60 | |

รวม **24 keys**

---

## 6. Naming Conventions

| สิ่ง | รูปแบบ | ตัวอย่าง |
|---|---|---|
| Environment model (Roblox) | `<Category>_<Name>[_<Variant>]` ตรงกับ AssetRegistry | `Building_House_Small_B`, `Tree_Forest_C` |
| Forage model | `Forage_<itemId>` | `Forage_wisp_lily` |
| Creature model | `Creature_<speciesId>_<Stage>` | `Creature_lunar_stag_Juvenile` |
| Animation object | ชื่อใน `CreatureAnimations` ตรงตัว | `Idle`, `Ability` |
| Animation source (Blender action / FBX) | `A_<speciesId>_<Stage>_<Anim>` | `A_spirit_kitsune_Adult_Run` |
| Blender source file | `<Key>.blend` / `Creature_<speciesId>.blend` | `Landmark_ElderTree.blend` |
| Mesh object (Blender) | `SM_<Key>[_<Part>]` / skinned `SK_<ModelName>` | `SM_Landmark_ClockTower_Crown` |
| MeshPart ใน Roblox | ชื่อส่วน (ไม่ต้องมี prefix) | `Crown`, `Trunk`, `Canopy`, `Body`, `Eyes` |
| LOD export | `<Key>_LOD1.fbx`, `<Key>_LOD2.fbx` | |
| Collision part | `Col_<Desc>` ในโฟลเดอร์ `Collision` | `Col_Trunk`, `Col_Base` |
| Texture (unique) | `T_<Key>_<Map>` Map = C/N/R/M | `T_Landmark_ElderTree_C.png` |
| Texture (atlas) | `T_ATL_<AtlasID>_<Map>` | `T_ATL_VIL_Trim_N.png` |
| Eye expression | `T_<speciesId>_Eye_<State>` | `T_treasure_mole_Eye_Happy.png` |
| Icon | Icon key ตรงตัว | `icon_wisp_lily.png` |
| Sound | Sound key ตรงตัว | `Ambience_Waterfall.ogg` |
| Attachments | ตาม §1.2 ตรงตัว (ซ้ำชื่อได้) | `LightSource`, `GlowSource` |

กฎ: ห้ามช่องว่าง, ห้ามอักขระไทยในชื่อไฟล์/ออบเจ็กต์, `speciesId`/`itemId` ใช้ snake_case ตามโค้ด, ส่วนอื่น PascalCase

---

## 7. Blender → Roblox Export Settings

### 7.1 Scene setup
| Setting | ค่า |
|---|---|
| Unit System | Metric, **Unit Scale 1.0** — ทำงานโดยถือ **1 Blender unit = 1 stud** |
| Orientation ในการ model | หน้า asset หัน **−Y ของ Blender** (มองเห็นด้านหน้าใน Front view `Numpad 1`) |
| Origin | ที่ bottom-center ของ asset (ตาม §1.1) — `Set Origin` ก่อน export |
| Transforms | **Apply All Transforms** (Ctrl+A → All Transforms) ทุก mesh: Location 0, Rotation 0, Scale 1 |
| Modifiers | Apply ก่อน export (ยกเว้น Armature) |
| Normals | Custom split normals OK; Auto Smooth/Shade Smooth by Angle 40–60° สำหรับ stylized |
| UV | ช่อง UV เดียว (`UVMap`), ไม่มี overlap ยกเว้นตั้งใจ mirror/atlas |
| Tris | Triangulate (modifier, Beauty) ก่อน export เพื่อให้นับตรง; **≤ 10,000 tris ต่อ mesh object** |
| Materials | 1 material ต่อ MeshPart (Roblox ใช้ SurfaceAppearance เดียวต่อ MeshPart) — ถ้าต้องหลาย material ให้แยก mesh |

### 7.2 FBX export (File → Export → FBX)
| Group | Setting | ค่า |
|---|---|---|
| Include | Limit to | **Selected Objects** |
| | Object Types | Mesh (+ Armature สำหรับสัตว์); ปิด Camera/Light/Empty (ยกเว้น Empty ที่ตั้งใจเป็น attachment ดูหมายเหตุ) |
| Transform | Scale | **1.00** |
| | Apply Scalings | **FBX All** |
| | Forward | **−Z Forward** |
| | Up | **Y Up** |
| | Apply Unit | ✔ |
| | Use Space Transform | ✔ |
| | Apply Transform (experimental) | ✔ (static mesh เท่านั้น — สัตว์ให้ปิดแล้วทดสอบ) |
| Geometry | Smoothing | **Face** |
| | Apply Modifiers | ✔ |
| | Triangulate Faces | ✔ |
| | Tangent Space | ✔ |
| Armature | Primary Bone Axis | **Y** |
| | Secondary Bone Axis | **X** |
| | Add Leaf Bones | **✗ ปิด** |
| | Only Deform Bones | ✔ (IK/Pole ไม่ export) |
| Bake Animation | ✔ (เฉพาะไฟล์ animation) · Key All Bones ✔ · NLA Strips ✗ · All Actions ✗ (export ทีละ action) · Force Start/End Keying ✔ · Sampling Rate 1.0 · Simplify 0 |
| Path Mode | Copy + Embed Textures ✗ (อัปโหลด texture แยกผ่าน SurfaceAppearance) |

### 7.3 Roblox 3D Importer
| Setting | ค่า |
|---|---|
| Scale Unit / File Dimensions | **Stud** |
| Import Only As Model | ✔ |
| Rig General → Rig Type | สัตว์: Custom (ไม่ใช่ R15) |
| Anchored | static env = ✔ |
| Insert Using Scene Position | ✗ |
| หลัง import | ตั้งชื่อ Model = Key, ตรวจ `WorldPivot`, ใส่ SurfaceAppearance, เพิ่ม attachments ตาม spec, ตั้ง CollisionFidelity / RenderFidelity = Automatic, ย้ายเข้า `ReplicatedStorage/Assets/<Key>` |
| Animation | Import ผ่าน Animation Editor → Import FBX animation → Publish → ใส่ AnimationId ใน Animation object ชื่อตรง |

### 7.4 Texture
| กฎ | ค่า |
|---|---|
| ขนาดสูงสุด | **1024 × 1024** (Roblox จะลดขนาดอัตโนมัติถ้าเกิน) |
| ขนาดที่อนุญาต | 1024, 512, 256 (สี่เหลี่ยมจัตุรัส, power of two) |
| Normal | OpenGL (Y+), 8-bit |
| Roughness/Metalness | Grayscale แยกไฟล์ |
| Bake | AO นุ่มผสมใน ColorMap ได้ (≤ 25%), ห้าม bake ทิศทางแสง |

### 7.5 Calibration (บังคับก่อนส่งงานชิ้นแรก)
Export ไฟล์ `Calibration_Cube` (กล่อง 4 × 4 × 4 Blender units, origin ที่ฐาน, มีลูกศรชี้ −Y) ด้วยค่าข้างบน → import → ตรวจว่า Studio แสดง Size = (4, 4, 4) studs และลูกศรชี้ทิศเดียวกับ `Model:GetPivot().LookVector` ถ้าไม่ตรง ห้ามส่งงาน ให้แก้ preset ก่อน (บันทึกเป็น Operator Preset `MythicalSanctuary_Roblox`)

---

## 8. Future / Gap Assets (ไม่อยู่ใน AssetRegistry — ต้องเพิ่ม Key ก่อนผลิต)

> รายการนี้ **ไม่ใช่** Key ที่โค้ดเรียกใช้ใน Phase 1 ชื่อทั้งหมดเป็นข้อเสนอ

| ข้อเสนอ | เหตุผล | อ้างอิง |
|---|---|---|
| `Prop_SteppingStones` (ENV-P08) | TempleTrail ข้ามแม่น้ำไม่มีสะพาน | WORLD_DESIGN WD-01 |
| `Prop_RoadSign_East` | ปลายถนนตะวันออก (230,0,10) เป็นทางตัน — hook Phase 3 | WORLD_DESIGN §6 |
| `Prop_CaveRunes` (decal set) | storytelling ในถ้ำลับ | WORLD_DESIGN §2.2 |
| `Ambience_Cave` | ถ้ำลับไม่มีเสียงบรรยากาศเฉพาะ | §5 |
| `Sfx_Portal`, `Sfx_Feed`, `Sfx_Pet`, `Sfx_Hatch`, `Sfx_Place`, `Sfx_Footstep_Water` | interaction หลักที่ยังไม่มีเสียง | GDD §4 |
| `Music_Cave` / stinger "Discovery" | ช่วงค้นพบ HiddenCave (q08) | |
| Animation `Hatch` (Egg), Emotional reactions (`Curious`, `ShyPeek`, `Nuzzle`, `Sad`, `Yawn`, `Stretch`, `Startle`, `Dislike`) | ต้องเพิ่มใน `CreatureAnimations` | §3.2 |
| UI icons: `icon_lumen`, `icon_hunger`, `icon_energy`, `icon_joy`, `icon_trust`, `icon_sneak`, `icon_bestiary`, `icon_quest`, `icon_sanctuary` | HUD/ปุ่มที่ต้องมีแต่ไม่อยู่ใน Items | §4 |
| Phase 3 creatures: `Creature_ember_dragon_*`, `Creature_storm_griffin_*`, `Creature_solar_phoenix_*`, `Creature_aqua_serpent_*`, `Creature_shadow_wolf_*` (CRE-04..08) | species มีใน `Species.lua` แต่ยังไม่มีใน `AssetRegistry.Creatures` | CONCEPT_BRIEFS |
| Phase 3 items/icons: food `ember_pepper`, `sky_seed`, `sun_nectar`, `pearl_kelp`, `dusk_meat`; habitats `habitat_dragon_cave`, `habitat_cliff_nest`, `habitat_sun_perch`, `habitat_deep_pool`, `habitat_shadow_den` | ถูกอ้างใน `Species.lua` แต่ไม่มีใน `Items.lua` | GDD OI-03 |
| `Prop_CrystalCluster_B/C` | `_A` บ่งชี้ชุด variation | ENV-C01 |
| Phase 3 biome kits (Crystal Cavern, Frost Mountains, Ember Valley, Celestial Islands) | | WORLD_DESIGN §7 |

---

## 9. Delivery Checklist (ต่อ asset)

**Environment**
- [ ] ชื่อ Model ตรง Key ทุกตัวอักษร
- [ ] อยู่ใน `ReplicatedStorage/Assets/<Key>`
- [ ] Pivot = bottom-center, หน้า = −Z (ผ่าน Calibration §7.5 แล้ว)
- [ ] ขนาดตรง `Size` ±10% โดยไม่ scale ใน Studio
- [ ] Tris LOD0 ≤ งบ; ทุก MeshPart ≤ 10,000; LOD1/LOD2 อยู่ใน source repo
- [ ] Texture ≤ 1024²; ใช้ atlas ตาม spec; texel density ตาม ART_DIRECTION §4.2
- [ ] SurfaceAppearance ครบ map ที่ระบุ; ไม่มี lighting อบใน albedo
- [ ] CollisionFidelity / โฟลเดอร์ `Collision` ตาม spec; ใบไม้/ของเล็ก `CanCollide = false`
- [ ] Child parts/attachments ครบชื่อตรงตัว (`LightSource`, `GlowSource`, `Interact`, `PortalSurface`, `SpawnPoint`, `NpcStand`, `NpcDoor`, `CreatureSlot`, `DrinkSpot`, `EggSlot`, `Seat`, `Emitter_*`)
- [ ] Placeable: footprint X/Z ตรง `Items.Footprint` และดูดีทุกการหมุน 90°
- [ ] ตรวจในเกมจริง: แทน Greybox สำเร็จ, ไม่ลอย/จม, กลางวัน + กลางคืน + ฝน, Graphics level 3 บนมือถือ
- [ ] Silhouette ผ่าน AD (เงาดำ 64 px ต่างจาก sibling)
- [ ] ไม่มีองค์ประกอบที่ลอก/อ้างอิง IP ภายนอก

**Creature (ต่อโมเดล)**
- [ ] ชื่อ `Creature_<speciesId>_<Stage>`; มี `HumanoidRootPart`, `Humanoid` หรือ `AnimationController`, `Animator`
- [ ] กระดูกตาม CRE-RIG (ชื่อมาตรฐานครบ) + กระดูกเฉพาะสายพันธุ์; ≤ 4 influences/vertex
- [ ] `Eyes` MeshPart + Decal `Expression` + 8 texture states
- [ ] โฟลเดอร์ `Animations` มี Animation objects ชื่อตรง `CreatureAnimations` (Egg: Idle/Happy/Sleep)
- [ ] Walk/Run sync กับ `Speed.Walk/Run` (ไม่มีเท้าไถล); markers `Step`, `Bite`, `Lap`, `AbilityFire`, `AbilityEnd`
- [ ] Palette ตรง `Species.Palette` (ตรวจด้วย color picker บน albedo ในแสงกลาง)
- [ ] สัดส่วนต่างกันจริงระหว่าง stage (ไม่ใช่แค่ scale)
- [ ] Ability VFX ตามโน้ต + `GlowSource` ที่ระบุ

**Icon / Audio**
- [ ] Icon PNG 256² โปร่งใส ชื่อ = Icon key, อ่านออกที่ 48 px บน `#1B2A4A`
- [ ] Audio ความยาว/loop/2D-3D ตามตาราง, loudness ตามมาตรฐาน, ไฟล์สิทธิ์ใช้งานแนบ (license record)
- [ ] อัปโหลดแล้วกรอก ID ใน `AssetRegistry.Icons` / `AssetRegistry.Sounds` (ผ่าน PR ให้ Code review)
