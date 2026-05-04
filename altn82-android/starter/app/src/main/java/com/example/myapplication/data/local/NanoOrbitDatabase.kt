package com.example.myapplication.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [SatelliteEntity::class, FenetreEntity::class],
    version = 2,
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
            )
            .fallbackToDestructiveMigration()
            .build()
    }
}
