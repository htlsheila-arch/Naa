# Complexe La Casa Del Shei — Mise en production

## Structure du dépôt GitHub

Tous les fichiers sont à la racine du dépôt — aucun sous-dossier requis :

```
votre-depot/
├── server.js
├── package.json
├── schema.sql
├── .env.example
├── README.md
├── index.html            (le site web public)
├── casa-del-shei.html    (l'application du personnel)
└── table-client.html     (la page client, ouverte via le code à 4 chiffres)
```

⚠️ **Important** : `server.js` ne sert QUE ces 3 fichiers `.html` précis, chacun par une
route explicite. Il ne sert pas "tout le dossier" (pas de `express.static` sur la racine)
— sinon vos visiteurs pourraient aussi télécharger `server.js`, `.env` ou `schema.sql`,
ce qu'on ne veut surtout pas puisqu'ils sont au même endroit. Si vous ajoutez un jour
d'autres fichiers statiques (images, CSS séparé...), il faudra ajouter une route pour
chacun, ou me redemander d'adapter `server.js`.

## URLs une fois déployé

| URL | Contenu |
|---|---|
| `https://votre-app.onrender.com/` | Le site web public (`index.html`) |
| `https://votre-app.onrender.com/app` | L'application du personnel (`casa-del-shei.html`) |
| `https://votre-app.onrender.com/table` | La page client à afficher/lier sur chaque table (`table-client.html`) |

(Les noms de fichiers directs marchent aussi : `/index.html`, `/casa-del-shei.html`,
`/table-client.html`.)

## Étape 1 — Base de données Neon

Dans l'éditeur SQL de Neon, exécutez `schema.sql` (sans risque de le relancer plusieurs
fois, rien n'est dupliqué). Il crée :
- les tables `employees` et `app_state`,
- `site_reservation_requests` et `site_messages` (demandes venant du site web),
- un utilisateur par défaut pour chaque rôle (voir plus bas).

## Étape 2 — Redéployer sur Render

1. Remplacez vos fichiers sur GitHub par ceux fournis ici, tous à la racine.
2. Vérifiez que la variable d'environnement `DATABASE_URL` est bien configurée dans
   Render (Settings → Environment).
3. Render redéploie automatiquement au push, ou via **Manual Deploy → Deploy latest commit**.
4. Ouvrez `https://votre-app.onrender.com/` — le site doit maintenant s'afficher.

## Ce qui a été corrigé dans `server.js`

1. **Service des 3 pages HTML** via des routes explicites (`/`, `/app`, `/table`) — c'est
   ce qui manquait et empêchait le site de s'afficher (seule l'API répondait avant).
2. **Routes pour le site web** (`/api/public/reservation-request`, `/api/public/message`,
   et leur consultation côté application `/api/site-reservation-requests` /
   `/api/site-messages`) — sans elles, le formulaire de réservation et le bouton de
   contact du site ne pouvaient rien envoyer, et l'onglet **🌐 Site Web** de l'application
   restait vide.

## Utilisateurs par défaut (un par rôle)

| Login | Mot de passe | Rôle |
|---|---|---|
| `admin` | `admin` | Admin |
| `hotel` | `hotel` | Réceptionniste (Hôtel + Bar Piscine) |
| `bar` | `bar` | Bar & VIP |
| `barber` | `barber` | Barber |
| `market` | `market` | Market |

⚠️ Changez ces mots de passe avant une utilisation réelle avec de l'argent.

## Limites actuelles à connaître

- Mots de passe stockés en clair, pas d'authentification par jeton — adapté à un usage
  interne de confiance, à durcir avant une exposition plus large.
- Synchronisation par sondage (toutes les ~4 secondes), pas instantanée.
- `app_state` est une seule ligne JSONB — simple et efficace pour cette taille
  d'application ; si vous voulez un jour des rapports SQL détaillés, on pourra normaliser
  certaines tables séparément.
