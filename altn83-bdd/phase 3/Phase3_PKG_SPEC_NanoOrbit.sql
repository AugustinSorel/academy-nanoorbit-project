CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS
    c_pi          CONSTANT NUMBER := 3.14159265359;
    c_rayon_terre CONSTANT NUMBER := 6371;           -- km

    TYPE t_resume_satellite IS RECORD (
        id_satellite      SATELLITE.id_satellite%TYPE,
        nom_satellite     SATELLITE.nom_satellite%TYPE,
        statut            SATELLITE.statut%TYPE,
        type_orbite       ORBITE.type_orbite%TYPE,
        altitude          ORBITE.altitude%TYPE,
        nb_instruments    NUMBER
    );


    PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2);

    PROCEDURE mettre_a_jour_statut(
        p_id            IN  VARCHAR2,
        p_statut        IN  VARCHAR2,
        p_ancien_statut OUT VARCHAR2
    );

    PROCEDURE rapport_flotte;

    PROCEDURE rapport_station(p_code_station IN VARCHAR2);

    PROCEDURE valider_fenetre(
        p_id_satellite IN VARCHAR2,
        p_code_station IN VARCHAR2,
        p_datetime     IN TIMESTAMP,
        p_duree        IN NUMBER
    );

    FUNCTION calculer_volume_session(p_id_fenetre IN VARCHAR2) RETURN NUMBER;

    FUNCTION vitesse_orbitale(p_id_satellite IN VARCHAR2) RETURN NUMBER;

    FUNCTION nb_instruments(p_id_satellite IN VARCHAR2) RETURN NUMBER;

    FUNCTION get_resume_satellite(p_id IN VARCHAR2) RETURN t_resume_satellite;

END pkg_nanoOrbit;
/

SHOW ERRORS PACKAGE pkg_nanoOrbit;
