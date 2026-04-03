package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert

/**
 * DAO — accès aux tables Room de NanoOrbit.
 *
 * Toutes les opérations sont suspendues (coroutines) pour ne jamais bloquer le thread principal.
 * Phase 3 — L3-D
 */
@Dao
interface NanoOrbitDao {

    // ── Satellites ──────────────────────────────────────────────────────────

    @Query("SELECT * FROM satellites")
    suspend fun getAllSatellites(): List<SatelliteEntity>

    /** Horodatage de la dernière mise à jour réseau (pour la bannière "mis à jour il y a X min"). */
    @Query("SELECT MAX(lastUpdated) FROM satellites")
    suspend fun getLastUpdated(): Long?

    /** INSERT ou UPDATE (upsert) — utilisé lors de la mise à jour réseau. */
    @Upsert
    suspend fun upsertSatellites(satellites: List<SatelliteEntity>)

    // ── Fenêtres de communication ────────────────────────────────────────────

    /** Fenêtres des 7 prochains jours (timestamp passé en paramètre). */
    @Query("SELECT * FROM fenetres_com WHERE datetimeDebut >= :fromEpoch ORDER BY datetimeDebut ASC")
    suspend fun getUpcomingFenetres(fromEpoch: Long): List<FenetreEntity>

    @Upsert
    suspend fun upsertFenetres(fenetres: List<FenetreEntity>)
}
