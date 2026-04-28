DROP TABLE PARTICIPATION       CASCADE CONSTRAINTS;
DROP TABLE FENETRE_COM         CASCADE CONSTRAINTS;
DROP TABLE MISSION             CASCADE CONSTRAINTS;
DROP TABLE EMBARQUEMENT        CASCADE CONSTRAINTS;
DROP TABLE HISTORIQUE_STATUT   CASCADE CONSTRAINTS;
DROP TABLE STATION_SOL         CASCADE CONSTRAINTS;
DROP TABLE CENTRE_CONTROLE     CASCADE CONSTRAINTS;
DROP TABLE INSTRUMENT          CASCADE CONSTRAINTS;
DROP TABLE SATELLITE           CASCADE CONSTRAINTS;
DROP TABLE ORBITE              CASCADE CONSTRAINTS;
DROP SEQUENCE seq_historique;

CREATE TABLE ORBITE (
    id_orbite        VARCHAR2(20)   CONSTRAINT pk_orbite PRIMARY KEY,
    type_orbite      VARCHAR2(10)   NOT NULL
                     CONSTRAINT ck_orbite_type CHECK (type_orbite IN ('SSO','LEO','MEO','GEO')),
    altitude         NUMBER(7,2)    NOT NULL,
    inclinaison      NUMBER(5,2)    NOT NULL,
    periode_orbitale NUMBER(7,2)    NOT NULL,
    excentricite     NUMBER(8,6)    NOT NULL,
    zone_couverture  VARCHAR2(200)  NOT NULL,
    CONSTRAINT uq_orbite_alt_inc UNIQUE (altitude, inclinaison)
);

CREATE TABLE SATELLITE (
    id_satellite      VARCHAR2(20)   CONSTRAINT pk_satellite PRIMARY KEY,
    nom_satellite     VARCHAR2(100)  NOT NULL,
    date_lancement    DATE           NOT NULL,
    masse             NUMBER(7,2)    NOT NULL,
    format_cubesat    VARCHAR2(3)    NOT NULL
                      CONSTRAINT ck_sat_format CHECK (format_cubesat IN ('1U','3U','6U','12U')),

    statut            VARCHAR2(30)   NOT NULL
                      CONSTRAINT ck_sat_statut CHECK (statut IN ('Opérationnel','En veille','Défaillant','Désorbité')),
    duree_vie_prevue  NUMBER(5,2)    NOT NULL,
    capacite_batterie NUMBER(5,2)    NOT NULL,
    id_orbite         VARCHAR2(20)   NOT NULL
                      CONSTRAINT fk_sat_orbite REFERENCES ORBITE(id_orbite)
);

CREATE SEQUENCE seq_historique START WITH 1 INCREMENT BY 1;

CREATE TABLE HISTORIQUE_STATUT (
    id_historique     NUMBER         DEFAULT seq_historique.NEXTVAL CONSTRAINT pk_historique PRIMARY KEY,
    id_satellite      VARCHAR2(20)   NOT NULL
                      CONSTRAINT fk_hist_satellite REFERENCES SATELLITE(id_satellite),
    ancien_statut     VARCHAR2(30)   NOT NULL,
    nouveau_statut    VARCHAR2(30)   NOT NULL,
    date_changement   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    motif             VARCHAR2(200)
);

CREATE TABLE INSTRUMENT (
    ref_instrument   VARCHAR2(20)   CONSTRAINT pk_instrument PRIMARY KEY,
    type_instrument  VARCHAR2(50)   NOT NULL,
    modele           VARCHAR2(100)  NOT NULL,
    resolution       NUMBER(10,2), 
    consommation     NUMBER(7,2)    NOT NULL,
    masse            NUMBER(7,2)    NOT NULL
);

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

CREATE TABLE CENTRE_CONTROLE (
    id_centre        VARCHAR2(20)   CONSTRAINT pk_centre PRIMARY KEY,
    nom_centre       VARCHAR2(100)  NOT NULL,
    ville            VARCHAR2(100)  NOT NULL,
    region_geo       VARCHAR2(100)  NOT NULL,
    fuseau_horaire   VARCHAR2(50)   NOT NULL,
    statut           VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_centre_statut CHECK (statut IN ('Actif','Inactif'))
);

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

CREATE TABLE MISSION (
    id_mission       VARCHAR2(20)   CONSTRAINT pk_mission PRIMARY KEY,
    nom_mission      VARCHAR2(100)  NOT NULL,
    objectif         VARCHAR2(500)  NOT NULL,
    zone_geo_cible   VARCHAR2(200)  NOT NULL,
    date_debut       DATE           NOT NULL,
    date_fin         DATE,          
    statut_mission   VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_mission_statut CHECK (statut_mission IN ('Active','Terminée','Planifiée'))
);

CREATE TABLE FENETRE_COM (
    id_fenetre       VARCHAR2(20)   CONSTRAINT pk_fenetre PRIMARY KEY,
    datetime_debut   TIMESTAMP      NOT NULL,
    duree            NUMBER(4)      NOT NULL
                     CONSTRAINT ck_fen_duree CHECK (duree BETWEEN 1 AND 900),

    elevation_max    NUMBER(5,2)    NOT NULL,
    volume_donnees   NUMBER(12,2),  -- Nullable — RG-F05 : NULL si statut != 'Réalisée'
    statut           VARCHAR2(20)   NOT NULL
                     CONSTRAINT ck_fen_statut CHECK (statut IN ('Planifiée','Réalisée','Annulée')),
    id_satellite     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_fen_satellite REFERENCES SATELLITE(id_satellite),
    code_station     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_fen_station REFERENCES STATION_SOL(code_station)
);

CREATE TABLE PARTICIPATION (
    id_satellite     VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_part_satellite REFERENCES SATELLITE(id_satellite),
    id_mission       VARCHAR2(20)   NOT NULL
                     CONSTRAINT fk_part_mission REFERENCES MISSION(id_mission),
    role_satellite   VARCHAR2(100)  NOT NULL,
    CONSTRAINT pk_participation PRIMARY KEY (id_satellite, id_mission)
);

SELECT table_name FROM user_tables ORDER BY table_name;

SELECT table_name, constraint_name, constraint_type, search_condition
FROM user_constraints
WHERE table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT','EMBARQUEMENT',
    'CENTRE_CONTROLE','STATION_SOL',
    'MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER BY table_name, constraint_type;
