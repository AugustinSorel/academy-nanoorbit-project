-- ============================================================
-- PROJET NANOORBIT — PHASE 2 — SCRIPT DML
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Insertion dans l'ordre strict des dépendances FK :
--   1. ORBITE → 2. SATELLITE → 3. INSTRUMENT → 4. EMBARQUEMENT
--   5. CENTRE_CONTROLE → 6. STATION_SOL
--   7. MISSION → 8. FENETRE_COM → 9. PARTICIPATION
-- Table AFFECTATION_STATION supprimée du schéma
-- ============================================================

-- ============================================================
-- 1. ORBITE (3 lignes : SSO × 2, LEO × 1)
-- ============================================================
INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('1', 'SSO', 550, 97.6, 95.5, 0.001, 'Polaire globale — Europe / Arctique');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('2', 'SSO', 700, 98.2, 98.8, 0.0008, 'Polaire globale — haute latitude');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('3', 'LEO', 400, 51.6, 92.6, 0.002, 'Équatoriale — zone tropicale');

-- ============================================================
-- 2. SATELLITE (5 lignes : Opérationnel ×3, En veille ×1, Désorbité ×1)
-- ============================================================
INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-001', 'NanoOrbit-Alpha', TO_DATE('2022-03-15','YYYY-MM-DD'), 1.3, '3U', 'Opérationnel', 60, 20, '1');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-002', 'NanoOrbit-Beta', TO_DATE('2022-03-15','YYYY-MM-DD'), 1.3, '3U', 'Opérationnel', 60, 20, '1');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-003', 'NanoOrbit-Gamma', TO_DATE('2023-06-10','YYYY-MM-DD'), 2.0, '6U', 'Opérationnel', 84, 40, '2');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-004', 'NanoOrbit-Delta', TO_DATE('2023-06-10','YYYY-MM-DD'), 2.0, '6U', 'En veille', 84, 40, '2');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-005', 'NanoOrbit-Epsilon', TO_DATE('2021-11-20','YYYY-MM-DD'), 4.5, '12U', 'Désorbité', 36, 80, '3');

-- ============================================================
-- 3. INSTRUMENT (4 lignes)
-- Note : INS-AIS-01 n'a pas de résolution → NULL
-- ============================================================
INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-CAM-01', 'Caméra optique', 'PlanetScope-Mini', 3, 2.5, 0.4);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-IR-01', 'Infrarouge', 'FLIR-Lepton-3', 160, 1.2, 0.15);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-AIS-01', 'Récepteur AIS', 'ShipTrack-V2', NULL, 0.8, 0.12);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-SPEC-01', 'Spectromètre', 'HyperSpec-Nano', 30, 3.1, 0.6);

-- ============================================================
-- 4. EMBARQUEMENT (7 lignes)
-- ============================================================
INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-CAM-01', TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-IR-01', TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-002', 'INS-CAM-01', TO_DATE('2022-03-15','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-CAM-01', TO_DATE('2023-06-10','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-SPEC-01', TO_DATE('2023-06-10','YYYY-MM-DD'), 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-004', 'INS-IR-01', TO_DATE('2023-06-10','YYYY-MM-DD'), 'Dégradé');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-005', 'INS-AIS-01', TO_DATE('2021-11-20','YYYY-MM-DD'), 'Hors service');

