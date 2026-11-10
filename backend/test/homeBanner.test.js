import test from "node:test";
import assert from "node:assert/strict";
import express from "express";
import HomeBanner from "../models/HomeBanner.js";
import homeBannerRoute from "../routes/homeBannerRoute.js";

test("home banner HTTP contract", async (t) => {
  const app = express();
  app.use(express.json());
  app.use("/api/v1", homeBannerRoute);
  const server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));

  const originalCreate = HomeBanner.create;
  const originalFind = HomeBanner.find;
  const endpoint = `http://127.0.0.1:${server.address().port}/api/v1/home-banners`;
  const post = (body) => fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const details = { title: "Play and win", imageUrl: "https://example.com/banner.jpg" };

  try {
    let saved;
    HomeBanner.create = async (data) => {
      saved = new HomeBanner(data);
      await saved.validate();
      return saved;
    };

    await t.test("creates a banner, applies defaults, and ignores unknown fields", async () => {
      const response = await post({ ...details, title: " Play and win ", __v: 99 });
      assert.equal(response.status, 201);
      const { banner } = await response.json();
      assert.equal(banner.title, details.title);
      assert.equal(banner.imageUrl, details.imageUrl);
      assert.equal(banner.sortOrder, 0);
      assert.ok(banner._id);
      assert.equal(banner.__v, undefined);
      assert.equal(saved.__v, undefined);

      const linked = await post({ ...details, linkUrl: "https://example.com/play", sortOrder: 2 });
      assert.equal(linked.status, 201);
      const body = await linked.json();
      assert.equal(body.banner.linkUrl, "https://example.com/play");
      assert.equal(body.banner.sortOrder, 2);
    });

    await t.test("rejects missing fields, wrong types, unsafe URLs, and invalid order", async () => {
      const invalidBodies = [
        {},
        { imageUrl: details.imageUrl },
        { title: details.title },
        { ...details, title: " " },
        { ...details, title: 123 },
        { ...details, title: "a".repeat(201) },
        { ...details, imageUrl: " " },
        { ...details, imageUrl: {} },
        { ...details, imageUrl: "not-a-url" },
        { ...details, imageUrl: "javascript:alert(1)" },
        { ...details, imageUrl: "ftp://example.com/banner.jpg" },
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

    await t.test("lists banners with a stable display order and handles empty collections", async () => {
      let banners = [saved];
      HomeBanner.find = (...args) => {
        assert.equal(args.length, 0);
        return {
          sort: async (order) => {
            assert.deepEqual(order, { sortOrder: 1, createdAt: -1, _id: -1 });
            return banners;
          },
        };
      };
      let response = await fetch(endpoint);
      assert.equal(response.status, 200);
      const body = await response.json();
      assert.equal(body.banners.length, 1);
      assert.equal(body.banners[0]._id, saved.id);
      banners = [];
      response = await fetch(endpoint);
      assert.equal(response.status, 200);
      assert.deepEqual((await response.json()).banners, []);
    });

    await t.test("returns generic database errors without leaking internals", async () => {
      HomeBanner.create = async () => { throw new Error("private database details"); };
      let response = await post(details);
      assert.equal(response.status, 500);
      assert.deepEqual(await response.json(), { message: "Unable to create home banner" });

      HomeBanner.find = () => ({
        sort: async () => { throw new Error("private database details"); },
      });
      response = await fetch(endpoint);
      assert.equal(response.status, 500);
      assert.deepEqual(await response.json(), { message: "Unable to fetch home banners" });
    });
  } finally {
    HomeBanner.create = originalCreate;
    HomeBanner.find = originalFind;
    await new Promise((resolve) => server.close(resolve));
  }
});
