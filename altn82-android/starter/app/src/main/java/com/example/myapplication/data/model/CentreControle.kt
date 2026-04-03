package com.example.myapplication.data.model

data class CentreControle(
    val idCentre: String,           // PK, format CTR-NNN
    val nomCentre: String,
    val ville: String,
    val regionGeo: String,          // Europe / Amériques / Asie-Pacifique
    val fuseauHoraire: String,      // IANA timezone id
    val statut: String              // Actif / Inactif
)
