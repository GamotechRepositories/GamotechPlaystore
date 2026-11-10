import mongoose from "mongoose";
import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";

const scrypt = promisify(scryptCallback);

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "Enter a valid email address"],
    },
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 3,
      maxlength: 30,
    },
    password: {
      type: String,
      required: function () {
        return !this.googleId;
      },
      minlength: 8,
      select: false,
    },
    // Set only from the subject (sub) of a verified Google ID token.
    googleId: {
      type: String,
      trim: true,
      minlength: 1,
      unique: true,
      sparse: true,
      select: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_document, result) {
        delete result.password;
        delete result.googleId;
        delete result.__v;
        return result;
      },
    },
  },
);

// The wallet owns the unique user reference, avoiding two stored links that can drift.
userSchema.virtual("wallet", {
  ref: "Wallet",
  localField: "_id",
  foreignField: "user",
  justOne: true,
});

// Create and change passwords with document.save() so this hook always runs.
userSchema.pre("save", async function () {
  if (!this.isModified("password") || !this.password) return;

  const salt = randomBytes(16).toString("hex");
  const hash = await scrypt(this.password, salt, 64);
  this.password = `scrypt:${salt}:${hash.toString("hex")}`;
});

// Fetch with .select("+password") before checking a local login.
userSchema.methods.comparePassword = async function (candidatePassword) {
  if (!this.password || typeof candidatePassword !== "string") return false;

  const [algorithm, salt, storedHash] = this.password.split(":");
  if (algorithm !== "scrypt" || !salt || !storedHash) return false;

  const hash = await scrypt(candidatePassword, salt, 64);
  const expectedHash = Buffer.from(storedHash, "hex");
  return expectedHash.length === hash.length && timingSafeEqual(expectedHash, hash);
};

export default mongoose.model("User", userSchema);
