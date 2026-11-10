import cors from "cors";

export default cors({
  origin(origin, callback) {
    // Native apps do not send Origin; browsers must match an allowed origin.
    if (!origin) return callback(null, true);

    const allowedOrigins = (process.env.CORS_ORIGINS ?? "")
      .split(",")
      .map(value => value.trim())
      .filter(Boolean);
    let localDevelopmentOrigin = false;
    try {
      const url = new URL(origin);
      localDevelopmentOrigin = process.env.NODE_ENV !== "production" &&
        ["http:", "https:"].includes(url.protocol) &&
        ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname);
    } catch (_) {
      // Invalid origins are not permitted.
    }

    callback(null, localDevelopmentOrigin || allowedOrigins.includes(origin));
  },
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
});
