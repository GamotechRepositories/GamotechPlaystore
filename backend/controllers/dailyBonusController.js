import mongoose from 'mongoose';
import Wallet from '../models/Wallet.js';
import WalletRecord from '../models/WalletRecord.js';
import { authenticateWalletUser } from './walletController.js';

export function bonusPolicy(now = new Date()) {
  // Server configuration is in paise. Claims reset at midnight in India.
  const amount = Number(process.env.DAILY_BONUS_PAISE ?? 10000);
  if (!Number.isSafeInteger(amount) || amount <= 0) throw new Error('Invalid bonus configuration');
  const shifted = new Date(now.getTime() + 330 * 60000);
  const day = shifted.toISOString().slice(0, 10);
  const nextClaimAt = new Date(Date.parse(`${day}T00:00:00+05:30`) + 86400000).toISOString();
  return { amount, day, nextClaimAt };
}

export const getDailyBonus = async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const user = authenticateWalletUser(req, res);
  if (!user) return;
  try {
    const policy = bonusPolicy();
    const wallet = await Wallet.findOne({ user });
    if (!wallet) return res.status(404).json({ message: 'No wallet is linked to your account.' });
    const claimed = await WalletRecord.exists({ reference: `daily-bonus:${wallet._id}:${policy.day}` });
    return res.json({ amount: policy.amount, claimed: Boolean(claimed), nextClaimAt: policy.nextClaimAt });
  } catch {
    return res.status(503).json({ message: 'Daily bonus is temporarily unavailable.' });
  }
};

export const claimDailyBonus = async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const user = authenticateWalletUser(req, res);
  if (!user) return;
  try {
    const policy = bonusPolicy();
    await WalletRecord.init();
    const result = await mongoose.connection.transaction(async session => {
      const wallet = await Wallet.findOne({ user }).session(session);
      if (!wallet) { const error = new Error('No wallet is linked to your account.'); error.status = 404; throw error; }
      const reference = `daily-bonus:${wallet._id}:${policy.day}`;
      if (await WalletRecord.exists({ reference }).session(session)) {
        const error = new Error('Today’s bonus has already been claimed.'); error.status = 409; throw error;
      }
      const balanceBefore = wallet.balance;
      wallet.balance += policy.amount;
      await wallet.save({ session });
      await WalletRecord.create([{
        wallet: wallet._id, type: 'credit', amount: policy.amount,
        balanceBefore, balanceAfter: wallet.balance, reason: 'bonus', reference,
        description: 'Daily login bonus',
      }], { session });
      return { balance: wallet.balance, currency: wallet.currency };
    }, { readPreference: 'primary', writeConcern: { w: 'majority' } });
    return res.json({ wallet: result, amount: policy.amount, claimed: true, nextClaimAt: policy.nextClaimAt });
  } catch (error) {
    const status = error.code === 11000 ? 409 : error.status ?? 503;
    return res.status(status).json({ message: status === 409 ? 'Today’s bonus has already been claimed.' : status === 404 ? error.message : 'Unable to claim your bonus. Please try again.' });
  }
};
