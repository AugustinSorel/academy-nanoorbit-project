package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

/**
 * DAO — accès aux tables Room de NanoOrbit.
 *
 * Toutes les opérations sont suspendues (coroutines) pour ne jamais bloquer le thread principal.
 * Note : @Insert(onConflict = REPLACE) remplace @Upsert — comportement identique,
 * compatible avec Room 2.6.x + KSP + Kotlin 2.x (bug @Upsert sur type de retour Unit).
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

    /** INSERT ou REPLACE — équivalent fonctionnel à Upsert. */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSatellites(satellites: List<SatelliteEntity>)

    // ── Fenêtres de communication ────────────────────────────────────────────

    /** Fenêtres des 7 prochains jours (timestamp passé en paramètre). */
    @Query("SELECT * FROM fenetres_com WHERE datetimeDebut >= :fromEpoch ORDER BY datetimeDebut ASC")
    suspend fun getUpcomingFenetres(fromEpoch: Long): List<FenetreEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertFenetres(fenetres: List<FenetreEntity>)
}
