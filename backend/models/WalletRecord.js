import mongoose from "mongoose";

const moneyField = (min = 0) => ({
  type: Number,
  required: true,
  immutable: true,
  min,
  validate: {
    validator: Number.isSafeInteger,
    message: "Money values must be safe integers in paise",
  },
});

// A record describes one completed credit or debit, not a pending payment.
const walletRecordSchema = new mongoose.Schema(
  {
    wallet: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Wallet",
      required: true,
      immutable: true,
    },
    type: {
      type: String,
      required: true,
      enum: ["credit", "debit"],
      immutable: true,
    },
    amount: moneyField(1),
    balanceBefore: moneyField(),
    balanceAfter: moneyField(),
    reason: {
      type: String,
      required: true,
      enum: ["deposit", "withdrawal", "game_entry", "winnings", "refund", "bonus", "adjustment"],
      immutable: true,
    },
    reference: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      maxlength: 128,
      immutable: true,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 500,
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

walletRecordSchema.index({ wallet: 1, createdAt: -1, _id: -1 });

walletRecordSchema.pre("validate", function () {
  if (
    ![this.amount, this.balanceBefore, this.balanceAfter].every(Number.isSafeInteger) ||
    !["credit", "debit"].includes(this.type)
  ) return;

  const expected = this.balanceBefore + (this.type === "credit" ? this.amount : -this.amount);
  if (!Number.isSafeInteger(expected) || this.balanceAfter !== expected) {
    this.invalidate("balanceAfter", "Balance after must match the credit or debit amount");
  }
});

export default mongoose.model("WalletRecord", walletRecordSchema);
