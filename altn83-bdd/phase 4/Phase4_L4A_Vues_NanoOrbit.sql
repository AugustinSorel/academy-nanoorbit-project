SET SERVEROUTPUT ON;

BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_volumes_mensuels'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_satellites_operationnels'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_fenetres_detail'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_stats_missions'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

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

SELECT * FROM v_satellites_operationnels ORDER BY id_satellite;


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

SELECT id_fenetre, nom_satellite, code_station, nom_station,
       bande_frequence, duree_formatee, volume_affiche, statut_fenetre
FROM v_fenetres_detail
ORDER BY id_fenetre;


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

SELECT * FROM v_stats_missions ORDER BY id_mission;


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

SELECT TO_CHAR(mois, 'DD/MM/YYYY') AS mois, code_station, nom_station,
       format_cubesat, nb_fenetres, volume_total_mo
FROM mv_volumes_mensuels
ORDER BY mois, code_station, format_cubesat;

BEGIN
    DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', 'C');
    DBMS_OUTPUT.PUT_LINE('Vue matérialisée rafraîchie avec succès.');
END;
/

SELECT mview_name, refresh_mode, refresh_method, last_refresh_date
FROM user_mviews
WHERE mview_name = 'MV_VOLUMES_MENSUELS';
