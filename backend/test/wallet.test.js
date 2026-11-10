import test from "node:test";
import assert from "node:assert/strict";
import mongoose from "mongoose";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import WalletRecord from "../models/WalletRecord.js";

test("wallet defaults to zero INR, links to a user, and configures unique ownership", async () => {
  const userId = new mongoose.Types.ObjectId();
  const wallet = new Wallet({ user: userId });
  await wallet.validate();
  assert.equal(wallet.balance, 0);
  assert.equal(wallet.currency, "INR");
  assert.equal(wallet.user.toString(), userId.toString());
  assert.equal(Wallet.schema.path("user").options.ref, "User");
  assert.ok(Wallet.schema.indexes().some(([fields, options]) => fields.user === 1 && options.unique));
  const relation = User.schema.virtuals.wallet.options;
  assert.equal(relation.ref, "Wallet");
  assert.equal(relation.foreignField, "user");
  assert.equal(relation.justOne, true);
  wallet.__v = 1;
  assert.equal(wallet.toJSON().__v, undefined);
});

test("wallet rejects missing owners, negative, fractional and unsafe balances", async () => {
  await assert.rejects(new Wallet().validate(), { name: "ValidationError" });
  for (const balance of [-1, 0.1, null, Infinity, Number.MAX_SAFE_INTEGER + 1]) {
    await assert.rejects(
      new Wallet({ user: new mongoose.Types.ObjectId(), balance }).validate(),
      { name: "ValidationError" },
    );
  }
  await assert.rejects(
    new Wallet({ user: new mongoose.Types.ObjectId(), currency: "USD" }).validate(),
    { name: "ValidationError" },
  );
});

const record = () => ({
  wallet: new mongoose.Types.ObjectId(),
  type: "credit",
  amount: 2500,
  balanceBefore: 1000,
  balanceAfter: 3500,
  reason: "deposit",
  reference: "deposit:test-payment-1",
});

test("separate wallet records validate credits, debits, and history lookup indexes", async () => {
  await new WalletRecord(record()).validate();
  const debit = new WalletRecord({ ...record(), type: "debit", amount: 500, balanceAfter: 500, reason: "game_entry" });
  await debit.validate();
  assert.equal(WalletRecord.schema.path("wallet").options.ref, "Wallet");
  assert.ok(WalletRecord.schema.indexes().some(([fields, options]) => fields.reference === 1 && options.unique));
  assert.ok(WalletRecord.schema.indexes().some(([fields]) => fields.wallet === 1 && fields.createdAt === -1));
  debit.__v = 1;
  assert.equal(debit.toJSON().__v, undefined);
});

test("records reject inconsistent movements, overdrafts, invalid amounts, and missing references", async () => {
  const invalid = [
    { amount: 0 },
    { amount: -1 },
    { amount: 0.25 },
    { amount: Number.MAX_SAFE_INTEGER + 1 },
    { balanceBefore: -1 },
    { balanceAfter: -1 },
    { balanceAfter: 1000 },
    { type: "debit", amount: 2500, balanceAfter: 0 },
    { amount: 1, balanceBefore: Number.MAX_SAFE_INTEGER, balanceAfter: Number.MAX_SAFE_INTEGER },
    { reference: " " },
    { reference: undefined },
    { wallet: undefined },
    { type: "transfer" },
    { reason: "unknown" },
  ];
  for (const fields of invalid) {
    await assert.rejects(new WalletRecord({ ...record(), ...fields }).validate(), { name: "ValidationError" });
  }
});
