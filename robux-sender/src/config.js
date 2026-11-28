import { existsSync } from 'node:fs';

const METHODS = ['group', 'gamepass'];

function int(env, name, fallback) {
  const raw = env[name];
  if (raw === undefined || raw === '') return fallback;
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 0) throw new Error(`${name} ต้องเป็นจำนวนเต็มไม่ติดลบ`);
  return n;
}

export function loadConfig(env = process.env) {
  if (env === process.env && existsSync('.env')) process.loadEnvFile('.env');

  const config = {
    adminToken: env.ADMIN_TOKEN || '',
    cookie: (env.ROBLOX_COOKIE || '').trim(),
    totpSecret: (env.ROBLOX_TOTP_SECRET || '').trim(),
    defaultMethod: env.DEFAULT_METHOD || 'group',
    groupId: int(env, 'ROBLOX_GROUP_ID', 0),
    maxPerOrder: int(env, 'MAX_PER_ORDER', 10000),
    dailyLimit: int(env, 'DAILY_LIMIT', 100000),
    sendDelayMs: int(env, 'SEND_DELAY_MS', 3000),
    host: env.HOST || '127.0.0.1',
    port: int(env, 'PORT', 3000),
    dbPath: env.DB_PATH || './data/orders.db',
    // ใช้ชี้ไป mock server ตอนทดสอบเท่านั้น
    apiBase: env.ROBLOX_API_BASE || '',
  };

  if (config.adminToken.length < 24) throw new Error('ต้องตั้ง ADMIN_TOKEN อย่างน้อย 24 ตัวอักษร');
  if (!config.cookie) throw new Error('ต้องตั้ง ROBLOX_COOKIE');
  if (!METHODS.includes(config.defaultMethod)) throw new Error('DEFAULT_METHOD ต้องเป็น group หรือ gamepass');
  if (config.defaultMethod === 'group' && !config.groupId) throw new Error('วิธี group ต้องตั้ง ROBLOX_GROUP_ID');
  return config;
}

export { METHODS };
