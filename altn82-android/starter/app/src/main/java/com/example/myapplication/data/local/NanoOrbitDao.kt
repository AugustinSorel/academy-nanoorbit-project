package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

/**
 * DAO — accès aux tables Room de NanoOrbit.
 *
 * Toutes les opérations sont suspendues (coroutines) pour ne jamais bloquer le thread principal.
 * @Insert(onConflict = REPLACE) utilisé à la place de @Upsert : comportement identique,
 * sans le bug KSP/Room sur la résolution du type de retour Unit ("unexpected jvm signature V").
 * Phase 3 — L3-D
 */
@Dao
interface NanoOrbitDao {

    // ── Satellites ──────────────────────────────────────────────────────────

    @Query("SELECT * FROM satellites")
    suspend fun getAllSatellites(): List<SatelliteEntity>

    @Query("SELECT MAX(lastUpdated) FROM satellites")
    suspend fun getLastUpdated(): Long?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSatellites(satellites: List<SatelliteEntity>)

    // ── Fenêtres de communication ────────────────────────────────────────────

    @Query("SELECT * FROM fenetres_com WHERE datetimeDebut >= :fromEpoch ORDER BY datetimeDebut ASC")
    suspend fun getUpcomingFenetres(fromEpoch: Long): List<FenetreEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertFenetres(fenetres: List<FenetreEntity>)
}
