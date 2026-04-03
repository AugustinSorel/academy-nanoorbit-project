package com.example.myapplication.data.model

data class Instrument(
    val refInstrument: String,      // PK, format INS-XXX-NN
    val typeInstrument: String,     // Caméra optique / Infrarouge / Récepteur AIS / Spectromètre
    val modele: String,
    val resolution: Double?,        // m, nullable si non applicable
    val consommation: Double,       // W
    val masse: Double               // kg
)
