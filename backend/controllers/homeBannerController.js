import HomeBanner from "../models/HomeBanner.js";

export const createHomeBanner = async (req, res) => {
  const { title, imageUrl, linkUrl, sortOrder } = req.body ?? {};

  if (
    typeof title !== "string" || !title.trim() ||
    typeof imageUrl !== "string" || !imageUrl.trim()
  ) {
    return res.status(400).json({
      message: "Title and imageUrl are required nonblank strings",
    });
  }

  if (linkUrl !== undefined && (typeof linkUrl !== "string" || !linkUrl.trim())) {
    return res.status(400).json({ message: "linkUrl must be a nonblank HTTP(S) URL string" });
  }

  if (sortOrder !== undefined && (!Number.isSafeInteger(sortOrder) || sortOrder < 0)) {
    return res.status(400).json({ message: "sortOrder must be a nonnegative safe integer" });
  }

  try {
    const banner = await HomeBanner.create({ title, imageUrl, linkUrl, sortOrder });
    return res.status(201).json({
      message: "Home banner created successfully",
      banner: banner.toJSON(),
    });
  } catch (error) {
    if (error.name === "ValidationError") {
      return res.status(400).json({
        message: "Invalid home banner details",
        errors: Object.values(error.errors).map(({ message }) => message),
      });
    }
    return res.status(500).json({ message: "Unable to create home banner" });
  }
};

export const getHomeBanners = async (_req, res) => {
  try {
    const banners = await HomeBanner.find().sort({ sortOrder: 1, createdAt: -1, _id: -1 });
    return res.status(200).json({
      message: "Home banners fetched successfully",
      banners,
    });
  } catch {
    return res.status(500).json({ message: "Unable to fetch home banners" });
  }
};
