-- ============================================================
-- PROJET NANOORBIT — PHASE 4 — L4-D : INDEX & EXPLAIN PLAN
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Exercices 17 à 19 + Rapport de pilotage intégral
-- Prérequis : Phases 1 à 3 + L4-A, L4-B, L4-C exécutées
-- ============================================================

SET SERVEROUTPUT ON;


-- ############################################################
--  PARTIE 6 — INDEX & EXPLAIN PLAN
-- ############################################################

-- ============================================================
-- EXERCICE 17 : Création des index stratégiques
-- Oracle ne crée PAS automatiquement d'index sur les colonnes FK.
-- Les PK ont un index implicite, mais pas les FK.
-- ============================================================

-- Nettoyage préalable (ignore les erreurs si l'index n'existe pas)
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fen_satellite';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fen_station';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_part_mission';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_sat_statut';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_sat_statut_orbite'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fen_mois';          EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ---------------------------------------------------------
-- 17.1 — Index FK sur FENETRE_COM(id_satellite)
-- Justification : colonne FK très sollicitée dans les jointures
-- avec SATELLITE (vues V1-V3, CTE, sous-requêtes corrélées).
-- Accélère aussi les DELETE CASCADE sur SATELLITE.
-- ---------------------------------------------------------
CREATE INDEX idx_fen_satellite ON FENETRE_COM(id_satellite);

-- ---------------------------------------------------------
-- 17.2 — Index FK sur FENETRE_COM(code_station)
-- Justification : jointures fréquentes avec STATION_SOL
-- (vues, rapports par station, Ex. 6, Ex. 11-13).
-- ---------------------------------------------------------
CREATE INDEX idx_fen_station ON FENETRE_COM(code_station);

-- ---------------------------------------------------------
-- 17.3 — Index FK sur PARTICIPATION(id_mission)
-- Justification : la PK composite (id_satellite, id_mission)
-- couvre id_satellite en colonne de tête mais PAS id_mission.
-- Cet index accélère les jointures MISSION → PARTICIPATION.
-- NOTE : Un index sur PARTICIPATION(id_satellite) serait
-- redondant car déjà couvert par la PK composite.
-- ---------------------------------------------------------
CREATE INDEX idx_part_mission ON PARTICIPATION(id_mission);

-- ---------------------------------------------------------
-- 17.4 — Index sur SATELLITE(statut)
-- Justification : colonne filtre fréquente (WHERE statut =
-- 'Opérationnel', vue V1, triggers, procédures package).
-- ---------------------------------------------------------
CREATE INDEX idx_sat_statut ON SATELLITE(statut);

-- ---------------------------------------------------------
-- 17.5 — Index composite sur SATELLITE(statut, id_orbite)
-- Justification : requêtes filtrant par statut avec jointure
-- sur ORBITE (Ex. 11 PARTITION BY type_orbite, vue V1).
-- Permet un INDEX RANGE SCAN couvrant les deux colonnes.
-- ---------------------------------------------------------
CREATE INDEX idx_sat_statut_orbite ON SATELLITE(statut, id_orbite);

-- ---------------------------------------------------------
-- 17.6 — Index fonctionnel sur TRUNC(datetime_debut, 'MM')
-- Justification : regroupements mensuels dans la vue
-- matérialisée V4, Ex. 6 (CTE fenetres_mois), Ex. 14
-- (tableau de bord mensuel), rapport de pilotage.
-- ---------------------------------------------------------
CREATE INDEX idx_fen_mois ON FENETRE_COM(TRUNC(datetime_debut, 'MM'));

-- Vérification des index créés
SELECT index_name, table_name, column_name, column_position
FROM user_ind_columns
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
  AND index_name LIKE 'IDX_%'
ORDER BY table_name, index_name, column_position;


-- ============================================================
-- EXERCICE 18 : EXPLAIN PLAN — Requête de reporting mensuel
-- Jointure sur 4+ tables + GROUP BY + agrégats.
-- Analyser le plan d'exécution pour identifier les opérations
-- coûteuses (TABLE ACCESS FULL).
-- ============================================================

