import { Router } from "express";
import { createGame, getGames } from "../controllers/gameController.js";

const gameRoute = Router();

gameRoute.get("/games", getGames);
gameRoute.post("/games", createGame);

export default gameRoute;
