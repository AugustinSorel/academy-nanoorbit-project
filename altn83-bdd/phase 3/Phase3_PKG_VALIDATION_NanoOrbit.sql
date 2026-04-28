SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 1 : afficher_statut_satellite(SAT-001)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-001');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 2 : afficher_statut_satellite(SAT-005)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-005');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 3 : afficher_statut_satellite(SAT-999)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-999');
END;
/

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 4 : mettre_a_jour_statut(SAT-004, Opérationnel)');
    DBMS_OUTPUT.PUT_LINE('');

    pkg_nanoOrbit.mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut récupéré (OUT) : ' || v_ancien);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('(ROLLBACK effectué)');
END;
/

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 5 : mettre_a_jour_statut(SAT-999, ...)');
    DBMS_OUTPUT.PUT_LINE('');

    pkg_nanoOrbit.mettre_a_jour_statut('SAT-999', 'Opérationnel', v_ancien);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exception capturée : ' || SQLERRM);
        ROLLBACK;
END;
/

DECLARE
    v_vol NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 6 : calculer_volume_session');
    DBMS_OUTPUT.PUT_LINE('');

    v_vol := pkg_nanoOrbit.calculer_volume_session('1');
    DBMS_OUTPUT.PUT_LINE('Fenêtre 1 : volume = ' || v_vol || ' Mo (GS-KIR-01, 400 Mbps x 420s / 8)');

    v_vol := pkg_nanoOrbit.calculer_volume_session('2');
    DBMS_OUTPUT.PUT_LINE('Fenêtre 2 : volume = ' || v_vol || ' Mo (GS-TLS-01, 150 Mbps x 310s / 8)');

    v_vol := pkg_nanoOrbit.calculer_volume_session('3');
    DBMS_OUTPUT.PUT_LINE('Fenêtre 3 : volume = ' || v_vol || ' Mo (GS-KIR-01, 400 Mbps x 540s / 8)');
END;
/

DECLARE
    v_vol NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 7 : calculer_volume_session(FEN-999)');
    DBMS_OUTPUT.PUT_LINE('');

    v_vol := pkg_nanoOrbit.calculer_volume_session('FEN-999');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exception capturée : ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 8 : vitesse_orbitale — tous les satellites');
    DBMS_OUTPUT.PUT_LINE('');

    FOR sat IN (SELECT id_satellite FROM SATELLITE ORDER BY id_satellite) LOOP
        DBMS_OUTPUT.PUT_LINE(
            sat.id_satellite || ' : v = '
            || pkg_nanoOrbit.vitesse_orbitale(sat.id_satellite) || ' km/s'
        );
    END LOOP;
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 9 : nb_instruments');
    DBMS_OUTPUT.PUT_LINE('');

    FOR sat IN (SELECT id_satellite FROM SATELLITE ORDER BY id_satellite) LOOP
        DBMS_OUTPUT.PUT_LINE(
            sat.id_satellite || ' : '
            || pkg_nanoOrbit.nb_instruments(sat.id_satellite)
            || ' instrument(s)'
        );
    END LOOP;
END;
/

DECLARE
    v_resume pkg_nanoOrbit.t_resume_satellite;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 10 : get_resume_satellite(SAT-003)');
    DBMS_OUTPUT.PUT_LINE('');

    v_resume := pkg_nanoOrbit.get_resume_satellite('SAT-003');

    DBMS_OUTPUT.PUT_LINE('Résumé ' || v_resume.id_satellite || ' :');
    DBMS_OUTPUT.PUT_LINE('  ID     : ' || v_resume.id_satellite);
    DBMS_OUTPUT.PUT_LINE('  Nom    : ' || v_resume.nom_satellite);
    DBMS_OUTPUT.PUT_LINE('  Statut : ' || v_resume.statut);
    DBMS_OUTPUT.PUT_LINE('  Orbite : ' || v_resume.type_orbite || ' à '
        || v_resume.altitude || ' km');
    DBMS_OUTPUT.PUT_LINE('  Instruments : ' || v_resume.nb_instruments);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 11 : valider_fenetre — cas valide');
    DBMS_OUTPUT.PUT_LINE('');

    pkg_nanoOrbit.valider_fenetre(
        'SAT-001', 'GS-KIR-01',
        TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300
    );
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 12 : valider_fenetre — satellite désorbité');
    DBMS_OUTPUT.PUT_LINE('');

    pkg_nanoOrbit.valider_fenetre(
        'SAT-005', 'GS-KIR-01',
        TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exception capturée : ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 13 : valider_fenetre — station maintenance');
    DBMS_OUTPUT.PUT_LINE('');

    pkg_nanoOrbit.valider_fenetre(
        'SAT-001', 'GS-SGP-01',
        TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exception capturée : ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 14 : rapport_flotte');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_flotte;
END;
/


BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 15 : rapport_station(GS-KIR-01)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-KIR-01');
END;
/


BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 16 : rapport_station(GS-TLS-01)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-TLS-01');
END;
/


BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 17 : rapport_station(GS-XXX-01) — inexistante');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-XXX-01');
END;
/


DECLARE
    v_ancien VARCHAR2(30);
    v_vol    NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 18 : Scénario opérationnel complet');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== SCENARIO OPERATIONNEL COMPLET ===');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('[Étape 1 : Consultation satellite SAT-003]');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-003');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('[Étape 2 : Validation fenêtre]');
    pkg_nanoOrbit.valider_fenetre(
        'SAT-003', 'GS-KIR-01',
        TO_TIMESTAMP('2024-07-01 12:00:00','YYYY-MM-DD HH24:MI:SS'), 480
    );
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('[Étape 3 : Volume théorique fenêtre 3]');
    v_vol := pkg_nanoOrbit.calculer_volume_session('3');
    DBMS_OUTPUT.PUT_LINE('Volume théorique fenêtre 3 = ' || v_vol || ' Mo');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('[Étape 4 : Mise à jour statut SAT-004]');
    pkg_nanoOrbit.mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut (OUT) : ' || v_ancien);
    DBMS_OUTPUT.PUT_LINE('');

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[Étape 5 : ROLLBACK effectué — données restaurées]');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== FIN DU SCENARIO ===');
END;
/


SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'PKG_NANOORBIT'
ORDER BY object_type;

