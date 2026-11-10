import { Router } from 'express';
import { getWallet } from '../controllers/walletController.js';

const router = Router();
router.get('/wallet', getWallet);

export default router;
