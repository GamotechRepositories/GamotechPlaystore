import mongoose from "mongoose";

const walletSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      immutable: true,
    },
    // All money values are integer paise: 100 paise = INR 1.
    balance: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
      validate: {
        validator: Number.isSafeInteger,
        message: "Balance must be a nonnegative safe integer in paise",
      },
    },
    currency: {
      type: String,
      required: true,
      enum: ["INR"],
      default: "INR",
      immutable: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_document, result) {
        delete result.__v;
        return result;
      },
    },
  },
);

export default mongoose.model("Wallet", walletSchema);
