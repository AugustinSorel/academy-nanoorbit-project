package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.data.model.FenetreCom

@Entity(tableName = "fenetres_com")
data class FenetreEntity(
    @PrimaryKey val idFenetre: Long,
    val datetimeDebut: Long,
    val duree: Int,
    val elevationMax: Double,
    val volumeDonnees: Double?,
    val statut: String,
    val idSatellite: String,
    val codeStation: String,
    val lastUpdated: Long = System.currentTimeMillis()
)

fun FenetreCom.toEntity() = FenetreEntity(
    idFenetre     = idFenetre,
    datetimeDebut = datetimeDebut.time,
    duree         = duree,
    elevationMax  = elevationMax,
    volumeDonnees = volumeDonnees,
    statut        = statut,
    idSatellite   = idSatellite,
    codeStation   = codeStation
)

fun FenetreEntity.toDomain() = FenetreCom(
    idFenetre     = idFenetre,
    datetimeDebut = java.util.Date(datetimeDebut),
    duree         = duree,
    elevationMax  = elevationMax,
    volumeDonnees = volumeDonnees,
    statut        = statut,
    idSatellite   = idSatellite,
    codeStation   = codeStation
)
