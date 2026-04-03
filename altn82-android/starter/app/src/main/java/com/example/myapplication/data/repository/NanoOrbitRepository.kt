package com.example.myapplication.data.repository

import com.example.myapplication.data.local.NanoOrbitDao
import com.example.myapplication.data.local.toEntity
import com.example.myapplication.data.local.toDomain
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Mission
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.SatelliteDetail
import com.example.myapplication.data.model.StationSol
import com.example.myapplication.data.remote.NanoOrbitApi
import java.util.concurrent.TimeUnit

/**
 * Repository principal — stratégie Cache-First pour le mode hors-ligne.
 *
 * Algorithme Cache-First (Phase 3 — L3-D) :
 *   1. Lire le cache Room en premier → retour immédiat, même sans réseau.
 *   2. Tenter la mise à jour réseau en arrière-plan.
 *   3. Si le réseau échoue → retourner les données du cache + isOffline = true.
 *   4. Si le cache est vide ET réseau KO → propager l'exception (erreur affichée).
 *
 * Synergie ALTN83 Q3 : cette stratégie répond directement à la question
 * "Comment Singapour peut-il continuer à planifier si le serveur central est indisponible ?"
 * Room joue le rôle de miroir local de la base Oracle.
 *
 * Validation RG-F04 — durée fenêtre [1, 900] secondes.
 * Miroir du trigger Oracle T3 côté Android : validation préventive avant envoi réseau.
 *
 * Routes couvertes :
 *   GET /satellites          → getSatellites()
 *   GET /satellites/:id      → getSatelliteDetail()
 *   GET /fenetres            → getFenetres()
 *   GET /stations            → getStations()
 *   GET /missions            → getMissions()
 *   PATCH /satellites/:id/statut → updateSatelliteStatut()
 */
class NanoOrbitRepository(
    private val api: NanoOrbitApi,
    private val dao: NanoOrbitDao
) {

    /**
     * Résultat enrichi : données + indicateur hors-ligne + âge du cache.
     */
    data class CacheResult<T>(
        val data: T,
        val isOffline: Boolean = false,
        val lastUpdated: Long? = null
    )

    // ── Satellites ───────────────────────────────────────────────────────────

    /**
     * Récupère la liste des satellites selon la stratégie Cache-First.
     * Sans filtre : utilise la vue v_satellites_operationnels (champs allégés).
     */
    suspend fun getSatellites(): CacheResult<List<Satellite>> {
        val cached = dao.getAllSatellites()
        val lastUpdated = dao.getLastUpdated()

        return try {
            val fresh = api.getSatellites()
            dao.upsertSatellites(fresh.map { it.toEntity() })
            CacheResult(data = fresh, isOffline = false, lastUpdated = System.currentTimeMillis())
        } catch (e: Exception) {
            if (cached.isNotEmpty()) {
                CacheResult(
                    data = cached.map { it.toDomain() },
                    isOffline = true,
                    lastUpdated = lastUpdated
                )
            } else {
                throw e
            }
        }
    }

    /**
     * Détail complet d'un satellite : instruments, missions, fenêtres récentes.
     * Source : GET /satellites/:id — pas de cache Room (données fraîches requises).
     */
    suspend fun getSatelliteDetail(id: String): SatelliteDetail = api.getSatelliteDetail(id)

    /**
     * Met à jour le statut d'un satellite via PATCH /satellites/:id/statut.
     * @return le nouveau statut confirmé par le serveur.
     */
    suspend fun updateSatelliteStatut(id: String, statut: String): String {
        val response = api.updateSatelliteStatut(id, mapOf("statut" to statut))
        return response["statut"] ?: statut
    }

    // ── Fenêtres de communication ─────────────────────────────────────────────

    /**
     * Récupère les fenêtres des 7 prochains jours — Cache-First.
     * Source : vue v_fenetres_detail (champs enrichis : nomSatellite, nomStation…).
     */
    suspend fun getFenetres(
        statut: String? = null,
        satellite: String? = null,
        station: String? = null
    ): CacheResult<List<FenetreCom>> {
        val sevenDaysAgo = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(7)
        val cached = dao.getUpcomingFenetres(sevenDaysAgo)

        return try {
            val fresh = api.getFenetres(statut, satellite, station)
            dao.upsertFenetres(fresh.map { it.toEntity() })
            CacheResult(data = fresh, isOffline = false)
        } catch (e: Exception) {
            if (cached.isNotEmpty()) {
                CacheResult(data = cached.map { it.toDomain() }, isOffline = true)
            } else {
                throw e
            }
        }
    }

    // ── Stations sol ─────────────────────────────────────────────────────────

    /**
     * Liste les stations sol depuis GET /stations.
     * Pas de cache Room — les stations sont peu nombreuses et rarement modifiées.
     */
    suspend fun getStations(statut: String? = null): List<StationSol> =
        api.getStations(statut)

    // ── Missions ─────────────────────────────────────────────────────────────

    /** Liste les missions depuis GET /missions. */
    suspend fun getMissions(statut: String? = null): List<Mission> =
        api.getMissions(statut)

    // ── Validation métier ─────────────────────────────────────────────────────

    /**
     * Validation RG-F04 — durée [1, 900] secondes.
     * @return null si valide, message d'erreur lisible sinon.
     */
    fun validateFenetreDuree(dureeSecondes: Int): String? = when {
        dureeSecondes < 1   -> "La durée doit être d'au moins 1 seconde (règle RG-F04)."
        dureeSecondes > 900 -> "La durée ne peut pas dépasser 900 secondes (règle RG-F04)."
        else                -> null
    }
}
