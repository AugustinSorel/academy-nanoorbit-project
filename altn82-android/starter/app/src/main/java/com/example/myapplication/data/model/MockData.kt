package com.example.myapplication.data.model

import java.util.Calendar

// ---------------------------------------------------------------------------
// Jeu de données de référence ALTN83 — NanoOrbit
// ---------------------------------------------------------------------------

private fun date(year: Int, month: Int, day: Int, hour: Int = 0, min: Int = 0): java.util.Date =
    Calendar.getInstance().apply {
        set(year, month - 1, day, hour, min, 0)
        set(Calendar.MILLISECOND, 0)
    }.time

// ---------------------------------------------------------------------------
// ORBITES — 3 orbites (2 SSO, 1 LEO)
// ---------------------------------------------------------------------------

val mockOrbites: List<Orbite> = listOf(
    Orbite(
        idOrbite       = "ORB-001",
        typeOrbite     = "SSO",
        altitude       = 550,
        inclinaison    = 97.60,
        periodeOrbitale = 95.50,
        excentricite   = 0.0010,
        zoneCouverture = "Polaire globale — couverture complète du globe en 14 jours"
    ),
    Orbite(
        idOrbite       = "ORB-002",
        typeOrbite     = "SSO",
        altitude       = 700,
        inclinaison    = 98.20,
        periodeOrbitale = 98.80,
        excentricite   = 0.0012,
        zoneCouverture = "Polaire haute altitude — résolution temporelle réduite"
    ),
    Orbite(
        idOrbite       = "ORB-003",
        typeOrbite     = "LEO",
        altitude       = 400,
        inclinaison    = 51.60,
        periodeOrbitale = 92.60,
        excentricite   = 0.0008,
        zoneCouverture = "Basse orbite équatoriale — latitude max ±52°"
    )
)

// ---------------------------------------------------------------------------
// SATELLITES — 5 satellites dont 1 Désorbité (SAT-004)
// ---------------------------------------------------------------------------

val mockSatellites: List<Satellite> = listOf(
    Satellite(
        idSatellite      = "SAT-001",
        nomSatellite     = "NanoOrbit-Alpha",
        dateLancement    = date(2022, 3, 15),
        masse            = 1.30,
        formatCubesat    = "3U",
        statut           = StatutSatellite.OPERATIONNEL,
        dureeViePrevue   = 60,
        capaciteBatterie = 20.0,
        idOrbite         = "ORB-001"
    ),
    Satellite(
        idSatellite      = "SAT-002",
        nomSatellite     = "NanoOrbit-Beta",
        dateLancement    = date(2022, 9, 1),
        masse            = 2.66,
        formatCubesat    = "6U",
        statut           = StatutSatellite.OPERATIONNEL,
        dureeViePrevue   = 48,
        capaciteBatterie = 30.0,
        idOrbite         = "ORB-001"
    ),
    Satellite(
        idSatellite      = "SAT-003",
        nomSatellite     = "NanoOrbit-Gamma",
        dateLancement    = date(2023, 6, 20),
        masse            = 1.33,
        formatCubesat    = "3U",
        statut           = StatutSatellite.EN_VEILLE,
        dureeViePrevue   = 36,
        capaciteBatterie = 18.5,
        idOrbite         = "ORB-002"
    ),
    Satellite(
        idSatellite      = "SAT-004",
        nomSatellite     = "NanoOrbit-Delta",
        dateLancement    = date(2021, 1, 12),
        masse            = 1.30,
        formatCubesat    = "1U",
        statut           = StatutSatellite.DESORBITE,  // RG-S06 : plus de fenêtre ni mission
        dureeViePrevue   = 24,
        capaciteBatterie = 10.0,
        idOrbite         = "ORB-003"
    ),
    Satellite(
        idSatellite      = "SAT-005",
        nomSatellite     = "NanoOrbit-Epsilon",
        dateLancement    = date(2024, 2, 28),
        masse            = 5.40,
        formatCubesat    = "12U",
        statut           = StatutSatellite.OPERATIONNEL,
        dureeViePrevue   = 72,
        capaciteBatterie = 55.0,
        idOrbite         = "ORB-002"
    )
)

// ---------------------------------------------------------------------------
// INSTRUMENTS — 4 instruments
// ---------------------------------------------------------------------------

val mockInstruments: List<Instrument> = listOf(
    Instrument(
        refInstrument  = "INS-CAM-01",
        typeInstrument = "Caméra optique",
        modele         = "PlanetScope-Mini",
        resolution     = 3.0,
        consommation   = 2.5,
        masse          = 0.400
    ),
    Instrument(
        refInstrument  = "INS-IR-01",
        typeInstrument = "Infrarouge",
        modele         = "FLIR-Nano-IR",
        resolution     = 10.0,
        consommation   = 3.1,
        masse          = 0.350
    ),
    Instrument(
        refInstrument  = "INS-AIS-01",
        typeInstrument = "Récepteur AIS",
        modele         = "exactEarth-AIS-v3",
        resolution     = null,               // non applicable pour récepteur AIS
        consommation   = 1.2,
        masse          = 0.150
    ),
    Instrument(
        refInstrument  = "INS-SPEC-01",
        typeInstrument = "Spectromètre",
        modele         = "OCI-Compact",
        resolution     = 30.0,
        consommation   = 4.8,
        masse          = 0.620
    )
)

// ---------------------------------------------------------------------------
// STATIONS SOL — 3 stations avec coordonnées GPS réelles
// ---------------------------------------------------------------------------

