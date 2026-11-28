import { createServer } from 'node:http';

/** Roblox จำลองสำหรับทดสอบ: path รูปแบบ /{host}/{path จริง} */
export async function startMock() {
  const state = {
    users: { alice: 101, bob: 102 },
    eligibility: { 101: 'Eligible', 102: 'NotInGroup' },
    passes: { 101: [{ id: 9001, productId: 7001, name: 'Donate', isForSale: true, price: 143 }] },
    payouts: [],
    purchases: [],
    dropPayout: false,
    challenge: false,
    challengeCodes: [],
  };
  const json = (res, status, body, headers = {}) => {
    res.writeHead(status, { 'content-type': 'application/json', ...headers });
    res.end(JSON.stringify(body));
  };
  const server = createServer(async (req, res) => {
    let raw = '';
    for await (const c of req) raw += c;
    const body = raw ? JSON.parse(raw) : {};
    const url = new URL(req.url, 'http://x');
    const p = url.pathname;
    if (!/\.ROBLOSECURITY=good/.test(req.headers.cookie || '')) return json(res, 401, { errors: [{ code: 0, message: 'Unauthorized' }] });
    if (req.method === 'POST' && req.headers['x-csrf-token'] !== 'csrf-1') {
      return json(res, 403, { errors: [{ code: 0, message: 'XSRF token invalid' }] }, { 'x-csrf-token': 'csrf-1' });
    }
    if (p === '/users/v1/users/authenticated') return json(res, 200, { id: 1, name: 'ShopOwner' });
    if (p === '/users/v1/usernames/users') {
      const name = body.usernames[0];
      const id = state.users[name.toLowerCase()];
      return json(res, 200, { data: id ? [{ id, name: name[0].toUpperCase() + name.slice(1).toLowerCase(), requestedUsername: name }] : [] });
    }
    if (p === '/economy/v1/users/1/currency') return json(res, 200, { robux: 5000 });
    if (p === '/economy/v1/groups/55/currency') return json(res, 200, { robux: 99999 });
    if (p === '/economy/v1/groups/55/users-payout-eligibility') {
      const id = url.searchParams.get('userIds');
      return json(res, 200, { usersGroupPayoutEligibility: { [id]: state.eligibility[id] } });
    }
    if (p === '/groups/v1/groups/55/payouts') {
      if (state.dropPayout) return req.socket.destroy();
      if (state.challenge && !req.headers['rblx-challenge-metadata']) {
        const meta = Buffer.from(JSON.stringify({ challengeId: 'inner-1', actionType: 'Generic' })).toString('base64');
        return json(res, 403, { errors: [{ code: 0, message: 'Challenge is required' }] }, {
          'rblx-challenge-id': 'outer-1', 'rblx-challenge-type': 'twostepverification', 'rblx-challenge-metadata': meta,
        });
      }
      state.payouts.push(body);
      return json(res, 200, {});
    }
    if (p === '/twostepverification/v1/users/1/challenges/authenticator/verify') {
      state.challengeCodes.push(body.code);
      return json(res, 200, { verificationToken: 'vt-1' });
    }
    if (p === '/apis/challenge/v1/continue') return json(res, 200, {});
    let m = /^\/games\/v2\/users\/(\d+)\/games$/.exec(p);
    if (m) return json(res, 200, { data: state.passes[m[1]] ? [{ id: Number(m[1]) * 10 }] : [], nextPageCursor: null });
    m = /^\/apis\/game-passes\/v1\/universes\/(\d+)\/game-passes$/.exec(p);
    if (m) {
      const owner = Number(m[1]) / 10;
      return json(res, 200, { gamePasses: (state.passes[owner] || []).map((x) => ({ ...x, creator: { creatorType: 'User', creatorId: owner } })) });
    }
    m = /^\/economy\/v1\/purchases\/products\/(\d+)$/.exec(p);
    if (m) {
      state.purchases.push({ productId: Number(m[1]), ...body });
      return json(res, 200, { purchased: true });
    }
    json(res, 404, { errors: [{ code: 0, message: `mock: no route ${p}` }] });
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  return { state, base: `http://127.0.0.1:${server.address().port}`, close: () => server.close() };
}
