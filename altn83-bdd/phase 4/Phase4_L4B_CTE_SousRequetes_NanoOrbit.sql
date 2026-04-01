-- ============================================================
-- PROJET NANOORBIT — PHASE 4 — L4-B : CTE & SOUS-REQUETES
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Exercices 5 à 10 : CTE simples, multiples, récursive,
-- sous-requêtes scalaires, corrélées, EXISTS / NOT EXISTS
-- Prérequis : Phase 4 L4-A (vues) exécutée
-- ============================================================

SET SERVEROUTPUT ON;


-- ############################################################
--  PARTIE 2 — CTE AVEC WITH … AS
-- ############################################################

-- ============================================================
-- EXERCICE 5 : CTE simple — Top 3 satellites par volume
-- Top 3 des satellites ayant téléchargé le plus grand volume
-- de données, avec nombre de fenêtres réalisées et volume
-- moyen par passage.
-- ============================================================
-- Résultat attendu (3 lignes) :
--   SAT-003 | NanoOrbit-Gamma | 1 fenêtre | 1680 Mo total | 1680 Mo/passage
--   SAT-001 | NanoOrbit-Alpha | 1 fenêtre | 1250 Mo total | 1250 Mo/passage
--   SAT-002 | NanoOrbit-Beta  | 1 fenêtre |  890 Mo total |  890 Mo/passage
-- ============================================================
WITH volumes_par_satellite AS (
    SELECT
        f.id_satellite,
        s.nom_satellite,
        COUNT(*)                                AS nb_fenetres,
        SUM(f.volume_donnees)                   AS volume_total,
        ROUND(AVG(f.volume_donnees), 2)         AS volume_moyen
    FROM FENETRE_COM f
    JOIN SATELLITE s ON f.id_satellite = s.id_satellite
    WHERE f.statut = 'Réalisée'
    GROUP BY f.id_satellite, s.nom_satellite
)
SELECT
    id_satellite,
    nom_satellite,
    nb_fenetres,
    volume_total   AS volume_total_mo,
    volume_moyen   AS volume_moyen_par_passage
FROM volumes_par_satellite
ORDER BY volume_total DESC
FETCH FIRST 3 ROWS ONLY;


-- ============================================================
-- EXERCICE 6 : CTE multiples — Analyse comparative par station
-- Pour chaque station : nombre de fenêtres du mois de référence
-- (janvier 2024), volume total réalisé, satellite le plus actif.
-- NOTE : Les données datent de janvier 2024.
-- En production, remplacer la date fixe par TRUNC(SYSDATE,'MM').
-- ============================================================
-- Résultat attendu (3 lignes) :
--   GS-KIR-01 | Kiruna Arctic Station | 2 fenêtres mois | 2930 Mo total | SAT-003 (plus actif)
--   GS-TLS-01 | Toulouse Ground St.   | 3 fenêtres mois |  890 Mo total | SAT-002 (plus actif)
--   GS-SGP-01 | Singapore Station     | 0 fenêtres mois |    0 Mo total | -
-- ============================================================
WITH fenetres_mois AS (
    -- Fenêtres du mois de référence (janvier 2024)
    SELECT code_station, COUNT(*) AS nb_fenetres_mois
    FROM FENETRE_COM
    WHERE TRUNC(datetime_debut, 'MM') = TO_DATE('2024-01-01','YYYY-MM-DD')
    GROUP BY code_station
),
volumes_station AS (
    -- Volume total réalisé par station (toutes périodes)
    SELECT code_station, SUM(volume_donnees) AS volume_total
    FROM FENETRE_COM
    WHERE statut = 'Réalisée'
    GROUP BY code_station
),
satellite_actif AS (
    -- Satellite ayant transféré le plus grand volume par station
    SELECT code_station, id_satellite, volume_donnees,
           ROW_NUMBER() OVER (
               PARTITION BY code_station
               ORDER BY volume_donnees DESC NULLS LAST
           ) AS rn
    FROM FENETRE_COM
    WHERE statut = 'Réalisée'
)
SELECT
    st.code_station,
    st.nom_station,
    NVL(fm.nb_fenetres_mois, 0)   AS nb_fenetres_mois,
    NVL(vs.volume_total, 0)        AS volume_total_mo,
    sa.id_satellite                 AS satellite_plus_actif
