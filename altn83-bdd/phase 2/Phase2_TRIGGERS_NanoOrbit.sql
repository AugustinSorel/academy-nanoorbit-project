    -- ============================================================
-- PROJET NANOORBIT — PHASE 2 — SCRIPT TRIGGERS
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- 5 triggers métier couvrant les règles non exprimables en DDL
-- T1 à T3 : Niveau 1 (obligatoire)
-- T4 à T5 : Niveau 2 (bonus)
-- ============================================================
-- Prérequis : DDL + DML exécutés (9 tables + HISTORIQUE_STATUT)
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- T1 — trg_valider_fenetre (Niveau 1)
-- BEFORE INSERT ON FENETRE_COM
-- Règles : RG-S06 (satellite désorbité) + RG-G03 (station maintenance)
-- Bloque l'insertion si :
--   - le satellite est Désorbité
--   - la station est en Maintenance
-- ============================================================
CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_satellite SATELLITE.statut%TYPE;
    v_statut_station   STATION_SOL.statut%TYPE;
BEGIN
    -- Vérifier le statut du satellite
    SELECT statut INTO v_statut_satellite
    FROM SATELLITE
    WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'T1 — Impossible de créer une fenêtre : le satellite '
            || :NEW.id_satellite || ' est Désorbité (RG-S06).');
    END IF;

    -- Vérifier le statut de la station
    SELECT statut INTO v_statut_station
    FROM STATION_SOL
    WHERE code_station = :NEW.code_station;

    IF v_statut_station = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'T1 — Impossible de créer une fenêtre : la station '
            || :NEW.code_station || ' est en Maintenance (RG-G03).');
    END IF;
END;
/
SHOW ERRORS TRIGGER trg_valider_fenetre;

-- ============================================================
-- T2 — trg_no_chevauchement (Niveau 1)
-- COMPOUND TRIGGER avec AFTER STATEMENT sur FENETRE_COM
-- Règles : RG-F02 (chevauchement satellite) + RG-F03 (chevauchement station)
--
-- Stratégie pour éviter ORA-04091 (table mutante) :
--   - BEFORE EACH ROW : on collecte les lignes insérées/modifiées
--     dans une collection PL/SQL (tableau en mémoire)
--   - AFTER STATEMENT : la table n'est plus en mutation, on peut
--     lire FENETRE_COM pour vérifier les chevauchements
--
-- Deux intervalles [A, A+durée] et [B, B+durée] se chevauchent
--   si A < B_fin ET B < A_fin
-- ============================================================
CREATE OR REPLACE TRIGGER trg_no_chevauchement
FOR INSERT OR UPDATE ON FENETRE_COM
COMPOUND TRIGGER

    -- Type record pour stocker les infos d'une fenêtre
    TYPE t_fenetre_rec IS RECORD (
        id_fenetre     FENETRE_COM.id_fenetre%TYPE,
        id_satellite   FENETRE_COM.id_satellite%TYPE,
        code_station   FENETRE_COM.code_station%TYPE,
        datetime_debut FENETRE_COM.datetime_debut%TYPE,
        duree          FENETRE_COM.duree%TYPE
    );

    -- Collection pour stocker toutes les lignes touchées par le statement
    TYPE t_fenetre_tab IS TABLE OF t_fenetre_rec INDEX BY PLS_INTEGER;
    g_fenetres t_fenetre_tab;
    g_index    PLS_INTEGER := 0;

    -- -------------------------------------------------------
    -- BEFORE EACH ROW : capturer les lignes dans la collection
    -- -------------------------------------------------------
    BEFORE EACH ROW IS
    BEGIN
        g_index := g_index + 1;
        g_fenetres(g_index).id_fenetre     := :NEW.id_fenetre;
        g_fenetres(g_index).id_satellite   := :NEW.id_satellite;
        g_fenetres(g_index).code_station   := :NEW.code_station;
        g_fenetres(g_index).datetime_debut := :NEW.datetime_debut;
        g_fenetres(g_index).duree          := :NEW.duree;
    END BEFORE EACH ROW;

    -- -------------------------------------------------------
    -- AFTER STATEMENT : vérifier les chevauchements
    -- La table n'est plus en mutation → SELECT autorisé
    -- -------------------------------------------------------
    AFTER STATEMENT IS
        v_count NUMBER;
    BEGIN
        FOR i IN 1 .. g_index LOOP
            -- RG-F02 : Chevauchement pour le même SATELLITE
            SELECT COUNT(*) INTO v_count
            FROM FENETRE_COM
            WHERE id_satellite = g_fenetres(i).id_satellite
              AND id_fenetre  != g_fenetres(i).id_fenetre
              AND datetime_debut < g_fenetres(i).datetime_debut + NUMTODSINTERVAL(g_fenetres(i).duree, 'SECOND')
              AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > g_fenetres(i).datetime_debut;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20003,
                    'T2 — Chevauchement détecté : le satellite '
                    || g_fenetres(i).id_satellite || ' a déjà une fenêtre sur ce créneau (RG-F02).');
            END IF;

            -- RG-F03 : Chevauchement pour la même STATION
            SELECT COUNT(*) INTO v_count
            FROM FENETRE_COM
            WHERE code_station = g_fenetres(i).code_station
              AND id_fenetre  != g_fenetres(i).id_fenetre
              AND datetime_debut < g_fenetres(i).datetime_debut + NUMTODSINTERVAL(g_fenetres(i).duree, 'SECOND')
              AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > g_fenetres(i).datetime_debut;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20004,
                    'T2 — Chevauchement détecté : la station '
                    || g_fenetres(i).code_station || ' a déjà une fenêtre sur ce créneau (RG-F03).');
            END IF;
        END LOOP;

        -- Réinitialiser la collection pour le prochain statement
        g_fenetres.DELETE;
        g_index := 0;
    END AFTER STATEMENT;

