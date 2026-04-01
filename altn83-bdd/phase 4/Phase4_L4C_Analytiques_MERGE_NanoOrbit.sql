-- ============================================================
-- PROJET NANOORBIT — PHASE 4 — L4-C : ANALYTIQUES & MERGE
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Exercices 11 à 16 : Fonctions analytiques OVER, MERGE INTO
-- Prérequis : Phases 1 à 3 + L4-A et L4-B exécutées
-- ============================================================

SET SERVEROUTPUT ON;


-- ############################################################
--  PARTIE 4 — FONCTIONS ANALYTIQUES OVER
-- ############################################################

-- ============================================================
-- EXERCICE 11 : ROW_NUMBER / RANK / DENSE_RANK
-- Classement des satellites par volume de données téléchargé,
-- global et par type d'orbite (PARTITION BY type_orbite).
-- ============================================================
-- Résultat attendu (5 lignes) :
--   SAT-003 | SSO | 1680 | row=1 | rank=1 | dense=1 | rank_orbite=1
--   SAT-001 | SSO | 1250 | row=2 | rank=2 | dense=2 | rank_orbite=2
--   SAT-002 | SSO |  890 | row=3 | rank=3 | dense=3 | rank_orbite=3
--   SAT-004 | SSO |    0 | row=4 | rank=4 | dense=4 | rank_orbite=4
--   SAT-005 | LEO |    0 | row=5 | rank=4 | dense=4 | rank_orbite=1
-- NOTE : SAT-004 et SAT-005 ont 0 Mo → même RANK (4) et DENSE_RANK (4)
-- ============================================================
SELECT
    s.id_satellite,
    s.nom_satellite,
    o.type_orbite,
    NVL(SUM(f.volume_donnees), 0)                                                           AS volume_total,
    ROW_NUMBER() OVER (ORDER BY NVL(SUM(f.volume_donnees), 0) DESC)                         AS row_num_global,
    RANK()       OVER (ORDER BY NVL(SUM(f.volume_donnees), 0) DESC)                         AS rank_global,
    DENSE_RANK() OVER (ORDER BY NVL(SUM(f.volume_donnees), 0) DESC)                         AS dense_rank_global,
    RANK()       OVER (PARTITION BY o.type_orbite ORDER BY NVL(SUM(f.volume_donnees), 0) DESC) AS rank_par_orbite
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
LEFT JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite AND f.statut = 'Réalisée'
GROUP BY s.id_satellite, s.nom_satellite, o.type_orbite
ORDER BY volume_total DESC, s.id_satellite;


-- ============================================================
-- EXERCICE 12 : LAG / LEAD — Évolution du volume par station
-- Pour chaque fenêtre réalisée d'une station, comparer le
-- volume avec la fenêtre précédente et calculer le % d'évolution.
-- ============================================================
-- Résultat attendu :
--   GS-KIR-01 | FEN 1 | 15/01/2024 09:14 | 1250 Mo | préc: -    | suiv: 1680 | évol: -
--   GS-KIR-01 | FEN 3 | 16/01/2024 08:30 | 1680 Mo | préc: 1250 | suiv: -    | évol: +34.4%
--   GS-TLS-01 | FEN 2 | 15/01/2024 11:52 |  890 Mo | préc: -    | suiv: -    | évol: -
-- ============================================================
SELECT
    f.code_station,
    st.nom_station,
    f.id_fenetre,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI')                                    AS date_fenetre,
    f.volume_donnees                                                                    AS volume_mo,
    LAG(f.volume_donnees) OVER (
        PARTITION BY f.code_station ORDER BY f.datetime_debut
    )                                                                                   AS volume_precedent,
    LEAD(f.volume_donnees) OVER (
        PARTITION BY f.code_station ORDER BY f.datetime_debut
    )                                                                                   AS volume_suivant,
    CASE
        WHEN LAG(f.volume_donnees) OVER (
                 PARTITION BY f.code_station ORDER BY f.datetime_debut) IS NOT NULL
        THEN ROUND(
            (f.volume_donnees - LAG(f.volume_donnees) OVER (
                PARTITION BY f.code_station ORDER BY f.datetime_debut))
            / LAG(f.volume_donnees) OVER (
                PARTITION BY f.code_station ORDER BY f.datetime_debut) * 100, 1
        )
    END                                                                                 AS pct_evolution
FROM FENETRE_COM f
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
ORDER BY f.code_station, f.datetime_debut;


