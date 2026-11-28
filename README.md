# 🎉 Skin Party Island (เกาะสกินปาร์ตี้)

เกม Roblox แนว **แต่งตัว–สะสมสกิน–มินิเกมปาร์ตี้** สำหรับทุกวัย
เก็บดาว ⭐ เล่นมินิเกม "พื้นสีวิบวับ" 🎨 แล้วเอาเหรียญไปซื้อสกิน หมวก หางวิ้ง สัตว์เลี้ยง และออร่า

📄 รายละเอียดการออกแบบทั้งหมด: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)

## ✨ ฟีเจอร์ (v2)
- 👗 **แฟชั่นโชว์** — ธีมสุ่ม 8 ธีม, เดินแบบบนรันเวย์, ผู้เล่นโหวตดาว, โพเดียม Top 3
- 🛍️ **ร้านค้า 3D** — พรีวิวหมุนได้ทุกชิ้น, ลองใส่ฟรี 20 วิ, ลดราคาประจำวัน, ฉากเปิดตัวไอเท็มใหม่
- 🎽 ไอเท็ม 75 ชิ้น 7 หมวด (สกิน หมวก **ปีกกระพือได้** สัตว์เลี้ยง หาง ออร่าโคจร **ฉายา**) 8 เซ็ตธีม
- 🎫 **Party Pass** 30 ขั้น (ฟรี + พรีเมียม) พร้อมนับถอยหลังซีซั่น
- 💎 Robux 8 ช่องทาง: Starter Pack, Party Pass, ข้ามขั้น, VIP, เหรียญ x2, เพชร 5 แพ็ก, ชุดเซ็ต 5 แบบ
- 📋 ภารกิจมือใหม่, 🎁 รางวัลรายวัน, 🎟️ โค้ด, 🏅 ฉายาจากความสำเร็จ, 📢 ประกาศทั้งเซิร์ฟ
- 🎨 มินิเกมพื้นสีวิบวับ (ไม่มีการตาย)
- 📊 ส่งข้อมูลเศรษฐกิจ/Funnel เข้า Creator Dashboard (AnalyticsService)
- 💾 DataStore ปลอดภัย (retry, autosave, กันให้ของ Robux ซ้ำ, ย้อนข้อมูลถ้าบันทึกพลาด)

## 🚀 วิธีนำเข้า Roblox Studio

1. ติดตั้ง [Rojo](https://rojo.space) (ผ่าน `aftman install` หรือปลั๊กอิน Rojo ใน Studio)
2. ในโฟลเดอร์นี้รัน:
   ```bash
   rojo serve
   ```
3. เปิด Roblox Studio → สร้าง Baseplate ใหม่ → กดปุ่ม **Connect** ในปลั๊กอิน Rojo
4. กด **Play** ▶️ เล่นได้เลย!

หรือ build เป็นไฟล์: `rojo build -o SkinPartyIsland.rbxl` แล้วเปิดไฟล์ใน Studio

### ⚙️ ก่อนเปิดให้คนเล่นจริง
1. **Game Settings → Security → Enable Studio Access to API Services** (เพื่อให้ DataStore บันทึกได้)
2. สร้าง **Game Pass** 3 อัน (VIP, DoubleCoins, PartyPass) และ **Developer Product** 12 อัน (เพชร 5, ชุดเซ็ต 5, Starter Pack, ข้ามขั้น) ใน Creator Dashboard — ราคาแนะนำอยู่ในคอมเมนต์ของ Config
3. ใส่ ID ทั้งหมดลงใน `src/shared/Config.lua` (`GamePasses`, `GemPacks`, `Bundles`, `StarterPack`, `TierSkip`)
4. ตั้งค่า **Experience Questionnaire** ให้ตรงกับเนื้อหา (เกมนี้ไม่มีความรุนแรง/กล่องสุ่ม)
5. เปลี่ยนโค้ดแจกของใน `Config.Codes` ตามแคมเปญ

> 💡 ทดสอบ Game Pass ใน Studio: ตั้ง `Config.StudioGrantAllPasses = true`

## 🗂️ โครงสร้างโปรเจกต์
```
src/
├── shared/                  → ReplicatedStorage.Shared
│   ├── Config.lua           ค่าตั้งค่าเกมทั้งหมด (ราคา, รางวัล, ID Robux, โค้ด)
│   ├── ItemCatalog.lua      รายการไอเท็ม 43 ชิ้น (เพิ่มของใหม่ที่นี่)
│   └── ShopRotation.lua     ของลดราคาประจำวัน
├── server/                  → ServerScriptService.Server
│   ├── init.server.lua      จุดเริ่มต้น
│   ├── Remotes.lua          RemoteEvent/Function
│   ├── DataService.lua      บันทึก/โหลดข้อมูล
│   ├── ShopService.lua      ซื้อ/ใส่ไอเท็ม, รางวัลรายวัน, โค้ด
│   ├── MonetizationService.lua  Robux (Game Pass + Developer Product)
│   ├── CosmeticService.lua  สร้างสกิน/หมวก/หาง/สัตว์เลี้ยง/ออร่าบนตัวละคร
│   ├── CollectibleService.lua   ดาวเก็บเหรียญ
│   ├── RoundService.lua     มินิเกมพื้นสีวิบวับ
│   └── MapBuilder.lua       สร้างแผนที่
└── client/                  → StarterPlayerScripts.Client
    ├── init.client.lua
    ├── Net.lua / UIKit.lua / Toast.lua
    ├── Hud.lua              แถบเงิน ปุ่มเมนู ป้ายมินิเกม
    ├── ShopUI.lua           หน้าต่างร้านค้า
    ├── Panels.lua           รางวัลรายวัน + แลกโค้ด
    └── Effects.lua          สายรุ้ง ใบพัดหมุน ดาวลอย แท็กแชท VIP
```

## ➕ เพิ่มไอเท็มใหม่
เพิ่มหนึ่งแถวใน `src/shared/ItemCatalog.lua` เช่น
```lua
{ Id = "hat_party_blue", Name = "หมวกปาร์ตี้ฟ้า", Category = "Hat", Rarity = "Common",
  Price = 120, Currency = "Coins", Icon = "🎉", Style = "PartyCone",
  Colors = { Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 255, 255) } },
```
ร้านค้าจะแสดงผลและขายได้อัตโนมัติ (สไตล์ที่มี: หมวก `PartyCone CatEars BunnyEars Flower Antenna TopHat Propeller Crown Halo`, สัตว์เลี้ยง `Ball Cube Ghost Cloud Ufo`, ออร่า `Particles Fire Sparkles`)

## 💸 Robux Sender (โปรเจกต์แยก)
ระบบส่ง Robux อัตโนมัติด้วย Username (เว็บแอดมิน + REST API) อยู่ในโฟลเดอร์ [`robux-sender/`](robux-sender/README.md)
