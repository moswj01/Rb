import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import { loadConfig } from '../src/config.js';
import { openDb } from '../src/db.js';
import { OrderService } from '../src/orders.js';
import { RobloxClient, gamepassPriceFor } from '../src/roblox.js';
import { createApp } from '../src/server.js';
import { totp } from '../src/totp.js';
import { startMock } from './mock-roblox.js';

const TOKEN = 'test-token-0123456789abcdefghij';
let mock;
let orders;
let roblox;
let config;

function setup(overrides = {}) {
  config = loadConfig({
    ADMIN_TOKEN: TOKEN, ROBLOX_COOKIE: 'good', ROBLOX_GROUP_ID: '55', ROBLOX_API_BASE: mock.base,
    ROBLOX_TOTP_SECRET: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', ...overrides,
  });
  roblox = new RobloxClient({ ...config, timeoutMs: 2000 });
  orders = new OrderService({ db: openDb(':memory:'), roblox, config });
  orders.stop(); // ทดสอบโดยเรียก processNext เอง
}

before(async () => { mock = await startMock(); });
after(() => mock.close());
beforeEach(() => {
  Object.assign(mock.state, { payouts: [], purchases: [], dropPayout: false, challenge: false, challengeCodes: [] });
  setup();
});

test('totp ตรงกับ RFC 6238', () => {
  assert.equal(totp('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', 59_000), '287082');
  assert.equal(totp('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', 1111111109_000), '081804');
});

test('group payout สำเร็จ (รวมขั้นตอนขอ CSRF token)', async () => {
  const { order } = orders.create({ username: 'alice', amount: 250 });
  assert.equal(await orders.processNext(), 'processed');
  const done = orders.get(order.id);
  assert.equal(done.status, 'completed');
  assert.equal(done.user_id, 101);
  assert.deepEqual(mock.state.payouts, [
    { PayoutType: 'FixedAmount', Recipients: [{ recipientId: 101, recipientType: 'User', amount: 250 }] },
  ]);
  assert.equal(await orders.processNext(), 'idle');
});

test('ผู้รับไม่อยู่ในกลุ่ม → failed และไม่จ่ายเงิน', async () => {
  const { order } = orders.create({ username: 'bob', amount: 100 });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'failed');
  assert.match(orders.get(order.id).error, /NotInGroup/);
  assert.equal(mock.state.payouts.length, 0);
});

test('ไม่พบ username → failed', async () => {
  const { order } = orders.create({ username: 'nobody_here', amount: 100 });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'failed');
});

test('เน็ตหลุดระหว่างจ่าย → review และไม่ส่งซ้ำเอง', async () => {
  mock.state.dropPayout = true;
  const { order } = orders.create({ username: 'alice', amount: 100 });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'review');
  assert.equal(await orders.processNext(), 'idle');
  assert.equal(orders.spentToday(), 100); // นับเป็นวงเงินที่ใช้ไปแล้วจนกว่าจะตรวจ
  assert.equal(orders.resolve(order.id, 'failed').status, 'failed');
});

test('2-step verification ถูกตอบด้วย TOTP แล้วจ่ายสำเร็จ', async () => {
  mock.state.challenge = true;
  const { order } = orders.create({ username: 'alice', amount: 100 });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'completed');
  assert.equal(mock.state.payouts.length, 1);
  assert.match(mock.state.challengeCodes[0], /^\d{6}$/);
});

test('ไม่มี TOTP secret → failed พร้อมข้อความชัดเจน', async () => {
  setup({ ROBLOX_TOTP_SECRET: '' });
  mock.state.challenge = true;
  const { order } = orders.create({ username: 'alice', amount: 100 });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'failed');
  assert.match(orders.get(order.id).error, /ROBLOX_TOTP_SECRET/);
  assert.equal(mock.state.payouts.length, 0);
});

test('gamepass: หา pass ราคาที่ถูกต้องแล้วซื้อ', async () => {
  assert.equal(gamepassPriceFor(100), 143);
  const { order } = orders.create({ username: 'alice', amount: 100, method: 'gamepass' });
  assert.equal(order.cost, 143);
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'completed');
  assert.deepEqual(mock.state.purchases, [{ productId: 7001, expectedCurrency: 1, expectedPrice: 143, expectedSellerId: 101 }]);
});

