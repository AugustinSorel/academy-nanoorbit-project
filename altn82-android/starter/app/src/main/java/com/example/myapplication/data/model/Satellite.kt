package com.example.myapplication.data.model

import java.util.Date

/**
 * Modèle domaine d'un satellite.
 *
 * Ce modèle couvre deux sources JSON distinctes de l'API :
 *
 * 1. GET /satellites (sans filtre) — vue v_satellites_operationnels :
 *    Retourne uniquement les satellites Opérationnels avec les champs :
 *    id_satellite, nom_satellite, format_cubesat, orbite (string), nb_instruments,
 *    capacite_batterie, etat_batterie.
 *    Les champs statut, id_orbite, masse, duree_vie_prevue, date_lancement sont ABSENTS.
 *
 * 2. GET /satellites?statut=<non-Opérationnel> — table SATELLITE jointure ORBITE :
 *    Retourne les champs complets : statut, id_orbite, masse, duree_vie_prevue,
 *    date_lancement, type_orbite, altitude.
 *    Le champ orbite (string) et nb_instruments sont ABSENTS.
 *
 * Tous les champs spécifiques à une source sont nullable avec default = null.
 * Le champ statut null en source 1 est interprété comme OPERATIONNEL (vue filtre déjà).
 */
data class Satellite(
    val idSatellite: String,
    val nomSatellite: String,
    val formatCubesat: String,
    val capaciteBatterie: Double,

    // ── Champs vue v_satellites_operationnels (source 1) ────────────────────
    val orbite: String? = null,         // ex: "SSO 550km" — description textuelle
    val nbInstruments: Int? = null,
    val etatBatterie: String? = null,   // catégorie calculée : "Bonne" / "Moyenne" / "Faible"

    // ── Champs table SATELLITE (source 2 et détail) ──────────────────────────
    val statut: StatutSatellite? = null,
    val idOrbite: String? = null,       // FK → ORBITE
    val dateLancement: Date? = null,
    val masse: Double? = null,          // kg
    val dureeViePrevue: Int? = null,    // mois

    // ── Champs orbite jointe (source 2) ─────────────────────────────────────
    val typeOrbite: String? = null,
    val altitude: Double? = null
)
