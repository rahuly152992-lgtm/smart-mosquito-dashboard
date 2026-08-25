const CACHE_NAME = "mosquito-guard-shell-v1";
const APP_SHELL = [
  "/",
  "/static/css/style.css",
  "/static/css/mobile_frame.css",
  "/static/js/api.js",
  "/static/js/app.js",
  "/static/js/charts.js",
  "/static/js/audio.js",
  "/static/images/logo.svg"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  event.respondWith(fetch(event.request).catch(() => caches.match(event.request)));
});