package com.example.myapplication.data.remote

import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Mission
import com.example.myapplication.data.model.Orbite
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.SatelliteDetail
import com.example.myapplication.data.model.StationSol
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.Path
import retrofit2.http.Query

interface NanoOrbitApi {

    @GET("satellites")
    suspend fun getSatellites(
        @Query("statut") statut: String? = null
    ): List<Satellite>

    @GET("satellites/{id}")
    suspend fun getSatelliteDetail(@Path("id") id: String): SatelliteDetail

    @PATCH("satellites/{id}/statut")
    suspend fun updateSatelliteStatut(
        @Path("id") id: String,
        @Body body: Map<String, String>
    ): Map<String, String>

    @GET("fenetres")
    suspend fun getFenetres(
        @Query("statut")    statut:    String? = null,
        @Query("satellite") satellite: String? = null,
        @Query("station")   station:   String? = null
    ): List<FenetreCom>

    @GET("stations")
    suspend fun getStations(
        @Query("statut") statut: String? = null
    ): List<StationSol>

    @GET("missions")
    suspend fun getMissions(
        @Query("statut") statut: String? = null
    ): List<Mission>

    @GET("orbites")
    suspend fun getOrbites(): List<Orbite>
}
