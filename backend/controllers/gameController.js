import Game from "../models/Game.js";

export const createGame = async (req, res) => {
  const { name, imageUrl, description, linkUrl, sortOrder } = req.body ?? {};

  if (
    typeof name !== "string" || !name.trim() ||
    typeof imageUrl !== "string" || !imageUrl.trim()
  ) {
    return res.status(400).json({
      message: "Name and imageUrl are required nonblank strings",
    });
  }

  if (description !== undefined && typeof description !== "string") {
    return res.status(400).json({ message: "description must be a string" });
  }

  if (linkUrl !== undefined && (typeof linkUrl !== "string" || !linkUrl.trim())) {
    return res.status(400).json({ message: "linkUrl must be a nonblank HTTP(S) URL string" });
  }

  if (sortOrder !== undefined && (!Number.isSafeInteger(sortOrder) || sortOrder < 0)) {
    return res.status(400).json({ message: "sortOrder must be a nonnegative safe integer" });
  }

  try {
    const game = await Game.create({ name, imageUrl, description, linkUrl, sortOrder });
    return res.status(201).json({
      message: "Game created successfully",
      game: game.toJSON(),
    });
  } catch (error) {
    if (error.name === "ValidationError") {
      return res.status(400).json({
        message: "Invalid game details",
        errors: Object.values(error.errors).map(({ message }) => message),
      });
    }
    return res.status(500).json({ message: "Unable to create game" });
  }
};

export const getGames = async (_req, res) => {
  try {
    const games = await Game.find().sort({ sortOrder: 1, createdAt: -1, _id: -1 });
    return res.status(200).json({
      message: "Games fetched successfully",
      games,
    });
  } catch {
    return res.status(500).json({ message: "Unable to fetch games" });
  }
};
