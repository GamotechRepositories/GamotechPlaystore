import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import Wallet from '../models/Wallet.js';
import WalletRecord from '../models/WalletRecord.js';
import walletRoute from '../routes/walletRoute.js';

test('wallet authenticates and scopes history to the token owner', async () => {
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'wallet-test-only';
  const originalWallet = Wallet.findOne;
  const originalRecords = WalletRecord.find;
  const user = '507f1f77bcf86cd799439011';
  const walletId = '507f1f77bcf86cd799439012';
  let missing = false;
  Wallet.findOne = async query => {
    assert.deepEqual(query, { user });
    return missing ? null : { _id: walletId, balance: 4567, currency: 'INR' };
  };
  WalletRecord.find = query => {
    assert.deepEqual(query, { wallet: walletId });
    return { sort(order) {
      assert.deepEqual(order, { createdAt: -1, _id: -1 });
      return { skip(offset) {
        assert.equal(offset, 20);
        return { limit: async limit => {
          assert.equal(limit, 21);
          return Array.from({ length: 21 }, (_, i) => ({ reference: `record-${i}` }));
        } };
      } };
    } };
  };
  const app = express();
  app.use('/api/v1', walletRoute);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/api/v1/wallet`;
  const token = jwt.sign({}, process.env.JWT_SECRET, { subject: user, algorithm: 'HS256', issuer: 'gamotech', audience: 'gamotech-app', expiresIn: '1h' });
  const headers = { Authorization: `Bearer ${token}` };
  try {
    assert.equal((await fetch(url)).status, 401);
    assert.equal((await fetch(url, { headers: { Authorization: 'Bearer invalid' } })).status, 401);
    assert.equal((await fetch(`${url}?page=0`, { headers })).status, 400);
    const response = await fetch(`${url}?page=2&user=other&wallet=other`, { headers });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const body = await response.json();
    assert.deepEqual(body.wallet, { balance: 4567, currency: 'INR' });
    assert.equal(body.records.length, 20);
    assert.equal(body.hasMore, true);
    missing = true;
    assert.equal((await fetch(url, { headers })).status, 404);
  } finally {
    Wallet.findOne = originalWallet;
    WalletRecord.find = originalRecords;
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
    await new Promise(resolve => server.close(resolve));
  }
});
