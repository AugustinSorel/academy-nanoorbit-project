package com.example.myapplication.data.model

data class Orbite(
    val idOrbite: String,           // PK, format ORB-NNN
    val typeOrbite: String,         // LEO / MEO / SSO / GEO
    val altitude: Int,              // km
    val inclinaison: Double,        // degrés
    val periodeOrbitale: Double,    // minutes
    val excentricite: Double,
    val zoneCouverture: String
)
