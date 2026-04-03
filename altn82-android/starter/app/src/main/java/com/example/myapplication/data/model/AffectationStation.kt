package com.example.myapplication.data.model

import java.util.Date

data class AffectationStation(
    val idCentre: String,           // PK+FK → CENTRE_CONTROLE
    val codeStation: String,        // PK+FK → STATION_SOL
    val dateAffectation: Date
)
