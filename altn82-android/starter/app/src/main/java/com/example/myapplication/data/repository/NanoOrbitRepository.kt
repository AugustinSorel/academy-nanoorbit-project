package com.example.myapplication.data.repository

import com.example.myapplication.data.local.NanoOrbitDao
import com.example.myapplication.data.local.toEntity
import com.example.myapplication.data.local.toDomain
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Mission
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.SatelliteDetail
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.StationSol
import com.example.myapplication.data.remote.NanoOrbitApi
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import java.util.concurrent.TimeUnit

class NanoOrbitRepository(
    private val api: NanoOrbitApi,
    private val dao: NanoOrbitDao
) {

    data class CacheResult<T>(
        val data: T,
        val isOffline: Boolean = false,
        val lastUpdated: Long? = null
    )

    suspend fun getSatellites(): CacheResult<List<Satellite>> {
        val cached = dao.getAllSatellites()
        val lastUpdated = dao.getLastUpdated()

        return try {
            val fresh = coroutineScope {
                val operationnelDeferred = async { api.getSatellites() }
                val enVeilleDeferred    = async {
                    runCatching { api.getSatellites("En veille") }.getOrElse { emptyList() }
                }
                val defaillantDeferred  = async {
                    runCatching { api.getSatellites("Défaillant") }.getOrElse { emptyList() }
                }
                val desorbiteDeferred   = async {
                    runCatching { api.getSatellites("Désorbité") }.getOrElse { emptyList() }
                }

                val operationnels = operationnelDeferred.await().map { sat ->
                    if (sat.statut == null) sat.copy(statut = StatutSatellite.OPERATIONNEL) else sat
                }

                operationnels +
                    enVeilleDeferred.await() +
                    defaillantDeferred.await() +
                    desorbiteDeferred.await()
            }

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

    suspend fun getSatelliteDetail(id: String): SatelliteDetail = api.getSatelliteDetail(id)

    suspend fun updateSatelliteStatut(id: String, statut: String): String {
        val response = api.updateSatelliteStatut(id, mapOf("statut" to statut))
        return response["statut"] ?: statut
    }

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

    suspend fun getStations(statut: String? = null): List<StationSol> =
        api.getStations(statut)

    suspend fun getMissions(statut: String? = null): List<Mission> =
        api.getMissions(statut)

    fun validateFenetreDuree(dureeSecondes: Int): String? = when {
        dureeSecondes < 1   -> "La durée doit être d'au moins 1 seconde (règle RG-F04)."
        dureeSecondes > 900 -> "La durée ne peut pas dépasser 900 secondes (règle RG-F04)."
        else                -> null
    }
}
