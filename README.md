# 🎉 Skin Party Island (เกาะสกินปาร์ตี้)

เกม Roblox แนว **แต่งตัว–สะสมสกิน–มินิเกมปาร์ตี้** สำหรับทุกวัย
เก็บดาว ⭐ เล่นมินิเกม "พื้นสีวิบวับ" 🎨 แล้วเอาเหรียญไปซื้อสกิน หมวก หางวิ้ง สัตว์เลี้ยง และออร่า

📄 รายละเอียดการออกแบบทั้งหมด: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)

## ✨ ฟีเจอร์
- 🏝️ แผนที่สร้างด้วยโค้ดทั้งหมด — เปิดแล้วเล่นได้ทันที ไม่ต้องสร้างฉาก/อัปโหลดโมเดล
- 🛍️ ร้านค้า 43 ไอเท็ม 5 หมวด 5 ระดับความหายาก + โปรลดราคาประจำวัน
- 🎨 มินิเกมพื้นสี 10 เวฟ (ไม่มีการตาย ตกแล้วเด้งกลับเกาะ)
- 🎁 รางวัลรายวัน 7 วัน, 🎟️ ระบบโค้ด
- 💎 Robux: เติมเพชร 4 แพ็ก + Game Pass VIP / เหรียญ x2 (ProcessReceipt ปลอดภัย กันให้ของซ้ำ)
- 💾 DataStore พร้อม retry / autosave / BindToClose
- 📱 UI ปรับขนาดอัตโนมัติ รองรับมือถือ แท็บเล็ต PC

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
2. สร้าง **Game Pass** (VIP, DoubleCoins) และ **Developer Product** (เพชร 4 แพ็ก) ใน Creator Dashboard
3. ใส่ ID ทั้งหมดลงใน `src/shared/Config.lua` (`Config.GamePasses` และ `Config.GemPacks`)
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
