-- ============================================================
-- PROJET NANOORBIT — PHASE 2 — SCRIPT DDL
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================

-- Nettoyage des tables existantes (ordre inverse des dépendances)
DROP TABLE PARTICIPATION      CASCADE CONSTRAINTS;
DROP TABLE FENETRE_COM        CASCADE CONSTRAINTS;
DROP TABLE AFFECTATION_STATION CASCADE CONSTRAINTS;
DROP TABLE MISSION            CASCADE CONSTRAINTS;
DROP TABLE EMBARQUEMENT       CASCADE CONSTRAINTS;
DROP TABLE STATION_SOL        CASCADE CONSTRAINTS;
DROP TABLE CENTRE_CONTROLE    CASCADE CONSTRAINTS;
DROP TABLE INSTRUMENT         CASCADE CONSTRAINTS;
DROP TABLE SATELLITE          CASCADE CONSTRAINTS;
DROP TABLE ORBITE             CASCADE CONSTRAINTS;

-- ============================================================
-- TABLE 1 : ORBITE
-- Aucune dépendance — référentiel des plans orbitaux
-- ============================================================
CREATE TABLE ORBITE (
    id_orbite        VARCHAR2(20)   CONSTRAINT pk_orbite PRIMARY KEY,
    type_orbite      VARCHAR2(10)   NOT NULL
                     CONSTRAINT ck_orbite_type CHECK (type_orbite IN ('SSO','LEO','MEO','GEO')),
    altitude         NUMBER(7,2)    NOT NULL,
    inclinaison      NUMBER(5,2)    NOT NULL,
    periode_orbitale NUMBER(7,2)    NOT NULL,
    excentricite     NUMBER(8,6)    NOT NULL,
    zone_couverture  VARCHAR2(200)  NOT NULL,
    -- RG-O02 : unicité du couple (altitude, inclinaison)
    CONSTRAINT uq_orbite_alt_inc UNIQUE (altitude, inclinaison)
);

-- ============================================================
-- TABLE 2 : SATELLITE
-- Dépend de ORBITE (FK id_orbite)
-- Q1 : On ne peut pas créer SATELLITE avant ORBITE car chaque
--       satellite référence obligatoirement une orbite (FK NOT NULL).
--       Cela traduit la règle : tout satellite est affecté à une orbite.
-- ============================================================
CREATE TABLE SATELLITE (
    id_satellite      VARCHAR2(20)   CONSTRAINT pk_satellite PRIMARY KEY,
    nom_satellite     VARCHAR2(100)  NOT NULL,
    date_lancement    DATE           NOT NULL,
    masse             NUMBER(7,2)    NOT NULL,
    format_cubesat    VARCHAR2(3)    NOT NULL
                      CONSTRAINT ck_sat_format CHECK (format_cubesat IN ('1U','3U','6U','12U')),
    -- Q4 : VARCHAR2(3) car les valeurs sont alphanumériques (1U, 3U, 6U, 12U).
    --      Un NUMBER ne peut pas stocker le suffixe "U". CHECK valide les 4 formats.
    statut            VARCHAR2(30)   NOT NULL
                      CONSTRAINT ck_sat_statut CHECK (statut IN ('Opérationnel','En veille','Défaillant','Désorbité')),
    duree_vie_prevue  NUMBER(5,2)    NOT NULL,
    capacite_batterie NUMBER(5,2)    NOT NULL,
    id_orbite         VARCHAR2(20)   NOT NULL
                      CONSTRAINT fk_sat_orbite REFERENCES ORBITE(id_orbite)
);

-- ============================================================
-- TABLE 3 : INSTRUMENT
-- Aucune dépendance — catalogue des instruments
-- ============================================================
CREATE TABLE INSTRUMENT (
    ref_instrument   VARCHAR2(20)   CONSTRAINT pk_instrument PRIMARY KEY,
    type_instrument  VARCHAR2(50)   NOT NULL,
    modele           VARCHAR2(100)  NOT NULL,
    resolution       NUMBER(10,2),  -- Nullable (ex: capteur AIS sans résolution)
    consommation     NUMBER(7,2)    NOT NULL,
    masse            NUMBER(7,2)    NOT NULL
);

-- ============================================================
-- TABLE 4 : EMBARQUEMENT
-- Dépend de SATELLITE et INSTRUMENT
-- PK composite (id_satellite, ref_instrument) — RG-S04
-- ============================================================
CREATE TABLE EMBARQUEMENT (
    id_satellite        VARCHAR2(20)  NOT NULL
                        CONSTRAINT fk_emb_satellite REFERENCES SATELLITE(id_satellite),
    ref_instrument      VARCHAR2(20)  NOT NULL
                        CONSTRAINT fk_emb_instrument REFERENCES INSTRUMENT(ref_instrument),
    date_integration    DATE          NOT NULL,
    etat_fonctionnement VARCHAR2(20)  NOT NULL
                        CONSTRAINT ck_emb_etat CHECK (etat_fonctionnement IN ('Nominal','Dégradé','Hors service')),
    CONSTRAINT pk_embarquement PRIMARY KEY (id_satellite, ref_instrument)
);

