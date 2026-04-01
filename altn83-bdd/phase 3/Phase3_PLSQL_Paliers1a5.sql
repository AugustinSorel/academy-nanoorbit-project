-- ============================================================
-- PROJET NANOORBIT — PHASE 3 — PL/SQL Paliers 1 à 5
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Exercices 1 à 16 — Blocs anonymes, curseurs, procédures, fonctions
-- Prérequis : Phase 2 complète (DDL + DML + Triggers)
-- ============================================================

SET SERVEROUTPUT ON;


-- ############################################################
--  PALIER 1 — BLOC ANONYME
-- ############################################################

-- ============================================================
-- EXERCICE 1 : Message de bienvenue + comptages
-- Afficher un message de bienvenue et le nombre de satellites,
-- stations et missions de la base.
-- ============================================================
-- Résultat attendu :
--   === Bienvenue sur le système NanoOrbit ===
--   Nombre de satellites : 5
--   Nombre de stations   : 3
--   Nombre de missions   : 3
-- ============================================================
DECLARE
    v_nb_satellites NUMBER;
    v_nb_stations   NUMBER;
    v_nb_missions   NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_satellites FROM SATELLITE;
    SELECT COUNT(*) INTO v_nb_stations   FROM STATION_SOL;
    SELECT COUNT(*) INTO v_nb_missions   FROM MISSION;

    DBMS_OUTPUT.PUT_LINE('=== Bienvenue sur le système NanoOrbit ===');
    DBMS_OUTPUT.PUT_LINE('Nombre de satellites : ' || v_nb_satellites);
    DBMS_OUTPUT.PUT_LINE('Nombre de stations   : ' || v_nb_stations);
    DBMS_OUTPUT.PUT_LINE('Nombre de missions   : ' || v_nb_missions);
END;
/


-- ============================================================
-- EXERCICE 2 : SELECT INTO — Caractéristiques de SAT-001
-- Récupérer et afficher les caractéristiques du satellite SAT-001.
-- ============================================================
-- Résultat attendu :
--   --- Satellite SAT-001 ---
--   Nom            : NanoOrbit-Alpha
--   Format         : 3U
--   Statut         : Opérationnel
--   Batterie       : 20 Wh
--   Orbite         : 1
--   Date lancement : 15/03/2022
-- ============================================================
DECLARE
    v_id            SATELLITE.id_satellite%TYPE;
    v_nom           SATELLITE.nom_satellite%TYPE;
    v_format        SATELLITE.format_cubesat%TYPE;
    v_statut        SATELLITE.statut%TYPE;
    v_batterie      SATELLITE.capacite_batterie%TYPE;
    v_orbite        SATELLITE.id_orbite%TYPE;
    v_date          SATELLITE.date_lancement%TYPE;
BEGIN
    SELECT id_satellite, nom_satellite, format_cubesat, statut,
           capacite_batterie, id_orbite, date_lancement
    INTO   v_id, v_nom, v_format, v_statut, v_batterie, v_orbite, v_date
    FROM   SATELLITE
    WHERE  id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('--- Satellite ' || v_id || ' ---');
    DBMS_OUTPUT.PUT_LINE('Nom            : ' || v_nom);
    DBMS_OUTPUT.PUT_LINE('Format         : ' || v_format);
    DBMS_OUTPUT.PUT_LINE('Statut         : ' || v_statut);
    DBMS_OUTPUT.PUT_LINE('Batterie       : ' || v_batterie || ' Wh');
    DBMS_OUTPUT.PUT_LINE('Orbite         : ' || v_orbite);
    DBMS_OUTPUT.PUT_LINE('Date lancement : ' || TO_CHAR(v_date, 'DD/MM/YYYY'));
END;
/


-- ############################################################
--  PALIER 2 — VARIABLES ET TYPES
-- ############################################################

