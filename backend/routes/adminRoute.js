import { Router } from 'express';
import { timingSafeEqual } from 'node:crypto';
import User from '../models/User.js';
import Game from '../models/Game.js';
import WalletRecord from '../models/WalletRecord.js';

const router = Router();
router.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  const key = process.env.ADMIN_API_KEY;
  if (!key) return res.status(503).json({ message: 'Configure ADMIN_API_KEY on the backend to enable admin access.' });
  const supplied = Buffer.from(req.get('Authorization')?.replace(/^Bearer /, '') ?? '');
  const expected = Buffer.from(key);
  if (supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) {
    return res.status(401).json({ message: 'Invalid admin key. Reconnect with your admin key.' });
  }
  next();
});
router.get('/overview', async (_req, res) => {
  try {
    const [users, games, transactions] = await Promise.all([
      User.countDocuments(), Game.countDocuments(), WalletRecord.countDocuments(),
    ]);
    res.json({ users, games, transactions });
  } catch { res.status(500).json({ message: 'Unable to load dashboard.' }); }
});
for (const [path, Model, fields] of [
  ['users', User, '_id username email createdAt'],
  ['transactions', WalletRecord, '_id wallet type amount balanceAfter reason reference createdAt'],
]) {
  router.get(`/${path}`, async (req, res) => {
    const value = req.query.page ?? '1';
    if (typeof value !== 'string' || !/^[1-9]\d{0,5}$/.test(value)) return res.status(400).json({ message: 'Invalid page.' });
    const page = Number(value);
    try {
      let query = Model.find().select(fields).sort({ createdAt: -1, _id: -1 }).skip((page - 1) * 20).limit(20);
      if (path === 'transactions') query = query.populate({ path: 'wallet', select: 'user currency', populate: { path: 'user', select: 'username email' } });
      const [items, total] = await Promise.all([query, Model.countDocuments()]);
      res.json({ [path]: items, total, page, hasMore: page * 20 < total });
    } catch { res.status(500).json({ message: `Unable to load ${path}.` }); }
  });
}
export default router;
