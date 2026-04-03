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

/**
 * Interface Retrofit — miroir des routes API NanoOrbit.
 *
 * Routes couvertes (api/src/routes/) :
 *   satellites.ts  → GET /satellites, GET /satellites/:id, PATCH /satellites/:id/statut
 *   fenetres.ts    → GET /fenetres
 *   stations.ts    → GET /stations
 *   missions.ts    → GET /missions
 *   orbites.ts     → GET /orbites
 *
 * Désérialisation JSON → Kotlin :
 *   - Gson FieldNamingPolicy.LOWER_CASE_WITH_UNDERSCORES (configuré dans AppModule)
 *     mappe automatiquement snake_case Oracle → camelCase Kotlin.
 *   - StatutSatellite.@SerializedName mappe les valeurs françaises de la CHECK Oracle.
 *   - FenetreCom.statut utilise @SerializedName("statut_fenetre") (champ de la vue).
 *
 * Base URL configurée dans AppModule : https://api.nanoorbit.io/v1/
 */
interface NanoOrbitApi {

    // ── Satellites ───────────────────────────────────────────────────────────

    /**
     * Liste la constellation.
     * Sans filtre → vue v_satellites_operationnels (champs : orbite, nbInstruments, etatBatterie).
     * Avec ?statut= → table SATELLITE jointe ORBITE (champs : dateLancement, masse, statut…).
     */
    @GET("satellites")
    suspend fun getSatellites(
        @Query("statut") statut: String? = null
    ): List<Satellite>

    /**
     * Détail complet d'un satellite avec instruments, missions et 10 fenêtres récentes.
     * Source : table SATELLITE jointe ORBITE + sous-requêtes EMBARQUEMENT, PARTICIPATION, FENETRE_COM.
     */
    @GET("satellites/{id}")
    suspend fun getSatelliteDetail(@Path("id") id: String): SatelliteDetail

    /**
     * Met à jour le statut d'un satellite (RG-S01).
     * Body : { "statut": "Opérationnel" | "En veille" | "Défaillant" | "Désorbité" }
     */
    @PATCH("satellites/{id}/statut")
    suspend fun updateSatelliteStatut(
        @Path("id") id: String,
        @Body body: Map<String, String>
    ): Map<String, String>

    // ── Fenêtres de communication ─────────────────────────────────────────────

    /**
     * Liste les fenêtres via la vue v_fenetres_detail (champs enrichis : nomSatellite, nomStation…).
     * Filtres optionnels : ?statut=, ?satellite=, ?station=
     */
    @GET("fenetres")
    suspend fun getFenetres(
        @Query("statut")    statut:    String? = null,
        @Query("satellite") satellite: String? = null,
        @Query("station")   station:   String? = null
    ): List<FenetreCom>

    // ── Stations sol ─────────────────────────────────────────────────────────

    /**
     * Liste les stations sol avec le compteur de fenêtres (nbFenetresTotal).
     * Filtre optionnel : ?statut=Active|Maintenance|Inactive
     */
    @GET("stations")
    suspend fun getStations(
        @Query("statut") statut: String? = null
    ): List<StationSol>

    // ── Missions ─────────────────────────────────────────────────────────────

    /**
     * Liste les missions avec statistiques (nbSatellites, typesOrbites, volumeTotalMo).
     * Filtre optionnel : ?statut=Active|Terminée|Planifiée
     */
    @GET("missions")
    suspend fun getMissions(
        @Query("statut") statut: String? = null
    ): List<Mission>

    // ── Orbites ──────────────────────────────────────────────────────────────

    /** Liste toutes les orbites avec le nombre de satellites. */
    @GET("orbites")
    suspend fun getOrbites(): List<Orbite>
}
