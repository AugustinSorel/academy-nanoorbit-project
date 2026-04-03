package com.example.myapplication.data.repository

import com.example.myapplication.data.local.NanoOrbitDao
import com.example.myapplication.data.local.toEntity
import com.example.myapplication.data.local.toDomain
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Instrument
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.mockFenetres
import com.example.myapplication.data.model.mockInstruments
import com.example.myapplication.data.model.mockSatellites
import com.example.myapplication.data.remote.NanoOrbitApi
import kotlinx.coroutines.delay
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
 * Room joue le rôle de miroir local de la base Oracle, exactement comme demandé en Q3.
 * Commenté dans NanoOrbitDatabase.kt (lien explicite ALTN83).
 *
 * Validation RG-F04 — durée fenêtre [1, 900] secondes.
 * Miroir du trigger Oracle T3 (Phase 2 ALTN83) :
 *   TRIGGER T1_FENETRE_DUREE BEFORE INSERT OR UPDATE ON FENETRE_COM
 *   FOR EACH ROW BEGIN
 *     IF :NEW.duree < 1 OR :NEW.duree > 900 THEN
 *       RAISE_APPLICATION_ERROR(-20001, 'RG-F04 : durée hors bornes [1,900]');
 *     END IF;
 *   END;
 * Côté Android : validation préventive avant envoi réseau pour retour immédiat.
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

    /**
     * Récupère les satellites selon la stratégie Cache-First.
     *
     * Phase 3 : lit Room d'abord, tente la mise à jour réseau, fallback cache si KO.
     */
    suspend fun getSatellites(): CacheResult<List<Satellite>> {
        val cached = dao.getAllSatellites()
        val lastUpdated = dao.getLastUpdated()

        return try {
            delay(500) // simulation latence — à supprimer avec vraie API
            // TODO Phase réelle : val fresh = api.getSatellites()
            val fresh = mockSatellites
            dao.upsertSatellites(fresh.map { it.toEntity() })
            CacheResult(data = fresh, isOffline = false, lastUpdated = System.currentTimeMillis())
        } catch (e: Exception) {
            if (cached.isNotEmpty()) {
                // Fallback cache : données locales disponibles, on reste hors-ligne
                CacheResult(
                    data = cached.map { it.toDomain() },
                    isOffline = true,
                    lastUpdated = lastUpdated
                )
            } else {
                // Cache vide ET réseau KO : l'erreur doit remonter au ViewModel
                throw e
            }
        }
    }

    /**
     * Récupère les fenêtres des 7 prochains jours — Cache-First.
     */
    suspend fun getFenetres(): CacheResult<List<FenetreCom>> {
        val sevenDaysAgo = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(7)
        val cached = dao.getUpcomingFenetres(sevenDaysAgo)

        return try {
            delay(400)
            // TODO Phase réelle : val fresh = api.getFenetres()
            val fresh = mockFenetres
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

    /** Instruments d'un satellite (pas de cache Room en Phase 3). */
    suspend fun getInstruments(satelliteId: String): List<Instrument> {
        delay(300)
        return mockInstruments
    }

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