-- ============================================================
-- EXERCICE 3 : %ROWTYPE — Ligne complète de SATELLITE
-- Lire une ligne complète de SATELLITE avec %ROWTYPE et
-- afficher son statut et sa capacité batterie.
-- ============================================================
-- Résultat attendu :
--   --- Satellite SAT-003 (%ROWTYPE) ---
--   Nom     : NanoOrbit-Gamma
--   Statut  : Opérationnel
--   Batterie: 40 Wh
--   Format  : 6U
--   Masse   : 2 kg
-- ============================================================
DECLARE
    v_sat SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat
    FROM SATELLITE
    WHERE id_satellite = 'SAT-003';

    DBMS_OUTPUT.PUT_LINE('--- Satellite ' || v_sat.id_satellite || ' (%ROWTYPE) ---');
    DBMS_OUTPUT.PUT_LINE('Nom     : ' || v_sat.nom_satellite);
    DBMS_OUTPUT.PUT_LINE('Statut  : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Batterie: ' || v_sat.capacite_batterie || ' Wh');
    DBMS_OUTPUT.PUT_LINE('Format  : ' || v_sat.format_cubesat);
    DBMS_OUTPUT.PUT_LINE('Masse   : ' || v_sat.masse || ' kg');
END;
/


-- ============================================================
-- EXERCICE 4 : NVL — Gestion des NULL sur résolution instrument
-- Afficher la résolution de chaque instrument.
-- Pour INS-AIS-01 (résolution NULL), afficher 'N/A'.
-- ============================================================
-- Résultat attendu :
--   --- Résolution des instruments ---
--   INS-CAM-01  | Caméra optique   | Résolution : 3 m
--   INS-IR-01   | Infrarouge       | Résolution : 160 m
--   INS-AIS-01  | Récepteur AIS    | Résolution : N/A
--   INS-SPEC-01 | Spectromètre     | Résolution : 30 m
-- ============================================================
DECLARE
    v_ref       INSTRUMENT.ref_instrument%TYPE;
    v_type      INSTRUMENT.type_instrument%TYPE;
    v_resolution VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Résolution des instruments ---');
    FOR rec IN (SELECT ref_instrument, type_instrument, resolution FROM INSTRUMENT ORDER BY ref_instrument) LOOP
        v_resolution := NVL(TO_CHAR(rec.resolution), 'N/A');
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ref_instrument, 12) || '| ' ||
            RPAD(rec.type_instrument, 17) || '| Résolution : ' ||
            CASE WHEN rec.resolution IS NOT NULL THEN TO_CHAR(rec.resolution) || ' m' ELSE 'N/A' END
        );
    END LOOP;
END;
/


-- ############################################################
--  PALIER 3 — STRUCTURES DE CONTROLE
-- ############################################################

-- ============================================================
-- EXERCICE 5 : IF/ELSIF — Catégoriser un satellite
-- Catégoriser chaque satellite selon son statut et sa durée
-- de vie restante estimée.
-- ============================================================
-- Résultat attendu :
--   --- Catégorisation des satellites ---
--   SAT-001 NanoOrbit-Alpha    | Opérationnel | Durée vie: 60 mois | → En bonne santé
--   SAT-002 NanoOrbit-Beta     | Opérationnel | Durée vie: 60 mois | → En bonne santé
--   SAT-003 NanoOrbit-Gamma    | Opérationnel | Durée vie: 84 mois | → En bonne santé
--   SAT-004 NanoOrbit-Delta    | En veille    | Durée vie: 84 mois | → Surveillance requise
--   SAT-005 NanoOrbit-Epsilon  | Désorbité    | Durée vie: 36 mois | → Hors service
-- ============================================================
DECLARE
    v_categorie VARCHAR2(50);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Catégorisation des satellites ---');
    FOR rec IN (SELECT id_satellite, nom_satellite, statut, duree_vie_prevue
                FROM SATELLITE ORDER BY id_satellite) LOOP

        IF rec.statut = 'Désorbité' THEN
            v_categorie := 'Hors service';
        ELSIF rec.statut = 'Défaillant' THEN
            v_categorie := 'Maintenance urgente';
        ELSIF rec.statut = 'En veille' THEN
            v_categorie := 'Surveillance requise';
        ELSIF rec.statut = 'Opérationnel' AND rec.duree_vie_prevue > 50 THEN
            v_categorie := 'En bonne santé';
        ELSIF rec.statut = 'Opérationnel' AND rec.duree_vie_prevue <= 50 THEN
            v_categorie := 'Fin de vie approche';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.id_satellite, 8) ||
            RPAD(rec.nom_satellite, 22) || '| ' ||
            RPAD(rec.statut, 14) || '| Durée vie: ' ||
            RPAD(rec.duree_vie_prevue || ' mois', 10) || '| → ' || v_categorie
        );
    END LOOP;
