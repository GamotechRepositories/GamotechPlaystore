import dotenv from "dotenv";
import mongoose from "mongoose";
import { fileURLToPath } from "node:url";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import WalletRecord from "../models/WalletRecord.js";

dotenv.config({ path: fileURLToPath(new URL("../.env", import.meta.url)), quiet: true });

try {
  if (!process.env.MONGO_URI) throw new Error("MONGO_URI is required");
  await mongoose.connect(process.env.MONGO_URI, { serverSelectionTimeoutMS: 10000 });
  await Wallet.init();
  await WalletRecord.init();

  let created = 0;
  let existing = 0;
  for await (const user of User.find().select("_id").lean().cursor()) {
    const now = new Date();
    const result = await Wallet.updateOne(
      { user: user._id },
      { $setOnInsert: { user: user._id, balance: 0, currency: "INR", createdAt: now, updatedAt: now } },
      { upsert: true, runValidators: true, setDefaultsOnInsert: true, timestamps: false },
    );
    if (result.upsertedCount) {
      created++;
    } else {
      existing++;
    }
  }

  const missing = await User.aggregate([
    { $lookup: { from: Wallet.collection.name, localField: "_id", foreignField: "user", as: "wallet" } },
    { $match: { wallet: { $size: 0 } } },
    { $count: "count" },
  ]);
  if (missing.length) throw new Error("Wallet backfill verification failed");

  console.log(`Wallet backfill complete: ${created} created, ${existing} already existed; every user has a wallet.`);
} catch (error) {
  console.error(`Wallet backfill failed (${error.name}). Check MONGO_URI, database access, and indexes.`);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
