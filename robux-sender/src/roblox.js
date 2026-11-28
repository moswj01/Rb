import { totp } from './totp.js';

/**
 * ข้อผิดพลาดจาก Roblox
 * ambiguous = true หมายถึงไม่รู้ว่าคำขอถูกประมวลผลหรือไม่ (เน็ตหลุด / timeout / 5xx)
 */
export class RobloxError extends Error {
  constructor(message, { status = 0, ambiguous = false } = {}) {
    super(message);
    this.name = 'RobloxError';
    this.status = status;
    this.ambiguous = ambiguous;
  }
}

/** ราคา Game Pass ที่ผู้รับต้องตั้ง เพื่อให้ได้รับ amount หลังหัก 30% */
export function gamepassPriceFor(amount) {
  return Math.ceil(amount / 0.7);
}

export class RobloxClient {
  constructor({ cookie, totpSecret = '', apiBase = '', timeoutMs = 15000 }) {
    this.cookie = cookie;
    this.totpSecret = totpSecret;
    this.apiBase = apiBase.replace(/\/$/, '');
    this.timeoutMs = timeoutMs;
    this.csrf = '';
    this.self = null;
  }

  url(host, path) {
    return this.apiBase ? `${this.apiBase}/${host}${path}` : `https://${host}.roblox.com${path}`;
  }

