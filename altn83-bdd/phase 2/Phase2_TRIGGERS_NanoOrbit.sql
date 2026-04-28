SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_satellite SATELLITE.statut%TYPE;
    v_statut_station   STATION_SOL.statut%TYPE;
BEGIN
    SELECT statut INTO v_statut_satellite
    FROM SATELLITE
    WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'T1 — Impossible de créer une fenêtre : le satellite '
            || :NEW.id_satellite || ' est Désorbité (RG-S06).');
    END IF;

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

CREATE OR REPLACE TRIGGER trg_no_chevauchement
FOR INSERT OR UPDATE ON FENETRE_COM
COMPOUND TRIGGER

    TYPE t_fenetre_rec IS RECORD (
        id_fenetre     FENETRE_COM.id_fenetre%TYPE,
        id_satellite   FENETRE_COM.id_satellite%TYPE,
        code_station   FENETRE_COM.code_station%TYPE,
        datetime_debut FENETRE_COM.datetime_debut%TYPE,
        duree          FENETRE_COM.duree%TYPE
    );

    TYPE t_fenetre_tab IS TABLE OF t_fenetre_rec INDEX BY PLS_INTEGER;
    g_fenetres t_fenetre_tab;
    g_index    PLS_INTEGER := 0;

    BEFORE EACH ROW IS
    BEGIN
        g_index := g_index + 1;
        g_fenetres(g_index).id_fenetre     := :NEW.id_fenetre;
        g_fenetres(g_index).id_satellite   := :NEW.id_satellite;
        g_fenetres(g_index).code_station   := :NEW.code_station;
        g_fenetres(g_index).datetime_debut := :NEW.datetime_debut;
        g_fenetres(g_index).duree          := :NEW.duree;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_count NUMBER;
    BEGIN
        FOR i IN 1 .. g_index LOOP
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

        g_fenetres.DELETE;
        g_index := 0;
    END AFTER STATEMENT;

END trg_no_chevauchement;
/
SHOW ERRORS TRIGGER trg_no_chevauchement;

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

SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM user_triggers
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
ORDER BY table_name, trigger_name;

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-OK', TO_TIMESTAMP('2024-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-001', 'GS-KIR-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-KO1', TO_TIMESTAMP('2024-06-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-005', 'GS-KIR-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T1-KO2', TO_TIMESTAMP('2024-06-03 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée', 'SAT-001', 'GS-SGP-01');

DELETE FROM FENETRE_COM WHERE id_fenetre = 'FEN-T1-OK';
COMMIT;

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-OK', TO_TIMESTAMP('2024-06-15 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 70.0, NULL, 'Planifiée', 'SAT-002', 'GS-KIR-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-KO1', TO_TIMESTAMP('2024-01-15 09:17:00','YYYY-MM-DD HH24:MI:SS'), 300, 65.0, NULL, 'Planifiée', 'SAT-001', 'GS-TLS-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T2-KO2', TO_TIMESTAMP('2024-01-15 09:18:00','YYYY-MM-DD HH24:MI:SS'), 200, 60.0, NULL, 'Planifiée', 'SAT-002', 'GS-KIR-01');

DELETE FROM FENETRE_COM WHERE id_fenetre = 'FEN-T2-OK';
COMMIT;

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T3-A', TO_TIMESTAMP('2024-07-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, 999, 'Planifiée', 'SAT-002', 'GS-TLS-01');

SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-A';

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('FEN-T3-B', TO_TIMESTAMP('2024-07-02 10:00:00','YYYY-MM-DD HH24:MI:SS'), 300, 75.0, 1500, 'Réalisée', 'SAT-002', 'GS-KIR-01');

SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-B';

UPDATE FENETRE_COM SET statut = 'Annulée' WHERE id_fenetre = 'FEN-T3-B';

SELECT id_fenetre, statut, volume_donnees
FROM FENETRE_COM WHERE id_fenetre = 'FEN-T3-B';

DELETE FROM FENETRE_COM WHERE id_fenetre IN ('FEN-T3-A', 'FEN-T3-B');
COMMIT;



INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de secours');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-DEF-2022', 'Imageur de secours');

DELETE FROM PARTICIPATION WHERE id_satellite = 'SAT-004' AND id_mission = 'MSN-ARC-2023';
COMMIT;

UPDATE SATELLITE SET statut = 'Opérationnel' WHERE id_satellite = 'SAT-004';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement, motif
FROM HISTORIQUE_STATUT
WHERE id_satellite = 'SAT-004'
ORDER BY date_changement DESC;

UPDATE SATELLITE SET nom_satellite = 'NanoOrbit-Delta-v2' WHERE id_satellite = 'SAT-004';

SELECT COUNT(*) AS nb_historique FROM HISTORIQUE_STATUT WHERE id_satellite = 'SAT-004';

UPDATE SATELLITE SET statut = 'En veille', nom_satellite = 'NanoOrbit-Delta' WHERE id_satellite = 'SAT-004';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
FROM HISTORIQUE_STATUT
WHERE id_satellite = 'SAT-004'
ORDER BY date_changement;

DELETE FROM HISTORIQUE_STATUT WHERE id_satellite = 'SAT-004';
COMMIT;


