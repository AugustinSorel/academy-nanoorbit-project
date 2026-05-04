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

val appModule = module {

    single {
        val oracleNamingStrategy = FieldNamingStrategy { field ->
            field.name
                .replace(Regex("([A-Z])"), "_$1")
                .uppercase()
        }

        val gson = GsonBuilder()
            .setFieldNamingStrategy(oracleNamingStrategy)
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .create()

        Retrofit.Builder()
            .baseUrl("http://10.0.2.2:3000/")
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    single<NanoOrbitApi> {
        get<Retrofit>().create(NanoOrbitApi::class.java)
    }

    single {
        NanoOrbitDatabase.create(androidContext())
    }

    single {
        get<NanoOrbitDatabase>().nanoOrbitDao()
    }

    single<NanoOrbitRepository> {
        NanoOrbitRepository(api = get(), dao = get())
    }

    viewModel {
        NanoOrbitViewModel(repository = get())
    }
}
