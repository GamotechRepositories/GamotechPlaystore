import { Router } from "express";
import { createHomeBanner, getHomeBanners } from "../controllers/homeBannerController.js";

const homeBannerRoute = Router();

homeBannerRoute.get("/home-banners", getHomeBanners);
homeBannerRoute.post("/home-banners", createHomeBanner);

export default homeBannerRoute;
