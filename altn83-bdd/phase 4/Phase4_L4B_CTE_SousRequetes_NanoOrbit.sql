
SET SERVEROUTPUT ON;

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

WITH fenetres_mois AS (
    SELECT code_station, COUNT(*) AS nb_fenetres_mois
    FROM FENETRE_COM
    WHERE TRUNC(datetime_debut, 'MM') = TO_DATE('2024-01-01','YYYY-MM-DD')
    GROUP BY code_station
),
volumes_station AS (
    SELECT code_station, SUM(volume_donnees) AS volume_total
    FROM FENETRE_COM
    WHERE statut = 'Réalisée'
    GROUP BY code_station
),
satellite_actif AS (
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

WITH
mapping_centre_station AS (
    SELECT '1' AS id_centre, 'GS-TLS-01' AS code_station FROM DUAL
    UNION ALL SELECT '1', 'GS-KIR-01' FROM DUAL
    UNION ALL SELECT '3', 'GS-SGP-01' FROM DUAL
),
niveau_centres AS (
    SELECT
        c.id_centre                                                 AS cle_tri_1,
        NULL                                                        AS cle_tri_2,
        NULL                                                        AS cle_tri_3,
        1                                                           AS niveau,
        '[Centre] ' || c.nom_centre || ' (' || c.region_geo || ')' AS libelle
    FROM CENTRE_CONTROLE c
),

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

SELECT s.id_satellite, s.nom_satellite, s.statut
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.id_satellite = s.id_satellite
      AND f.statut = 'Réalisée'
)
ORDER BY s.id_satellite;
SELECT st.code_station, st.nom_station, st.statut
FROM STATION_SOL st
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.code_station = st.code_station
      AND TRUNC(f.datetime_debut, 'Q') = TO_DATE('2024-01-01','YYYY-MM-DD')
)
ORDER BY st.code_station;
