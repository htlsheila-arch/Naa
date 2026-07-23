// ============================================================
// Complexe La Casa Del Shei — Backend API (Express + Neon Postgres)
// ============================================================
// Rôle de ce serveur : remplacer le localStorage du navigateur par une
// vraie base de données partagée, pour que TOUS les appareils (tablettes,
// téléphones, ordinateurs) voient et modifient les mêmes données en temps
// (quasi) réel — commandes, comptes de table, messages, réservations, etc.
//
// Démarrage local :
//   1) npm install
//   2) copier .env.example en .env et y mettre votre DATABASE_URL Neon
//   3) npm start
// ============================================================

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
const PORT = process.env.PORT || 3000;

if (!process.env.DATABASE_URL) {
    console.error("ERREUR: la variable d'environnement DATABASE_URL est manquante.");
    console.error("Copiez .env.example vers .env et renseignez votre chaîne de connexion Neon.");
    process.exit(1);
}

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // requis par Neon
});

app.use(cors()); // ⚠️ ouvert à tous les domaines par simplicité — voir README pour restreindre en prod
app.use(express.json({ limit: "5mb" }));

// ------------------------------------------------------------
// Authentification
// ------------------------------------------------------------
app.post("/api/login", async (req, res) => {
    const { username, password } = req.body || {};
    if (!username || !password) return res.status(400).json({ error: "Login et mot de passe requis" });
    try {
        const result = await pool.query(
            "SELECT id, username, nom, roles FROM employees WHERE username = $1 AND password = $2",
            [username, password]
        );
        if (result.rows.length === 0) return res.status(401).json({ error: "Identifiants incorrects" });
        res.json(result.rows[0]);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

// ------------------------------------------------------------
// Employés (gestion par l'admin)
// ------------------------------------------------------------
app.get("/api/employees", async (req, res) => {
    try {
        const result = await pool.query("SELECT id, username, password, nom, roles FROM employees ORDER BY id");
        res.json(result.rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

app.post("/api/employees", async (req, res) => {
    const { username, password, nom, roles } = req.body || {};
    if (!username || !password || !nom || !Array.isArray(roles) || roles.length === 0) {
        return res.status(400).json({ error: "Champs manquants (username, password, nom, roles)" });
    }
    try {
        const result = await pool.query(
            "INSERT INTO employees (username, password, nom, roles) VALUES ($1,$2,$3,$4) RETURNING id, username, password, nom, roles",
            [username, password, nom, roles]
        );
        res.status(201).json(result.rows[0]);
    } catch (e) {
        if (e.code === "23505") return res.status(409).json({ error: "Ce login existe déjà" });
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

app.delete("/api/employees/:id", async (req, res) => {
    try {
        await pool.query("DELETE FROM employees WHERE id = $1", [req.params.id]);
        res.status(204).end();
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

// ------------------------------------------------------------
// État applicatif (produits, chambres, commandes, messages, tarifs...)
// ------------------------------------------------------------
app.get("/api/state", async (req, res) => {
    try {
        const result = await pool.query("SELECT data FROM app_state WHERE id = 1");
        res.json(result.rows[0] ? result.rows[0].data : {});
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

app.post("/api/state", async (req, res) => {
    try {
        await pool.query(
            `INSERT INTO app_state (id, data, updated_at) VALUES (1, $1, now())
             ON CONFLICT (id) DO UPDATE SET data = $1, updated_at = now()`,
            [JSON.stringify(req.body || {})]
        );
        res.status(204).end();
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Erreur serveur" });
    }
});

app.get("/", (req, res) => {
    res.send("Complexe La Casa Del Shei — API en ligne ✅");
});

app.listen(PORT, () => {
    console.log(`API démarrée sur le port ${PORT}`);
});