val mockStations: List<StationSol> = listOf(
    StationSol(
        codeStation    = "GS-TLS-01",
        nomStation     = "Toulouse Station",
        latitude       = 43.604700,          // Toulouse, France
        longitude      = 1.444200,
        diametreAntenne = 3.5,
        bandeFrequence = "S",
        debitMax       = 150.0,
        statut         = "Active"
    ),
    StationSol(
        codeStation    = "GS-KIR-01",
        nomStation     = "Kiruna Ground Station",
        latitude       = 67.855800,          // Kiruna, Suède (ESA)
        longitude      = 20.225300,
        diametreAntenne = 5.4,
        bandeFrequence  = "X",
        debitMax       = 300.0,
        statut         = "Active"
    ),
    StationSol(
        codeStation    = "GS-SGP-01",
        nomStation     = "Singapore Downlink",
        latitude       = 1.352100,           // Singapour
        longitude      = 103.819800,
        diametreAntenne = 4.0,
        bandeFrequence  = "S",
        debitMax       = 200.0,
        statut         = "Maintenance"
    )
)

// ---------------------------------------------------------------------------
// FENÊTRES DE COMMUNICATION — 5 fenêtres (3 Réalisées, 2 Planifiées)
// ---------------------------------------------------------------------------

val mockFenetres: List<FenetreCom> = listOf(
    FenetreCom(
        idFenetre      = 1L,
        datetimeDebut  = date(2024, 1, 15, 9, 14),
        duree          = 420,                // secondes
        elevationMax   = 82.30,
        volumeDonnees  = 1250.0,             // Mo
        statut         = "Réalisée",
        idSatellite    = "SAT-001",
        codeStation    = "GS-KIR-01"
    ),
    FenetreCom(
        idFenetre      = 2L,
        datetimeDebut  = date(2024, 1, 15, 11, 32),
        duree          = 360,
        elevationMax   = 67.50,
        volumeDonnees  = 980.0,
        statut         = "Réalisée",
        idSatellite    = "SAT-002",
        codeStation    = "GS-TLS-01"
    ),
    FenetreCom(
        idFenetre      = 3L,
        datetimeDebut  = date(2024, 1, 16, 7, 48),
        duree          = 510,
        elevationMax   = 74.10,
        volumeDonnees  = 1540.0,
        statut         = "Réalisée",
        idSatellite    = "SAT-001",
        codeStation    = "GS-TLS-01"
    ),
    FenetreCom(
        idFenetre      = 4L,
        datetimeDebut  = date(2024, 4, 10, 14, 0),
        duree          = 480,
        elevationMax   = 55.00,
        volumeDonnees  = null,               // RG-F05 : NULL car statut ≠ Réalisée
        statut         = "Planifiée",
        idSatellite    = "SAT-002",
        codeStation    = "GS-KIR-01"
    ),
    FenetreCom(
        idFenetre      = 5L,
        datetimeDebut  = date(2024, 4, 10, 16, 22),
        duree          = 300,
        elevationMax   = 41.80,
        volumeDonnees  = null,               // RG-F05 : NULL car statut ≠ Réalisée
        statut         = "Planifiée",
        idSatellite    = "SAT-005",
        codeStation    = "GS-KIR-01"
    )
)

// ---------------------------------------------------------------------------
// EMBARQUEMENTS
// ---------------------------------------------------------------------------

val mockEmbarquements: List<Embarquement> = listOf(
    Embarquement("SAT-001", "INS-CAM-01",  date(2022, 3, 15),  "Actif"),
    Embarquement("SAT-001", "INS-AIS-01",  date(2022, 3, 15),  "Actif"),
    Embarquement("SAT-002", "INS-IR-01",   date(2022, 9, 1),   "Actif"),
    Embarquement("SAT-002", "INS-CAM-01",  date(2022, 9, 1),   "Dégradé"),
    Embarquement("SAT-003", "INS-SPEC-01", date(2023, 6, 20),  "Inactif"),
    Embarquement("SAT-005", "INS-CAM-01",  date(2024, 2, 28),  "Actif"),
    Embarquement("SAT-005", "INS-SPEC-01", date(2024, 2, 28),  "Actif")
)

// ---------------------------------------------------------------------------
// MISSIONS
// ---------------------------------------------------------------------------

val mockMissions: List<Mission> = listOf(
    Mission(
        idMission      = "MSN-ARC-2023",
        nomMission     = "ArcticWatch 2023",
        objectif       = "Surveillance des glaces arctiques et suivi de la fonte des calottes polaires",
        zoneGeoCible   = "Arctique — latitude > 66°N",
        dateDebut      = date(2023, 1, 1),
        dateFin        = date(2023, 12, 31),
        statutMission  = "Terminée"
    ),
    Mission(
        idMission      = "MSN-MAR-2024",
        nomMission     = "MarineTrack 2024",
        objectif       = "Détection et suivi du trafic maritime mondial via AIS",
        zoneGeoCible   = "Océans Atlantique et Pacifique",
        dateDebut      = date(2024, 1, 1),
        dateFin        = null,               // RG-M01 : mission en cours
        statutMission  = "Active"
    )
)

// ---------------------------------------------------------------------------
// PARTICIPATIONS
// ---------------------------------------------------------------------------

val mockParticipations: List<Participation> = listOf(
    Participation("SAT-001", "MSN-ARC-2023", "Imageur principal"),
    Participation("SAT-003", "MSN-ARC-2023", "Imageur secondaire"),
    Participation("SAT-001", "MSN-MAR-2024", "Imageur principal"),
    Participation("SAT-002", "MSN-MAR-2024", "Récepteur AIS")
)
