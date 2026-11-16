import { defineConfig } from "vite";

export default defineConfig({
  root: "www",
  base: "./",
  build: {
    outDir: "../dist",
    emptyOutDir: true,
    target: "es2020",
    assetsInlineLimit: 0,
  },
  worker: { format: "es" },
});
