SET SERVEROUTPUT ON;

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

    v_vitesse := (2 * c_pi * (c_rayon_terre + v_altitude)) / (v_periode * 60);

    DBMS_OUTPUT.PUT_LINE('--- Orbite du satellite SAT-001 ---');
    DBMS_OUTPUT.PUT_LINE('Type d''orbite : ' || v_type_orbite || ' — ' || v_description);
    DBMS_OUTPUT.PUT_LINE('Altitude      : ' || v_altitude || ' km');
    DBMS_OUTPUT.PUT_LINE('Période       : ' || v_periode || ' min');
    DBMS_OUTPUT.PUT_LINE('Vitesse orbitale ≈ ' || ROUND(v_vitesse, 2) || ' km/s');
END;
/

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
        SELECT statut INTO v_statut_sat
        FROM SATELLITE WHERE id_satellite = p_id_satellite;

        IF v_statut_sat != 'Opérationnel' THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Satellite ' || p_id_satellite || ' non opérationnel (statut: ' || v_statut_sat || ')');
        END IF;

        SELECT statut INTO v_statut_sta
        FROM STATION_SOL WHERE code_station = p_code_station;

        IF v_statut_sta != 'Active' THEN
            RAISE_APPLICATION_ERROR(-20011,
                'Station ' || p_code_station || ' non active (statut: ' || v_statut_sta || ')');
        END IF;

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

    DBMS_OUTPUT.PUT('Test 1 (SAT-001, GS-KIR-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;

    DBMS_OUTPUT.PUT('Test 2 (SAT-005, GS-KIR-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-005', 'GS-KIR-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;

    DBMS_OUTPUT.PUT('Test 3 (SAT-001, GS-SGP-01, 2024-06-01) : ');
    BEGIN
        valider_fenetre('SAT-001', 'GS-SGP-01', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
END;
/


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

BEGIN
    afficher_statut_satellite('SAT-001');
    DBMS_OUTPUT.PUT_LINE('');
    afficher_statut_satellite('SAT-005');
END;
/


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