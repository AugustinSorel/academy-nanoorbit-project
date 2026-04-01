-- ============================================================
-- PROJET NANOORBIT — PHASE 3 — L3-D : SCRIPT DE VALIDATION
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Scénario de test enchaîné du package pkg_nanoOrbit
-- Toutes les sorties sont commentées avec les résultats attendus
-- Les modifications de données sont annulées par ROLLBACK
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- TEST 1 : afficher_statut_satellite — Satellite existant
-- ============================================================
-- Résultat attendu :
--   === Statut du satellite SAT-001 ===
--   Nom    : NanoOrbit-Alpha
--   Statut : Opérationnel
--   Orbite : SSO — Orbite héliosynchrone
--            Altitude: 550 km | Période: 95.5 min
--   Instruments embarqués :
--     1. INS-CAM-01 (Caméra optique) — Nominal
--     2. INS-IR-01 (Infrarouge) — Nominal
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 1 : afficher_statut_satellite(SAT-001)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-001');
END;
/


-- ============================================================
-- TEST 2 : afficher_statut_satellite — Satellite désorbité
-- ============================================================
-- Résultat attendu :
--   === Statut du satellite SAT-005 ===
--   Nom    : NanoOrbit-Epsilon
--   Statut : Désorbité
--   Orbite : LEO — Orbite basse terrestre
--            Altitude: 400 km | Période: 92.6 min
--   Instruments embarqués :
--     1. INS-AIS-01 (Récepteur AIS) — Hors service
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 2 : afficher_statut_satellite(SAT-005)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-005');
END;
/


-- ============================================================
-- TEST 3 : afficher_statut_satellite — Satellite inexistant
-- ============================================================
-- Résultat attendu :
--   ERREUR — Satellite SAT-999 introuvable.
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 3 : afficher_statut_satellite(SAT-999)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-999');
END;
/


-- ============================================================
-- TEST 4 : mettre_a_jour_statut — Passage En veille → Opérationnel
-- ============================================================
-- Résultat attendu :
--   Statut de SAT-004 mis à jour : En veille → Opérationnel
--   Ancien statut récupéré (OUT) : En veille
--   (ROLLBACK effectué)
-- ============================================================
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


-- ============================================================
-- TEST 5 : mettre_a_jour_statut — Satellite inexistant
-- ============================================================
-- Résultat attendu :
--   ORA-20020: Satellite SAT-999 introuvable.
-- ============================================================
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


-- ============================================================
-- TEST 6 : calculer_volume_session — Fenêtre existante
-- ============================================================
-- Résultat attendu :
--   Fenêtre 1 : volume = 21000 Mo (GS-KIR-01, 400 Mbps × 420s / 8)
--   Fenêtre 2 : volume = 5812.5 Mo (GS-TLS-01, 150 Mbps × 310s / 8)
--   Fenêtre 3 : volume = 27000 Mo (GS-KIR-01, 400 Mbps × 540s / 8)
-- ============================================================
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


-- ============================================================
-- TEST 7 : calculer_volume_session — Fenêtre inexistante
-- ============================================================
-- Résultat attendu :
--   ORA-20030: Fenêtre FEN-999 introuvable.
-- ============================================================
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


-- ============================================================
-- TEST 8 : vitesse_orbitale — Tous les satellites
-- ============================================================
-- Résultat attendu :
--   SAT-001 : v ≈ 7.19 km/s (SSO, 550 km, 95.5 min)
--   SAT-002 : v ≈ 7.19 km/s (SSO, 550 km, 95.5 min)
--   SAT-003 : v ≈ 7.11 km/s (SSO, 700 km, 98.8 min)
--   SAT-004 : v ≈ 7.11 km/s (SSO, 700 km, 98.8 min)
--   SAT-005 : v ≈ 7.13 km/s (LEO, 400 km, 92.6 min)
-- ============================================================
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


-- ============================================================
-- TEST 9 : nb_instruments — Comptage par satellite
-- ============================================================
-- Résultat attendu :
--   SAT-001 : 2 instrument(s)
--   SAT-002 : 1 instrument(s)
--   SAT-003 : 2 instrument(s)
--   SAT-004 : 1 instrument(s)
--   SAT-005 : 1 instrument(s)
-- ============================================================
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


-- ============================================================
-- TEST 10 : get_resume_satellite — Record résumé
-- ============================================================
-- Résultat attendu :
--   Résumé SAT-003 :
--     ID     : SAT-003
--     Nom    : NanoOrbit-Gamma
--     Statut : Opérationnel
--     Orbite : SSO à 700 km
--     Instruments : 2
-- ============================================================
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


-- ============================================================
-- TEST 11 : valider_fenetre — Cas valide
-- ============================================================
-- Résultat attendu :
--   Validation OK — insertion autorisée pour SAT-001 / GS-KIR-01
-- ============================================================
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


-- ============================================================
-- TEST 12 : valider_fenetre — Satellite désorbité
-- ============================================================
-- Résultat attendu :
--   ORA-20010: Satellite SAT-005 non opérationnel (statut: Désorbité)
-- ============================================================
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


-- ============================================================
-- TEST 13 : valider_fenetre — Station en maintenance
-- ============================================================
-- Résultat attendu :
--   ORA-20011: Station GS-SGP-01 non active (statut: Maintenance)
-- ============================================================
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


