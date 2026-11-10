import dotenv from "dotenv";
import mongoose from "mongoose";
import { fileURLToPath } from "node:url";
import HomeBanner from "../models/HomeBanner.js";

dotenv.config({
  path: fileURLToPath(new URL("../.env", import.meta.url)),
  quiet: true,
});

const banners = [
  {
    title: "Live Dealer Teen Patti Casino",
    imageUrl: "https://cdn.dmcrms.in/gamotechSolution/documents/1791529849716-Live-Dealer-Teen-Patti-Casino-1.png",
    sortOrder: 0,
  },
  {
    title: "Ludo",
    imageUrl: "https://cdn.dmcrms.in/gamotechSolution/profiles/1794217371161-ludo.png",
    sortOrder: 1,
  },
  {
    title: "Rummy",
    imageUrl: "https://cdn.dmcrms.in/gamotechSolution/profiles/1794217642820-rummy.png",
    sortOrder: 2,
  },
  {
    title: "Poker",
    imageUrl: "https://cdn.dmcrms.in/gamotechSolution/profiles/1794217689101-poker.png",
    sortOrder: 3,
  },
];

try {
  if (!process.env.MONGO_URI) {
    throw new Error("MONGO_URI is required in the backend environment");
  }

  // Validate the whole seed before making any database changes.
  await Promise.all(banners.map((banner) => new HomeBanner(banner).validate()));
  await mongoose.connect(process.env.MONGO_URI, { serverSelectionTimeoutMS: 10000 });

  let inserted = 0;
  for (const banner of banners) {
    const result = await HomeBanner.updateOne(
      { imageUrl: banner.imageUrl },
      { $setOnInsert: banner },
      { upsert: true, runValidators: true, setDefaultsOnInsert: true },
    );
    inserted += result.upsertedCount;
  }

  const saved = await HomeBanner.find({
    imageUrl: { $in: banners.map(({ imageUrl }) => imageUrl) },
  }).sort({ sortOrder: 1, createdAt: -1, _id: -1 });

  if (new Set(saved.map(({ imageUrl }) => imageUrl)).size !== banners.length) {
    throw new Error("Seed verification failed");
  }

  console.log(`Home banner seed complete: ${inserted} inserted, ${banners.length - inserted} already existed.`);
  for (const banner of saved) {
    console.log(`${banner.sortOrder}: ${banner.title}`);
  }
} catch (error) {
  // Avoid printing database connection details or credentials from driver errors.
  console.error(`Home banner seed failed (${error.name}). Check MONGO_URI and database connectivity.`);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