-- ============================================================
-- EXERCICE 13 : SUM OVER — Volumes cumulés chronologiquement
-- par station avec moyenne mobile sur les 3 dernières fenêtres.
-- ============================================================
-- Résultat attendu :
--   GS-KIR-01 | FEN 1 | 1250 | cumulé: 1250 | moy3: 1250
--   GS-KIR-01 | FEN 3 | 1680 | cumulé: 2930 | moy3: 1465
--   GS-TLS-01 | FEN 2 |  890 | cumulé:  890 | moy3:  890
-- ============================================================
SELECT
    f.id_fenetre,
    f.code_station,
    st.nom_station,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI')                                    AS date_fenetre,
    f.volume_donnees                                                                    AS volume_mo,
    SUM(f.volume_donnees) OVER (
        PARTITION BY f.code_station
        ORDER BY f.datetime_debut
        ROWS UNBOUNDED PRECEDING
    )                                                                                   AS volume_cumule,
    ROUND(AVG(f.volume_donnees) OVER (
        PARTITION BY f.code_station
        ORDER BY f.datetime_debut
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                                                               AS moy_mobile_3
FROM FENETRE_COM f
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
ORDER BY f.code_station, f.datetime_debut;


-- ============================================================
-- EXERCICE 14 : Tableau de bord constellation
-- Combiner RANK, SUM OVER et ROUND pour produire le rapport
-- mensuel : rang satellite, part % du volume total, cumul,
-- comparaison à la moyenne.
-- ============================================================
-- Résultat attendu (janvier 2024, 3 lignes) :
--   2024-01 | #1 SAT-003 | NanoOrbit-Gamma | GS-KIR-01 | 1680 Mo | 44.0% | total mois: 3820
--   2024-01 | #2 SAT-001 | NanoOrbit-Alpha | GS-KIR-01 | 1250 Mo | 32.7% | total mois: 3820
--   2024-01 | #3 SAT-002 | NanoOrbit-Beta  | GS-TLS-01 |  890 Mo | 23.3% | total mois: 3820
-- Moyenne mensuelle par passage : 3820 / 3 = 1273.33 Mo
-- ============================================================
SELECT
    TO_CHAR(TRUNC(f.datetime_debut, 'MM'), 'YYYY-MM')                                  AS mois,
    f.code_station,
    s.id_satellite,
    s.nom_satellite,
    f.volume_donnees                                                                    AS volume_mo,
    RANK() OVER (
        PARTITION BY TRUNC(f.datetime_debut, 'MM')
        ORDER BY f.volume_donnees DESC
    )                                                                                   AS rang_mensuel,
    ROUND(SUM(f.volume_donnees) OVER (
        PARTITION BY TRUNC(f.datetime_debut, 'MM')
    ), 2)                                                                               AS total_mois,
    ROUND(f.volume_donnees / SUM(f.volume_donnees) OVER (
        PARTITION BY TRUNC(f.datetime_debut, 'MM')
    ) * 100, 1)                                                                         AS pct_du_total,
    ROUND(AVG(f.volume_donnees) OVER (
        PARTITION BY TRUNC(f.datetime_debut, 'MM')
    ), 2)                                                                               AS moyenne_mois,
    ROUND(f.volume_donnees - AVG(f.volume_donnees) OVER (
        PARTITION BY TRUNC(f.datetime_debut, 'MM')
    ), 2)                                                                               AS ecart_a_moyenne
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE f.statut = 'Réalisée'
ORDER BY mois, rang_mensuel;


-- ############################################################
--  PARTIE 5 — MERGE INTO
-- ############################################################

-- ============================================================
-- EXERCICE 15 : MERGE INTO SATELLITE
-- Synchroniser un lot de mises à jour de statuts reçues d'un
-- système IoT externe.
-- Si le satellite existe : mettre à jour statut et orbite.
-- Si nouveau : insérer avec statut 'En veille'.
-- ============================================================
-- Résultat attendu :
--   SAT-004 existant → UPDATE statut En veille → Opérationnel
--   SAT-006 nouveau  → INSERT avec statut 'En veille' (règle métier)
-- ============================================================

-- Table temporaire simulant les données IoT
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tmp_iot_satellites'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE GLOBAL TEMPORARY TABLE tmp_iot_satellites (
    id_satellite      VARCHAR2(20),
    nom_satellite     VARCHAR2(100),
    statut            VARCHAR2(30),
    id_orbite         VARCHAR2(20),
    masse             NUMBER(7,2),
    format_cubesat    VARCHAR2(3),
    date_lancement    DATE,
    duree_vie_prevue  NUMBER(5,2),
    capacite_batterie NUMBER(5,2)
) ON COMMIT PRESERVE ROWS;

-- Données IoT : 1 existant (SAT-004) + 1 nouveau (SAT-006)
INSERT INTO tmp_iot_satellites VALUES (
    'SAT-004', 'NanoOrbit-Delta', 'Opérationnel', '2', 2.0, '6U',
    TO_DATE('2023-06-10','YYYY-MM-DD'), 84, 40
);
INSERT INTO tmp_iot_satellites VALUES (
    'SAT-006', 'NanoOrbit-Zeta', 'Opérationnel', '3', 3.0, '6U',
    TO_DATE('2025-01-15','YYYY-MM-DD'), 60, 30
);

-- MERGE
MERGE INTO SATELLITE tgt
USING tmp_iot_satellites src
ON (tgt.id_satellite = src.id_satellite)
WHEN MATCHED THEN
    UPDATE SET
        tgt.statut    = src.statut,
        tgt.id_orbite = src.id_orbite
WHEN NOT MATCHED THEN
    INSERT (id_satellite, nom_satellite, date_lancement, masse, format_cubesat,
            statut, duree_vie_prevue, capacite_batterie, id_orbite)
    VALUES (src.id_satellite, src.nom_satellite, src.date_lancement, src.masse,
            src.format_cubesat,
            'En veille',   -- Règle métier : tout nouveau satellite arrive En veille
            src.duree_vie_prevue, src.capacite_batterie, src.id_orbite);

-- Vérification
-- Résultat attendu :
--   SAT-004 → Opérationnel (mis à jour depuis En veille)
--   SAT-006 → En veille (inséré, statut forcé malgré source 'Opérationnel')
SELECT id_satellite, nom_satellite, statut, id_orbite
FROM SATELLITE
WHERE id_satellite IN ('SAT-004', 'SAT-006')
ORDER BY id_satellite;

-- Annulation pour garder les données propres
ROLLBACK;

-- Vérification post-rollback
-- SAT-004 doit être revenu à 'En veille', SAT-006 ne doit plus exister
SELECT id_satellite, statut FROM SATELLITE
WHERE id_satellite IN ('SAT-004', 'SAT-006')
ORDER BY id_satellite;


-- ============================================================
-- EXERCICE 16 : MERGE INTO STATION_SOL
-- Synchroniser les stations au sol depuis un fichier de
-- configuration révisé : mettre à jour débit et statut si
-- la station existe, insérer si nouvelle.
-- NOTE : Remplace l'exercice sur AFFECTATION_STATION
-- (table supprimée du schéma).
-- ============================================================
-- Résultat attendu :
--   GS-SGP-01 existant → UPDATE debit_max 120→200, statut Maintenance→Active
--   GS-SVB-01 nouveau  → INSERT (Svalbard Arctic Station)
-- ============================================================

-- Table temporaire simulant le fichier de configuration
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tmp_config_stations'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE GLOBAL TEMPORARY TABLE tmp_config_stations (
    code_station     VARCHAR2(20),
    nom_station      VARCHAR2(100),
    latitude         NUMBER(9,6),
    longitude        NUMBER(9,6),
    diametre_antenne NUMBER(5,2),
    bande_frequence  VARCHAR2(20),
    debit_max        NUMBER(10,2),
    statut           VARCHAR2(20)
) ON COMMIT PRESERVE ROWS;

