import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Wallet from '../models/Wallet.js';
import userRoute from '../routes/userRoute.js';

test('signin validates credentials and issues a signed token', async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/v1', userRoute);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const originalFind = User.findOne;
  const originalWalletFind = Wallet.findOne;
  const originalSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'test-only-secret-that-is-not-used-in-production';
  const post = body => fetch(`http://127.0.0.1:${server.address().port}/api/v1/signin`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  try {
    const user = new User({ email: 'player@example.com', username: 'player1', password: 'password123' });
    await user.validate();
    await User.schema.s.hooks.execPre('save', user, []);
    Wallet.findOne = async query => {
      assert.equal(query.user.toString(), user._id.toString());
      return { balance: 12345, currency: 'INR' };
    };
    let found = user;
    User.findOne = query => {
      assert.equal(query.email, 'player@example.com');
      return { select: async field => { assert.equal(field, '+password'); return found; } };
    };
    let response = await post({ email: ' PLAYER@example.com ', password: 'password123' });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    const body = await response.json();
    const payload = jwt.verify(body.token, process.env.JWT_SECRET, { algorithms: ['HS256'], issuer: 'gamotech', audience: 'gamotech-app' });
    assert.equal(payload.sub, user._id.toString());
    assert.equal(payload.exp - payload.iat, 3600);
    assert.equal(body.user.password, undefined);
    assert.equal(body.user.username, 'player1');
    assert.deepEqual(body.wallet, { balance: 12345, currency: 'INR' });
    assert.equal((await post({})).status, 400);
    response = await post({ email: user.email, password: 'wrong-password' });
    assert.equal(response.status, 401);
    const invalid = await response.json();
    found = null;
    response = await post({ email: user.email, password: 'password123' });
    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), invalid);
    found = new User({ email: user.email, username: 'google-player', googleId: 'verified-google-id' });
    assert.equal((await post({ email: user.email, password: 'password123' })).status, 401);
    delete process.env.JWT_SECRET;
    assert.equal((await post({ email: user.email, password: 'password123' })).status, 503);
  } finally {
    User.findOne = originalFind;
    Wallet.findOne = originalWalletFind;
    if (originalSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = originalSecret;
    await new Promise(resolve => server.close(resolve));
  }
});
