package com.example.myapplication.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface NanoOrbitDao {

    @Query("SELECT * FROM satellites")
    suspend fun getAllSatellites(): List<SatelliteEntity>

    @Query("SELECT MAX(lastUpdated) FROM satellites")
    suspend fun getLastUpdated(): Long?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSatellites(satellites: List<SatelliteEntity>)

    @Query("SELECT * FROM fenetres_com WHERE datetimeDebut >= :fromEpoch ORDER BY datetimeDebut ASC")
    suspend fun getUpcomingFenetres(fromEpoch: Long): List<FenetreEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertFenetres(fenetres: List<FenetreEntity>)
}
