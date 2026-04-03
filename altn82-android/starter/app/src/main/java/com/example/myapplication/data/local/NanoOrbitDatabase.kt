package com.example.myapplication.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Base de données Room — NanoOrbit Ground Control.
 *
 * Entités :
 *   - SatelliteEntity  → table "satellites"
 *   - FenetreEntity    → table "fenetres_com"
 *
 * Stratégie hors-ligne (Synergie ALTN83 Q3) :
 * Room joue le rôle de miroir local de la base Oracle. Si le serveur central
 * est indisponible (ex : Singapour sans réseau), l'application lit les données
 * du cache Room et affiche une bannière "Mode hors-ligne".
 *
 * Phase 3 — L3-D
 */
@Database(
    entities = [SatelliteEntity::class, FenetreEntity::class],
    version = 1,
    exportSchema = false
)
abstract class NanoOrbitDatabase : RoomDatabase() {
    abstract fun nanoOrbitDao(): NanoOrbitDao

    companion object {
        fun create(context: Context): NanoOrbitDatabase =
            Room.databaseBuilder(
                context,
                NanoOrbitDatabase::class.java,
                "nanoorbit_db"
            ).build()
    }
}
