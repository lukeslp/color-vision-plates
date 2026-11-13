// Service worker for the Color Vision Plates page (scope: this folder).
//
// The screening is fully client-side, so once the page has loaded it can run
// without a connection. This worker keeps a copy of the page's own files and
// serves it only when the network fails. The network always goes first, so a
// deploy is picked up on the next online visit and nothing is pinned.
//
// The site root has its own worker (What Color). This one names its cache
// with its own prefix and removes only caches with that prefix.
'use strict';

const CACHE_PREFIX = 'cvp-page-';
const CACHE_NAME = CACHE_PREFIX + 'v1';
const PAGE_FILES = ['./', 'color-math.js', 'icon-512.png', 'pwa.webmanifest'];

self.addEventListener('install', event => {
    event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(PAGE_FILES)));
    self.skipWaiting();
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys()
            .then(keys => Promise.all(
                keys.filter(key => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
                    .map(key => caches.delete(key))
            ))
            .then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', event => {
    const request = event.request;
    if (request.method !== 'GET') return;
    const url = new URL(request.url);
    // Only this page's own files. Analytics and other hosts are left alone.
    if (url.origin !== self.location.origin) return;

    event.respondWith(
        fetch(request)
            .then(response => {
                if (response.ok) {
                    const copy = response.clone();
                    // Store under the bare path so a launch URL with a query
                    // string and a plain visit share one entry.
                    caches.open(CACHE_NAME).then(cache => cache.put(url.origin + url.pathname, copy));
                }
                return response;
            })
            .catch(() => caches.open(CACHE_NAME).then(cache =>
                cache.match(url.origin + url.pathname).then(hit => {
                    if (hit) return hit;
                    if (request.mode === 'navigate') return cache.match('./');
                    return Response.error();
                })
            ))
    );
});
