import adminRoute from "./routes/adminRoute.js";
import walletRoute from './routes/walletRoute.js';
import express from "express";
import dotenv from "dotenv";
import connect from "./config/db.js";
import userRoute from "./routes/userRoute.js";
import homeBannerRoute from "./routes/homeBannerRoute.js";
import gameRoute from "./routes/gameRoute.js";
import corsMiddleware from "./config/cors.js";

dotenv.config();

const app = express();

app.use(corsMiddleware);
app.use(express.json());
app.use("/api/v1/admin", adminRoute);
app.use("/api/v1", userRoute);
app.use("/api/v1", walletRoute);
app.use("/api/v1", homeBannerRoute);
app.use("/api/v1", gameRoute);

app.get("/", (req, res) => {
  res.send("Hello from backend!");
});
app.get('/health', (req, res)=>{
    res.status(200).json({message: 'Server is healthy'});
})
connect();

const PORT = process.env.PORT;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