-- Données config : 1 mise à jour (SGP) + 1 nouvelle station (Svalbard)
INSERT INTO tmp_config_stations VALUES (
    'GS-SGP-01', 'Singapore Station', 1.3521, 103.8198, 3.0, 'S', 200, 'Active'
);
INSERT INTO tmp_config_stations VALUES (
    'GS-SVB-01', 'Svalbard Arctic Station', 78.2297, 15.3937, 4.5, 'X', 350, 'Active'
);

-- MERGE
MERGE INTO STATION_SOL tgt
USING tmp_config_stations src
ON (tgt.code_station = src.code_station)
WHEN MATCHED THEN
    UPDATE SET
        tgt.debit_max = src.debit_max,
        tgt.statut    = src.statut
WHEN NOT MATCHED THEN
    INSERT (code_station, nom_station, latitude, longitude,
            diametre_antenne, bande_frequence, debit_max, statut)
    VALUES (src.code_station, src.nom_station, src.latitude, src.longitude,
            src.diametre_antenne, src.bande_frequence, src.debit_max, src.statut);

-- Vérification
-- Résultat attendu :
--   GS-SGP-01 → debit_max=200, statut=Active
--   GS-SVB-01 → nouvelle station insérée
SELECT code_station, nom_station, debit_max, statut
FROM STATION_SOL
WHERE code_station IN ('GS-SGP-01', 'GS-SVB-01')
ORDER BY code_station;

-- Annulation pour garder les données propres
ROLLBACK;

-- Vérification post-rollback
SELECT code_station, nom_station, debit_max, statut
FROM STATION_SOL
ORDER BY code_station;