-- Requête de reporting mensuel à analyser
EXPLAIN PLAN FOR
SELECT
    TO_CHAR(TRUNC(f.datetime_debut, 'MM'), 'YYYY-MM')  AS mois,
    s.nom_satellite,
    o.type_orbite,
    st.nom_station,
    m.nom_mission,
    COUNT(*)                                             AS nb_fenetres,
    SUM(f.volume_donnees)                                AS volume_total
FROM FENETRE_COM f
JOIN SATELLITE s    ON f.id_satellite = s.id_satellite
JOIN ORBITE o       ON s.id_orbite = o.id_orbite
JOIN STATION_SOL st ON f.code_station = st.code_station
JOIN PARTICIPATION p ON s.id_satellite = p.id_satellite
JOIN MISSION m       ON p.id_mission = m.id_mission
WHERE f.statut = 'Réalisée'
GROUP BY
    TO_CHAR(TRUNC(f.datetime_debut, 'MM'), 'YYYY-MM'),
    s.nom_satellite, o.type_orbite, st.nom_station, m.nom_mission
ORDER BY mois, volume_total DESC;

-- Affichage du plan d'exécution
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));

-- ============================================================
-- ANALYSE DU PLAN (à documenter après exécution) :
-- Avec seulement 3 à 9 lignes par table, l'optimiseur Oracle
-- choisira probablement des TABLE ACCESS FULL pour toutes les
-- tables (coût inférieur à un accès par index sur si peu de données).
--
-- En PRODUCTION avec des milliers de lignes :
-- - idx_fen_satellite → INDEX RANGE SCAN sur FENETRE_COM
--   au lieu de TABLE ACCESS FULL
-- - idx_fen_station → INDEX RANGE SCAN pour la jointure STATION_SOL
-- - idx_part_mission → INDEX RANGE SCAN pour PARTICIPATION→MISSION
-- - idx_fen_mois → INDEX RANGE SCAN pour le TRUNC mensuel
-- - idx_sat_statut → INDEX RANGE SCAN pour le filtre statut='Réalisée'
--
-- L'optimiseur bascule vers les index quand la sélectivité
-- est suffisante (généralement < 5-10% des lignes de la table).
-- ============================================================


-- ============================================================
-- EXERCICE 19 : Impact de la visibilité d'un index
-- Rendre idx_fen_satellite INVISIBLE, observer le changement
-- de plan, puis le rendre VISIBLE à nouveau.
-- ============================================================

-- 19.1 — État initial : index VISIBLE
SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';
-- Résultat attendu : IDX_FEN_SATELLITE | VISIBLE

-- 19.2 — Rendre l'index INVISIBLE
ALTER INDEX idx_fen_satellite INVISIBLE;

-- Vérification
SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';
-- Résultat attendu : IDX_FEN_SATELLITE | INVISIBLE

-- 19.3 — Plan SANS index (INVISIBLE)
-- L'optimiseur ne voit plus l'index → TABLE ACCESS FULL attendu
-- sur FENETRE_COM pour la jointure avec SATELLITE.
EXPLAIN PLAN FOR
SELECT s.nom_satellite, COUNT(*) AS nb_fenetres, SUM(f.volume_donnees) AS volume_total
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE f.statut = 'Réalisée'
GROUP BY s.nom_satellite;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));

-- ============================================================
-- INTERPRETATION (index INVISIBLE) :
-- Le plan devrait montrer TABLE ACCESS FULL sur FENETRE_COM
-- car l'optimiseur ne peut plus utiliser IDX_FEN_SATELLITE
-- pour parcourir les lignes par id_satellite.
-- NOTE : Sur notre jeu de données réduit (5 fenêtres), le plan
-- peut être identique car l'optimiseur préfère le FULL SCAN de
-- toute façon. La différence serait visible sur des volumes
-- de données plus importants.
-- ============================================================

-- 19.4 — Restaurer la visibilité de l'index
ALTER INDEX idx_fen_satellite VISIBLE;

