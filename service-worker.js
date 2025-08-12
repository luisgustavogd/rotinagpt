self.addEventListener('install', e => {
  e.waitUntil(caches.open('rotina-csv-v2').then(cache => cache.addAll(['./','./index.html','./rotina.csv','./manifest.webmanifest'])));
});
self.addEventListener('fetch', e => {
  e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
});
