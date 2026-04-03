package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite

/**
 * Entité Room — cache local de la constellation.
 *
 * Le schéma reflète l'union des deux sources de l'API :
 *   - Vue v_satellites_operationnels : orbite (string), nbInstruments
 *   - Table SATELLITE : statut, idOrbite, masse, dureeViePrevue, dateLancement
 * Tous les champs spécifiques à une source sont nullable.
 *
 * Version 2 : champs nullable pour compatibilité vue + table de base.
 * fallbackToDestructiveMigration() configuré dans NanoOrbitDatabase.
 *
 * Phase 3 — L3-D / refactoring routes
 */
@Entity(tableName = "satellites")
data class SatelliteEntity(
    @PrimaryKey val idSatellite: String,
    val nomSatellite: String,
    val formatCubesat: String,
    val capaciteBatterie: Double,
    val statut: String? = null,         // StatutSatellite.name, null si source = vue
    val idOrbite: String? = null,       // null si source = vue
    val masse: Double? = null,          // null si source = vue
    val dureeViePrevue: Int? = null,    // null si source = vue
    val dateLancement: Long? = null,    // epoch ms, null si source = vue
    val orbite: String? = null,         // string orbite de la vue, null si source = table
    val nbInstruments: Int? = null,     // null si source = table
    val lastUpdated: Long = System.currentTimeMillis()
)

// ── Conversions domaine ↔ entité ────────────────────────────────────────────

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
