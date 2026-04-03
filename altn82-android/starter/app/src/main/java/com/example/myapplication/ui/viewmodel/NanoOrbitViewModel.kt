package com.example.myapplication.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.SatelliteDetail
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.StationSol
import com.example.myapplication.data.model.mockStations
import com.example.myapplication.data.repository.NanoOrbitRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * ViewModel unique — Phase 3 / refactoring routes.
 *
 * StateFlows exposés :
 *   Dashboard   : satellites, isLoading, errorMessage, isOffline, lastUpdated,
 *                 searchQuery, selectedStatut, filteredSatellites, operationnelCount
 *   Planning    : fenetres, selectedStation, filteredFenetres
 *   Detail      : satelliteDetail (chargé à la demande via loadSatelliteDetail)
 *   Stations    : stations (chargées au démarrage, fallback mock si API KO)
 */
class NanoOrbitViewModel(private val repository: NanoOrbitRepository) : ViewModel() {

    // ── Source de vérité satellites ──────────────────────────────────────────
    private val _allSatellites = MutableStateFlow<List<Satellite>>(emptyList())

    // ── États chargement / erreur ────────────────────────────────────────────
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // ── Mode hors-ligne (Cache-First) ────────────────────────────────────────
    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline.asStateFlow()

    private val _lastUpdated = MutableStateFlow<Long?>(null)
    val lastUpdated: StateFlow<Long?> = _lastUpdated.asStateFlow()

    // ── Recherche & filtre statut (Dashboard) ────────────────────────────────
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedStatut = MutableStateFlow<StatutSatellite?>(null)
    val selectedStatut: StateFlow<StatutSatellite?> = _selectedStatut.asStateFlow()

    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        _allSatellites,
        _searchQuery,
        _selectedStatut
    ) { satellites, query, statut ->
        satellites
            .filter { sat ->
                query.isBlank() ||
                    sat.nomSatellite.contains(query, ignoreCase = true) ||
                    sat.idOrbite?.contains(query, ignoreCase = true) == true ||
                    sat.orbite?.contains(query, ignoreCase = true) == true
            }
            .filter { sat -> statut == null || sat.statut == statut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** Satellites opérationnels dans la liste filtrée. */
    val operationnelCount: StateFlow<Int> = filteredSatellites
        .combine(_allSatellites) { filtered, _ ->
            filtered.count { it.statut == StatutSatellite.OPERATIONNEL || it.statut == null }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    // ── Fenêtres de communication (PlanningScreen) ───────────────────────────
    private val _fenetres = MutableStateFlow<List<FenetreCom>>(emptyList())

    private val _selectedStation = MutableStateFlow<String?>(null)
    val selectedStation: StateFlow<String?> = _selectedStation.asStateFlow()

    val filteredFenetres: StateFlow<List<FenetreCom>> = combine(
        _fenetres,
        _selectedStation
    ) { fenetres, station ->
        fenetres
            .filter { f -> station == null || f.codeStation == station }
            .sortedBy { it.datetimeDebut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    // ── Stations sol (PlanningScreen + MapScreen) ────────────────────────────
    private val _stations = MutableStateFlow<List<StationSol>>(emptyList())
    val stations: StateFlow<List<StationSol>> = _stations.asStateFlow()

    // ── Détail satellite (DetailScreen) ─────────────────────────────────────
    private val _satelliteDetail = MutableStateFlow<SatelliteDetail?>(null)
    val satelliteDetail: StateFlow<SatelliteDetail?> = _satelliteDetail.asStateFlow()

    init {
        loadSatellites()
        loadFenetres()
        loadStations()
    }

    // ── Chargements ─────────────────────────────────────────────────────────

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
            } catch (_: Exception) {
                // Erreur silencieuse — l'erreur satellites est suffisante
            }
        }
    }

    fun loadStations() {
        viewModelScope.launch {
            try {
                _stations.value = repository.getStations()
            } catch (_: Exception) {
                // Fallback sur les données mock si l'API est indisponible
                _stations.value = mockStations
            }
        }
    }

    /**
     * Charge le détail complet d'un satellite depuis GET /satellites/:id.
     * Appelé par DetailScreen via LaunchedEffect(satelliteId).
     */
    fun loadSatelliteDetail(id: String) {
        viewModelScope.launch {
            try {
                _satelliteDetail.value = repository.getSatelliteDetail(id)
            } catch (_: Exception) {
                _satelliteDetail.value = null
            }
        }
    }

    // ── Actions UI ───────────────────────────────────────────────────────────

    fun onSearchQueryChange(query: String) { _searchQuery.value = query }
    fun onStatutFilterChange(statut: StatutSatellite?) { _selectedStatut.value = statut }
    fun onStationChange(station: String?) { _selectedStation.value = station }
    fun refreshSatellites() { loadSatellites() }

    // ── Helpers pour DetailScreen ────────────────────────────────────────────

    /** Retourne le satellite de la liste (données allégées vue opérationnelle). */
    fun getSatelliteById(id: String): Satellite? =
        _allSatellites.value.find { it.idSatellite == id }
}
