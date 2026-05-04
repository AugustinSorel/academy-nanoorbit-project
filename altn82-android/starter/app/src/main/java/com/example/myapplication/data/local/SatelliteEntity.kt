package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite

@Entity(tableName = "satellites")
data class SatelliteEntity(
    @PrimaryKey val idSatellite: String,
    val nomSatellite: String,
    val formatCubesat: String,
    val capaciteBatterie: Double,
    val statut: String? = null,
    val idOrbite: String? = null,
    val masse: Double? = null,
    val dureeViePrevue: Int? = null,
    val dateLancement: Long? = null,
    val orbite: String? = null,
    val nbInstruments: Int? = null,
    val lastUpdated: Long = System.currentTimeMillis()
)

fun Satellite.toEntity() = SatelliteEntity(
    idSatellite      = idSatellite,
    nomSatellite     = nomSatellite,
    formatCubesat    = formatCubesat,
    capaciteBatterie = capaciteBatterie,
    statut           = statut?.name,
    idOrbite         = idOrbite,
    masse            = masse,
    dureeViePrevue   = dureeViePrevue,
    dateLancement    = dateLancement?.time,
    orbite           = orbite,
    nbInstruments    = nbInstruments
)

fun SatelliteEntity.toDomain() = Satellite(
    idSatellite      = idSatellite,
    nomSatellite     = nomSatellite,
    formatCubesat    = formatCubesat,
    capaciteBatterie = capaciteBatterie,
    statut           = statut?.let {
        try { StatutSatellite.valueOf(it) } catch (_: IllegalArgumentException) { null }
    },
    idOrbite         = idOrbite,
    masse            = masse,
    dureeViePrevue   = dureeViePrevue,
    dateLancement    = dateLancement?.let { java.util.Date(it) },
    orbite           = orbite,
    nbInstruments    = nbInstruments
)
