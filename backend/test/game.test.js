import test from "node:test";
import assert from "node:assert/strict";
import express from "express";
import Game from "../models/Game.js";
import gameRoute from "../routes/gameRoute.js";

test("game HTTP contract", async (t) => {
  const app = express();
  app.use(express.json());
  app.use("/api/v1", gameRoute);
  const server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));

  const originalCreate = Game.create;
  const originalFind = Game.find;
  const endpoint = `http://127.0.0.1:${server.address().port}/api/v1/games`;
  const post = (body) => fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const details = { name: "Play and win", imageUrl: "https://example.com/game.jpg" };

  try {
    let saved;
    Game.create = async (data) => {
      saved = new Game(data);
      await saved.validate();
      return saved;
    };

    await t.test("creates a game, applies defaults, and ignores unknown fields", async () => {
      const response = await post({ ...details, name: " Play and win ", __v: 99 });
      assert.equal(response.status, 201);
      const { game } = await response.json();
      assert.equal(game.name, details.name);
      assert.equal(game.imageUrl, details.imageUrl);
      assert.equal(game.sortOrder, 0);
      assert.ok(game._id);
      assert.equal(game.__v, undefined);
      assert.equal(saved.__v, undefined);

      const linked = await post({ ...details, linkUrl: "https://example.com/play", sortOrder: 2 });
      assert.equal(linked.status, 201);
      const body = await linked.json();
      assert.equal(body.game.linkUrl, "https://example.com/play");
      assert.equal(body.game.sortOrder, 2);
    });

    await t.test("rejects missing fields, wrong types, unsafe URLs, and invalid order", async () => {
      const invalidBodies = [
        { ...details, description: 42 },
        { ...details, description: "a".repeat(2001) },
        {},
        { imageUrl: details.imageUrl },
        { name: details.name },
        { ...details, name: " " },
        { ...details, name: 123 },
        { ...details, name: "a".repeat(201) },
        { ...details, imageUrl: " " },
        { ...details, imageUrl: {} },
        { ...details, imageUrl: "not-a-url" },
        { ...details, imageUrl: "javascript:alert(1)" },
        { ...details, imageUrl: "ftp://example.com/game.jpg" },
        { ...details, linkUrl: "not-a-url" },
        { ...details, linkUrl: "data:text/html,hello" },
        { ...details, linkUrl: "" },
        { ...details, linkUrl: null },
        { ...details, linkUrl: 42 },
        { ...details, sortOrder: -1 },
        { ...details, sortOrder: 0.5 },
        { ...details, sortOrder: "1" },
        { ...details, sortOrder: null },
        { ...details, sortOrder: Number.MAX_SAFE_INTEGER + 1 },
      ];
      for (const body of invalidBodies) {
        const response = await post(body);
        assert.equal(response.status, 400, JSON.stringify(body));
        assert.ok((await response.json()).message);
      }
    });

    await t.test("lists games with a stable display order and handles empty collections", async () => {
      let games = [saved];
      Game.find = (...args) => {
        assert.equal(args.length, 0);
        return {
          sort: async (order) => {
            assert.deepEqual(order, { sortOrder: 1, createdAt: -1, _id: -1 });
            return games;
          },
        };
      };
      let response = await fetch(endpoint);
      assert.equal(response.status, 200);
      const body = await response.json();
      assert.equal(body.games.length, 1);
      assert.equal(body.games[0]._id, saved.id);
      games = [];
      response = await fetch(endpoint);
      assert.equal(response.status, 200);
      assert.deepEqual((await response.json()).games, []);
    });

    await t.test("returns generic database errors without leaking internals", async () => {
      Game.create = async () => { throw new Error("private database details"); };
      let response = await post(details);
      assert.equal(response.status, 500);
      assert.deepEqual(await response.json(), { message: "Unable to create game" });

      Game.find = () => ({
        sort: async () => { throw new Error("private database details"); },
      });
      response = await fetch(endpoint);
      assert.equal(response.status, 500);
      assert.deepEqual(await response.json(), { message: "Unable to fetch games" });
    });
  } finally {
    Game.create = originalCreate;
    Game.find = originalFind;
    await new Promise((resolve) => server.close(resolve));
  }
});
