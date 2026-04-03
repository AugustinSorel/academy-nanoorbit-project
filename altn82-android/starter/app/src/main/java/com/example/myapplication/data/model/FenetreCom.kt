package com.example.myapplication.data.model

import java.util.Date

data class FenetreCom(
    val idFenetre: Long,            // PK, auto-incrémentée
    val datetimeDebut: Date,
    val duree: Int,                 // secondes, entre 1 et 900
    val elevationMax: Double,       // degrés
    val volumeDonnees: Double?,     // Mo, nullable si statut ≠ Réalisée
    val statut: String,             // Planifiée / Réalisée
    val idSatellite: String,        // FK → SATELLITE
    val codeStation: String         // FK → STATION_SOL
)