END trg_no_chevauchement;
/
SHOW ERRORS TRIGGER trg_no_chevauchement;

-- ============================================================
-- T3 — trg_volume_realise (Niveau 1)
-- BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Règle : RG-F05
-- Force volume_donnees à NULL si le statut de la fenêtre
-- est différent de 'Réalisée'
-- ============================================================
CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    IF :NEW.statut != 'Réalisée' THEN
        :NEW.volume_donnees := NULL;
    END IF;
END;
/
SHOW ERRORS TRIGGER trg_volume_realise;

-- ============================================================
-- T4 — trg_mission_terminee (Niveau 2 — Bonus)
-- BEFORE INSERT ON PARTICIPATION
-- Règle : RG-M04
-- Bloque l'ajout d'un satellite à une mission Terminée
-- ============================================================
CREATE OR REPLACE TRIGGER trg_mission_terminee
BEFORE INSERT ON PARTICIPATION
FOR EACH ROW
DECLARE
    v_statut_mission MISSION.statut_mission%TYPE;
BEGIN
    SELECT statut_mission INTO v_statut_mission
    FROM MISSION
    WHERE id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminée' THEN
        RAISE_APPLICATION_ERROR(-20005,
            'T4 — Impossible d''affecter le satellite '
            || :NEW.id_satellite || ' : la mission '
            || :NEW.id_mission || ' est Terminée (RG-M04).');
    END IF;
END;
/
SHOW ERRORS TRIGGER trg_mission_terminee;

-- ============================================================
-- T5 — trg_historique_statut (Niveau 2 — Bonus)
-- AFTER UPDATE OF statut ON SATELLITE
-- Règle : RG-S06 (traçabilité)
-- Trace tout changement de statut dans HISTORIQUE_STATUT
-- Ne s'exécute que si le statut a réellement changé
-- ============================================================
CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
BEGIN
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO HISTORIQUE_STATUT (id_satellite, ancien_statut, nouveau_statut, date_changement, motif)
        VALUES (
            :NEW.id_satellite,
            :OLD.statut,
            :NEW.statut,
            SYSTIMESTAMP,
            'Changement de statut : ' || :OLD.statut || ' → ' || :NEW.statut
        );

        DBMS_OUTPUT.PUT_LINE('T5 — Historique enregistré pour ' || :NEW.id_satellite
            || ' : ' || :OLD.statut || ' → ' || :NEW.statut);
    END IF;
END;
/
SHOW ERRORS TRIGGER trg_historique_statut;

