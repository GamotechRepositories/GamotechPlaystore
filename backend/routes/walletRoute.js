import { Router } from 'express';
import { getWallet } from '../controllers/walletController.js';

import { getDailyBonus, claimDailyBonus } from '../controllers/dailyBonusController.js';

const router = Router();
router.get('/wallet/daily-bonus', getDailyBonus);
router.post('/wallet/daily-bonus/claim', claimDailyBonus);
router.get('/wallet', getWallet);

export default router;
