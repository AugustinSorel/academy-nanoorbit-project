package com.example.myapplication.data.model

import com.google.gson.annotations.SerializedName

enum class StatutSatellite(val displayName: String) {
    @SerializedName("Opérationnel")
    OPERATIONNEL("Opérationnel"),
    @SerializedName("En veille")
    EN_VEILLE("En veille"),
    @SerializedName("Défaillant")
    DEFAILLANT("Défaillant"),
    @SerializedName("Désorbité")
    DESORBITE("Désorbité")
}