-- ============================================================
-- VERIFICATION : liste des triggers créés
-- ============================================================
SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM user_triggers
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
ORDER BY table_name, trigger_name;


-- ############################################################
--                    JEUX DE TESTS
-- ############################################################

-- ============================================================
-- TESTS T1 — trg_valider_fenetre
-- ============================================================

-- T1 — CAS VALIDE : fenêtre pour satellite Opérationnel + station Active
-- Résultat attendu : 1 ligne insérée
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-OK', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-001', 'GS-KIR-01');

-- T1 — CAS ERREUR 1 : satellite SAT-005 est Désorbité
-- Résultat attendu : ORA-20001 — satellite SAT-005 est Désorbité (RG-S06)
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-KO1', TO_TIMESTAMP('2024-06-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-005', 'GS-KIR-01');

-- T1 — CAS ERREUR 2 : station GS-SGP-01 est en Maintenance
-- Résultat attendu : ORA-20002 — station GS-SGP-01 est en Maintenance (RG-G03)
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-KO2', TO_TIMESTAMP('2024-06-03 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-001', 'GS-SGP-01');

-- Nettoyage T1
DELETE FROM FENETRE_COM WHERE id_fenetre = 'FEN-T1-OK';
COMMIT;


-- ============================================================
-- TESTS T2 — trg_no_chevauchement
-- ============================================================

-- T2 — CAS VALIDE : fenêtre sans chevauchement (créneau libre)
-- Résultat attendu : 1 ligne insérée
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-OK', TO_TIMESTAMP('2024-06-15 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 70.0, NULL, 'Planifiée', 'SAT-002', 'GS-KIR-01');

-- T2 — CAS ERREUR 1 (RG-F02) : chevauchement satellite
-- SAT-001 a FEN id=1 le 2024-01-15 09:14:00, durée 420s → fin à 09:21:00
-- On insère à 09:17:00 pour SAT-001 → chevauche !
-- Résultat attendu : ORA-20003 — chevauchement satellite SAT-001 (RG-F02)
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-KO1', TO_TIMESTAMP('2024-01-15 09:17:00','YYYY-MM-DD HH24:MI:SS'), 300, 65.0, NULL, 'Planifiée', 'SAT-001', 'GS-TLS-01');

-- T2 — CAS ERREUR 2 (RG-F03) : chevauchement station
-- GS-KIR-01 a FEN id=1 le 2024-01-15 09:14:00, durée 420s → fin à 09:21:00
-- On insère à 09:18:00 pour SAT-002 (autre satellite) sur GS-KIR-01 → chevauche !
-- Résultat attendu : ORA-20004 — chevauchement station GS-KIR-01 (RG-F03)
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-KO2', TO_TIMESTAMP('2024-01-15 09:18:00','YYYY-MM-DD HH24:MI:SS'), 200, 60.0, NULL, 'Planifiée', 'SAT-002', 'GS-KIR-01');

-- Nettoyage T2
DELETE FROM FENETRE_COM WHERE id_fenetre = 'FEN-T2-OK';
COMMIT;


-- ============================================================
-- TESTS T3 — trg_volume_realise
-- ============================================================

-- T3 — CAS 1 : statut 'Planifiée' avec volume_donnees renseigné → forcé à NULL
-- Résultat attendu : insertion réussie, volume_donnees = NULL
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T3-A', TO_TIMESTAMP('2024-07-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, 999, 'Planifiée', 'SAT-002', 'GS-TLS-01');

-- Vérification : volume_donnees doit être NULL
-- Résultat attendu : FEN-T3-A | Planifiée | (null)
SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-A';

-- T3 — CAS 2 : statut 'Réalisée' avec volume_donnees renseigné → conservé
-- Résultat attendu : insertion réussie, volume_donnees = 1500
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T3-B', TO_TIMESTAMP('2024-07-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, 1500, 'Réalisée', 'SAT-002', 'GS-KIR-01');

-- Vérification : volume_donnees doit être 1500
-- Résultat attendu : FEN-T3-B | Réalisée | 1500
SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-B';

