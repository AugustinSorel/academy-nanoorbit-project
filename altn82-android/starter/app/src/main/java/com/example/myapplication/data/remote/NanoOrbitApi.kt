package com.example.myapplication.data.remote

import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Instrument
import com.example.myapplication.data.model.Satellite
import retrofit2.http.GET
import retrofit2.http.Path

/**
 * Interface Retrofit — API REST NanoOrbit.
 *
 * Endpoints miroir du schéma Oracle ALTN83 :
 *   - GET /satellites       → table SATELLITE
 *   - GET /satellites/{id}/instruments → jointure EMBARQUEMENT + INSTRUMENT
 *   - GET /fenetres         → table FENETRE_COM
 *
 * Base URL configurée dans AppModule : https://api.nanoorbit.io/v1/
 * Phase 2 : les données sont simulées dans NanoOrbitRepository (mock + delay).
 * Phase 3 : les appels réels remplaceront les mocks.
 */
interface NanoOrbitApi {

    /** Liste complète de la constellation. */
    @GET("satellites")
    suspend fun getSatellites(): List<Satellite>

    /** Instruments embarqués d'un satellite donné. */
    @GET("satellites/{id}/instruments")
    suspend fun getInstruments(@Path("id") satelliteId: String): List<Instrument>

    /** Toutes les fenêtres de communication (Planifiées et Réalisées). */
    @GET("fenetres")
    suspend fun getFenetres(): List<FenetreCom>
}
