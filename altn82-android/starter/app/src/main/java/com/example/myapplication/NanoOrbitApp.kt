package com.example.myapplication

import android.app.Application
import com.example.myapplication.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.startKoin
import org.koin.core.logger.Level

class NanoOrbitApp : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidLogger(Level.DEBUG)
            androidContext(this@NanoOrbitApp)
            modules(appModule)
        }
    }
}