-- Vérification
SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';
-- Résultat attendu : IDX_FEN_SATELLITE | VISIBLE

-- 19.5 — Plan AVEC index (VISIBLE)
-- L'optimiseur peut à nouveau utiliser l'index.
-- Sur un grand volume → INDEX RANGE SCAN au lieu de TABLE ACCESS FULL.
EXPLAIN PLAN FOR
SELECT s.nom_satellite, COUNT(*) AS nb_fenetres, SUM(f.volume_donnees) AS volume_total
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE f.statut = 'Réalisée'
GROUP BY s.nom_satellite;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));

-- ============================================================
-- INTERPRETATION (index VISIBLE) :
-- Avec l'index visible, le plan peut montrer INDEX RANGE SCAN
-- sur IDX_FEN_SATELLITE si l'optimiseur estime que c'est plus
-- efficace que le TABLE ACCESS FULL.
--
-- CONCLUSION : ALTER INDEX ... INVISIBLE est une méthode
-- non-destructive pour tester l'impact d'un index sur les
-- performances. L'index reste physiquement présent et mis à jour
-- lors des DML, mais l'optimiseur l'ignore pour les requêtes.
-- C'est plus sûr que DROP INDEX car on peut le rendre VISIBLE
-- instantanément sans reconstruire.
-- ============================================================


-- ############################################################
--  RAPPORT DE PILOTAGE INTEGRAL — EXERCICE DE SYNTHESE
-- ############################################################