-- ============================================================
-- TEST 14 : rapport_flotte — Vue d'ensemble
-- ============================================================
-- Résultat attendu :
--   ========================================
--     RAPPORT DE FLOTTE NANOORBIT
--   ========================================
--   SAT-001 | NanoOrbit-Alpha        | Opérationnel  | 3U 1.3kg | SSO 550km | 2 instrument(s)
--   SAT-002 | NanoOrbit-Beta         | Opérationnel  | 3U 1.3kg | SSO 550km | 1 instrument(s)
--   SAT-003 | NanoOrbit-Gamma        | Opérationnel  | 6U 2kg   | SSO 700km | 2 instrument(s)
--   SAT-004 | NanoOrbit-Delta        | En veille     | 6U 2kg   | SSO 700km | 1 instrument(s)
--   SAT-005 | NanoOrbit-Epsilon      | Désorbité     | 12U 4.5kg| LEO 400km | 1 instrument(s)
--   ----------------------------------------
--   Total : 5 satellites dont 3 opérationnels
--   ========================================
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 14 : rapport_flotte');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_flotte;
END;
/


-- ============================================================
-- TEST 15 : rapport_station — GS-KIR-01
-- ============================================================
-- Résultat attendu :
--   ========================================
--     RAPPORT STATION : GS-KIR-01
--     Kiruna Arctic Station | Bande X | Débit max: 400 Mbps
--   ========================================
--   FEN 1  | SAT-001 | 15/01/2024 09:14 | 420s | Réalisée  | 1250 Mo
--   FEN 3  | SAT-003 | 16/01/2024 08:30 | 540s | Réalisée  | 1680 Mo
--   ----------------------------------------
--   Total fenêtres : 2 | Volume téléchargé (Réalisée) : 2930 Mo
--   ========================================
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 15 : rapport_station(GS-KIR-01)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-KIR-01');
END;
/


-- ============================================================
-- TEST 16 : rapport_station — GS-TLS-01
-- ============================================================
-- Résultat attendu :
--   ========================================
--     RAPPORT STATION : GS-TLS-01
--     Toulouse Ground Station | Bande S | Débit max: 150 Mbps
--   ========================================
--   FEN 2  | SAT-002 | 15/01/2024 11:52 | 310s | Réalisée  | 890 Mo
--   FEN 4  | SAT-001 | 20/01/2024 14:22 | 380s | Planifiée | - Mo
--   FEN 5  | SAT-003 | 21/01/2024 07:45 | 290s | Planifiée | - Mo
--   ----------------------------------------
--   Total fenêtres : 3 | Volume téléchargé (Réalisée) : 890 Mo
--   ========================================
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 16 : rapport_station(GS-TLS-01)');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-TLS-01');
END;
/


-- ============================================================
-- TEST 17 : rapport_station — Station inexistante
-- ============================================================
-- Résultat attendu :
--   ERREUR — Station GS-XXX-01 introuvable.
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 17 : rapport_station(GS-XXX-01) — inexistante');
    DBMS_OUTPUT.PUT_LINE('');
    pkg_nanoOrbit.rapport_station('GS-XXX-01');
END;
/


-- ============================================================
-- TEST 18 : Scénario enchaîné complet
-- Simule un workflow opérationnel :
--   1. Consulter un satellite
--   2. Vérifier si une fenêtre est possible
--   3. Calculer le volume théorique
--   4. Mettre à jour un statut
--   5. Annuler les modifications
-- ============================================================
-- Résultat attendu :
--   === SCENARIO OPERATIONNEL COMPLET ===
--   [Étape 1 : Consultation]  ... affichage SAT-003
--   [Étape 2 : Validation]    Validation OK
--   [Étape 3 : Volume]        Fenêtre 3 → 27000 Mo
--   [Étape 4 : MAJ statut]    SAT-004 : En veille → Opérationnel
--   [Étape 5 : Rollback]      Données restaurées
-- ============================================================
DECLARE
    v_ancien VARCHAR2(30);
    v_vol    NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> TEST 18 : Scénario opérationnel complet');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== SCENARIO OPERATIONNEL COMPLET ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- Étape 1 : Consultation satellite
    DBMS_OUTPUT.PUT_LINE('[Étape 1 : Consultation satellite SAT-003]');
    pkg_nanoOrbit.afficher_statut_satellite('SAT-003');
    DBMS_OUTPUT.PUT_LINE('');

    -- Étape 2 : Validation fenêtre possible
    DBMS_OUTPUT.PUT_LINE('[Étape 2 : Validation fenêtre]');
    pkg_nanoOrbit.valider_fenetre(
        'SAT-003', 'GS-KIR-01',
        TO_TIMESTAMP('2024-07-01 12:00:00','YYYY-MM-DD HH24:MI:SS'), 480
    );
    DBMS_OUTPUT.PUT_LINE('');

    -- Étape 3 : Calcul volume théorique d'une fenêtre existante
    DBMS_OUTPUT.PUT_LINE('[Étape 3 : Volume théorique fenêtre 3]');
    v_vol := pkg_nanoOrbit.calculer_volume_session('3');
    DBMS_OUTPUT.PUT_LINE('Volume théorique fenêtre 3 = ' || v_vol || ' Mo');
    DBMS_OUTPUT.PUT_LINE('');

    -- Étape 4 : Mise à jour statut
    DBMS_OUTPUT.PUT_LINE('[Étape 4 : Mise à jour statut SAT-004]');
    pkg_nanoOrbit.mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut (OUT) : ' || v_ancien);
    DBMS_OUTPUT.PUT_LINE('');

    -- Étape 5 : Rollback
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[Étape 5 : ROLLBACK effectué — données restaurées]');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== FIN DU SCENARIO ===');
END;
/


-- ============================================================
-- VERIFICATION FINALE : état du package dans le dictionnaire
-- ============================================================
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'PKG_NANOORBIT'
ORDER BY object_type;

-- Résultat attendu :
--   PKG_NANOORBIT    PACKAGE        VALID
--   PKG_NANOORBIT    PACKAGE BODY   VALID
