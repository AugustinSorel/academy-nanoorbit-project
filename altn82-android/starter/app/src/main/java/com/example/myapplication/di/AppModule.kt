package com.example.myapplication.di

import com.example.myapplication.data.local.NanoOrbitDatabase
import com.example.myapplication.data.remote.NanoOrbitApi
import com.example.myapplication.data.repository.NanoOrbitRepository
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import com.google.gson.FieldNamingStrategy
import com.google.gson.GsonBuilder
import org.koin.android.ext.koin.androidContext
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Module Koin — Phase 3 / refactoring routes.
 *
 * Graphe de dépendances :
 *   Retrofit → NanoOrbitApi ──┐
 *                              ├→ NanoOrbitRepository → NanoOrbitViewModel
 *   Room → NanoOrbitDao ──────┘
 *
 * Configuration Gson — stratégie UPPER_CASE_WITH_UNDERSCORES :
 *   node-oracledb avec outFormat: OUT_FORMAT_OBJECT (4002) retourne les noms de colonnes
 *   Oracle en MAJUSCULES (ex: ID_SATELLITE, NOM_SATELLITE, DATE_LANCEMENT).
 *   La stratégie convertit le camelCase Kotlin → UPPER_CASE_WITH_UNDERSCORES pour matcher.
 *     idSatellite      → ID_SATELLITE      ✓
 *     nomSatellite     → NOM_SATELLITE     ✓
 *     dateLancement    → DATE_LANCEMENT    ✓
 *     formatCubesat    → FORMAT_CUBESAT    ✓
 *     capaciteBatterie → CAPACITE_BATTERIE ✓
 *   Exception : les clés ajoutées côté JavaScript (instruments, missions, recentFenetres)
 *   restent en camelCase — gérées avec @SerializedName dans SatelliteDetail.
 *   Exception : statut_fenetre (alias de vue) → géré avec @SerializedName dans FenetreCom.
 */
val appModule = module {

    // ── Retrofit ─────────────────────────────────────────────────────────────
    single {
        val oracleNamingStrategy = FieldNamingStrategy { field ->
            // camelCase → UPPER_CASE_WITH_UNDERSCORES
            // idSatellite → ID_SATELLITE
            field.name
                .replace(Regex("([A-Z])"), "_$1")
                .uppercase()
        }

        val gson = GsonBuilder()
            .setFieldNamingStrategy(oracleNamingStrategy)
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .create()

        Retrofit.Builder()
            .baseUrl("http://10.0.2.2:3000/")  // 10.0.2.2 = hôte local vu depuis l'émulateur
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    single<NanoOrbitApi> {
        get<Retrofit>().create(NanoOrbitApi::class.java)
    }

    // ── Room — base de données locale Cache-First ─────────────────────────────
    single {
        NanoOrbitDatabase.create(androidContext())
    }

    single {
        get<NanoOrbitDatabase>().nanoOrbitDao()
    }

    // ── Repository ────────────────────────────────────────────────────────────
    single<NanoOrbitRepository> {
        NanoOrbitRepository(api = get(), dao = get())
    }

    // ── ViewModel ─────────────────────────────────────────────────────────────
    viewModel {
        NanoOrbitViewModel(repository = get())
    }
}
