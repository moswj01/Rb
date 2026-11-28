import { createHash, timingSafeEqual } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { OrderError } from './orders.js';
import { RobloxError } from './roblox.js';

const INDEX_HTML = readFileSync(new URL('../public/index.html', import.meta.url));
const sha = (s) => createHash('sha256').update(s).digest();

function send(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' });
  res.end(JSON.stringify(body));
}

async function readJson(req) {
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 10_000) throw new OrderError('body ใหญ่เกินไป', 413);
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try {
    const data = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (data && typeof data === 'object' && !Array.isArray(data)) return data;
  } catch {
    /* fallthrough */
  }
  throw new OrderError('body ต้องเป็น JSON object');
}

export function createApp({ orders, roblox, config }) {
  const expected = sha(config.adminToken);
  const authorized = (req) => {
    const match = /^Bearer (.+)$/.exec(req.headers.authorization || '');
    return Boolean(match) && timingSafeEqual(sha(match[1]), expected);
  };

  async function route(req, res) {
    const url = new URL(req.url, 'http://localhost');
    const { pathname } = url;
    const method = req.method;

    if (method === 'GET' && pathname === '/') {
      res.writeHead(200, {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-store',
        'content-security-policy': "default-src 'self'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; frame-ancestors 'none'",
        'x-content-type-options': 'nosniff',
        'referrer-policy': 'no-referrer',
      });
      return res.end(INDEX_HTML);
    }
    if (!pathname.startsWith('/api/')) return send(res, 404, { error: 'not found' });
    if (!authorized(req)) return send(res, 401, { error: 'unauthorized' });

    if (method === 'GET' && pathname === '/api/status') {
      const status = { ...orders.stats(), defaultMethod: config.defaultMethod, groupId: config.groupId, maxPerOrder: config.maxPerOrder };
      try {
        status.account = await roblox.getSelf();
        status.userBalance = await roblox.getUserBalance();
        if (config.groupId) status.groupBalance = await roblox.getGroupBalance(config.groupId);
      } catch (err) {
        status.robloxError = err.message;
      }
      return send(res, 200, status);
    }
    if (method === 'GET' && pathname === '/api/check') {
      const username = url.searchParams.get('username') || '';
      const amount = Number(url.searchParams.get('amount') || 1);
      const how = url.searchParams.get('method') || config.defaultMethod;
      if (!/^[A-Za-z0-9_]{3,20}$/.test(username)) throw new OrderError('username ไม่ถูกต้อง');
      if (!Number.isInteger(amount) || amount < 1) throw new OrderError('amount ไม่ถูกต้อง');
      if (!['group', 'gamepass'].includes(how)) throw new OrderError('method ไม่ถูกต้อง');
      return send(res, 200, await orders.check(username, amount, how));
    }
    if (pathname === '/api/orders') {
      if (method === 'GET') {
        return send(res, 200, {
          orders: orders.list({ status: url.searchParams.get('status') || undefined, limit: url.searchParams.get('limit') }),
        });
      }
      if (method === 'POST') {
        const { order, created } = orders.create(await readJson(req));
        return send(res, created ? 201 : 200, { order, created });
      }
    }
    const m = /^\/api\/orders\/(\d+)(?:\/(retry|cancel|resolve))?$/.exec(pathname);
    if (m) {
      const id = Number(m[1]);
      if (method === 'GET' && !m[2]) return send(res, 200, { order: orders.get(id), events: orders.events(id) });
      if (method === 'POST' && m[2] === 'retry') return send(res, 200, { order: orders.retry(id) });
      if (method === 'POST' && m[2] === 'cancel') return send(res, 200, { order: orders.cancel(id) });
      if (method === 'POST' && m[2] === 'resolve') {
        return send(res, 200, { order: orders.resolve(id, (await readJson(req)).status) });
      }
    }
    return send(res, 404, { error: 'not found' });
  }

  return createServer((req, res) => {
    route(req, res).catch((err) => {
      if (err instanceof OrderError) return send(res, err.status, { error: err.message });
      if (err instanceof RobloxError) return send(res, 502, { error: err.message });
      console.error(err);
      send(res, 500, { error: 'internal error' });
    });
  });
}
