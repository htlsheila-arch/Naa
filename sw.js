// Service worker minimal — sert surtout à rendre la page "installable" sur
// tablette/téléphone (condition technique exigée par les navigateurs).
// La page a de toute façon besoin du réseau pour fonctionner (commandes en
// direct), donc on ne met pas en cache les données, seulement la coquille
// de la page pour un chargement plus rapide au prochain lancement.

const CACHE_NAME = "casa-del-shei-table-v1";
const APP_SHELL = ["/table"];

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).catch(() => {})
    );
    self.skipWaiting();
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches.keys().then((keys) =>
            Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
        )
    );
    self.clients.claim();
});

// Réseau en priorité (les commandes/soldes doivent toujours être à jour) ;
// on ne retombe sur le cache que si le réseau est indisponible.
self.addEventListener("fetch", (event) => {
    if (event.request.method !== "GET") return;
    event.respondWith(
        fetch(event.request).catch(() => caches.match(event.request))
    );
});
