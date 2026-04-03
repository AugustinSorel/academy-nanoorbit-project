package com.example.myapplication.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.mockEmbarquements
import com.example.myapplication.data.model.mockMissions
import com.example.myapplication.data.model.mockParticipations
import com.example.myapplication.data.repository.NanoOrbitRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * ViewModel unique — Phase 3.
 *
 * Centralise tout l'état observable : Dashboard, DetailScreen, PlanningScreen.
 * Ne connaît pas l'interface (règle MVVM). Survit aux rotations via viewModelScope.
 *
 * StateFlows exposés (6 + dérivés) :
 *   - satellites, isLoading, errorMessage, searchQuery, selectedStatut → Dashboard
 *   - fenetres, selectedStation → PlanningScreen
 *   - isOffline, lastUpdated → bannière hors-ligne (Cache-First)
 */
class NanoOrbitViewModel(private val repository: NanoOrbitRepository) : ViewModel() {

    // ── Source de vérité satellites ─────────────────────────────────────────
    private val _allSatellites = MutableStateFlow<List<Satellite>>(emptyList())

    // ── États chargement / erreur ───────────────────────────────────────────
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // ── Mode hors-ligne (Cache-First) ───────────────────────────────────────
    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline.asStateFlow()

    /** Horodatage de la dernière MAJ réseau (pour "Mis à jour il y a X min"). */
    private val _lastUpdated = MutableStateFlow<Long?>(null)
    val lastUpdated: StateFlow<Long?> = _lastUpdated.asStateFlow()

    // ── Recherche & filtre statut (Dashboard) ───────────────────────────────
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedStatut = MutableStateFlow<StatutSatellite?>(null)
    val selectedStatut: StateFlow<StatutSatellite?> = _selectedStatut.asStateFlow()

    /**
     * Liste filtrée en temps réel (searchQuery + selectedStatut).
     * Calcul dans le ViewModel via combine() pour garantir la testabilité.
     */
    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        _allSatellites,
        _searchQuery,
        _selectedStatut
    ) { satellites, query, statut ->
        satellites
            .filter { sat ->
                query.isBlank() ||
                    sat.nomSatellite.contains(query, ignoreCase = true) ||
                    sat.idOrbite.contains(query, ignoreCase = true)
            }
            .filter { sat -> statut == null || sat.statut == statut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** Satellites opérationnels dans la liste filtrée. */
    val operationnelCount: StateFlow<Int> = filteredSatellites
        .combine(_allSatellites) { filtered, _ ->
            filtered.count { it.statut == StatutSatellite.OPERATIONNEL }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    // ── Fenêtres de communication (PlanningScreen) ──────────────────────────
    private val _fenetres = MutableStateFlow<List<FenetreCom>>(emptyList())

    private val _selectedStation = MutableStateFlow<String?>(null)
    val selectedStation: StateFlow<String?> = _selectedStation.asStateFlow()

    /** Fenêtres filtrées par station et triées chronologiquement. */
    val filteredFenetres: StateFlow<List<FenetreCom>> = combine(
        _fenetres,
        _selectedStation
    ) { fenetres, station ->
        fenetres
            .filter { f -> station == null || f.codeStation == station }
            .sortedBy { it.datetimeDebut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        loadSatellites()
        loadFenetres()
    }

    // ── Fonctions publiques ─────────────────────────────────────────────────

    fun loadSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                val result = repository.getSatellites()
                _allSatellites.value = result.data
                _isOffline.value = result.isOffline
                _lastUpdated.value = result.lastUpdated
            } catch (e: Exception) {
                _errorMessage.value = "Impossible de charger les satellites : ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadFenetres() {
        viewModelScope.launch {
            try {
                val result = repository.getFenetres()
                _fenetres.value = result.data
            } catch (e: Exception) {
                // Erreur silencieuse pour les fenêtres (l'erreur satellites est suffisante)
            }
        }
    }

    fun onSearchQueryChange(query: String) { _searchQuery.value = query }

    fun onStatutFilterChange(statut: StatutSatellite?) { _selectedStatut.value = statut }

    fun onStationChange(station: String?) { _selectedStation.value = station }

    /** Recharge depuis le repository (bouton "Réessayer" + pull-to-refresh). */
    fun refreshSatellites() { loadSatellites() }

    // ── Helpers pour DetailScreen ───────────────────────────────────────────

    /** Retourne le satellite correspondant à l'id passé en paramètre de route. */
    fun getSatelliteById(id: String): Satellite? =
        _allSatellites.value.find { it.idSatellite == id }

    /** Instruments embarqués du satellite (via les embarquements mock). */
    fun getEmbarquementsForSatellite(satelliteId: String) =
        mockEmbarquements.filter { it.idSatellite == satelliteId }

    /** Missions actives impliquant ce satellite. */
    fun getMissionsForSatellite(satelliteId: String) =
        mockParticipations
            .filter { it.idSatellite == satelliteId }
            .mapNotNull { p ->
                mockMissions.find { it.idMission == p.idMission }
                    ?.let { m -> Pair(m, p.roleSatellite) }
            }
}
