SET SERVEROUTPUT ON;

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

CREATE INDEX idx_fen_satellite ON FENETRE_COM(id_satellite);

CREATE INDEX idx_fen_station ON FENETRE_COM(code_station);

CREATE INDEX idx_part_mission ON PARTICIPATION(id_mission);

CREATE INDEX idx_sat_statut ON SATELLITE(statut);

CREATE INDEX idx_sat_statut_orbite ON SATELLITE(statut, id_orbite);

CREATE INDEX idx_fen_mois ON FENETRE_COM(TRUNC(datetime_debut, 'MM'));

SELECT index_name, table_name, column_name, column_position
FROM user_ind_columns
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
  AND index_name LIKE 'IDX_%'
ORDER BY table_name, index_name, column_position;

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

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));




SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';

ALTER INDEX idx_fen_satellite INVISIBLE;

SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';

EXPLAIN PLAN FOR
SELECT s.nom_satellite, COUNT(*) AS nb_fenetres, SUM(f.volume_donnees) AS volume_total
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE f.statut = 'Réalisée'
GROUP BY s.nom_satellite;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));


ALTER INDEX idx_fen_satellite VISIBLE;

SELECT index_name, visibility
FROM user_indexes
WHERE index_name = 'IDX_FEN_SATELLITE';

EXPLAIN PLAN FOR
SELECT s.nom_satellite, COUNT(*) AS nb_fenetres, SUM(f.volume_donnees) AS volume_total
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE f.statut = 'Réalisée'
GROUP BY s.nom_satellite;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'TYPICAL'));


WITH
kpi_global AS (
    SELECT
        (SELECT COUNT(*) FROM SATELLITE)                                      AS total_satellites,
        (SELECT COUNT(*) FROM SATELLITE WHERE statut = 'Opérationnel')        AS nb_operationnels,
        (SELECT COUNT(*) FROM MISSION WHERE statut_mission = 'Active')        AS nb_missions_actives,
        (SELECT NVL(SUM(volume_donnees), 0) FROM FENETRE_COM
         WHERE statut = 'Réalisée')                                           AS volume_global
    FROM DUAL
),
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
top_sat_station AS (
    SELECT code_station, id_satellite,
           ROW_NUMBER() OVER (PARTITION BY code_station ORDER BY volume_donnees DESC NULLS LAST) AS rn
    FROM FENETRE_COM
    WHERE statut = 'Réalisée'
),
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
SELECT section, rang, libelle FROM (
    SELECT 0 AS section, 0 AS rang,
        '=== RAPPORT DE PILOTAGE NANOORBIT ===' AS libelle FROM DUAL
    UNION ALL
    SELECT 1, 0,
        'Total satellites: ' || total_satellites
        || ' | Opérationnels: ' || nb_operationnels
        || ' | Missions actives: ' || nb_missions_actives
        || ' | Volume global: ' || volume_global || ' Mo'
    FROM kpi_global
    UNION ALL
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
