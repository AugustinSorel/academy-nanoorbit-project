package com.example.myapplication.data.model

import java.util.Date

data class Embarquement(
    val idSatellite: String,        // PK+FK → SATELLITE
    val refInstrument: String,      // PK+FK → INSTRUMENT
    val dateIntegration: Date,
    val etatFonctionnement: String  // Nominal / Dégradé / Hors service
)