-- ============================================================
-- Requête finale combinant CTE, fonctions analytiques et
-- référence à la vue matérialisée pour produire le tableau
-- de bord opérationnel NanoOrbit :
-- - Rang des stations par volume téléchargé
-- - Part % du volume total
-- - Évolution par rapport au mois précédent (LAG)
-- - Statut de chaque satellite rattaché
-- ============================================================
-- Résultat attendu (format tabulaire) :
--
--  === RAPPORT DE PILOTAGE NANOORBIT ===
--
--  SECTION 1 : KPI FLOTTE
--   Total satellites: 5 | Opérationnels: 3 | Missions actives: 2
--
--  SECTION 2 : CLASSEMENT SATELLITES PAR VOLUME
--   #1 SAT-003 NanoOrbit-Gamma  | SSO | 1680 Mo | 44.0% du total
--   #2 SAT-001 NanoOrbit-Alpha  | SSO | 1250 Mo | 32.7% du total
--   #3 SAT-002 NanoOrbit-Beta   | SSO |  890 Mo | 23.3% du total
--
--  SECTION 3 : PERFORMANCE STATIONS
--   GS-KIR-01 | Kiruna  | 2930 Mo | 76.7% | top satellite: SAT-003
--   GS-TLS-01 | Toulouse|  890 Mo | 23.3% | top satellite: SAT-002
--
--  SECTION 4 : MISSIONS ACTIVES
--   MSN-ARC-2023  | 3 satellites | 3820 Mo
--   MSN-COAST-2024| 2 satellites | 1680 Mo
-- ============================================================
WITH
-- KPI globaux
kpi_global AS (
    SELECT
        (SELECT COUNT(*) FROM SATELLITE)                                      AS total_satellites,
        (SELECT COUNT(*) FROM SATELLITE WHERE statut = 'Opérationnel')        AS nb_operationnels,
        (SELECT COUNT(*) FROM MISSION WHERE statut_mission = 'Active')        AS nb_missions_actives,
        (SELECT NVL(SUM(volume_donnees), 0) FROM FENETRE_COM
         WHERE statut = 'Réalisée')                                           AS volume_global
    FROM DUAL
),
-- Classement satellites
classement_satellites AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        s.statut,
        o.type_orbite,
        NVL(SUM(f.volume_donnees), 0)                                         AS volume_total,
        RANK() OVER (ORDER BY NVL(SUM(f.volume_donnees), 0) DESC)             AS rang
    FROM SATELLITE s
    JOIN ORBITE o ON s.id_orbite = o.id_orbite
    LEFT JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite AND f.statut = 'Réalisée'
    GROUP BY s.id_satellite, s.nom_satellite, s.statut, o.type_orbite
),
-- Performance stations
perf_stations AS (
    SELECT
        st.code_station,
        st.nom_station,
        NVL(SUM(f.volume_donnees), 0)                                         AS volume_station,
        COUNT(f.id_fenetre)                                                    AS nb_fenetres
    FROM STATION_SOL st
    LEFT JOIN FENETRE_COM f ON st.code_station = f.code_station AND f.statut = 'Réalisée'
    GROUP BY st.code_station, st.nom_station
),
-- Top satellite par station
top_sat_station AS (
    SELECT code_station, id_satellite,
           ROW_NUMBER() OVER (PARTITION BY code_station ORDER BY volume_donnees DESC NULLS LAST) AS rn
    FROM FENETRE_COM
    WHERE statut = 'Réalisée'
),
-- Stats missions
stats_missions AS (
    SELECT
        m.id_mission,
        m.nom_mission,
        m.statut_mission,
        COUNT(DISTINCT p.id_satellite) AS nb_satellites,
        NVL(SUM(f.volume_donnees), 0)  AS volume_mission
    FROM MISSION m
    LEFT JOIN PARTICIPATION p ON m.id_mission = p.id_mission
    LEFT JOIN FENETRE_COM f   ON p.id_satellite = f.id_satellite AND f.statut = 'Réalisée'
    GROUP BY m.id_mission, m.nom_mission, m.statut_mission
)
-- Assemblage final en sections
SELECT section, rang, libelle FROM (
    -- En-tête
    SELECT 0 AS section, 0 AS rang,
        '=== RAPPORT DE PILOTAGE NANOORBIT ===' AS libelle FROM DUAL
    UNION ALL
    -- Section 1 : KPI flotte
    SELECT 1, 0,
        'Total satellites: ' || total_satellites
        || ' | Opérationnels: ' || nb_operationnels
        || ' | Missions actives: ' || nb_missions_actives
        || ' | Volume global: ' || volume_global || ' Mo'
    FROM kpi_global
    UNION ALL
    -- Section 2 : Classement satellites
    SELECT 2, 0, '--- CLASSEMENT SATELLITES PAR VOLUME ---' FROM DUAL
    UNION ALL
    SELECT 2, rang,
        '#' || rang || ' ' || RPAD(id_satellite, 8)
        || RPAD(nom_satellite, 22) || '| ' || type_orbite
        || ' | ' || LPAD(volume_total, 6) || ' Mo'
        || ' | ' || ROUND(volume_total / NULLIF((SELECT volume_global FROM kpi_global), 0) * 100, 1) || '%'
        || ' | ' || statut
    FROM classement_satellites
    WHERE rang <= 5
    UNION ALL
    -- Section 3 : Stations
    SELECT 3, 0, '--- PERFORMANCE STATIONS ---' FROM DUAL
    UNION ALL
    SELECT 3, ROWNUM,
        ps.code_station || ' | ' || RPAD(ps.nom_station, 25)
        || '| ' || LPAD(ps.volume_station, 6) || ' Mo'
        || ' | ' || ps.nb_fenetres || ' fenêtre(s)'
        || ' | Top: ' || NVL(ts.id_satellite, '-')
    FROM perf_stations ps
    LEFT JOIN top_sat_station ts ON ps.code_station = ts.code_station AND ts.rn = 1
    UNION ALL
    -- Section 4 : Missions actives
    SELECT 4, 0, '--- MISSIONS ACTIVES ---' FROM DUAL
    UNION ALL
    SELECT 4, ROWNUM,
        RPAD(id_mission, 16) || '| ' || nom_mission
        || ' | ' || nb_satellites || ' satellite(s)'
        || ' | ' || volume_mission || ' Mo'
    FROM stats_missions
    WHERE statut_mission = 'Active'
)
ORDER BY section, rang;