END;
/


-- ============================================================
-- EXERCICE 6 : CASE — Type d'orbite + vitesse orbitale
-- Afficher le type d'orbite de SAT-001 et calculer sa vitesse
-- orbitale approximative : v = 2π × (6371 + altitude) / (période × 60)
-- Résultat en km/s.
-- ============================================================
-- Résultat attendu :
--   --- Orbite du satellite SAT-001 ---
--   Type d'orbite : SSO — Orbite héliosynchrone
--   Altitude      : 550 km
--   Période        : 95.5 min
--   Vitesse orbitale ≈ 7.19 km/s
-- ============================================================
DECLARE
    v_type_orbite  ORBITE.type_orbite%TYPE;
    v_altitude     ORBITE.altitude%TYPE;
    v_periode      ORBITE.periode_orbitale%TYPE;
    v_description  VARCHAR2(100);
    v_vitesse      NUMBER(8,2);
    c_pi           CONSTANT NUMBER := 3.14159265359;
    c_rayon_terre  CONSTANT NUMBER := 6371;
BEGIN
    SELECT o.type_orbite, o.altitude, o.periode_orbitale
    INTO   v_type_orbite, v_altitude, v_periode
    FROM   SATELLITE s
    JOIN   ORBITE o ON s.id_orbite = o.id_orbite
    WHERE  s.id_satellite = 'SAT-001';

    v_description := CASE v_type_orbite
        WHEN 'SSO' THEN 'Orbite héliosynchrone'
        WHEN 'LEO' THEN 'Orbite basse terrestre'
        WHEN 'MEO' THEN 'Orbite moyenne terrestre'
        WHEN 'GEO' THEN 'Orbite géostationnaire'
        ELSE 'Type inconnu'
    END;

    -- v = 2π × (R_terre + altitude) / (période en secondes)
    v_vitesse := (2 * c_pi * (c_rayon_terre + v_altitude)) / (v_periode * 60);

    DBMS_OUTPUT.PUT_LINE('--- Orbite du satellite SAT-001 ---');
    DBMS_OUTPUT.PUT_LINE('Type d''orbite : ' || v_type_orbite || ' — ' || v_description);
    DBMS_OUTPUT.PUT_LINE('Altitude      : ' || v_altitude || ' km');
    DBMS_OUTPUT.PUT_LINE('Période       : ' || v_periode || ' min');
    DBMS_OUTPUT.PUT_LINE('Vitesse orbitale ≈ ' || ROUND(v_vitesse, 2) || ' km/s');
END;
/


-- ============================================================
-- EXERCICE 7 : Boucle FOR — Grille des volumes de données
-- Afficher les volumes de données attendus pour des passages
-- de 5 à 15 minutes avec le débit de la station GS-TLS-01.
-- volume (Mo) = débit (Mbps) × durée (secondes) / 8
-- (division par 8 pour convertir Megabits en Megaoctets)
-- ============================================================
-- Résultat attendu :
--   --- Grille volumes — Station GS-TLS-01 (débit: 150 Mbps) ---
--    5 min (300s)  →  5625.00 Mo
--    6 min (360s)  →  6750.00 Mo
--    7 min (420s)  →  7875.00 Mo
--    8 min (480s)  →  9000.00 Mo
--    9 min (540s)  → 10125.00 Mo
--   10 min (600s)  → 11250.00 Mo
--   11 min (660s)  → 12375.00 Mo
--   12 min (720s)  → 13500.00 Mo
--   13 min (780s)  → 14625.00 Mo
--   14 min (840s)  → 15750.00 Mo
--   15 min (900s)  → 16875.00 Mo
-- ============================================================
DECLARE
    v_debit   STATION_SOL.debit_max%TYPE;
    v_volume  NUMBER(12,2);
    v_duree_s NUMBER;
