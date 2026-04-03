package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite

/**
 * Entité Room — miroir de la table SATELLITE Oracle.
 *
 * Tous les champs de la data class Satellite sont persistés.
 * - Date stockée en epoch ms (Long) pour Room.
 * - StatutSatellite stocké en String et reconverti à la lecture.
 * - lastUpdated : horodatage de la dernière mise à jour réseau (stratégie Cache-First).
 *
 * Phase 3 — L3-D
 */
@Entity(tableName = "satellites")
data class SatelliteEntity(
    @PrimaryKey val idSatellite: String,
    val nomSatellite: String,
    val statut: String,           // StatutSatellite.name stocké en String
    val formatCubesat: String,
    val idOrbite: String,
    val masse: Double,
    val dureeViePrevue: Int,
    val capaciteBatterie: Double,
    val dateLancement: Long,      // epoch ms — oracle: DATE non-null
    val lastUpdated: Long = System.currentTimeMillis()
)

// ── Conversions domaine ↔ entité ────────────────────────────────────────────

fun Satellite.toEntity() = SatelliteEntity(
    idSatellite      = idSatellite,
    nomSatellite     = nomSatellite,
    statut           = statut.name,
    formatCubesat    = formatCubesat,
    idOrbite         = idOrbite,
    masse            = masse,
    dureeViePrevue   = dureeViePrevue,
    capaciteBatterie = capaciteBatterie,
    dateLancement    = dateLancement.time
)

fun SatelliteEntity.toDomain() = Satellite(
    idSatellite      = idSatellite,
    nomSatellite     = nomSatellite,
    statut           = StatutSatellite.valueOf(statut),
    formatCubesat    = formatCubesat,
    idOrbite         = idOrbite,
    masse            = masse,
    dureeViePrevue   = dureeViePrevue,
    capaciteBatterie = capaciteBatterie,
    dateLancement    = java.util.Date(dateLancement)
)
