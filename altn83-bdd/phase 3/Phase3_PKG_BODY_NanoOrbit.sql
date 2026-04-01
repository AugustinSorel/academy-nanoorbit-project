-- ============================================================
-- PROJET NANOORBIT — PHASE 3 — L3-C : PACKAGE BODY
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Package pkg_nanoOrbit — Corps (BODY)
-- Implémentation de toutes les procédures et fonctions
-- ============================================================

CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS

    -- ==============================================================
    -- FONCTION PRIVEE : description du type d'orbite
    -- ==============================================================
    FUNCTION description_orbite(p_type IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN CASE p_type
            WHEN 'SSO' THEN 'Orbite héliosynchrone'
            WHEN 'LEO' THEN 'Orbite basse terrestre'
            WHEN 'MEO' THEN 'Orbite moyenne terrestre'
            WHEN 'GEO' THEN 'Orbite géostationnaire'
            ELSE 'Type inconnu'
        END;
    END description_orbite;


    -- ==============================================================
    -- PROCEDURE : afficher_statut_satellite (Ex.14)
    -- ==============================================================
    PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2)
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
        DBMS_OUTPUT.PUT_LINE('Orbite : ' || v_type_orb || ' — '
            || description_orbite(v_type_orb));
        DBMS_OUTPUT.PUT_LINE('         Altitude: ' || v_altitude || ' km | Période: '
            || v_periode || ' min');
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
    END afficher_statut_satellite;


    -- ==============================================================
    -- PROCEDURE : mettre_a_jour_statut (Ex.15)
    -- ==============================================================
    PROCEDURE mettre_a_jour_statut(
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

        DBMS_OUTPUT.PUT_LINE('Statut de ' || p_id || ' mis à jour : '
            || p_ancien_statut || ' → ' || p_statut);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020, 'Satellite ' || p_id || ' introuvable.');
    END mettre_a_jour_statut;


    -- ==============================================================
    -- PROCEDURE : rapport_flotte
    -- Affiche un rapport complet de tous les satellites
    -- ==============================================================
    PROCEDURE rapport_flotte
    IS
        v_total       NUMBER := 0;
        v_operationnels NUMBER := 0;
        v_nb_ins      NUMBER;

        CURSOR c_flotte IS
            SELECT s.id_satellite, s.nom_satellite, s.statut,
                   s.format_cubesat, s.masse,
                   o.type_orbite, o.altitude
            FROM SATELLITE s
            JOIN ORBITE o ON s.id_orbite = o.id_orbite
            ORDER BY s.id_satellite;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('  RAPPORT DE FLOTTE NANOORBIT');
        DBMS_OUTPUT.PUT_LINE('========================================');

        FOR sat IN c_flotte LOOP
            v_total := v_total + 1;
            IF sat.statut = 'Opérationnel' THEN
                v_operationnels := v_operationnels + 1;
            END IF;

            v_nb_ins := nb_instruments(sat.id_satellite);

            DBMS_OUTPUT.PUT_LINE(
                RPAD(sat.id_satellite, 8) || '| ' ||
                RPAD(sat.nom_satellite, 22) || '| ' ||
                RPAD(sat.statut, 14) || '| ' ||
                sat.format_cubesat || ' ' || sat.masse || 'kg | ' ||
                sat.type_orbite || ' ' || sat.altitude || 'km | ' ||
                v_nb_ins || ' instrument(s)'
            );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Total : ' || v_total || ' satellites dont '
            || v_operationnels || ' opérationnels');
        DBMS_OUTPUT.PUT_LINE('========================================');
    END rapport_flotte;


    -- ==============================================================
    -- PROCEDURE : rapport_station
    -- Affiche les fenêtres d'une station avec volume total
    -- ==============================================================
    PROCEDURE rapport_station(p_code_station IN VARCHAR2)
    IS
        v_nom_station   STATION_SOL.nom_station%TYPE;
        v_debit         STATION_SOL.debit_max%TYPE;
        v_bande         STATION_SOL.bande_frequence%TYPE;
        v_total_volume  NUMBER := 0;
        v_nb_fenetres   NUMBER := 0;

        CURSOR c_fenetres IS
            SELECT f.id_fenetre, f.id_satellite, f.datetime_debut,
                   f.duree, f.statut, f.volume_donnees
            FROM FENETRE_COM f
            WHERE f.code_station = p_code_station
            ORDER BY f.datetime_debut;
    BEGIN
        SELECT nom_station, debit_max, bande_frequence
        INTO   v_nom_station, v_debit, v_bande
        FROM   STATION_SOL
        WHERE  code_station = p_code_station;

        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('  RAPPORT STATION : ' || p_code_station);
        DBMS_OUTPUT.PUT_LINE('  ' || v_nom_station || ' | Bande ' || v_bande
            || ' | Débit max: ' || v_debit || ' Mbps');
        DBMS_OUTPUT.PUT_LINE('========================================');

        FOR fen IN c_fenetres LOOP
            v_nb_fenetres := v_nb_fenetres + 1;
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

        IF v_nb_fenetres = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  (aucune fenêtre enregistrée)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Total fenêtres : ' || v_nb_fenetres
                || ' | Volume téléchargé (Réalisée) : ' || v_total_volume || ' Mo');
        END IF;
        DBMS_OUTPUT.PUT_LINE('========================================');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERREUR — Station ' || p_code_station || ' introuvable.');
    END rapport_station;


    -- ==============================================================
    -- PROCEDURE : valider_fenetre (Ex.13 intégré au package)
    -- ==============================================================
    PROCEDURE valider_fenetre(
        p_id_satellite IN VARCHAR2,
        p_code_station IN VARCHAR2,
        p_datetime     IN TIMESTAMP,
        p_duree        IN NUMBER
    )
    IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_sta STATION_SOL.statut%TYPE;
        v_count      NUMBER;
    BEGIN
        -- Vérifier le satellite
        SELECT statut INTO v_statut_sat
        FROM SATELLITE WHERE id_satellite = p_id_satellite;

        IF v_statut_sat != 'Opérationnel' THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Satellite ' || p_id_satellite
                || ' non opérationnel (statut: ' || v_statut_sat || ')');
        END IF;

        -- Vérifier la station
        SELECT statut INTO v_statut_sta
        FROM STATION_SOL WHERE code_station = p_code_station;

        IF v_statut_sta != 'Active' THEN
            RAISE_APPLICATION_ERROR(-20011,
                'Station ' || p_code_station
                || ' non active (statut: ' || v_statut_sta || ')');
        END IF;

        -- Vérifier le chevauchement sur le satellite
        SELECT COUNT(*) INTO v_count
        FROM FENETRE_COM
        WHERE id_satellite = p_id_satellite
          AND datetime_debut < p_datetime + NUMTODSINTERVAL(p_duree, 'SECOND')
          AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > p_datetime;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Chevauchement détecté pour le satellite ' || p_id_satellite);
        END IF;

        -- Vérifier le chevauchement sur la station
        SELECT COUNT(*) INTO v_count
        FROM FENETRE_COM
        WHERE code_station = p_code_station
          AND datetime_debut < p_datetime + NUMTODSINTERVAL(p_duree, 'SECOND')
          AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > p_datetime;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20013,
                'Chevauchement détecté pour la station ' || p_code_station);
        END IF;

        DBMS_OUTPUT.PUT_LINE('Validation OK — insertion autorisée pour '
            || p_id_satellite || ' / ' || p_code_station);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014,
                'Satellite ou station introuvable.');
    END valider_fenetre;


    -- ==============================================================
    -- FONCTION : calculer_volume_session (Ex.16)
    -- volume = debit_max (Mbps) × duree (s) / 8  → Mo
    -- ==============================================================
    FUNCTION calculer_volume_session(p_id_fenetre IN VARCHAR2) RETURN NUMBER
    IS
        v_debit  STATION_SOL.debit_max%TYPE;
        v_duree  FENETRE_COM.duree%TYPE;
    BEGIN
        SELECT st.debit_max, f.duree
        INTO   v_debit, v_duree
        FROM   FENETRE_COM f
        JOIN   STATION_SOL st ON f.code_station = st.code_station
        WHERE  f.id_fenetre = p_id_fenetre;

        RETURN v_debit * v_duree / 8;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030,
                'Fenêtre ' || p_id_fenetre || ' introuvable.');
    END calculer_volume_session;


    -- ==============================================================
    -- FONCTION : vitesse_orbitale (Ex.6)
    -- v = 2π × (R_terre + altitude) / (période × 60)  → km/s
    -- ==============================================================
    FUNCTION vitesse_orbitale(p_id_satellite IN VARCHAR2) RETURN NUMBER
    IS
        v_altitude ORBITE.altitude%TYPE;
        v_periode  ORBITE.periode_orbitale%TYPE;
    BEGIN
        SELECT o.altitude, o.periode_orbitale
        INTO   v_altitude, v_periode
        FROM   SATELLITE s
        JOIN   ORBITE o ON s.id_orbite = o.id_orbite
        WHERE  s.id_satellite = p_id_satellite;

        RETURN ROUND((2 * c_pi * (c_rayon_terre + v_altitude)) / (v_periode * 60), 2);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20031,
                'Satellite ' || p_id_satellite || ' introuvable.');
    END vitesse_orbitale;


    -- ==============================================================
    -- FONCTION : nb_instruments
    -- Retourne le nombre d'instruments embarqués
    -- ==============================================================
    FUNCTION nb_instruments(p_id_satellite IN VARCHAR2) RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM EMBARQUEMENT
        WHERE id_satellite = p_id_satellite;

        RETURN v_count;
    END nb_instruments;


    -- ==============================================================
    -- FONCTION : get_resume_satellite
    -- Retourne un record résumé d'un satellite
    -- ==============================================================
    FUNCTION get_resume_satellite(p_id IN VARCHAR2) RETURN t_resume_satellite
    IS
        v_resume t_resume_satellite;
    BEGIN
        SELECT s.id_satellite, s.nom_satellite, s.statut,
               o.type_orbite, o.altitude
        INTO   v_resume.id_satellite, v_resume.nom_satellite, v_resume.statut,
               v_resume.type_orbite, v_resume.altitude
        FROM   SATELLITE s
        JOIN   ORBITE o ON s.id_orbite = o.id_orbite
        WHERE  s.id_satellite = p_id;

        v_resume.nb_instruments := nb_instruments(p_id);

        RETURN v_resume;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20032,
                'Satellite ' || p_id || ' introuvable.');
    END get_resume_satellite;

END pkg_nanoOrbit;
/

SHOW ERRORS PACKAGE BODY pkg_nanoOrbit;
