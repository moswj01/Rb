# Robux Sender

ระบบส่ง Robux อัตโนมัติด้วย Username — เว็บแอดมิน + REST API (Node.js ไม่มี dependency ภายนอก)

ร้านค้า/ระบบรับชำระเงินของคุณเรียก `POST /api/orders` เมื่อลูกค้าจ่ายเงินแล้ว ระบบจะเข้าคิวและส่ง Robux ให้เองทีละออเดอร์

> ⚠️ **ความเสี่ยงที่ต้องรู้ก่อนใช้**
> - การขาย Robux นอกแพลตฟอร์มผิดข้อตกลงการใช้งานของ Roblox บัญชี/กลุ่มที่ใช้จ่ายอาจถูกแบนและยึด Robux ได้
> - ระบบนี้ควบคุมบัญชีผ่าน cookie `.ROBLOSECURITY` ซึ่งไม่ใช่ API ทางการ Roblox เปลี่ยน endpoint ได้โดยไม่แจ้ง
> - cookie เทียบเท่ารหัสผ่านบัญชี ใครได้ไปก็เข้าบัญชีได้ทันที เก็บไว้ใน `.env` บนเครื่องที่คุณควบคุมเท่านั้น

## วิธีส่ง 2 แบบ

| | `group` (Group Payout) | `gamepass` (ซื้อ Game Pass) |
|---|---|---|
| ผู้รับได้ | เต็มจำนวน | หลังหัก 30% (ระบบคิดราคาเผื่อให้) |
| ผู้รับต้องทำ | เข้ากลุ่มและรอพ้นช่วงรอของสมาชิกใหม่ (ราว 14 วัน) | สร้าง Game Pass ราคา `ceil(จำนวน ÷ 0.7)` เช่น อยากได้ 100 ตั้ง 143 |
| Robux เข้าเมื่อ | ทันที | ค้าง pending หลายวันตามระบบ Roblox |
| จ่ายจาก | เงินกองกลางกลุ่ม | Robux ในบัญชีผู้จ่าย |
| ข้อจำกัด | Roblox มักขอ 2-step verification (ตั้ง `ROBLOX_TOTP_SECRET`) | บัญชีผู้จ่ายซื้อ pass เดิมซ้ำไม่ได้ ลูกค้าเก่าต้องสร้าง pass ใหม่ |

## ติดตั้ง

ต้องใช้ Node.js 22.13 ขึ้นไป

```bash
cd robux-sender
cp .env.example .env      # แล้วกรอกค่า
npm start
```

เปิด `http://127.0.0.1:3000` แล้วใส่ `ADMIN_TOKEN`

ค่าที่ต้องกรอกใน `.env` (ดูคำอธิบายครบใน `.env.example`): `ADMIN_TOKEN`, `ROBLOX_COOKIE`, `DEFAULT_METHOD`, และ `ROBLOX_GROUP_ID` ถ้าใช้วิธี group

ระบบฟังที่ `127.0.0.1` เท่านั้นโดยค่าเริ่มต้น ถ้าจะเปิดให้เครื่องอื่นเรียก ให้วางหลัง reverse proxy ที่มี HTTPS อย่าเปิดพอร์ตตรง ๆ สู่อินเทอร์เน็ต

## REST API

ทุกคำขอต้องมี header `Authorization: Bearer <ADMIN_TOKEN>`

| Method | Path | ใช้ทำอะไร |
|---|---|---|
| `POST` | `/api/orders` | สร้างออเดอร์ `{ username, amount, method?, reference? }` |
| `GET` | `/api/orders?status=&limit=` | รายการออเดอร์ |
| `GET` | `/api/orders/:id` | รายละเอียด + ประวัติเหตุการณ์ |
| `POST` | `/api/orders/:id/cancel` | ยกเลิก (เฉพาะที่ยังรอคิว) |
| `POST` | `/api/orders/:id/retry` | ส่งใหม่ (เฉพาะ `failed` / `review`) |
| `POST` | `/api/orders/:id/resolve` | ปิดออเดอร์ `review` ด้วยมือ `{ status: "completed" \| "failed" }` |
| `GET` | `/api/check?username=&amount=&method=` | ตรวจว่าผู้รับพร้อมหรือยัง (ไม่จ่ายเงิน) |
| `GET` | `/api/status` | บัญชี ยอดคงเหลือ คิว วงเงิน |

```bash
curl -X POST http://127.0.0.1:3000/api/orders \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"username":"SomePlayer","amount":100,"reference":"payment-12345"}'
```

- `amount` คือ Robux ที่ผู้รับได้จริง
- **ส่ง `reference` ทุกครั้ง** (เช่น เลขที่ชำระเงิน) ถ้าเรียกซ้ำด้วย reference เดิมจะได้ออเดอร์เดิมกลับมา ไม่ส่งซ้ำ

## สถานะออเดอร์

| สถานะ | ความหมาย |
|---|---|
| `pending` | รอคิว |
| `processing` | กำลังส่ง |
| `completed` | ส่งสำเร็จ |
| `failed` | ไม่สำเร็จ และยืนยันได้ว่าไม่มี Robux ถูกจ่ายออก กดส่งใหม่ได้ |
| `review` | **ไม่ทราบผล** (เน็ตหลุด/Roblox ล่ม/โปรแกรมดับระหว่างส่ง) ระบบจะไม่ส่งซ้ำเอง ให้ตรวจประวัติธุรกรรมใน Roblox ก่อน แล้วกด "ส่งถึงแล้ว" หรือ "ส่งใหม่" |
| `cancelled` | ยกเลิกก่อนส่ง |

## ตัวป้องกันความเสียหาย

- ส่งทีละออเดอร์ มีหน่วงเวลาระหว่างออเดอร์ (`SEND_DELAY_MS`)
- วงเงินต่อออเดอร์ (`MAX_PER_ORDER`) และต่อ 24 ชั่วโมง (`DAILY_LIMIT`) — ถึงวงเงินแล้วออเดอร์ที่เหลือจะรอ ไม่ถูกตีตก
- ตรวจคุณสมบัติผู้รับก่อนจ่ายทุกครั้ง และล็อกราคา/ผู้ขายตอนซื้อ Game Pass
- ทุกการเปลี่ยนสถานะถูกบันทึกในตาราง `events`

## ทดสอบ

```bash
npm test
```

ชุดทดสอบใช้ Roblox จำลอง (`test/mock-roblox.js`) จึงไม่มีการจ่าย Robux จริง **ก่อนใช้งานจริงให้ลองส่งจำนวนน้อย ๆ ให้บัญชีทดสอบของคุณเองก่อน** เพราะขั้นตอนจ่ายเงินและ 2-step verification ยังไม่เคยถูกทดสอบกับ Roblox จริง