FROM STATION_SOL st
LEFT JOIN fenetres_mois fm     ON st.code_station = fm.code_station
LEFT JOIN volumes_station vs   ON st.code_station = vs.code_station
LEFT JOIN satellite_actif sa   ON st.code_station = sa.code_station AND sa.rn = 1
ORDER BY volume_total_mo DESC;


-- ============================================================
-- EXERCICE 7 : CTE récursive — Hiérarchie Centre → Station → Fenêtres
-- Affichage hiérarchique avec indentation LPAD.
-- NOTE : Pas de FK entre CENTRE_CONTROLE et STATION_SOL
-- (table AFFECTATION_STATION supprimée). On associe les
-- stations aux centres par correspondance géographique :
--   Europe        → Toulouse (GS-TLS-01), Kiruna (GS-KIR-01)
--   Asie-Pacifique → Singapore (GS-SGP-01)
-- ============================================================
-- Résultat attendu :
--   [Centre] NanoOrbit Paris HQ (Europe)
--       [Station] Toulouse Ground Station (S, 150 Mbps)
--           [Fenêtre] 2 — 15/01/2024 11:52 — SAT-002 — Réalisée (890 Mo)
--           [Fenêtre] 4 — 20/01/2024 14:22 — SAT-001 — Planifiée
--           [Fenêtre] 5 — 21/01/2024 07:45 — SAT-003 — Planifiée
--       [Station] Kiruna Arctic Station (X, 400 Mbps)
--           [Fenêtre] 1 — 15/01/2024 09:14 — SAT-001 — Réalisée (1250 Mo)
--           [Fenêtre] 3 — 16/01/2024 08:30 — SAT-003 — Réalisée (1680 Mo)
--   [Centre] NanoOrbit Singapore (Asie-Pacifique)
--       [Station] Singapore Station (S, 120 Mbps)
--   [Centre] NanoOrbit Houston (Amériques)
--       (aucune station rattachée)
-- ============================================================
WITH
-- Association manuelle centres ↔ stations (remplacement AFFECTATION_STATION)
mapping_centre_station AS (
    SELECT '1' AS id_centre, 'GS-TLS-01' AS code_station FROM DUAL
    UNION ALL SELECT '1', 'GS-KIR-01' FROM DUAL
    UNION ALL SELECT '3', 'GS-SGP-01' FROM DUAL
),
-- Niveau 1 : Centres de contrôle
niveau_centres AS (
    SELECT
        c.id_centre                                                 AS cle_tri_1,
        NULL                                                        AS cle_tri_2,
        NULL                                                        AS cle_tri_3,
        1                                                           AS niveau,
        '[Centre] ' || c.nom_centre || ' (' || c.region_geo || ')' AS libelle
    FROM CENTRE_CONTROLE c
),
-- Niveau 2 : Stations au sol
niveau_stations AS (
    SELECT
        m.id_centre                                                                          AS cle_tri_1,
        st.code_station                                                                      AS cle_tri_2,
        NULL                                                                                 AS cle_tri_3,
        2                                                                                    AS niveau,
        '[Station] ' || st.nom_station || ' (' || st.bande_frequence || ', '
            || st.debit_max || ' Mbps)'                                                      AS libelle
    FROM mapping_centre_station m
    JOIN STATION_SOL st ON m.code_station = st.code_station
),
-- Niveau 3 : Fenêtres récentes
niveau_fenetres AS (
    SELECT
        m.id_centre                                                                            AS cle_tri_1,
        f.code_station                                                                         AS cle_tri_2,
        f.id_fenetre                                                                           AS cle_tri_3,
        3                                                                                      AS niveau,
        '[Fenêtre] ' || f.id_fenetre || ' — '
            || TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') || ' — '
            || f.id_satellite || ' — ' || f.statut
            || CASE WHEN f.volume_donnees IS NOT NULL
                    THEN ' (' || f.volume_donnees || ' Mo)'
                    ELSE '' END                                                                AS libelle
    FROM FENETRE_COM f
    JOIN mapping_centre_station m ON f.code_station = m.code_station
),
-- Union des 3 niveaux
hierarchie AS (
    SELECT * FROM niveau_centres
    UNION ALL
    SELECT * FROM niveau_stations
    UNION ALL
    SELECT * FROM niveau_fenetres
)
SELECT
    LPAD(' ', (niveau - 1) * 4) || libelle AS affichage_hierarchique
FROM hierarchie
ORDER BY cle_tri_1, cle_tri_2 NULLS FIRST, cle_tri_3 NULLS FIRST;


-- ############################################################
--  PARTIE 3 — SOUS-REQUETES AVANCEES
-- ############################################################

