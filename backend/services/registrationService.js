import mongoose from "mongoose";
import User from "../models/User.js";
import Wallet from "../models/Wallet.js";

export const registerUser = async ({ email, username, password }) => {
  // Initialize collections and unique indexes before entering a transaction.
  await User.init();
  await Wallet.init();

  return mongoose.connection.transaction(async (session) => {
    const [user] = await User.create([{ email, username, password }], { session });
    const [wallet] = await Wallet.create([{ user: user._id }], { session });
    return { user, wallet };
  }, { readPreference: "primary", writeConcern: { w: "majority" } });
};
