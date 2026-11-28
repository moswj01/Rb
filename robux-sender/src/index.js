import { loadConfig } from './config.js';
import { openDb } from './db.js';
import { OrderService } from './orders.js';
import { RobloxClient } from './roblox.js';
import { createApp } from './server.js';

let config;
try {
  config = loadConfig();
} catch (err) {
  console.error(`ตั้งค่าไม่ถูกต้อง: ${err.message}\nดูตัวอย่างที่ .env.example`);
  process.exit(1);
}

const roblox = new RobloxClient(config);
const orders = new OrderService({ db: openDb(config.dbPath), roblox, config });

try {
  const me = await roblox.getSelf();
  console.log(`เข้าสู่ระบบ Roblox เป็น ${me.name} (${me.id})`);
} catch (err) {
  console.error(`คำเตือน: ตรวจสอบ cookie ไม่สำเร็จ — ${err.message}`);
}

createApp({ orders, roblox, config }).listen(config.port, config.host, () => {
  console.log(`เว็บแอดมิน: http://${config.host}:${config.port}`);
  orders.start();
});
