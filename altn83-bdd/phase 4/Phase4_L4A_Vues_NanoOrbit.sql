-- ============================================================
-- PROJET NANOORBIT — PHASE 4 — L4-A : VUES
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Vues V1 à V3 (CREATE VIEW) + V4 (vue matérialisée)
-- Prérequis : Phases 1 à 3 terminées (DDL + DML + Triggers)
-- ============================================================
-- NOTE : La table AFFECTATION_STATION a été supprimée du schéma.
-- Il n'y a pas de FK entre STATION_SOL et CENTRE_CONTROLE.
-- Les vues sont adaptées en conséquence.
-- ============================================================

SET SERVEROUTPUT ON;

-- Nettoyage préalable
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_volumes_mensuels'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_satellites_operationnels'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_fenetres_detail'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_stats_missions'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- ============================================================
-- V1 — v_satellites_operationnels
-- Vue simple filtrée : satellites opérationnels avec orbite,
-- nombre d'instruments embarqués et statut batterie.
-- ============================================================
CREATE OR REPLACE VIEW v_satellites_operationnels AS
SELECT
    s.id_satellite,
    s.nom_satellite,
    s.format_cubesat,
    o.type_orbite || ' ' || o.altitude || ' km' AS orbite,
    (SELECT COUNT(*)
     FROM EMBARQUEMENT e
     WHERE e.id_satellite = s.id_satellite)            AS nb_instruments,
    s.capacite_batterie,
    CASE
        WHEN s.capacite_batterie >= 40 THEN 'Bonne'
        WHEN s.capacite_batterie >= 20 THEN 'Moyenne'
        ELSE 'Faible'
    END                                                 AS etat_batterie
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE s.statut = 'Opérationnel';

-- Test V1
-- Résultat attendu (3 lignes) :
--   SAT-001 | NanoOrbit-Alpha | 3U | SSO 550 km | 2 | 20 | Moyenne
--   SAT-002 | NanoOrbit-Beta  | 3U | SSO 550 km | 1 | 20 | Moyenne
--   SAT-003 | NanoOrbit-Gamma | 6U | SSO 700 km | 2 | 40 | Bonne
SELECT * FROM v_satellites_operationnels ORDER BY id_satellite;


-- ============================================================
-- V2 — v_fenetres_detail
-- Vue jointure dénormalisée : toutes les fenêtres avec nom
-- satellite, nom station, bande fréquence, durée formatée et
-- volume.
-- NOTE : Pas de lien FK vers CENTRE_CONTROLE (table
-- AFFECTATION_STATION supprimée), le centre est omis.
-- ============================================================
CREATE OR REPLACE VIEW v_fenetres_detail AS
SELECT
    f.id_fenetre,
    f.datetime_debut,
    s.id_satellite,
    s.nom_satellite,
    st.code_station,
    st.nom_station,
    st.bande_frequence,
    f.duree,
    FLOOR(f.duree / 60) || ' min ' || MOD(f.duree, 60) || ' s'  AS duree_formatee,
    f.elevation_max,
    f.volume_donnees,
    NVL(TO_CHAR(f.volume_donnees), 'N/A')                        AS volume_affiche,
    f.statut                                                      AS statut_fenetre
FROM FENETRE_COM f
JOIN SATELLITE s   ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station;

-- Test V2
-- Résultat attendu (5 lignes) :
--   1 | NanoOrbit-Alpha | GS-KIR-01 | Kiruna Arctic Station | X | 7 min 0 s | 1250  | Réalisée
--   2 | NanoOrbit-Beta  | GS-TLS-01 | Toulouse Ground St.   | S | 5 min 10 s| 890   | Réalisée
--   3 | NanoOrbit-Gamma | GS-KIR-01 | Kiruna Arctic Station | X | 9 min 0 s | 1680  | Réalisée
--   4 | NanoOrbit-Alpha | GS-TLS-01 | Toulouse Ground St.   | S | 6 min 20 s| N/A   | Planifiée
--   5 | NanoOrbit-Gamma | GS-TLS-01 | Toulouse Ground St.   | S | 4 min 50 s| N/A   | Planifiée
SELECT id_fenetre, nom_satellite, code_station, nom_station,
       bande_frequence, duree_formatee, volume_affiche, statut_fenetre
