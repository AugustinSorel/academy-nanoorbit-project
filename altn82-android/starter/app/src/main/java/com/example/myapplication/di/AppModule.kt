package com.example.myapplication.di

import com.example.myapplication.data.local.NanoOrbitDatabase
import com.example.myapplication.data.remote.NanoOrbitApi
import com.example.myapplication.data.repository.NanoOrbitRepository
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/**
 * Module Koin — Phase 3.
 *
 * Graphe de dépendances :
 *   Retrofit → NanoOrbitApi ──┐
 *                              ├→ NanoOrbitRepository → NanoOrbitViewModel
 *   Room → NanoOrbitDao ──────┘
 *
 * single<T>  : singleton partagé (Repository, API, DB).
 * viewModel  : recréé par Android, survit aux rotations via viewModelScope.
 */
val appModule = module {

    // ── Retrofit ────────────────────────────────────────────────────────────
    single {
        Retrofit.Builder()
            .baseUrl("https://api.nanoorbit.io/v1/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    single<NanoOrbitApi> {
        get<Retrofit>().create(NanoOrbitApi::class.java)
    }

    // ── Room — base de données locale Cache-First ────────────────────────────
    single {
        NanoOrbitDatabase.create(androidContext())
    }

    single {
        get<NanoOrbitDatabase>().nanoOrbitDao()
    }

    // ── Repository ──────────────────────────────────────────────────────────
    single<NanoOrbitRepository> {
        NanoOrbitRepository(api = get(), dao = get())
    }

    // ── ViewModel ───────────────────────────────────────────────────────────
    viewModel {
        NanoOrbitViewModel(repository = get())
    }
}
