# Performance Test Plan

> **ยังไม่มีผลการทดสอบ** — ต้องทดสอบบนอุปกรณ์จริง (สภาพแวดล้อมพัฒนาไม่มี Roblox client)
> เป้าหมายตาม Brief: **60 FPS** บน PC ระดับกลาง, **≥ 30 FPS** บนมือถือระดับกลาง

## อุปกรณ์ทดสอบ (ขั้นต่ำ)
| ประเภท | ตัวอย่าง | ระดับกราฟิก |
|---|---|---|
| PC ระดับกลาง | GTX 1650 / Ryzen 5, RAM 16GB | Auto + High |
| มือถือ Android ระดับกลาง | Snapdragon 7-series, RAM 6GB | Auto |
| iPhone รุ่นเก่า | iPhone 11 | Auto |
| แท็บเล็ต | iPad 9th gen | Auto |

## สถานการณ์ทดสอบ
| # | สถานการณ์ | วิธีวัด | เป้า PC | เป้ามือถือ | ผล PC | ผลมือถือ |
|---|---|---|---|---|---|---|
| 1 | ยืนกลางจัตุรัสหอนาฬิกา กลางคืน (ไฟเปิด) | Shift+F5 / MicroProfiler | 60 | 30 | | |
| 2 | วิ่งตามทางป่าไปต้นไม้ผู้เฒ่า (สตรีมมิ่ง) | FPS ต่ำสุด | 55 | 28 | | |
| 3 | ลานต้นไม้ผู้เฒ่า + สัตว์ 6 ตัว + หิ่งห้อย | FPS เฉลี่ย 60 วิ | 60 | 30 | | |
| 4 | ฝนตก + หมอก ในป่า | FPS เฉลี่ย | 60 | 30 | | |
| 5 | เขตอนุรักษ์ วางของ 150 ชิ้น + สัตว์ 12 ตัว | FPS + Memory | 60 | 30 | | |
| 6 | 10 ผู้เล่นพร้อมกัน | Server Heartbeat (Shift+F2) | ≥ 55 Hz | — | | |
| 7 | เวลาสร้างโลกตอนเปิดเซิร์ฟ (ไม่ Bake / Bake) | log `[Boot]` | — | — | | |

## ตัวชี้วัดหน่วยความจำ (Developer Console → Memory)
| หมวด | เป้า (มือถือ) | ผล |
|---|---|---|
| Total client memory | < 1.2 GB | |
| GraphicsTexture | < 250 MB | |
| GraphicsMeshParts | < 150 MB | |
| PhysicsParts | — | |

## ปุ่มปรับถ้าไม่ถึงเป้า (เรียงตามผลกระทบ)
1. `WorldLayout.Scatter[*].Count` (พืชพรรณ)
2. `Atmosphere` QUALITY → `Lights`, `ParticleScale`
3. `Config.AI.NearDistance / FarDistance`
4. `Workspace.StreamingTargetRadius`
5. Mesh LOD / Texture ขนาดเล็กลง (หลังมี Asset จริง)
