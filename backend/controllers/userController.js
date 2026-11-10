import User from "../models/User.js";
import Wallet from "../models/Wallet.js";
import jwt from "jsonwebtoken";
import { registerUser } from "../services/registrationService.js";

export const signUp = async (req, res) => {
  const { email, username, password } = req.body ?? {};

  if (
    typeof email !== "string" ||
    typeof username !== "string" ||
    typeof password !== "string" ||
    !email.trim() ||
    !username.trim() ||
    !password
  ) {
    return res.status(400).json({
      message: "Email, username, and password are required strings",
    });
  }

  try {
    // Only accept local registration fields; Google identity must be verified separately.
    const { user, wallet } = await registerUser({ email, username, password });

    return res.status(201).json({
      message: "User created successfully",
      user: user.toJSON(),
      wallet: wallet.toJSON(),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ message: "Email or username already exists" });
    }

    if (error.name === "ValidationError") {
      return res.status(400).json({
        message: "Invalid user details",
        errors: Object.values(error.errors).map(({ message }) => message),
      });
    }

    return res.status(500).json({ message: "Unable to create user" });
  }
};

// Keep the existing creation endpoint compatible with current callers.
export const createUser = signUp;

export const signIn = async (req, res) => {
  const { email, password } = req.body ?? {};
  if (typeof email !== "string" || !email.trim() ||
      typeof password !== "string" || !password) {
    return res.status(400).json({ message: "Email and password are required strings" });
  }

  if (!process.env.JWT_SECRET) {
    return res.status(503).json({ message: "Sign-in is temporarily unavailable" });
  }

  try {
    const user = await User.findOne({ email: email.trim().toLowerCase() }).select("+password");
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const wallet = await Wallet.findOne({ user: user._id });

    const token = jwt.sign({}, process.env.JWT_SECRET, {
      subject: user._id.toString(),
      algorithm: "HS256",
      expiresIn: "1h",
      issuer: "gamotech",
      audience: "gamotech-app",
    });
    res.set("Cache-Control", "no-store");
    return res.status(200).json({
      message: "Signed in successfully",
      token,
      wallet: wallet ? { balance: wallet.balance, currency: wallet.currency } : null,
      user: user.toJSON(),
    });
  } catch (_) {
    return res.status(500).json({ message: "Unable to sign in. Please try again" });
  }
};
