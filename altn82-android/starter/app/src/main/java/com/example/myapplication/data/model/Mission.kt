package com.example.myapplication.data.model

import java.util.Date

data class Mission(
    val idMission: String,          // PK, format MSN-XXX-AAAA
    val nomMission: String,
    val objectif: String,
    val zoneGeoCible: String,
    val dateDebut: Date,
    val dateFin: Date?,             // nullable si mission active
    val statutMission: String       // Active / Terminée
)
