import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import adminRoute from '../routes/adminRoute.js';
import User from '../models/User.js';
import Game from '../models/Game.js';
import WalletRecord from '../models/WalletRecord.js';

test('admin access and paginated data contract', async t => {
  const oldKey = process.env.ADMIN_API_KEY;
  const originals = [User.find, User.countDocuments, Game.countDocuments, WalletRecord.find, WalletRecord.countDocuments];
  const app = express(); app.use('/api/v1/admin', adminRoute);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api/v1/admin`;
  const get = (path, key = 'test-admin-key') => fetch(`${base}${path}`, { headers: { Authorization: `Bearer ${key}` } });
  try {
    delete process.env.ADMIN_API_KEY;
    assert.equal((await get('/users')).status, 503);
    process.env.ADMIN_API_KEY = 'test-admin-key';
    for (const path of ['/overview', '/users', '/transactions']) {
      assert.equal((await get(path, 'wrong')).status, 401);
      assert.equal((await fetch(`${base}${path}`)).status, 401);
    }
    User.countDocuments = async () => 21;
    Game.countDocuments = async () => 4;
    WalletRecord.countDocuments = async () => 21;
    await t.test('overview returns collection totals', async () => {
      const response = await get('/overview');
      assert.equal(response.status, 200);
      assert.equal(response.headers.get('cache-control'), 'no-store');
      assert.deepEqual(await response.json(), { users: 21, games: 4, transactions: 21 });
    });
    await t.test('lists whitelist fields, paginate, and populate transaction owners', async () => {
      for (const [path, Model] of [['users', User], ['transactions', WalletRecord]]) {
        let selected, skipped, populated;
        const query = {
          select(fields) { selected = fields; return this; },
          sort(order) { assert.deepEqual(order, { createdAt: -1, _id: -1 }); return this; },
          skip(value) { skipped = value; return this; },
          limit(value) { assert.equal(value, 20); return this; },
          populate(options) { populated = options; return this; },
          then(resolve, reject) { return Promise.resolve([{ _id: 'record' }]).then(resolve, reject); },
        };
        Model.find = () => query;
        const response = await get(`/${path}?page=2`);
        assert.equal(response.status, 200);
        assert.equal(skipped, 20);
        assert.ok(!selected.includes('password'));
        assert.ok(!selected.includes('googleId'));
        assert.deepEqual(await response.json(), { [path]: [{ _id: 'record' }], total: 21, page: 2, hasMore: false });
        if (path === 'transactions') assert.equal(populated.populate.select, 'username email');
        for (const page of ['0', '-1', 'abc', '1.5', '1000000']) assert.equal((await get(`/${path}?page=${page}`)).status, 400);
      }
    });
    await t.test('database failures return generic errors', async () => {
      User.find = () => { throw new Error('private'); };
      const response = await get('/users');
      assert.equal(response.status, 500);
      assert.deepEqual(await response.json(), { message: 'Unable to load users.' });
    });
  } finally {
    [User.find, User.countDocuments, Game.countDocuments, WalletRecord.find, WalletRecord.countDocuments] = originals;
    if (oldKey === undefined) delete process.env.ADMIN_API_KEY; else process.env.ADMIN_API_KEY = oldKey;
    await new Promise(resolve => server.close(resolve));
  }
});