FROM v_fenetres_detail
ORDER BY id_fenetre;


-- ============================================================
-- V3 — v_stats_missions
-- Vue avec agrégats : par mission, nombre de satellites,
-- types d'orbites représentés, volume total téléchargé.
-- Le volume total correspond aux fenêtres Réalisées des
-- satellites participant à chaque mission.
-- ============================================================
CREATE OR REPLACE VIEW v_stats_missions AS
SELECT
    m.id_mission,
    m.nom_mission,
    m.statut_mission,
    COUNT(DISTINCT p.id_satellite)                                          AS nb_satellites,
    LISTAGG(DISTINCT o.type_orbite, ', ') WITHIN GROUP (ORDER BY o.type_orbite) AS types_orbites,
    NVL(SUM(f.volume_donnees), 0)                                           AS volume_total_mo
FROM MISSION m
LEFT JOIN PARTICIPATION p ON m.id_mission = p.id_mission
LEFT JOIN SATELLITE s     ON p.id_satellite = s.id_satellite
LEFT JOIN ORBITE o        ON s.id_orbite = o.id_orbite
LEFT JOIN FENETRE_COM f   ON s.id_satellite = f.id_satellite AND f.statut = 'Réalisée'
GROUP BY m.id_mission, m.nom_mission, m.statut_mission;

-- Test V3
-- Résultat attendu (3 lignes) :
--   MSN-ARC-2023  | ArcticWatch 2023  | Active   | 3 | SSO      | 3820
--     (SAT-001→1250 + SAT-002→890 + SAT-003→1680)
--   MSN-COAST-2024| CoastGuard 2024   | Active   | 2 | SSO      | 1680
--     (SAT-003→1680, SAT-004→0)
--   MSN-DEF-2022  | DeforestAlert     | Terminée | 2 | LEO, SSO | 1250
--     (SAT-001→1250, SAT-005→0)
SELECT * FROM v_stats_missions ORDER BY id_mission;


-- ============================================================
-- V4 — mv_volumes_mensuels (Vue Matérialisée)
-- REFRESH ON DEMAND — Volumes téléchargés par mois,
-- par station et par format CubeSat.
-- Seules les fenêtres Réalisées sont comptées.
-- ============================================================
CREATE MATERIALIZED VIEW mv_volumes_mensuels
BUILD IMMEDIATE
REFRESH ON DEMAND
AS
SELECT
    TRUNC(f.datetime_debut, 'MM')   AS mois,
    f.code_station,
    st.nom_station,
    s.format_cubesat,
    COUNT(*)                         AS nb_fenetres,
    SUM(f.volume_donnees)            AS volume_total_mo
FROM FENETRE_COM f
JOIN SATELLITE s    ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
GROUP BY TRUNC(f.datetime_debut, 'MM'), f.code_station, st.nom_station, s.format_cubesat;

-- Test V4
-- Résultat attendu (3 lignes, toutes en janvier 2024) :
--   01/01/2024 | GS-KIR-01 | Kiruna Arctic Station | 3U | 1 | 1250  (SAT-001)
--   01/01/2024 | GS-KIR-01 | Kiruna Arctic Station | 6U | 1 | 1680  (SAT-003)
--   01/01/2024 | GS-TLS-01 | Toulouse Ground St.   | 3U | 1 | 890   (SAT-002)
SELECT TO_CHAR(mois, 'DD/MM/YYYY') AS mois, code_station, nom_station,
       format_cubesat, nb_fenetres, volume_total_mo
FROM mv_volumes_mensuels
ORDER BY mois, code_station, format_cubesat;

-- Rafraîchissement manuel (COMPLETE)
BEGIN
    DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', 'C');
    DBMS_OUTPUT.PUT_LINE('Vue matérialisée rafraîchie avec succès.');
END;
/

-- Vérification dans le dictionnaire
SELECT mview_name, refresh_mode, refresh_method, last_refresh_date
FROM user_mviews
WHERE mview_name = 'MV_VOLUMES_MENSUELS';
