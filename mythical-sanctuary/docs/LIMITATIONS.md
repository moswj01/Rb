# ขอบเขตงานและข้อจำกัด (อ่านก่อน)

> ตามข้อกำหนดของโปรเจกต์: *"หากเครื่องมือที่ใช้ไม่สามารถสร้าง Custom Mesh, Texture หรือ Animation ได้จริง ให้ระบุข้อจำกัดอย่างชัดเจน … ห้ามใช้โมเดลทรงเรขาคณิตพื้นฐานทดแทนแล้วอ้างว่าเป็นงานสมบูรณ์"*
> เอกสารนี้แยกให้ชัดว่า **อะไรทำเสร็จจริง**, **อะไรเป็น Greybox รองาน Artist** และ **อะไรยังไม่ได้ทำ**

## 1. สิ่งที่ทำไม่ได้ในสภาพแวดล้อมนี้

งานนี้พัฒนาในสภาพแวดล้อมแบบ code-only (ไม่มี Roblox Studio, ไม่มี Blender แบบมีหน้าจอ, ไม่มีสิทธิ์อัปโหลด Asset เข้าบัญชี Roblox ของคุณ) จึง **ไม่สามารถ** ผลิตสิ่งต่อไปนี้ได้อย่างมีคุณภาพระดับที่กำหนด:

| สิ่งที่ส่งมอบ (ตาม Brief) | สถานะ | สิ่งที่ส่งมอบแทน |
|---|---|---|
| Custom 3D Mesh (ปั้นด้วยมือ) | ❌ ทำไม่ได้ | `ASSET_SPEC.md` สเปกรายชิ้นพร้อม Spec ID, ขนาด, งบ polygon, LOD, texture, pivot |
| Hand-painted Texture / SurfaceAppearance | ❌ | สเปก texture + palette ใน `ART_DIRECTION.md` |
| Creature Rig + Animation (11 ท่า × 3 สายพันธุ์ × 4 วัย) | ❌ | สเปก Rig (CRE-RIG), รายการท่า, จำนวนเฟรม, การเปลี่ยนสัดส่วนตามวัย |
| Concept Art | ❌ | `CONCEPT_BRIEFS.md` บรีฟสำหรับ Concept Artist |
| Blender Source Files | ❌ | ขั้นตอน Export/Import ใน `ASSET_SPEC.md` + `DEPLOYMENT.md` |
| ดนตรี/เสียงประกอบ | ❌ | รายการเสียงพร้อม SoundId slot ใน `AssetRegistry.lua` (ระบบเล่นเสียงพร้อมแล้ว) |
| ไอคอน UI วาดมือ | ❌ | ระบบรองรับ `AssetRegistry.Icons` แล้ว — ระหว่างนี้แสดงวงทอง+อักษรย่อ |
| Performance Test บนอุปกรณ์จริง | ❌ | `PERFORMANCE_TEST_PLAN.md` แผนทดสอบ + ตารางให้กรอกผล |

**สิ่งที่ไม่ได้ทำ (โดยตั้งใจ):** ไม่ได้ใช้โมเดลจาก Toolbox และไม่ได้เอาทรงเรขาคณิตมาอ้างว่าเป็นงานศิลป์

## 2. Greybox Blockout คืออะไร (สิ่งที่คุณจะเห็นตอนกด Play)

ทุก Asset ที่ยังไม่มีโมเดลจริงจะแสดงเป็น **Greybox สีดินเหนียว** ตามมาตรฐานสตูดิโอเกม
ใช้ทดสอบขนาด ระยะ การจัดองค์ประกอบ และ gameplay ก่อนลงงานศิลป์

- ทุกชิ้นติดแท็ก `Placeholder` + Attribute `Spec` (เช่น `ENV-L05`) ชี้กลับไปที่สเปก
- ตรวจว่ายังเหลือ Greybox กี่ชนิด: ใน Studio Command Bar
  `require(game.ReplicatedStorage.Shared.AssetLibrary).Report()`
- **เมื่อ Artist ส่งงาน:** วางโมเดลชื่อตรง Key ไว้ที่ `ReplicatedStorage/Assets/<Key>` → เกมสลับให้อัตโนมัติ **ไม่ต้องแก้โค้ด**

> ⚠️ พื้นที่ใดที่ยังมี Greybox **ไม่นับว่าส่งมอบสมบูรณ์** ตาม Acceptance Criteria ข้อ "ไม่มี Placeholder Asset"

## 3. สิ่งที่ทำเสร็จจริง (ใช้งานได้ ไม่ใช่ Mockup)