BEGIN
    SELECT debit_max INTO v_debit
    FROM STATION_SOL
    WHERE code_station = 'GS-TLS-01';

    DBMS_OUTPUT.PUT_LINE('--- Grille volumes — Station GS-TLS-01 (débit: ' || v_debit || ' Mbps) ---');

    FOR i IN 5..15 LOOP
        v_duree_s := i * 60;
        v_volume  := v_debit * v_duree_s / 8;
        DBMS_OUTPUT.PUT_LINE(
            LPAD(i, 3) || ' min (' || v_duree_s || 's)  → ' ||
            LPAD(TO_CHAR(v_volume, '99999.00'), 10) || ' Mo'
        );
    END LOOP;
END;
/


-- ############################################################
--  PALIER 4 — CURSEURS
-- ############################################################

-- ============================================================
-- EXERCICE 8 : SQL%ROWCOUNT — Mise à jour de statuts
-- Mettre à jour les satellites 'En veille' → 'Opérationnel'
-- et afficher le nombre de lignes modifiées.
-- ROLLBACK à la fin pour ne pas altérer les données.
-- ============================================================
-- Résultat attendu :
--   --- Mise à jour des statuts ---
--   UPDATE En veille → Opérationnel
--   Nombre de satellites mis à jour : 1
--   (ROLLBACK effectué — données restaurées)
-- ============================================================
BEGIN
    UPDATE SATELLITE
    SET statut = 'Opérationnel'
    WHERE statut = 'En veille';

    DBMS_OUTPUT.PUT_LINE('--- Mise à jour des statuts ---');
    DBMS_OUTPUT.PUT_LINE('UPDATE En veille → Opérationnel');
    DBMS_OUTPUT.PUT_LINE('Nombre de satellites mis à jour : ' || SQL%ROWCOUNT);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('(ROLLBACK effectué — données restaurées)');
END;
/


-- ============================================================
-- EXERCICE 9 : Cursor FOR Loop — Satellites avec orbite et instruments
-- Lister tous les satellites avec leur orbite, leur statut et
-- leurs instruments embarqués.
-- ============================================================
-- Résultat attendu :
--   --- Liste des satellites avec orbite et instruments ---
--   SAT-001 | NanoOrbit-Alpha   | Opérationnel | SSO 550km
--     → INS-CAM-01 (Caméra optique) — Nominal
--     → INS-IR-01 (Infrarouge) — Nominal
--   SAT-002 | NanoOrbit-Beta    | Opérationnel | SSO 550km
--     → INS-CAM-01 (Caméra optique) — Nominal
--   SAT-003 | NanoOrbit-Gamma   | Opérationnel | SSO 700km
--     → INS-CAM-01 (Caméra optique) — Nominal
--     → INS-SPEC-01 (Spectromètre) — Nominal
--   SAT-004 | NanoOrbit-Delta   | En veille    | SSO 700km
--     → INS-IR-01 (Infrarouge) — Dégradé
--   SAT-005 | NanoOrbit-Epsilon | Désorbité    | LEO 400km
--     → INS-AIS-01 (Récepteur AIS) — Hors service
-- ============================================================
DECLARE
    CURSOR c_satellites IS
        SELECT s.id_satellite, s.nom_satellite, s.statut,
               o.type_orbite, o.altitude
        FROM SATELLITE s
        JOIN ORBITE o ON s.id_orbite = o.id_orbite
        ORDER BY s.id_satellite;

    CURSOR c_instruments(p_id_sat VARCHAR2) IS
        SELECT i.ref_instrument, i.type_instrument, e.etat_fonctionnement
        FROM EMBARQUEMENT e
        JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
        WHERE e.id_satellite = p_id_sat
        ORDER BY i.ref_instrument;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Liste des satellites avec orbite et instruments ---');

    FOR sat IN c_satellites LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(sat.id_satellite, 8) || '| ' ||
            RPAD(sat.nom_satellite, 22) || '| ' ||
            RPAD(sat.statut, 14) || '| ' ||
            sat.type_orbite || ' ' || sat.altitude || 'km'
        );

        FOR ins IN c_instruments(sat.id_satellite) LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  → ' || ins.ref_instrument ||
                ' (' || ins.type_instrument || ') — ' ||
                ins.etat_fonctionnement
            );
        END LOOP;
    END LOOP;
