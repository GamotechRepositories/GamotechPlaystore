import mongoose from "mongoose";

const isHttpUrl = (value) => {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
};

const gameSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: "",
    },
    imageUrl: {
      type: String,
      required: true,
      trim: true,
      validate: { validator: isHttpUrl, message: "imageUrl must be an HTTP(S) URL" },
    },
    linkUrl: {
      type: String,
      trim: true,
      validate: { validator: isHttpUrl, message: "linkUrl must be an HTTP(S) URL" },
    },
    sortOrder: {
      type: Number,
      default: 0,
      min: 0,
      validate: {
        validator: Number.isSafeInteger,
        message: "sortOrder must be a nonnegative safe integer",
      },
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

gameSchema.index({ sortOrder: 1, createdAt: -1, _id: -1 });

export default mongoose.model("Game", gameSchema);
