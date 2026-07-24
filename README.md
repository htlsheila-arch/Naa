# Complexe La Casa Del Shei — Mise en production

Ce dossier contient tout ce qu'il faut pour faire fonctionner l'application
avec une **vraie base de données partagée** (Neon Postgres), afin que toutes
les tablettes/téléphones/ordinateurs voient et modifient les mêmes données
en direct (commandes, comptes de table, messages, réservations...).

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `schema.sql` | Script à exécuter une fois dans Neon : crée les tables et insère un utilisateur par défaut pour chaque rôle |
| `server.js` | Le backend (API) qui relie l'application à la base de données |
| `package.json` | Liste des dépendances du backend |
| `.env.example` | Modèle du fichier de configuration (chaîne de connexion Neon) |
| `casa-del-shei.html` | L'application (interface) — à ouvrir dans le navigateur ou à héberger |
| `index.html` | Le site web public de l'hôtel — connecté au même backend |
| `README.md` | Ce guide |

## Étape 1 — Créer la base de données sur Neon

1. Créez un compte sur [neon.tech](https://neon.tech) (gratuit pour démarrer).
2. Créez un nouveau projet (choisissez une région proche de vous, ex. `us-east` ou `eu-central`).
3. Dans le tableau de bord du projet, ouvrez l'onglet **SQL Editor**.
4. Collez tout le contenu de `schema.sql` et cliquez sur **Run**.
   - Cela crée les tables `employees` et `app_state`.
   - Cela insère automatiquement **un utilisateur par défaut pour chaque rôle** (voir plus bas).
5. Dans **Connection Details**, copiez la chaîne de connexion (elle ressemble à
   `postgresql://user:password@ep-xxxx.neon.tech/dbname?sslmode=require`).

## Étape 2 — Déployer le backend (server.js)

Vous avez besoin d'un service qui garde `server.js` en marche 24h/24. Options
gratuites/simples : **Render**, **Railway**, ou **Fly.io**. Exemple avec Render :

1. Mettez ce dossier (`schema.sql`, `server.js`, `package.json`, `.env.example`) dans un dépôt GitHub.
2. Sur [render.com](https://render.com) : **New +** → **Web Service** → connectez le dépôt.
3. Render détecte Node.js automatiquement :
   - Build Command : `npm install`
   - Start Command : `npm start`
4. Dans **Environment**, ajoutez la variable `DATABASE_URL` avec la chaîne copiée à l'étape 1.
5. Déployez. Render vous donne une URL du type `https://casa-del-shei-backend.onrender.com`.
6. Vérifiez que ça marche en ouvrant cette URL dans un navigateur : vous devez voir
   `Complexe La Casa Del Shei — API en ligne ✅`.

*(Test en local avant déploiement : `npm install` puis `npm start`, avec un fichier `.env`
rempli à partir de `.env.example`.)*

## Étape 3 — Connecter l'application à votre backend

Ouvrez `casa-del-shei.html` dans un éditeur de texte, tout en haut du `<script>` :

```js
const API_BASE = "http://localhost:3000";
```

Remplacez par l'URL de votre backend déployé à l'étape 2, par exemple :

```js
const API_BASE = "https://casa-del-shei-backend.onrender.com";
```

Enregistrez le fichier. **Faites la même chose tout en haut du `<script>` de `index.html`**
(le site web public) — les deux fichiers pointent vers le même backend.

## Étape 3bis — Le site web public (index.html)

`index.html` est le site vitrine de l'hôtel. Il envoie deux choses vers l'application :
- Le formulaire **"Réserver votre séjour"** → apparaît dans l'onglet **🌐 Site Web** de
  l'application (visible par l'Admin et la Réception), avec le nom, le type de séjour,
  les dates et le message du client.
- Le bouton flottant **"Une question ?"** en bas à droite → envoie un message de contact
  qui apparaît lui aussi dans ce même onglet **🌐 Site Web**.

La réception voit ces demandes arriver, peut les marquer comme traitées, puis crée la
réservation réelle (avec attribution de chambre) dans l'onglet **🏨 Réservations Hôtel**
une fois le client confirmé par téléphone/email.

## Étape 4 — Héberger/distribuer l'application

Plusieurs options, du plus simple au plus robuste :
- **Le plus simple** : partagez `casa-del-shei.html` directement sur chaque tablette/téléphone
  (par email, clé USB, Google Drive) — chaque appareil l'ouvre dans son navigateur.
- **Plus pratique** : hébergez le fichier sur un service gratuit comme **Netlify**, **Vercel**
  ou **GitHub Pages** (glisser-déposer le fichier suffit sur Netlify), puis partagez le lien
  à toute l'équipe — plus besoin de redistribuer le fichier à chaque mise à jour.

## Utilisateurs par défaut (un par rôle)

Ces comptes sont créés automatiquement par `schema.sql` :

| Login | Mot de passe | Rôle |
|---|---|---|
| `admin` | `admin` | Admin |
| `hotel` | `hotel` | Réceptionniste (Hôtel + Bar Piscine) |
| `bar` | `bar` | Bar & VIP |
| `barber` | `barber` | Barber |
| `market` | `market` | Market |

⚠️ **Changez ces mots de passe** (via l'onglet Employés en tant qu'admin, ou directement
en SQL) avant une utilisation réelle avec de l'argent — ce sont des mots de passe de démarrage,
pas des mots de passe sécurisés.

## Ce qui change concrètement par rapport à la version précédente

- Avant : chaque appareil gardait ses données dans son propre navigateur (`localStorage`) —
  un message ou une commande créée sur une tablette n'apparaissait jamais sur une autre.
- Maintenant : toutes les données vivent dans Neon Postgres. Chaque appareil interroge le
  serveur toutes les 4 secondes environ, donc une commande passée sur la tablette de la
  table 5 apparaît en quelques secondes sur le téléphone du barman, où qu'il soit.

## Limites actuelles à connaître (honnêteté avant tout)

- **Sécurité simplifiée** : les mots de passe sont stockés en clair dans la base de données
  et l'API n'exige pas de jeton de connexion — adapté à un usage interne de confiance, mais
  à durcir (hachage des mots de passe, authentification par jeton, HTTPS obligatoire, limiter
  les origines CORS) avant une exposition plus large ou des enjeux financiers importants.
- **Synchronisation par sondage (polling)**, pas en temps réel instantané : un délai de
  quelques secondes est normal, ce n'est pas un bug.
- **Une seule ligne `app_state`** : simple et efficace pour la taille de cette application,
  mais si vous voulez un jour des rapports SQL détaillés (ex. "total des ventes bar par mois"
  directement en requête SQL), il faudra normaliser certaines tables (commandes, ventes...)
  séparément — dites-le si vous voulez qu'on fasse cette évolution.
