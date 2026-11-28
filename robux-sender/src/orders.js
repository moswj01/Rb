import { METHODS } from './config.js';
import { gamepassPriceFor } from './roblox.js';

const USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;
const MAX_ATTEMPTS = 3;

export class OrderError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.status = status;
  }
}

/**
 * สถานะออเดอร์
 *   pending    รอคิว
 *   processing กำลังส่ง
 *   completed  ส่งสำเร็จ
 *   failed     ไม่สำเร็จ และยืนยันได้ว่าไม่มี Robux ถูกจ่ายออก
 *   review     ไม่ทราบผล (เช่น เน็ตหลุดระหว่างส่ง) ต้องให้คนตรวจก่อน ระบบจะไม่ส่งซ้ำเอง
 *   cancelled  ยกเลิกก่อนส่ง
 */
export class OrderService {
  constructor({ db, roblox, config, now = Date.now }) {
    this.db = db;
    this.roblox = roblox;
    this.config = config;
    this.now = now;
    this.timer = null;
    this.busy = false;
    this.lastWorkerError = null;
    // ออเดอร์ที่ค้าง processing ตอนโปรแกรมดับ ไม่รู้ว่าส่งไปแล้วหรือยัง จึงต้องให้คนตรวจ
    const stuck = db.prepare(`SELECT id FROM orders WHERE status = 'processing'`).all();
    for (const { id } of stuck) {
      this.#update(id, { status: 'review', error: 'โปรแกรมหยุดทำงานระหว่างส่ง กรุณาตรวจสอบประวัติธุรกรรมใน Roblox' });
    }
  }

