package com.example.myapplication.di

import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module

/**
 * Module Koin principal — Phase 1.
 * Phase 2 ajoutera : single<NanoOrbitRepository> { ... } + single<NanoOrbitApi> { ... }
 */
val appModule = module {
    viewModel { NanoOrbitViewModel() }
}