END;
/


-- ============================================================
-- EXERCICE 10 : OPEN/FETCH/CLOSE — Satellites opérationnels
-- avec leur fenêtre de communication la plus récente (Réalisée).
-- ============================================================
-- Résultat attendu :
--   --- Satellites opérationnels — dernière fenêtre réalisée ---
--   SAT-001 | NanoOrbit-Alpha | Dernière fenêtre: 15/01/2024 09:14 sur GS-KIR-01 (1250 Mo)
--   SAT-002 | NanoOrbit-Beta  | Dernière fenêtre: 15/01/2024 11:52 sur GS-TLS-01 (890 Mo)
--   SAT-003 | NanoOrbit-Gamma | Dernière fenêtre: 16/01/2024 08:30 sur GS-KIR-01 (1680 Mo)
-- ============================================================
DECLARE
    CURSOR c_sat_op IS
        SELECT s.id_satellite, s.nom_satellite
        FROM SATELLITE s
        WHERE s.statut = 'Opérationnel'
        ORDER BY s.id_satellite;

    v_sat       c_sat_op%ROWTYPE;
    v_date_fen  FENETRE_COM.datetime_debut%TYPE;
    v_station   FENETRE_COM.code_station%TYPE;
    v_volume    FENETRE_COM.volume_donnees%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Satellites opérationnels — dernière fenêtre réalisée ---');

    OPEN c_sat_op;
    LOOP
        FETCH c_sat_op INTO v_sat;
        EXIT WHEN c_sat_op%NOTFOUND;

        -- Rechercher la fenêtre réalisée la plus récente
        BEGIN
            SELECT datetime_debut, code_station, volume_donnees
            INTO   v_date_fen, v_station, v_volume
            FROM   FENETRE_COM
            WHERE  id_satellite = v_sat.id_satellite
              AND  statut = 'Réalisée'
              AND  datetime_debut = (
                  SELECT MAX(datetime_debut)
                  FROM FENETRE_COM
                  WHERE id_satellite = v_sat.id_satellite
                    AND statut = 'Réalisée'
              );

            DBMS_OUTPUT.PUT_LINE(
                RPAD(v_sat.id_satellite, 8) || '| ' ||
                RPAD(v_sat.nom_satellite, 20) || '| Dernière fenêtre: ' ||
                TO_CHAR(v_date_fen, 'DD/MM/YYYY HH24:MI') ||
                ' sur ' || v_station || ' (' || v_volume || ' Mo)'
            );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(
                    RPAD(v_sat.id_satellite, 8) || '| ' ||
                    RPAD(v_sat.nom_satellite, 20) || '| Aucune fenêtre réalisée'
                );
        END;
    END LOOP;
    CLOSE c_sat_op;
END;
/


-- ============================================================
-- EXERCICE 11 : Curseur paramétré — Fenêtres d'une station
-- Afficher les fenêtres de communication de GS-KIR-01
-- avec le volume total téléchargé.
-- ============================================================
-- Résultat attendu :
--   --- Fenêtres de la station GS-KIR-01 ---
--   FEN 1 | SAT-001 | 15/01/2024 09:14 | 420s | Réalisée  | 1250 Mo
--   FEN 3 | SAT-003 | 16/01/2024 08:30 | 540s | Réalisée  | 1680 Mo
--   ---
--   Volume total téléchargé (Réalisée) : 2930 Mo
-- ============================================================
DECLARE
    CURSOR c_fenetres(p_station VARCHAR2) IS
        SELECT f.id_fenetre, f.id_satellite, f.datetime_debut,
               f.duree, f.statut, f.volume_donnees
        FROM FENETRE_COM f
        WHERE f.code_station = p_station
        ORDER BY f.datetime_debut;

    v_total_volume NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Fenêtres de la station GS-KIR-01 ---');

    FOR fen IN c_fenetres('GS-KIR-01') LOOP
        DBMS_OUTPUT.PUT_LINE(
            'FEN ' || RPAD(fen.id_fenetre, 3) || '| ' ||
            RPAD(fen.id_satellite, 8) || '| ' ||
            TO_CHAR(fen.datetime_debut, 'DD/MM/YYYY HH24:MI') || ' | ' ||
            RPAD(fen.duree || 's', 5) || '| ' ||
            RPAD(fen.statut, 10) || '| ' ||
            NVL(TO_CHAR(fen.volume_donnees), '-') || ' Mo'
        );

        IF fen.statut = 'Réalisée' AND fen.volume_donnees IS NOT NULL THEN
            v_total_volume := v_total_volume + fen.volume_donnees;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('---');
    DBMS_OUTPUT.PUT_LINE('Volume total téléchargé (Réalisée) : ' || v_total_volume || ' Mo');
