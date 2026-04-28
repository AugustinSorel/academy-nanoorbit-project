
SET SERVEROUTPUT ON;

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

INSERT INTO tmp_iot_satellites VALUES (
    'SAT-004', 'NanoOrbit-Delta', 'Opérationnel', '2', 2.0, '6U',
    TO_DATE('2023-06-10','YYYY-MM-DD'), 84, 40
);
INSERT INTO tmp_iot_satellites VALUES (
    'SAT-006', 'NanoOrbit-Zeta', 'Opérationnel', '3', 3.0, '6U',
    TO_DATE('2025-01-15','YYYY-MM-DD'), 60, 30
);

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

SELECT id_satellite, nom_satellite, statut, id_orbite
FROM SATELLITE
WHERE id_satellite IN ('SAT-004', 'SAT-006')
ORDER BY id_satellite;

ROLLBACK;

SELECT id_satellite, statut FROM SATELLITE
WHERE id_satellite IN ('SAT-004', 'SAT-006')
ORDER BY id_satellite;



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

SELECT code_station, nom_station, debit_max, statut
FROM STATION_SOL
WHERE code_station IN ('GS-SGP-01', 'GS-SVB-01')
ORDER BY code_station;

ROLLBACK;

SELECT code_station, nom_station, debit_max, statut
FROM STATION_SOL
ORDER BY code_station;