-- T3 — CAS 3 : UPDATE statut de Réalisée → Annulée → volume forcé à NULL
-- Résultat attendu : volume_donnees passe à NULL
UPDATE FENETRE_COM SET statut = 'Annulée' WHERE id_fenetre = 'FEN-T3-B';

-- Vérification après UPDATE
-- Résultat attendu : FEN-T3-B | Annulée | (null)
SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-B';

-- Nettoyage T3
DELETE FROM FENETRE_COM WHERE id_fenetre IN ('FEN-T3-A', 'FEN-T3-B');
COMMIT;


-- ============================================================
-- TESTS T4 — trg_mission_terminee
-- ============================================================

-- T4 — CAS VALIDE : affecter un satellite à une mission Active
-- MSN-ARC-2023 est Active → insertion autorisée
-- Résultat attendu : 1 ligne insérée
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de secours');

-- T4 — CAS ERREUR : affecter un satellite à une mission Terminée
-- MSN-DEF-2022 est Terminée → insertion bloquée
-- Résultat attendu : ORA-20005 — mission MSN-DEF-2022 est Terminée (RG-M04)
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-DEF-2022', 'Imageur de secours');

-- Nettoyage T4
DELETE FROM PARTICIPATION WHERE id_satellite = 'SAT-004' AND id_mission = 'MSN-ARC-2023';
COMMIT;


-- ============================================================
-- TESTS T5 — trg_historique_statut
-- ============================================================

-- T5 — CAS VALIDE : changement de statut → trace dans HISTORIQUE_STATUT
-- SAT-004 passe de 'En veille' à 'Opérationnel'
-- Résultat attendu : UPDATE réussi + ligne dans HISTORIQUE_STATUT
--   + DBMS_OUTPUT : "T5 — Historique enregistré pour SAT-004 : En veille → Opérationnel"
UPDATE SATELLITE SET statut = 'Opérationnel' WHERE id_satellite = 'SAT-004';

-- Vérification : une ligne doit exister
-- Résultat attendu : SAT-004 | En veille | Opérationnel | (timestamp)
SELECT id_satellite, ancien_statut, nouveau_statut, date_changement, motif
FROM HISTORIQUE_STATUT
WHERE id_satellite = 'SAT-004'
ORDER BY date_changement DESC;

-- T5 — CAS 2 : UPDATE sans changement de statut → PAS de trace
-- Résultat attendu : aucune nouvelle ligne dans HISTORIQUE_STATUT
UPDATE SATELLITE SET nom_satellite = 'NanoOrbit-Delta-v2' WHERE id_satellite = 'SAT-004';

-- Vérification : toujours 1 seule ligne pour SAT-004
-- Résultat attendu : 1
SELECT COUNT(*) AS nb_historique FROM HISTORIQUE_STATUT WHERE id_satellite = 'SAT-004';

-- Restauration des données originales
-- Note : ce UPDATE génère une 2e ligne d'historique (Opérationnel → En veille)
UPDATE SATELLITE SET statut = 'En veille', nom_satellite = 'NanoOrbit-Delta' WHERE id_satellite = 'SAT-004';

-- Vérification finale : 2 lignes d'historique pour SAT-004
-- Résultat attendu :
--   1. En veille → Opérationnel
--   2. Opérationnel → En veille
SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
FROM HISTORIQUE_STATUT
WHERE id_satellite = 'SAT-004'
ORDER BY date_changement;

-- Nettoyage T5
DELETE FROM HISTORIQUE_STATUT WHERE id_satellite = 'SAT-004';
COMMIT;


-- ============================================================
-- RÉSUMÉ DES TRIGGERS
-- ============================================================
-- T1 — trg_valider_fenetre    : BEFORE INSERT ON FENETRE_COM       → RG-S06, RG-G03
-- T2 — trg_no_chevauchement   : COMPOUND (AFTER STATEMENT) ON FENETRE_COM → RG-F02, RG-F03
-- T3 — trg_volume_realise     : BEFORE INSERT/UPDATE ON FENETRE_COM → RG-F05
-- T4 — trg_mission_terminee   : BEFORE INSERT ON PARTICIPATION      → RG-M04
-- T5 — trg_historique_statut  : AFTER UPDATE OF statut ON SATELLITE  → RG-S06 traçabilité
-- ============================================================
