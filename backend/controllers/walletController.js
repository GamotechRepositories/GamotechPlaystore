import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import Wallet from '../models/Wallet.js';
import WalletRecord from '../models/WalletRecord.js';

export const getWallet = async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const subject = authenticateWalletUser(req, res);
  if (!subject) return;
  const page = req.query.page ?? '1';
  if (typeof page !== 'string' || !/^[1-9]\d{0,5}$/.test(page)) {
    return res.status(400).json({ message: 'Invalid history page' });
  }
  try {
    // Ownership always comes from the verified token, never a caller-supplied user ID.
    const wallet = await Wallet.findOne({ user: subject });
    if (!wallet) return res.status(404).json({ message: 'No wallet is linked to your account.' });
    const records = await WalletRecord.find({ wallet: wallet._id })
      .sort({ createdAt: -1, _id: -1 }).skip((Number(page) - 1) * 20).limit(21);
    return res.json({
      wallet: { balance: wallet.balance, currency: wallet.currency },
      records: records.slice(0, 20), page: Number(page), hasMore: records.length > 20,
    });
  } catch {
    return res.status(500).json({ message: 'Unable to load your wallet. Please try again.' });
  }
};

export const authenticateWalletUser = (req, res) => {
  if (!process.env.JWT_SECRET) { res.status(503).json({ message: 'Wallet is temporarily unavailable' }); return null; }
  let subject;
  try {
    const match = /^Bearer (\S+)$/.exec(req.get('Authorization') ?? '');
    if (!match) throw new Error('Missing token');
    const payload = jwt.verify(match[1], process.env.JWT_SECRET, {
      algorithms: ['HS256'], issuer: 'gamotech', audience: 'gamotech-app',
    });
    subject = payload.sub;
    if (typeof subject !== 'string' || !mongoose.isObjectIdOrHexString(subject)) throw new Error('Invalid user');
  } catch {
    res.status(401).json({ message: 'Your session has expired. Please sign in again.' });
    return null;
  }
  return subject;
};