  #log(orderId, message) {
    this.db.prepare('INSERT INTO events (order_id, at, message) VALUES (?, ?, ?)').run(orderId, this.now(), message);
  }

  #update(id, fields) {
    const data = { ...fields, updated_at: this.now() };
    const keys = Object.keys(data);
    this.db
      .prepare(`UPDATE orders SET ${keys.map((k) => `${k} = ?`).join(', ')} WHERE id = ?`)
      .run(...keys.map((k) => data[k]), id);
    if (fields.status) this.#log(id, `สถานะ → ${fields.status}${fields.error ? `: ${fields.error}` : ''}`);
  }

  get(id) {
    const order = this.db.prepare('SELECT * FROM orders WHERE id = ?').get(id);
    if (!order) throw new OrderError('ไม่พบออเดอร์', 404);
    return order;
  }

  events(id) {
    return this.db.prepare('SELECT at, message FROM events WHERE order_id = ? ORDER BY id').all(id);
  }

  list({ status, limit = 100 } = {}) {
    const n = Math.min(Math.max(Number(limit) || 100, 1), 500);
    return status
      ? this.db.prepare('SELECT * FROM orders WHERE status = ? ORDER BY id DESC LIMIT ?').all(status, n)
      : this.db.prepare('SELECT * FROM orders ORDER BY id DESC LIMIT ?').all(n);
  }

  create({ username, amount, method, reference }) {
    username = typeof username === 'string' ? username.trim().replace(/^@/, '') : '';
    if (!USERNAME_RE.test(username)) throw new OrderError('username ไม่ถูกต้อง (3-20 ตัว: a-z, 0-9, _)');
    if (!Number.isInteger(amount) || amount < 1) throw new OrderError('amount ต้องเป็นจำนวนเต็มตั้งแต่ 1 ขึ้นไป');
    method = method || this.config.defaultMethod;
    if (!METHODS.includes(method)) throw new OrderError('method ต้องเป็น group หรือ gamepass');
    if (method === 'group' && !this.config.groupId) throw new OrderError('ยังไม่ได้ตั้ง ROBLOX_GROUP_ID');
    const cost = method === 'gamepass' ? gamepassPriceFor(amount) : amount;
    if (cost > this.config.maxPerOrder) {
      throw new OrderError(`เกินวงเงินต่อออเดอร์ (${cost} > ${this.config.maxPerOrder})`);
    }
    if (reference !== undefined && reference !== null) {
      if (typeof reference !== 'string' || !/^[\w.:-]{1,100}$/.test(reference)) {
        throw new OrderError('reference ต้องเป็นตัวอักษร/ตัวเลข/._:- ไม่เกิน 100 ตัว');
      }
      const existing = this.db.prepare('SELECT * FROM orders WHERE reference = ?').get(reference);
      if (existing) {
        if (existing.username.toLowerCase() !== username.toLowerCase() || existing.amount !== amount || existing.method !== method) {
          throw new OrderError('reference นี้ถูกใช้กับออเดอร์อื่นที่ข้อมูลไม่ตรงกัน', 409);
        }
        return { order: existing, created: false };
      }
    }
    const t = this.now();
    const { lastInsertRowid } = this.db
      .prepare(
        `INSERT INTO orders (reference, username, amount, cost, method, status, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)`,
      )
      .run(reference ?? null, username, amount, cost, method, t, t);
    const id = Number(lastInsertRowid);
    this.#log(id, `สร้างออเดอร์: ${amount} R$ → ${username} (${method})`);
    this.kick();
    return { order: this.get(id), created: true };
  }

  cancel(id) {
    if (this.get(id).status !== 'pending') throw new OrderError('ยกเลิกได้เฉพาะออเดอร์ที่ยังรอคิว', 409);
    this.#update(id, { status: 'cancelled' });
    return this.get(id);
  }

  /** ส่งใหม่: ใช้กับ failed หรือ review (หลังตรวจแล้วว่า Robux ยังไม่ถูกจ่าย) */
  retry(id) {
    if (!['failed', 'review'].includes(this.get(id).status)) {
      throw new OrderError('ส่งใหม่ได้เฉพาะออเดอร์ที่ failed หรือ review', 409);
    }
    this.#update(id, { status: 'pending', attempts: 0, error: null });
    this.kick();
    return this.get(id);
  }

  /** ปิดออเดอร์ review ด้วยมือหลังตรวจประวัติธุรกรรมแล้ว */
  resolve(id, status) {
    if (!['completed', 'failed'].includes(status)) throw new OrderError('status ต้องเป็น completed หรือ failed');
    if (this.get(id).status !== 'review') throw new OrderError('ใช้ได้เฉพาะออเดอร์ที่อยู่ในสถานะ review', 409);
    this.#update(id, { status, error: null, completed_at: status === 'completed' ? this.now() : null });
    this.#log(id, 'แอดมินปิดออเดอร์ด้วยมือ');
    return this.get(id);
  }

  /** Robux ที่จ่ายออก (หรืออาจจ่ายออกแล้ว) ใน 24 ชั่วโมงล่าสุด */
  spentToday() {
    const row = this.db
      .prepare(
        `SELECT COALESCE(SUM(cost), 0) AS total FROM orders
         WHERE status IN ('completed', 'review', 'processing') AND updated_at > ?`,
      )
      .get(this.now() - 24 * 3600 * 1000);
    return row.total;
  }

  stats() {
    const counts = Object.fromEntries(
      this.db.prepare('SELECT status, COUNT(*) AS n FROM orders GROUP BY status').all().map((r) => [r.status, r.n]),
    );
    return { counts, spentToday: this.spentToday(), dailyLimit: this.config.dailyLimit, lastWorkerError: this.lastWorkerError };
  }

  /** ตรวจล่วงหน้าว่า username นี้พร้อมรับหรือไม่ (ไม่มีการจ่ายเงิน) */
  async check(username, amount, method = this.config.defaultMethod) {
    const user = await this.roblox.resolveUsername(username);
    if (!user) return { found: false };
    const result = { found: true, user, method };
    if (method === 'group') {
      result.eligibility = await this.roblox.getPayoutEligibility(this.config.groupId, user.id);
      result.ready = result.eligibility === 'Eligible';
    } else {
      result.requiredPrice = gamepassPriceFor(amount);
      result.gamePass = await this.roblox.findGamePass(user.id, result.requiredPrice);
      result.ready = Boolean(result.gamePass);
    }
    return result;
  }

  // ---------- worker ----------

  start() {
    this.kick();
  }

  stop() {
    clearTimeout(this.timer);
    this.timer = null;
    this.stopped = true;
  }

  kick(delay = 0) {
    if (this.stopped || this.timer) return;
    this.timer = setTimeout(async () => {
      this.timer = null;
      const outcome = await this.processNext().catch((err) => {
        this.lastWorkerError = err.message;
        return 'error';
      });
      if (outcome === 'processed') this.kick(this.config.sendDelayMs);
      else if (outcome !== 'idle') this.kick(60_000); // ติดวงเงิน/ผิดพลาด: รอแล้วลองใหม่
    }, delay);
    this.timer.unref?.();
  }

  /** ประมวลผลออเดอร์ถัดไป 1 รายการ คืน 'idle' | 'limited' | 'processed' */
  async processNext() {
    if (this.busy) return 'idle';
    const order = this.db.prepare(`SELECT * FROM orders WHERE status = 'pending' ORDER BY id LIMIT 1`).get();
    if (!order) return 'idle';
    if (this.spentToday() + order.cost > this.config.dailyLimit) {
      this.lastWorkerError = 'ถึงวงเงินรายวันแล้ว ออเดอร์ที่เหลือจะรอจนกว่าวงเงินจะว่าง';
      return 'limited';
    }
    this.busy = true;
    try {
      await this.#send(order);
      this.lastWorkerError = null;
    } finally {
      this.busy = false;
    }
    return 'processed';
  }

  async #send(order) {
    const attempts = order.attempts + 1;
    this.#update(order.id, { status: 'processing', attempts, error: null });
    let moneyRequested = false;
    try {
      const user = await this.roblox.resolveUsername(order.username);
      if (!user) throw new OrderError(`ไม่พบผู้ใช้ "${order.username}"`);
      this.#update(order.id, { user_id: user.id, username: user.name });

      let detail;
      if (order.method === 'group') {
        const eligibility = await this.roblox.getPayoutEligibility(this.config.groupId, user.id);
        if (eligibility !== 'Eligible') {
          throw new OrderError(`ผู้รับยังรับเงินจากกลุ่มไม่ได้ (${eligibility}) — ต้องเป็นสมาชิกกลุ่มและพ้นช่วงรอ`);
        }
        moneyRequested = true;
        await this.roblox.groupPayout(this.config.groupId, user.id, order.amount);
        detail = `group payout จากกลุ่ม ${this.config.groupId}`;
      } else {
        const pass = await this.roblox.findGamePass(user.id, order.cost);
        if (!pass) throw new OrderError(`ไม่พบ Game Pass ของผู้รับที่เปิดขายราคา ${order.cost} R$`);
        moneyRequested = true;
        await this.roblox.buyGamePass(pass, user.id);
        detail = `ซื้อ Game Pass #${pass.id} ราคา ${pass.price} R$`;
      }
      this.#update(order.id, { status: 'completed', detail, completed_at: this.now() });
    } catch (err) {
      const message = String(err.message || err).slice(0, 500);
      if (err.ambiguous && moneyRequested) {
        this.#update(order.id, { status: 'review', error: `ไม่ทราบผลการส่ง: ${message}` });
      } else if (err.ambiguous && attempts < MAX_ATTEMPTS) {
        // ยังไม่ได้ยิงคำขอจ่ายเงิน จึงลองใหม่ได้อย่างปลอดภัย
        this.#update(order.id, { status: 'pending', error: message });
      } else {
        this.#update(order.id, { status: 'failed', error: message });
      }
    }
  }
}