| ระบบ | ไฟล์หลัก | หมายเหตุ |
|---|---|---|
| ภูมิประเทศ Organic (Terrain voxel) | `World/TerrainBuilder.lua` | เนิน 3 ชั้น noise + สันเขา ridged-noise, หน้าผาขอบโลก, ที่ราบหมู่บ้าน, แม่น้ำไหลลดหลั่นมีตลิ่ง, ทางเดินอยู่ในหุบ, ถ้ำลับเจาะใต้เนิน, เกาะเขตอนุรักษ์ — **นี่คือภูมิประเทศจริง ไม่ใช่ Greybox** (Environment Artist ปั้นต่อได้หลัง Bake) |
| แผนผังโลก (Composition) | `shared/WorldLayout.lua` | วาง Landmark ด้วยมือ, Hero trees กรอบภาพ, กฎกระจายพืช (blue-noise + density + เขตห้าม) |
| แสง/บรรยากาศ | `shared/LightingProfiles.lua`, `client/World/Atmosphere.lua` | Day/Night, พลบค่ำ, โปรไฟล์ต่อโซน, Bloom/SunRays/ColorCorrection/Atmosphere, หมอก/ฝน, อนุภาค, จำกัดไฟตามระยะ |
| AI สัตว์ | `Creatures/CreatureService.lua` | State machine 11 สถานะ, บุคลิก 4 แบบ, ช่วงเวลา, สภาพอากาศ, Pathfinding, LOD 3 ระดับ |
| Taming แบบไว้วางใจ / Rescue | `Creatures/CreatureCare.lua` | ย่อตัว, อาหารโปรด/ไม่ชอบ, ปลอบ, รักษาบาดแผล, ผูกพัน |
| ดูแลสัตว์ + การเติบโต + ฟักไข่ | `CreatureCare.lua`, `SanctuaryService.lua` | หิว/พลัง/สุข, offline decay (cozy), Egg→Baby→Juvenile→Adult |
| เขตอนุรักษ์ส่วนตัว | `Sanctuary/SanctuaryService.lua`, `client/UI/SanctuaryEditor.lua` | เกาะ Terrain ต่อคน, ประตูมิติ, Grid snap, หมุน, ย้าย/เก็บ, ตรวจชนที่เซิร์ฟเวอร์ |
| ภารกิจ / สมุดภาพสัตว์ / ค้นพบสถานที่ | `Gameplay/QuestService.lua`, `shared/Quests.lua` | เนื้อเรื่องบทนำ 8 ภารกิจ |
| เก็บสมุนไพร / ปรุงยา / ร้านค้า | `Gameplay/EconomyService.lua` | ตรวจระยะจริง, ลิลลี่บานเฉพาะกลางคืน |
| NPC ตามตารางเวลา | `World/NpcService.lua` | ใช้ตัวมนุษย์มาตรฐาน Roblox ชั่วคราว (Placeholder) |
| บันทึกข้อมูล | `Data/DataService.lua` | Session Locking, Retry/Backoff, Migration, Autosave, BindToClose |
| UI Premium Fantasy | `client/UI/*` | Theme Midnight/Gold/Forest/Ivory, Journal 6 แท็บ, HUD เล็ก, Dialog, Shop, Crafting, Editor, Main Menu cinematic, รองรับมือถือ |
| Multiplayer | ทุกระบบ | Server-authoritative, เกาะแยกต่อผู้เล่น, สัตว์ภารกิจแยกต่อคน |

## 4. ยังไม่ได้ทำ (นอก Phase 1 หรือรอขั้นถัดไป)

- Breeding, Farming, Creature Training, Riding/Flying (Phase 2–3)
- Zone C–F (Crystal Cavern, Frost Mountains, Ember Valley, Celestial Islands) — มีเฉพาะ Design Brief
- สัตว์ 5 สายพันธุ์ที่เหลือ — มีข้อมูลใน `Species.lua` แล้ว แต่ปิดไว้ (Phase 3)
- การเยี่ยมเขตอนุรักษ์ของเพื่อน, การแลกเปลี่ยน (ต้องใช้ MemoryStoreService — ออกแบบไว้แต่ยังไม่ทำ)
- LOD ของ Mesh (ต้องรอ Mesh จริง), Texture Atlas (ต้องรอ Texture จริง)

## 5. ความเสี่ยงที่ต้องตรวจใน Studio

โค้ดผ่านการตรวจไวยากรณ์ Luau และ build เป็นไฟล์ .rbxlx ได้ แต่ **ยังไม่เคยรันใน Roblox Studio จริง**
จุดที่ควรตรวจเป็นพิเศษ:
1. เวลาสร้าง Terrain ตอนเปิดเซิร์ฟ (แนะนำให้ Bake ตาม `DEPLOYMENT.md`)
2. Humanoid บนโมเดลสัตว์ Greybox (HipHeight/การเดิน)
3. ProximityPrompt แบบ Custom บนมือถือ
4. ความหนาแน่นพืชพรรณต่อ FPS บนมือถือ (ปรับ `Count` ใน `WorldLayout.Scatter`)
