-- ============================================================
-- PROJET NANOORBIT — PHASE 3 — L3-B : PACKAGE SPEC
-- Module ALTN83 — Bases de Données Réparties
-- SGBD : Oracle 23ai — Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================
-- Package pkg_nanoOrbit — Spécification (SPEC)
-- Regroupe les procédures et fonctions du Palier 5 + utilitaires
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS

    -- ==============================================================
    -- CONSTANTES PUBLIQUES
    -- ==============================================================
    c_pi          CONSTANT NUMBER := 3.14159265359;
    c_rayon_terre CONSTANT NUMBER := 6371;           -- km

    -- ==============================================================
    -- TYPES PUBLICS
    -- ==============================================================
    -- Record pour résumé satellite
    TYPE t_resume_satellite IS RECORD (
        id_satellite      SATELLITE.id_satellite%TYPE,
        nom_satellite     SATELLITE.nom_satellite%TYPE,
        statut            SATELLITE.statut%TYPE,
        type_orbite       ORBITE.type_orbite%TYPE,
        altitude          ORBITE.altitude%TYPE,
        nb_instruments    NUMBER
    );

    -- ==============================================================
    -- PROCEDURES PUBLIQUES
    -- ==============================================================

    -- Ex.14 : Affiche le statut, l'orbite et les instruments d'un satellite
    PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2);

    -- Ex.15 : Met à jour le statut d'un satellite, retourne l'ancien statut
    PROCEDURE mettre_a_jour_statut(
        p_id            IN  VARCHAR2,
        p_statut        IN  VARCHAR2,
        p_ancien_statut OUT VARCHAR2
    );

    -- Afficher le résumé complet de la flotte (tous les satellites)
    PROCEDURE rapport_flotte;

    -- Afficher les fenêtres d'une station donnée avec volume total
    PROCEDURE rapport_station(p_code_station IN VARCHAR2);

    -- Valider les conditions avant insertion d'une fenêtre (Ex.13 amélioré)
    PROCEDURE valider_fenetre(
        p_id_satellite IN VARCHAR2,
        p_code_station IN VARCHAR2,
        p_datetime     IN TIMESTAMP,
        p_duree        IN NUMBER
    );

    -- ==============================================================
    -- FONCTIONS PUBLIQUES
    -- ==============================================================

    -- Ex.16 : Calcule le volume théorique d'une fenêtre (Mo)
    FUNCTION calculer_volume_session(p_id_fenetre IN VARCHAR2) RETURN NUMBER;

    -- Ex.6 : Calcule la vitesse orbitale d'un satellite (km/s)
    FUNCTION vitesse_orbitale(p_id_satellite IN VARCHAR2) RETURN NUMBER;

    -- Retourne le nombre d'instruments embarqués sur un satellite
    FUNCTION nb_instruments(p_id_satellite IN VARCHAR2) RETURN NUMBER;

    -- Retourne le résumé d'un satellite sous forme de record
    FUNCTION get_resume_satellite(p_id IN VARCHAR2) RETURN t_resume_satellite;

END pkg_nanoOrbit;
/

SHOW ERRORS PACKAGE pkg_nanoOrbit;
