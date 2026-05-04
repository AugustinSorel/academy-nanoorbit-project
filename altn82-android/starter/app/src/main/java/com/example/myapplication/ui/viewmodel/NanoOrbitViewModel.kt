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

class NanoOrbitViewModel(private val repository: NanoOrbitRepository) : ViewModel() {

    private val _allSatellites = MutableStateFlow<List<Satellite>>(emptyList())

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline.asStateFlow()

    private val _lastUpdated = MutableStateFlow<Long?>(null)
    val lastUpdated: StateFlow<Long?> = _lastUpdated.asStateFlow()

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

    val operationnelCount: StateFlow<Int> = _allSatellites
        .combine(_allSatellites) { all, _ ->
            all.count { it.statut == StatutSatellite.OPERATIONNEL }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    private val _isFenetresLoading = MutableStateFlow(false)
    val isFenetresLoading: StateFlow<Boolean> = _isFenetresLoading.asStateFlow()

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

    private val _stations = MutableStateFlow<List<StationSol>>(emptyList())
    val stations: StateFlow<List<StationSol>> = _stations.asStateFlow()

    private val _satelliteDetail = MutableStateFlow<SatelliteDetail?>(null)
    val satelliteDetail: StateFlow<SatelliteDetail?> = _satelliteDetail.asStateFlow()

    init {
        loadSatellites()
        loadFenetres()
        loadStations()
    }

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
            _isFenetresLoading.value = true
            try {
                val result = repository.getFenetres()
                _fenetres.value = result.data
            } catch (_: Exception) {
            } finally {
                _isFenetresLoading.value = false
            }
        }
    }

    fun loadStations() {
        viewModelScope.launch {
            try {
                _stations.value = repository.getStations()
            } catch (_: Exception) {
                _stations.value = mockStations
            }
        }
    }

    fun loadSatelliteDetail(id: String) {
        viewModelScope.launch {
            try {
                _satelliteDetail.value = repository.getSatelliteDetail(id)
            } catch (_: Exception) {
                _satelliteDetail.value = null
            }
        }
    }

    fun onSearchQueryChange(query: String) { _searchQuery.value = query }
    fun onStatutFilterChange(statut: StatutSatellite?) { _selectedStatut.value = statut }
    fun onStationChange(station: String?) { _selectedStation.value = station }
    fun refreshSatellites() { loadSatellites() }
    fun refreshFenetres() { loadFenetres() }
    fun getSatelliteById(id: String): Satellite? =
        _allSatellites.value.find { it.idSatellite == id }
}