-- ============================================================
-- 5. CENTRE_CONTROLE (3 lignes)
-- ============================================================
INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('1', 'NanoOrbit Paris HQ', 'Paris', 'Europe', 'Europe/Paris', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('2', 'NanoOrbit Houston', 'Houston', 'Amériques', 'America/Chicago', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('3', 'NanoOrbit Singapore', 'Singapour', 'Asie-Pacifique', 'Asia/Singapore', 'Actif');

-- ============================================================
-- 6. STATION_SOL (3 lignes)
-- ============================================================
INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.6047, 1.4442, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station', 67.8557, 20.2253, 5.4, 'X', 400, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-SGP-01', 'Singapore Station', 1.3521, 103.8198, 3.0, 'S', 120, 'Maintenance');

-- ============================================================
-- 7. MISSION (3 lignes : Active × 2, Terminée × 1)
-- ============================================================
INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-ARC-2023', 'ArcticWatch 2023',
        'Surveillance de la fonte des glaces et dynamique des banquises arctiques',
        'Arctique / Groenland',
        TO_DATE('2023-01-01','YYYY-MM-DD'), NULL, 'Active');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-DEF-2022', 'DeforestAlert',
        'Détection et cartographie de la déforestation en temps quasi-réel',
        'Amazonie / Congo',
        TO_DATE('2022-06-01','YYYY-MM-DD'), TO_DATE('2023-05-31','YYYY-MM-DD'), 'Terminée');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-COAST-2024', 'CoastGuard 2024',
        'Surveillance de l''évolution du trait de côte et détection d''érosion côtière',
        'Méditerranée / Atlantique',
        TO_DATE('2024-03-01','YYYY-MM-DD'), NULL, 'Active');

-- ============================================================
-- 8. FENETRE_COM (5 lignes : Réalisée × 3, Planifiée × 2)
-- Note : volume_donnees = NULL pour les fenêtres Planifiées (RG-F05)
-- ============================================================
INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('1', TO_TIMESTAMP('2024-01-15 09:14:00','YYYY-MM-DD HH24:MI:SS'), 420, 82.3, 1250, 'Réalisée', 'SAT-001', 'GS-KIR-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('2', TO_TIMESTAMP('2024-01-15 11:52:00','YYYY-MM-DD HH24:MI:SS'), 310, 67.1, 890, 'Réalisée', 'SAT-002', 'GS-TLS-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('3', TO_TIMESTAMP('2024-01-16 08:30:00','YYYY-MM-DD HH24:MI:SS'), 540, 88.9, 1680, 'Réalisée', 'SAT-003', 'GS-KIR-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('4', TO_TIMESTAMP('2024-01-20 14:22:00','YYYY-MM-DD HH24:MI:SS'), 380, 71.4, NULL, 'Planifiée', 'SAT-001', 'GS-TLS-01');

INSERT INTO FENETRE_COM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES ('5', TO_TIMESTAMP('2024-01-21 07:45:00','YYYY-MM-DD HH24:MI:SS'), 290, 59.8, NULL, 'Planifiée', 'SAT-003', 'GS-TLS-01');

-- ============================================================
-- 9. PARTICIPATION (7 lignes)
-- ============================================================
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-ARC-2023', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-002', 'MSN-ARC-2023', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-ARC-2023', 'Satellite de relais');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-DEF-2022', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-005', 'MSN-DEF-2022', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-COAST-2024', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-COAST-2024', 'Satellite de secours');

-- ============================================================
-- COMMIT FINAL
-- ============================================================
COMMIT;

-- ============================================================
-- VERIFICATION : comptage des lignes par table
-- ============================================================
SELECT 'ORBITE' AS table_name, COUNT(*) AS nb_lignes FROM ORBITE
UNION ALL SELECT 'SATELLITE', COUNT(*) FROM SATELLITE
UNION ALL SELECT 'INSTRUMENT', COUNT(*) FROM INSTRUMENT
UNION ALL SELECT 'EMBARQUEMENT', COUNT(*) FROM EMBARQUEMENT
UNION ALL SELECT 'CENTRE_CONTROLE', COUNT(*) FROM CENTRE_CONTROLE
UNION ALL SELECT 'STATION_SOL', COUNT(*) FROM STATION_SOL
UNION ALL SELECT 'MISSION', COUNT(*) FROM MISSION
UNION ALL SELECT 'FENETRE_COM', COUNT(*) FROM FENETRE_COM
UNION ALL SELECT 'PARTICIPATION', COUNT(*) FROM PARTICIPATION;