-- ============================================================
-- EXERCICE 8 : Sous-requête scalaire — Fenêtres au-dessus
-- de la moyenne de volume
-- Lister les fenêtres réalisées dont le volume est supérieur
-- à la moyenne générale, en affichant l'écart à la moyenne.
-- ============================================================
-- Moyenne des fenêtres réalisées = (1250 + 890 + 1680) / 3 = 1273.33 Mo
-- Résultat attendu (1 ligne) :
--   Fenêtre 3 | NanoOrbit-Gamma | GS-KIR-01 | 1680 Mo | Moy: 1273.33 | Écart: +406.67
-- (Fenêtre 1 = 1250 < 1273.33 → exclue)
-- ============================================================
SELECT
    f.id_fenetre,
    s.nom_satellite,
    st.nom_station,
    f.volume_donnees,
    (SELECT ROUND(AVG(volume_donnees), 2)
     FROM FENETRE_COM WHERE statut = 'Réalisée')                                        AS moyenne_globale,
    ROUND(f.volume_donnees
        - (SELECT AVG(volume_donnees)
           FROM FENETRE_COM WHERE statut = 'Réalisée'), 2)                               AS ecart_a_moyenne
FROM FENETRE_COM f
JOIN SATELLITE s    ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
  AND f.volume_donnees > (SELECT AVG(volume_donnees)
                          FROM FENETRE_COM
                          WHERE statut = 'Réalisée')
ORDER BY f.volume_donnees DESC;


-- ============================================================
-- EXERCICE 9 : Sous-requête corrélée — Dernière fenêtre
-- réalisée par satellite
-- Pour chaque satellite, récupérer sa dernière fenêtre de
-- communication réalisée (date, station, volume).
-- ============================================================
-- Résultat attendu (3 lignes) :
--   SAT-001 | NanoOrbit-Alpha | FEN 1 | 15/01/2024 09:14 | GS-KIR-01 | 1250 Mo
--   SAT-002 | NanoOrbit-Beta  | FEN 2 | 15/01/2024 11:52 | GS-TLS-01 |  890 Mo
--   SAT-003 | NanoOrbit-Gamma | FEN 3 | 16/01/2024 08:30 | GS-KIR-01 | 1680 Mo
-- (SAT-004 et SAT-005 n'ont aucune fenêtre réalisée → absents)
-- ============================================================
SELECT
    s.id_satellite,
    s.nom_satellite,
    f.id_fenetre,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') AS date_fenetre,
    f.code_station,
    f.volume_donnees
FROM SATELLITE s
JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
WHERE f.statut = 'Réalisée'
  AND f.datetime_debut = (
      SELECT MAX(f2.datetime_debut)
      FROM FENETRE_COM f2
      WHERE f2.id_satellite = s.id_satellite
        AND f2.statut = 'Réalisée'
  )
ORDER BY s.id_satellite;


-- ============================================================
-- EXERCICE 10 : EXISTS / NOT EXISTS
-- A) Satellites sans aucune fenêtre de communication réalisée
-- B) Stations n'ayant traité aucune fenêtre ce trimestre
-- ============================================================

-- 10.A — Satellites sans fenêtre réalisée
-- Résultat attendu (2 lignes) :
--   SAT-004 | NanoOrbit-Delta   | En veille  (aucune fenêtre associée)
--   SAT-005 | NanoOrbit-Epsilon | Désorbité  (aucune fenêtre associée)
-- ============================================================
SELECT s.id_satellite, s.nom_satellite, s.statut
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.id_satellite = s.id_satellite
      AND f.statut = 'Réalisée'
)
ORDER BY s.id_satellite;

-- 10.B — Stations sans fenêtre au T1 2024
-- Résultat attendu (1 ligne) :
--   GS-SGP-01 | Singapore Station
-- Explication : la station de Singapour est en statut 'Maintenance'
-- (RG-G03), ce qui bloque la planification de nouvelles fenêtres
-- via le trigger T1 (trg_valider_fenetre). Elle n'a donc aucune
-- fenêtre enregistrée sur aucune période.
-- ============================================================
-- NOTE : En production, remplacer la date fixe par TRUNC(SYSDATE,'Q')
SELECT st.code_station, st.nom_station, st.statut
FROM STATION_SOL st
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.code_station = st.code_station
      AND TRUNC(f.datetime_debut, 'Q') = TO_DATE('2024-01-01','YYYY-MM-DD')
)
ORDER BY st.code_station;
