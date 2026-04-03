package com.example.myapplication.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.data.model.FenetreCom

/**
 * Entité Room — miroir de la table FENETRE_COM Oracle.
 *
 * Seules les fenêtres des 7 prochains jours sont mises en cache
 * (stratégie définie dans NanoOrbitRepository).
 * - datetimeDebut stocké en epoch ms.
 *
 * Phase 3 — L3-D
 */
@Entity(tableName = "fenetres_com")
data class FenetreEntity(
    @PrimaryKey val idFenetre: Long,
    val datetimeDebut: Long,      // epoch ms
    val duree: Int,               // secondes [1-900] — RG-F04
    val elevationMax: Double,
    val volumeDonnees: Double?,   // nullable si statut ≠ Réalisée — RG-F05
    val statut: String,           // Planifiée / Réalisée
    val idSatellite: String,
    val codeStation: String,
    val lastUpdated: Long = System.currentTimeMillis()
)

// ── Conversions domaine ↔ entité ────────────────────────────────────────────

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
