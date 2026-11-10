import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import mongoose from 'mongoose';
import User from '../models/User.js';
import Wallet from '../models/Wallet.js';
import userRoute from '../routes/userRoute.js';

test('signup HTTP contract and existing creation route', async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/v1', userRoute);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const original = User.create;
  const originalUserInit = User.init;
  const originalWalletInit = Wallet.init;
  const originalWalletCreate = Wallet.create;
  const originalTransaction = mongoose.connection.transaction;
  const session = { testSession: true };
  const post = (path, body) => fetch(`http://127.0.0.1:${server.address().port}/api/v1${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const details = { email: 'player@example.com', username: 'player1', password: 'password123' };
  try {
    let saved;
    let savedWallet;
    let transactionFailure;
    User.init = async () => User;
    Wallet.init = async () => Wallet;
    mongoose.connection.transaction = async (callback, options) => {
      assert.equal(options.readPreference, 'primary');
      assert.deepEqual(options.writeConcern, { w: 'majority' });
      try {
        return await callback(session);
      } catch (error) {
        transactionFailure = error;
        throw error;
      }
    };
    User.create = async ([data], options) => {
      assert.equal(options.session, session);
      const user = new User(data);
      await user.validate();
      await User.schema.s.hooks.execPre('save', user, []);
      saved = user;
      return [user];
    };
    Wallet.create = async ([data], options) => {
      assert.equal(options.session, session);
      assert.deepEqual(Object.keys(data), ['user']);
      assert.equal(data.user.toString(), saved.id);
      savedWallet = new Wallet(data);
      await savedWallet.validate();
      return [savedWallet];
    };
    let response = await post('/signup', { ...details, googleId: 'untrusted', wallet: { balance: 999999 }, balance: 999999 });
    assert.equal(response.status, 201);
    const body = await response.json();
    assert.equal(body.user.email, details.email);
    assert.equal(body.user.password, undefined);
    assert.equal(body.wallet.user, body.user._id);
    assert.equal(body.wallet.balance, 0);
    assert.equal(body.wallet.currency, 'INR');
    assert.equal(body.wallet.__v, undefined);
    assert.equal(saved.googleId, undefined);
    assert.notEqual(saved.password, details.password);
    assert.equal(await saved.comparePassword(details.password), true);
    assert.equal((await post('/create-user', details)).status, 201);
    assert.equal((await post('/signup', {})).status, 400);
    assert.equal((await post('/signup', { ...details, password: 'short' })).status, 400);
    const walletFailure = new Error('private wallet database error');
    Wallet.create = async () => { throw walletFailure; };
    response = await post('/signup', details);
    assert.equal(response.status, 500);
    assert.deepEqual(await response.json(), { message: 'Unable to create user' });
    assert.equal(transactionFailure, walletFailure);
    User.create = async () => { throw { code: 11000 }; };
    assert.equal((await post('/signup', details)).status, 409);
    User.create = async () => { throw new Error('private database error'); };
    response = await post('/signup', details);
    assert.equal(response.status, 500);
    assert.equal((await response.json()).message, 'Unable to create user');
  } finally {
    User.create = original;
    User.init = originalUserInit;
    Wallet.init = originalWalletInit;
    Wallet.create = originalWalletCreate;
    mongoose.connection.transaction = originalTransaction;
    await new Promise(resolve => server.close(resolve));
  }
});