-- ============================================================
-- TABLE 5 : CENTRE_CONTROLE
-- Aucune dépendance — centres d'opération NanoOrbit
-- ============================================================
CREATE TABLE CENTRE_CONTROLE (
    id_centre        VARCHAR2(20)   CONSTRAINT pk_centre PRIMARY KEY,
    nom_centre       VARCHAR2(100)  NOT NULL,
    ville            VARCHAR2(100)  NOT NULL,
    region_geo       VARCHAR2(100)  NOT NULL,
    fuseau_horaire   VARCHAR2(50)   NOT NULL,
    statut           VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_centre_statut CHECK (statut IN ('Actif','Inactif'))
);

-- ============================================================
-- TABLE 6 : STATION_SOL
-- Aucune dépendance — stations d'antenne mondiales
-- ============================================================
CREATE TABLE STATION_SOL (
    code_station     VARCHAR2(20)   CONSTRAINT pk_station PRIMARY KEY,
    nom_station      VARCHAR2(100)  NOT NULL,
    latitude         NUMBER(9,6)    NOT NULL,
    longitude        NUMBER(9,6)    NOT NULL,
    diametre_antenne NUMBER(5,2)    NOT NULL,
    bande_frequence  VARCHAR2(20)   NOT NULL,
    debit_max        NUMBER(10,2)   NOT NULL,
    statut           VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_station_statut CHECK (statut IN ('Active','Maintenance','Inactive'))
);

-- ============================================================
-- TABLE 7 : AFFECTATION_STATION
-- Dépend de CENTRE_CONTROLE et STATION_SOL
-- PK composite (id_centre, code_station)
-- ============================================================
CREATE TABLE AFFECTATION_STATION (
    id_centre        VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_aff_centre REFERENCES CENTRE_CONTROLE(id_centre),
    code_station     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_aff_station REFERENCES STATION_SOL(code_station),
    date_affectation DATE           NOT NULL,
    CONSTRAINT pk_affectation PRIMARY KEY (id_centre, code_station)
);

-- ============================================================
-- TABLE 8 : MISSION
-- Aucune dépendance — missions scientifiques
-- ============================================================
CREATE TABLE MISSION (
    id_mission       VARCHAR2(20)   CONSTRAINT pk_mission PRIMARY KEY,
    nom_mission      VARCHAR2(100)  NOT NULL,
    objectif         VARCHAR2(500)  NOT NULL,
    zone_geo_cible   VARCHAR2(200)  NOT NULL,
    date_debut       DATE           NOT NULL,
    date_fin         DATE,          -- Nullable — RG-M01 : mission en cours si NULL
    statut_mission   VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_mission_statut CHECK (statut_mission IN ('Active','Terminée','Planifiée'))
);

-- ============================================================
-- TABLE 9 : FENETRE_COM
-- Dépend de SATELLITE et STATION_SOL
-- Q2 : RG-S06 (satellite désorbité bloqué) ne peut pas être
--       vérifiée en DDL seul car elle nécessite de lire le statut
--       du satellite référencé → solution : trigger BEFORE INSERT.
-- Q3 : RG-F02 (pas de chevauchement) n'est pas exprimable en
--       CHECK car elle nécessite une sous-requête sur d'autres
--       lignes de la même table → solution : trigger BEFORE INSERT.
-- ============================================================
CREATE TABLE FENETRE_COM (
    id_fenetre       VARCHAR2(20)   CONSTRAINT pk_fenetre PRIMARY KEY,
    datetime_debut   TIMESTAMP      NOT NULL,
    duree            NUMBER(4)      NOT NULL
                     CONSTRAINT ck_fen_duree CHECK (duree BETWEEN 1 AND 900),
                     -- RG-F04 : durée entre 1 et 900 secondes
    elevation_max    NUMBER(5,2)    NOT NULL,
    volume_donnees   NUMBER(12,2),  -- Nullable — RG-F05 : NULL si statut != 'Réalisée'
    statut           VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_fen_statut CHECK (statut IN ('Planifiée','Réalisée','Annulée')),
    id_satellite     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_fen_satellite REFERENCES SATELLITE(id_satellite),
    code_station     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_fen_station REFERENCES STATION_SOL(code_station)
);

-- ============================================================
-- TABLE 10 : PARTICIPATION
-- Dépend de SATELLITE et MISSION
-- PK composite (id_satellite, id_mission) — RG-M03
-- ============================================================
CREATE TABLE PARTICIPATION (
    id_satellite     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_part_satellite REFERENCES SATELLITE(id_satellite),
    id_mission       VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_part_mission REFERENCES MISSION(id_mission),
    role_satellite   VARCHAR2(100)  NOT NULL,
    CONSTRAINT pk_participation PRIMARY KEY (id_satellite, id_mission)
);

-- ============================================================
-- VERIFICATION DU SCHEMA
-- ============================================================
SELECT table_name FROM user_tables ORDER BY table_name;

SELECT table_name, constraint_name, constraint_type, search_condition
FROM user_constraints
WHERE table_name IN (
    'ORBITE','SATELLITE','INSTRUMENT','EMBARQUEMENT',
    'CENTRE_CONTROLE','STATION_SOL','AFFECTATION_STATION',
    'MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER BY table_name, constraint_type;
