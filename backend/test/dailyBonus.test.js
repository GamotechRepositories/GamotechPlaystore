import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import Wallet from '../models/Wallet.js';
import WalletRecord from '../models/WalletRecord.js';
import { bonusPolicy, claimDailyBonus } from '../controllers/dailyBonusController.js';

test('daily bonus resets at India midnight', () => {
  assert.equal(bonusPolicy(new Date('2026-11-10T18:29:59Z')).day, '2026-11-10');
  assert.equal(bonusPolicy(new Date('2026-11-10T18:30:00Z')).day, '2026-11-11');
  assert.equal(bonusPolicy(new Date('2026-11-10T12:00:00Z')).nextClaimAt, '2026-11-10T18:30:00.000Z');
});

test('claim credits token owner and records history in a transaction; repeats are rejected', async () => {
  const originals = [Wallet.findOne, WalletRecord.init, WalletRecord.exists, WalletRecord.create, mongoose.connection.transaction];
  const oldSecret = process.env.JWT_SECRET;
  const oldAmount = process.env.DAILY_BONUS_PAISE;
  process.env.JWT_SECRET = 'bonus-test-only';
  process.env.DAILY_BONUS_PAISE = '10000';
  const user = '507f1f77bcf86cd799439011';
  const session = {};
  let claimed = false;
  let record;
  const wallet = { _id: 'wallet1', balance: 500, currency: 'INR', save: async options => assert.equal(options.session, session) };
  Wallet.findOne = query => { assert.deepEqual(query, { user }); return { session: async actual => { assert.equal(actual, session); return wallet; } }; };
  WalletRecord.init = async () => {};
  WalletRecord.exists = () => ({ session: async () => claimed });
  WalletRecord.create = async (records, options) => { assert.equal(options.session, session); record = records[0]; claimed = true; };
  mongoose.connection.transaction = async callback => callback(session);
  const token = jwt.sign({}, process.env.JWT_SECRET, { subject: user, algorithm: 'HS256', issuer: 'gamotech', audience: 'gamotech-app', expiresIn: '1h' });
  const req = { get: () => `Bearer ${token}`, body: { amount: 999999, user: 'someone-else' } };
  const response = () => ({ code: 200, set() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });
  try {
    let res = response();
    await claimDailyBonus(req, res);
    assert.equal(res.code, 200);
    assert.equal(res.body.wallet.balance, 10500);
    assert.equal(record.amount, 10000);
    assert.equal(record.balanceBefore, 500);
    assert.equal(record.balanceAfter, 10500);
    assert.equal(record.reason, 'bonus');
    res = response();
    await claimDailyBonus(req, res);
    assert.equal(res.code, 409);
    assert.equal(wallet.balance, 10500);
  } finally {
    [Wallet.findOne, WalletRecord.init, WalletRecord.exists, WalletRecord.create, mongoose.connection.transaction] = originals;
    if (oldSecret === undefined) delete process.env.JWT_SECRET; else process.env.JWT_SECRET = oldSecret;
    if (oldAmount === undefined) delete process.env.DAILY_BONUS_PAISE; else process.env.DAILY_BONUS_PAISE = oldAmount;
  }
});
