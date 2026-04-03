package com.example.myapplication.data.model

data class StationSol(
    val codeStation: String,            // PK, format GS-XXX-NN
    val nomStation: String,
    val latitude: Double,
    val longitude: Double,
    val diametreAntenne: Double,        // mètres
    val bandeFrequence: String,         // UHF / S / X / Ka
    val debitMax: Double,               // Mbps
    val statut: String,                 // Active / Maintenance / Inactive
    val nbFenetresTotal: Int? = null    // COUNT depuis GET /stations (agrégat JOIN)
)