  async request(host, path, { method = 'GET', body, extraHeaders = {}, retried = {} } = {}) {
    const headers = { accept: 'application/json', cookie: `.ROBLOSECURITY=${this.cookie}`, ...extraHeaders };
    if (body !== undefined) headers['content-type'] = 'application/json';
    if (method !== 'GET' && this.csrf) headers['x-csrf-token'] = this.csrf;

    let res;
    let text;
    try {
      res = await fetch(this.url(host, path), {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      text = await res.text();
    } catch (err) {
      throw new RobloxError(`เชื่อมต่อ Roblox ไม่สำเร็จ: ${err.cause?.code || err.name}`, { ambiguous: true });
    }
    const again = (extra) => this.request(host, path, { method, body, extraHeaders, ...extra });

    if (res.status === 403) {
      // Roblox ปฏิเสธคำขอที่ไม่มี CSRF token โดยยังไม่ประมวลผล จึงลองใหม่ได้อย่างปลอดภัย
      const token = res.headers.get('x-csrf-token');
      if (token && !retried.csrf) {
        this.csrf = token;
        return again({ retried: { ...retried, csrf: true } });
      }
      const challengeId = res.headers.get('rblx-challenge-id');
      if (challengeId && !retried.challenge) {
        const solved = await this.solveChallenge(challengeId, res.headers);
        return again({ extraHeaders: { ...extraHeaders, ...solved }, retried: { ...retried, challenge: true } });
      }
    }

    let data = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      /* ไม่ใช่ JSON */
    }
    if (!res.ok) {
      const first = data?.errors?.[0];
      const msg = first?.message || data?.errorMessage || data?.message || text.slice(0, 200) || res.statusText;
      const code = first?.code !== undefined ? ` (code ${first.code})` : '';
      throw new RobloxError(`Roblox ตอบ ${res.status}: ${msg}${code}`, {
        status: res.status,
        ambiguous: res.status >= 500,
      });
    }
    return data;
  }

  /** ตอบ 2-step verification ด้วยรหัส Authenticator แล้วคืน header สำหรับส่งคำขอเดิมซ้ำ */
  async solveChallenge(challengeId, headers) {
    const type = headers.get('rblx-challenge-type');
    if (type !== 'twostepverification') {
      throw new RobloxError(`Roblox ขอการยืนยันแบบ "${type}" ซึ่งระบบตอบอัตโนมัติไม่ได้`, { status: 403 });
    }
    if (!this.totpSecret) {
      throw new RobloxError('Roblox ขอ 2-step verification แต่ยังไม่ได้ตั้ง ROBLOX_TOTP_SECRET', { status: 403 });
    }
    const meta = JSON.parse(Buffer.from(headers.get('rblx-challenge-metadata') || '', 'base64').toString('utf8'));
    const { id: userId } = await this.getSelf();
    const verify = await this.request('twostepverification', `/v1/users/${userId}/challenges/authenticator/verify`, {
      method: 'POST',
      body: { challengeId: meta.challengeId, actionType: meta.actionType, code: totp(this.totpSecret) },
      retried: { challenge: true },
    });
    const challengeMetadata = JSON.stringify({
      verificationToken: verify.verificationToken,
      rememberDevice: false,
      challengeId: meta.challengeId,
      actionType: meta.actionType,
    });
    await this.request('apis', '/challenge/v1/continue', {
      method: 'POST',
      body: { challengeId, challengeType: type, challengeMetadata },
      retried: { challenge: true },
    });
    return {
      'rblx-challenge-id': challengeId,
      'rblx-challenge-type': type,
      'rblx-challenge-metadata': Buffer.from(challengeMetadata).toString('base64'),
    };
  }

  async getSelf() {
    if (!this.self) {
      const me = await this.request('users', '/v1/users/authenticated');
      this.self = { id: me.id, name: me.name };
    }
    return this.self;
  }

  /** คืน { id, name } หรือ null ถ้าไม่พบ username */
  async resolveUsername(username) {
    const data = await this.request('users', '/v1/usernames/users', {
      method: 'POST',
      body: { usernames: [username], excludeBannedUsers: true },
    });
    const user = data?.data?.[0];
    return user ? { id: user.id, name: user.name } : null;
  }

  async getUserBalance() {
    const { id } = await this.getSelf();
    return (await this.request('economy', `/v1/users/${id}/currency`)).robux;
  }

  async getGroupBalance(groupId) {
    return (await this.request('economy', `/v1/groups/${groupId}/currency`)).robux;
  }

  /** คืนสถานะ เช่น "Eligible", "NotInGroup", "PayoutRestricted" */
  async getPayoutEligibility(groupId, userId) {
    const data = await this.request('economy', `/v1/groups/${groupId}/users-payout-eligibility?userIds=${userId}`);
    return data?.usersGroupPayoutEligibility?.[String(userId)] || 'Unknown';
  }

  async groupPayout(groupId, userId, amount) {
    await this.request('groups', `/v1/groups/${groupId}/payouts`, {
      method: 'POST',
      body: { PayoutType: 'FixedAmount', Recipients: [{ recipientId: userId, recipientType: 'User', amount }] },
    });
  }

  /** หา Game Pass ที่ผู้ใช้สร้างเอง เปิดขายอยู่ และราคาตรงกับ price */
  async findGamePass(userId, price) {
    let cursor = '';
    for (let page = 0; page < 5; page++) {
      const games = await this.request(
        'games',
        `/v2/users/${userId}/games?accessFilter=Public&limit=50&sortOrder=Asc${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ''}`,
      );
      for (const game of games?.data || []) {
        const passes = await this.request(
          'apis',
          `/game-passes/v1/universes/${game.id}/game-passes?passView=Full&pageSize=100`,
        );
        const hit = (passes?.gamePasses || []).find(
          (p) => p.isForSale && p.price === price && p.creator?.creatorType === 'User' && p.creator?.creatorId === userId,
        );
        if (hit) return { id: hit.id, productId: hit.productId, name: hit.name, price: hit.price };
      }
      cursor = games?.nextPageCursor;
      if (!cursor) break;
    }
    return null;
  }

  async buyGamePass(pass, sellerId) {
    const data = await this.request('economy', `/v1/purchases/products/${pass.productId}`, {
      method: 'POST',
      body: { expectedCurrency: 1, expectedPrice: pass.price, expectedSellerId: sellerId },
    });
    if (!data?.purchased) {
      throw new RobloxError(`ซื้อ Game Pass ไม่สำเร็จ: ${data?.reason || data?.errorMsg || 'ไม่ทราบสาเหตุ'}`, { status: 200 });
    }
  }
}