END;
/


-- ############################################################
--  PALIER 5 — PROCEDURES ET FONCTIONS STANDALONE
-- ############################################################

-- ============================================================
-- EXERCICE 12 : Exceptions prédéfinies — SELECT INTO sécurisé
-- Rechercher un satellite inexistant 'SAT-999' et gérer
-- NO_DATA_FOUND et OTHERS.
-- ============================================================
-- Résultat attendu :
--   --- Test exceptions sur SATELLITE ---
--   Test 1 (SAT-001) : Trouvé — NanoOrbit-Alpha (Opérationnel)
--   Test 2 (SAT-999) : ERREUR — Aucun satellite trouvé avec l'ID SAT-999
-- ============================================================
DECLARE
    v_nom    SATELLITE.nom_satellite%TYPE;
    v_statut SATELLITE.statut%TYPE;

    PROCEDURE chercher_satellite(p_id IN VARCHAR2) IS
    BEGIN
        SELECT nom_satellite, statut
        INTO   v_nom, v_statut
        FROM   SATELLITE
        WHERE  id_satellite = p_id;

        DBMS_OUTPUT.PUT_LINE('Test (' || p_id || ') : Trouvé — ' || v_nom || ' (' || v_statut || ')');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test (' || p_id || ') : ERREUR — Aucun satellite trouvé avec l''ID ' || p_id);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test (' || p_id || ') : ERREUR INATTENDUE — ' || SQLERRM);
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test exceptions sur SATELLITE ---');
    chercher_satellite('SAT-001');
    chercher_satellite('SAT-999');
END;
/


