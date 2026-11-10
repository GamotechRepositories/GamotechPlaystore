import { Router } from "express";
import { createUser, signUp, signIn } from "../controllers/userController.js";

const userRoute = Router();

userRoute.post("/create-user", createUser);
userRoute.post("/signup", signUp);
userRoute.post("/signin", signIn);

export default userRoute;
