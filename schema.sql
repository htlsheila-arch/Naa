-- ============================================================
-- Complexe La Casa Del Shei — Schéma Postgres pour Neon
-- ============================================================
-- À exécuter une seule fois dans l'éditeur SQL de Neon
-- (console.neon.tech -> votre projet -> SQL Editor -> coller ce fichier -> Run)
-- ou via psql :  psql "$DATABASE_URL" -f schema.sql
-- ============================================================

-- ------------------------------------------------------------
-- Table des employés (comptes de connexion)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employees (
    id BIGSERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    nom TEXT NOT NULL,
    roles TEXT[] NOT NULL DEFAULT '{}'
);

-- ------------------------------------------------------------
-- Table unique contenant tout le reste de l'état de l'application
-- (produits, chambres, réservations, commandes, messages, tarifs...)
-- Une seule ligne (id = 1), mise à jour à chaque sauvegarde.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_state (
    id INT PRIMARY KEY DEFAULT 1,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT app_state_single_row CHECK (id = 1)
);

-- ------------------------------------------------------------
-- Demandes venant du site web public (formulaire de réservation
-- et messages de contact) — tables séparées de app_state pour que
-- le site public n'ait jamais accès en écriture aux données internes.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS site_reservation_requests (
    id BIGSERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    type_reservation TEXT,
    date_arrivee DATE,
    date_depart DATE,
    message TEXT,
    statut TEXT NOT NULL DEFAULT 'nouvelle',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS site_messages (
    id BIGSERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    contact TEXT,
    message TEXT NOT NULL,
    lu BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- Seed : un utilisateur par défaut pour CHAQUE rôle
-- (login = mot de passe pour démarrer — à changer une fois en production)
-- ------------------------------------------------------------
INSERT INTO employees (username, password, nom, roles) VALUES
    ('admin',  'admin',  'Super Admin',                 ARRAY['admin']),
    ('hotel',  'hotel',  'Réceptionniste',               ARRAY['hotel']),
    ('bar',    'bar',    'Barman Bar & VIP',             ARRAY['bar']),
    ('barber', 'barber', 'Coiffeur',                     ARRAY['barber']),
    ('market', 'market', 'Caissier Market',               ARRAY['market'])
ON CONFLICT (username) DO NOTHING;

-- ------------------------------------------------------------
-- Seed : état initial de l'application (produits, chambres, tarifs par défaut)
-- ------------------------------------------------------------
INSERT INTO app_state (id, data)
VALUES (1, $$
{
  "servicesBarber": [
    { "id": 1, "nom": "Coupe homme", "prix": 20 },
    { "id": 2, "nom": "Barbe + coupe", "prix": 35 },
    { "id": 3, "nom": "Cheveux ordinaire", "prix": 15 },
    { "id": 4, "nom": "Modèle", "prix": 45 }
  ],
  "coiffeurs": [
    { "id": 1, "nom": "Jean", "numChaise": 1 },
    { "id": 2, "nom": "Marc", "numChaise": 2 }
  ],
  "ventesBarber": [],
  "produitsBar": [
    { "id": 1, "nom": "Bière 33cl", "prix": 4,  "zone": "bar", "stock": 100 },
    { "id": 2, "nom": "Soft",       "prix": 3,  "zone": "bar", "stock": 100 },
    { "id": 3, "nom": "Cocktail",   "prix": 8,  "zone": "bar", "stock": 60 },
    { "id": 4, "nom": "Champagne",  "prix": 45, "zone": "vip", "stock": 15 },
    { "id": 5, "nom": "Whisky",     "prix": 30, "zone": "vip", "stock": 20 }
  ],
  "ventesBar": [],
  "articlesMarket": [
    { "id": 1, "nom": "Eau 1.5L", "prix": 1.5, "stock": 20, "codeBarre": "123456" },
    { "id": 2, "nom": "Chips",    "prix": 2.5, "stock": 15, "codeBarre": "123457" },
    { "id": 3, "nom": "Snickers", "prix": 1,   "stock": 30, "codeBarre": "123458" },
    { "id": 4, "nom": "Lait",     "prix": 1.2, "stock": 10, "codeBarre": "123459" }
  ],
  "ventesMarket": [],
  "chambres": [
    { "id": 1, "numero": "101", "type": "Standard",   "prixMoment": 15, "prixParNuit": 50,  "prixSemaine": 300, "prixMois": 1200, "statut": "libre", "checkOut": null },
    { "id": 2, "numero": "102", "type": "Standard",   "prixMoment": 15, "prixParNuit": 50,  "prixSemaine": 300, "prixMois": 1200, "statut": "libre", "checkOut": null },
    { "id": 3, "numero": "201", "type": "Supérieure", "prixMoment": 22, "prixParNuit": 80,  "prixSemaine": 480, "prixMois": 1900, "statut": "libre", "checkOut": null },
    { "id": 4, "numero": "202", "type": "VIP Suite",  "prixMoment": 40, "prixParNuit": 150, "prixSemaine": 900, "prixMois": 3600, "statut": "libre", "checkOut": null }
  ],
  "reservationsHotel": [],
  "servicesHotel": [
    { "id": 1, "nom": "Petit-déjeuner", "prix": 12, "type": "moment" },
    { "id": 2, "nom": "Dîner",          "prix": 25, "type": "soiree" },
    { "id": 3, "nom": "Spa (1h)",       "prix": 40, "type": "moment" }
  ],
  "reservationServices": [],
  "comptesTables": [],
  "commandes": [],
  "tauxChange": 130,
  "ventesPiscineSessions": [],
  "prixSeancePiscine": 5,
  "seuilGratuitGroupe": 12,
  "rabaisGroupePourcent": 0,
  "messages": []
}
$$::jsonb)
ON CONFLICT (id) DO NOTHING;
