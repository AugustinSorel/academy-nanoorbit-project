package com.example.myapplication.data.model

import java.util.Date

data class Satellite(
    val idSatellite: String,            // PK, format SAT-NNN — Oracle VARCHAR2(20)
    val nomSatellite: String,           // Oracle VARCHAR2(100)
    val dateLancement: Date,            // Oracle DATE
    val masse: Double,                  // kg — Oracle NUMBER(5,2)
    val formatCubesat: String,          // 1U / 3U / 6U / 12U — Oracle CHECK
    val statut: StatutSatellite,        // enum miroir CHECK Oracle (voir StatutSatellite.kt)
    val dureeViePrevue: Int,            // mois — Oracle NUMBER(4)
    val capaciteBatterie: Double,       // Wh — Oracle NUMBER(6,1)
    val idOrbite: String                // FK → ORBITE — Oracle VARCHAR2(10)
)
