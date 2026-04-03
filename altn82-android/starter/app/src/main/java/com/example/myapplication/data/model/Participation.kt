package com.example.myapplication.data.model

data class Participation(
    val idSatellite: String,        // PK+FK → SATELLITE
    val idMission: String,          // PK+FK → MISSION
    val roleSatellite: String
)