-- ============================================================
-- EXERCICE 13 : RAISE_APPLICATION_ERROR — Validation fenêtre
-- Valider les conditions avant insertion d'une fenêtre de
-- communication : satellite opérationnel, station active,
-- pas de chevauchement.
-- ============================================================
-- Résultat attendu :
--   --- Validation fenêtre de communication ---
--   Test 1 (SAT-001, GS-KIR-01, 2024-06-01) : Validation OK — insertion autorisée
--   Test 2 (SAT-005, GS-KIR-01, 2024-06-01) : ORA-20010 — Satellite SAT-005 non opérationnel (statut: Désorbité)
--   Test 3 (SAT-001, GS-SGP-01, 2024-06-01) : ORA-20011 — Station GS-SGP-01 non active (statut: Maintenance)
-- ============================================================
DECLARE
    PROCEDURE valider_fenetre(
        p_id_satellite IN VARCHAR2,
        p_code_station IN VARCHAR2,
        p_datetime     IN TIMESTAMP,
        p_duree        IN NUMBER
    ) IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_sta STATION_SOL.statut%TYPE;
        v_count      NUMBER;
    BEGIN
        -- Vérifier le satellite
        SELECT statut INTO v_statut_sat
        FROM SATELLITE WHERE id_satellite = p_id_satellite;

        IF v_statut_sat != 'Opérationnel' THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Satellite ' || p_id_satellite || ' non opérationnel (statut: ' || v_statut_sat || ')');
        END IF;

        -- Vérifier la station
        SELECT statut INTO v_statut_sta
        FROM STATION_SOL WHERE code_station = p_code_station;

        IF v_statut_sta != 'Active' THEN
            RAISE_APPLICATION_ERROR(-20011,
                'Station ' || p_code_station || ' non active (statut: ' || v_statut_sta || ')');
        END IF;

        -- Vérifier le chevauchement
        SELECT COUNT(*) INTO v_count
        FROM FENETRE_COM
        WHERE id_satellite = p_id_satellite
          AND datetime_debut < p_datetime + NUMTODSINTERVAL(p_duree, 'SECOND')
          AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > p_datetime;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Chevauchement détecté pour le satellite ' || p_id_satellite);
        END IF;

        DBMS_OUTPUT.PUT_LINE('Validation OK — insertion autorisée');
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Validation fenêtre de communication ---');

    -- Test 1 : tout OK
    DBMS_OUTPUT.PUT('Test 1 (SAT-001, GS-KIR-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;

    -- Test 2 : satellite désorbité
    DBMS_OUTPUT.PUT('Test 2 (SAT-005, GS-KIR-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-005', 'GS-KIR-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;

    -- Test 3 : station en maintenance
    DBMS_OUTPUT.PUT('Test 3 (SAT-001, GS-SGP-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-001', 'GS-SGP-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
END;
/


-- ============================================================
-- EXERCICE 14 : Procédure — afficher_statut_satellite
-- Affiche le statut, l'orbite et les instruments du satellite.
-- ============================================================
-- Résultat attendu (appel avec SAT-001) :
--   === Statut du satellite SAT-001 ===
--   Nom    : NanoOrbit-Alpha
--   Statut : Opérationnel
--   Orbite : SSO — 550 km (période: 95.5 min)
--   Instruments embarqués :
--     1. INS-CAM-01 (Caméra optique) — Nominal
--     2. INS-IR-01 (Infrarouge) — Nominal
-- ============================================================
CREATE OR REPLACE PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2)
IS
    v_nom       SATELLITE.nom_satellite%TYPE;
    v_statut    SATELLITE.statut%TYPE;
    v_type_orb  ORBITE.type_orbite%TYPE;
    v_altitude  ORBITE.altitude%TYPE;
    v_periode   ORBITE.periode_orbitale%TYPE;
    v_compteur  NUMBER := 0;

    CURSOR c_instruments IS
        SELECT i.ref_instrument, i.type_instrument, e.etat_fonctionnement
        FROM EMBARQUEMENT e
        JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
        WHERE e.id_satellite = p_id
        ORDER BY i.ref_instrument;
BEGIN
    SELECT s.nom_satellite, s.statut, o.type_orbite, o.altitude, o.periode_orbitale
    INTO   v_nom, v_statut, v_type_orb, v_altitude, v_periode
    FROM   SATELLITE s
    JOIN   ORBITE o ON s.id_orbite = o.id_orbite
    WHERE  s.id_satellite = p_id;

    DBMS_OUTPUT.PUT_LINE('=== Statut du satellite ' || p_id || ' ===');
    DBMS_OUTPUT.PUT_LINE('Nom    : ' || v_nom);
    DBMS_OUTPUT.PUT_LINE('Statut : ' || v_statut);
    DBMS_OUTPUT.PUT_LINE('Orbite : ' || v_type_orb || ' — ' || v_altitude || ' km (période: ' || v_periode || ' min)');
    DBMS_OUTPUT.PUT_LINE('Instruments embarqués :');

    FOR ins IN c_instruments LOOP
        v_compteur := v_compteur + 1;
        DBMS_OUTPUT.PUT_LINE('  ' || v_compteur || '. ' || ins.ref_instrument ||
            ' (' || ins.type_instrument || ') — ' || ins.etat_fonctionnement);
    END LOOP;

    IF v_compteur = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (aucun instrument embarqué)');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR — Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS PROCEDURE afficher_statut_satellite;

-- Test de la procédure
BEGIN
    afficher_statut_satellite('SAT-001');
    DBMS_OUTPUT.PUT_LINE('');
    afficher_statut_satellite('SAT-005');
END;
/


-- ============================================================
-- EXERCICE 15 : Procédure — mettre_a_jour_statut
-- Met à jour le statut d'un satellite et retourne l'ancien
-- statut via un paramètre OUT.
-- ROLLBACK à la fin pour ne pas altérer les données.
-- ============================================================
-- Résultat attendu :
--   --- Mise à jour statut SAT-004 ---
--   Ancien statut : En veille
--   Nouveau statut: Opérationnel
--   (ROLLBACK effectué)
-- ============================================================
CREATE OR REPLACE PROCEDURE mettre_a_jour_statut(
    p_id            IN  VARCHAR2,
    p_statut        IN  VARCHAR2,
    p_ancien_statut OUT VARCHAR2
)
IS
BEGIN
    -- Récupérer l'ancien statut
    SELECT statut INTO p_ancien_statut
    FROM SATELLITE
    WHERE id_satellite = p_id;

    -- Mettre à jour
    UPDATE SATELLITE
    SET statut = p_statut
    WHERE id_satellite = p_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Satellite ' || p_id || ' introuvable.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Statut de ' || p_id || ' mis à jour : ' || p_ancien_statut || ' → ' || p_statut);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS PROCEDURE mettre_a_jour_statut;

-- Test de la procédure
DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Mise à jour statut SAT-004 ---');
    mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut : ' || v_ancien);
    DBMS_OUTPUT.PUT_LINE('Nouveau statut: Opérationnel');

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('(ROLLBACK effectué)');
END;
/


-- ============================================================
-- EXERCICE 16 : Fonction — calculer_volume_session
-- Retourne le volume théorique d'une fenêtre de communication :
-- volume = debit_max (Mbps) × duree (s) / 8  (résultat en Mo)
-- ============================================================
-- Résultat attendu :
--   --- Test calculer_volume_session ---
--   Fenêtre 1 : volume théorique = 21000 Mo (GS-KIR-01, 400 Mbps × 420s / 8)
--   Fenêtre 2 : volume théorique = 5812.5 Mo (GS-TLS-01, 150 Mbps × 310s / 8)
-- ============================================================
CREATE OR REPLACE FUNCTION calculer_volume_session(
    p_id_fenetre IN VARCHAR2
) RETURN NUMBER
IS
    v_debit  STATION_SOL.debit_max%TYPE;
    v_duree  FENETRE_COM.duree%TYPE;
    v_volume NUMBER;
BEGIN
    SELECT st.debit_max, f.duree
    INTO   v_debit, v_duree
    FROM   FENETRE_COM f
    JOIN   STATION_SOL st ON f.code_station = st.code_station
    WHERE  f.id_fenetre = p_id_fenetre;

    v_volume := v_debit * v_duree / 8;
    RETURN v_volume;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'Fenêtre ' || p_id_fenetre || ' introuvable.');
END;
/
SHOW ERRORS FUNCTION calculer_volume_session;

-- Test de la fonction
DECLARE
    v_vol NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test calculer_volume_session ---');

    v_vol := calculer_volume_session('1');
    DBMS_OUTPUT.PUT_LINE('Fenêtre 1 : volume théorique = ' || v_vol || ' Mo (GS-KIR-01, 400 Mbps × 420s / 8)');

    v_vol := calculer_volume_session('2');
    DBMS_OUTPUT.PUT_LINE('Fenêtre 2 : volume théorique = ' || v_vol || ' Mo (GS-TLS-01, 150 Mbps × 310s / 8)');
END;
/


-- ============================================================
-- RÉSUMÉ DES LIVRABLES PALIERS 1–5
-- ============================================================
-- Palier 1 : Ex. 1 (comptages), Ex. 2 (SELECT INTO)
-- Palier 2 : Ex. 3 (%ROWTYPE), Ex. 4 (NVL)
-- Palier 3 : Ex. 5 (IF/ELSIF), Ex. 6 (CASE + vitesse), Ex. 7 (FOR)
-- Palier 4 : Ex. 8 (ROWCOUNT), Ex. 9 (Cursor FOR), Ex. 10 (OPEN/FETCH), Ex. 11 (paramétré)
-- Palier 5 : Ex. 12 (exceptions), Ex. 13 (RAISE), Ex. 14 (proc afficher), Ex. 15 (proc MAJ), Ex. 16 (fonction volume)
-- ============================================================