test('gamepass: ไม่มี pass ราคาตรง → failed', async () => {
  const { order } = orders.create({ username: 'alice', amount: 500, method: 'gamepass' });
  await orders.processNext();
  assert.equal(orders.get(order.id).status, 'failed');
  assert.equal(mock.state.purchases.length, 0);
});

test('reference ซ้ำไม่สร้างออเดอร์ใหม่', () => {
  const a = orders.create({ username: 'alice', amount: 100, reference: 'pay-1' });
  const b = orders.create({ username: 'alice', amount: 100, reference: 'pay-1' });
  assert.equal(a.created, true);
  assert.equal(b.created, false);
  assert.equal(a.order.id, b.order.id);
  assert.throws(() => orders.create({ username: 'alice', amount: 999, reference: 'pay-1' }), /reference/);
});

test('วงเงิน: ต่อออเดอร์และรายวัน', async () => {
  setup({ MAX_PER_ORDER: '500', DAILY_LIMIT: '300' });
  assert.throws(() => orders.create({ username: 'alice', amount: 501 }), /วงเงิน/);
  assert.throws(() => orders.create({ username: 'alice', amount: 1.5 }), /amount/);
  assert.throws(() => orders.create({ username: 'a b', amount: 5 }), /username/);
  orders.create({ username: 'alice', amount: 200 });
  const second = orders.create({ username: 'alice', amount: 200 }).order;
  assert.equal(await orders.processNext(), 'processed');
  assert.equal(await orders.processNext(), 'limited');
  assert.equal(orders.get(second.id).status, 'pending');
  assert.equal(mock.state.payouts.length, 1);
});

test('ออเดอร์ค้าง processing ตอนรีสตาร์ต → review', () => {
  const db = openDb(':memory:');
  db.prepare(`INSERT INTO orders (username, amount, cost, method, status, created_at, updated_at) VALUES ('alice', 5, 5, 'group', 'processing', 1, 1)`).run();
  const svc = new OrderService({ db, roblox, config });
  svc.stop();
  assert.equal(svc.get(1).status, 'review');
});

test('HTTP API: ต้องมีโทเคน, สร้าง/ดู/ยกเลิกออเดอร์', async () => {
  const server = createApp({ orders, roblox, config });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = (path, { token = TOKEN, method = 'GET', body } = {}) =>
    fetch(base + path, {
      method,
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: body && JSON.stringify(body),
    });
  try {
    assert.equal((await call('/api/orders', { token: 'wrong' })).status, 401);
    assert.equal((await fetch(base + '/api/status')).status, 401);
    assert.equal((await fetch(base + '/')).status, 200);

    let res = await call('/api/orders', { method: 'POST', body: { username: 'alice', amount: 50, reference: 'r1' } });
    assert.equal(res.status, 201);
    const { order } = await res.json();
    assert.equal((await call('/api/orders', { method: 'POST', body: { username: 'alice', amount: 50, reference: 'r1' } })).status, 200);
    assert.equal((await call('/api/orders', { method: 'POST', body: { username: 'x', amount: 50 } })).status, 400);

    res = await call('/api/status');
    const status = await res.json();
    assert.equal(status.account.name, 'ShopOwner');
    assert.equal(status.groupBalance, 99999);

    res = await call('/api/check?username=bob&amount=10');
    assert.deepEqual((await res.json()).eligibility, 'NotInGroup');

    assert.equal((await call(`/api/orders/${order.id}/cancel`, { method: 'POST' })).status, 200);
    assert.equal((await call(`/api/orders/${order.id}/cancel`, { method: 'POST' })).status, 409);
    res = await call(`/api/orders/${order.id}`);
    const detail = await res.json();
    assert.equal(detail.order.status, 'cancelled');
    assert.ok(detail.events.length >= 2);
    assert.equal((await call('/api/orders/9999')).status, 404);
  } finally {
    server.close();
  }
});
