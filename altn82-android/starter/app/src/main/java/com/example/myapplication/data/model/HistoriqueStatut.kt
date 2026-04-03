package com.example.myapplication.data.model

import java.util.Date

data class HistoriqueStatut(
    val idHistorique: Long,         // PK, auto-incrémentée
    val idSatellite: String,        // FK → SATELLITE
    val ancienStatut: String,
    val nouveauStatut: String,
    val dateChangement: Date,
    val motif: String?              // nullable
)
